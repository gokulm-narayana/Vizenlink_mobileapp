import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' show md5;
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:record/record.dart';

import 'talk_downlink_player.dart';

/// Outcome of [RtspTalkSession.connect].
enum TalkConnectResult {
  /// RECORD succeeded — mic is streaming, return audio is playing.
  connected,

  /// The camera rejected the session because another talker already holds
  /// it (`FR-CF-131`).
  busy,

  /// Microphone permission was denied on this device.
  micPermissionDenied,

  /// Any other failure (TLS, auth, RTSP error, network).
  error,
}

/// A self-contained client for the camera's **dedicated audio-only
/// two-way-talk** RTSPS module (`module_rtsps_talk.c`, port 560, discovered
/// via `TalkUriClient`/`POST /nuraeye/talk-uri`). Completely independent of
/// live view — its own TLS connection, its own state — so it runs whether
/// or not a video screen is showing anything.
///
/// **Replaces the old WebRTC-renegotiation talk mechanism** (2026-09-15) —
/// see `packages/camera_api/TWO_WAY_TALK_GUIDE.md`'s history note: the
/// camera's firmware removed the `{"talk": true}` flag on `POST /webrtc`
/// entirely on 2026-09-11 in favor of this dedicated module, so the old
/// mechanism was no longer just suboptimal, it was talking to an endpoint
/// the firmware had already stopped honoring.
///
/// Wire protocol (mirrors `testing_utilities/two_way_talk_rtsp_test.py`'s
/// `RtspsTalkSession`): `OPTIONS` → `DESCRIBE` (RFC 2617 Digest,
/// `realm="ONVIF"`, no `qop`, MD5) → `SETUP .../streamid=0`
/// (`interleaved=0-1`, camera mic → us) → `SETUP .../streamid=1`
/// (`interleaved=2-3`, our mic → camera) → `RECORD` → bidirectional
/// `$`-framed RTP → `TEARDOWN`. AAC-LC 8000 Hz mono both directions, RTP
/// payload type 97, RFC 3640 "AU-hbr" framing (4-byte AU-header section:
/// `00 10` then `auLen << 3`).
///
/// The `Authorization`/request-line URI is always `rtsp://host:port/talk`
/// (no `s`) — the same convention `RtspLiveViewSession` uses; the server's
/// `rtsp_digest_verify()` trusts the client-supplied string for its own
/// hash recomputation.
class RtspTalkSession {
  RtspTalkSession(Uri mediaUri, this._username, this._password)
    : _host = mediaUri.host,
      _port = mediaUri.port,
      _path = mediaUri.path.isEmpty ? '/talk' : mediaUri.path;

  final String _host;
  final int _port;
  final String _path;
  final String _username;
  final String _password;

  static const int _payloadType = 97;
  static const int _uplinkChannel =
      2; // interleaved=2-3, streamid=1 (our mic -> camera)
  static const int _downlinkChannel =
      0; // interleaved=0-1, streamid=0 (camera mic -> us)
  static const int _samplesPerFrame = 1024;

  SecureSocket? _socket;
  int _cseq = 0;
  String? _nonce;
  bool _closed = false;
  bool _reading = false;
  bool _recording = false;

  final AudioRecorder _recorder = AudioRecorder();
  StreamSubscription<Uint8List>? _micSub;
  Uint8List _adtsBuffer = Uint8List(0);
  int _ulSeq = 0;
  final int _ulSsrc = 0x5A5A0001;

  final TalkDownlinkPlayer downlink = TalkDownlinkPlayer();

  /// Fires when the connection is lost after RECORD (so the caller can end
  /// the call) — a genuine drop, distinct from [close] being called by the
  /// caller itself.
  final StreamController<void> _onEnded = StreamController<void>.broadcast();
  Stream<void> get onEnded => _onEnded.stream;

  // --- receive buffering (single reader once _reading is true) -----------
  final StreamController<Uint8List> _incoming = StreamController<Uint8List>();
  StreamSubscription<Uint8List>? _socketSub;
  StreamSubscription<Uint8List>? _incomingSub;
  final List<Uint8List> _chunkQueue = [];
  final List<Completer<Uint8List>> _chunkWaiters = [];
  Uint8List _recvBytes = Uint8List(0);
  int _recvOffset = 0;
  Completer<_TalkRtspResponse>? _pendingResponse;

  String get _uri => 'rtsp://$_host:$_port$_path';

  /// Opens the connection and runs OPTIONS/DESCRIBE/SETUP×2/RECORD, then
  /// starts the mic uplink and the return-audio player. On
  /// [TalkConnectResult.busy]/[TalkConnectResult.error] the session is
  /// fully torn down before returning.
  Future<TalkConnectResult> connect({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    if (_closed) return TalkConnectResult.error;

    if (!await _recorder.hasPermission()) {
      debugPrint('[RtspTalkSession] microphone permission denied');
      await close();
      return TalkConnectResult.micPermissionDenied;
    }

    try {
      _socket = await SecureSocket.connect(
        _host,
        _port,
        timeout: timeout,
        onBadCertificate: (_) =>
            true, // self-signed cert, same posture as RtspLiveViewSession
      );
      _socketSub = _socket!.listen(
        (chunk) {
          if (!_incoming.isClosed) _incoming.add(chunk);
        },
        onError: (Object _) => _incoming.close(),
        onDone: () => _incoming.close(),
        cancelOnError: true,
      );

      final options = await _request('OPTIONS', const {}, timeout);
      if (options.status != 200) {
        throw _TalkRtspException('OPTIONS failed: ${options.status}');
      }

      final describe = await _request('DESCRIBE', {
        'Accept': 'application/sdp',
      }, timeout);
      if (describe.status != 200) {
        throw _TalkRtspException('DESCRIBE failed: ${describe.status}');
      }

      final setup0 = await _request(
        'SETUP',
        {'Transport': 'RTP/AVP/TCP;unicast;interleaved=0-1'},
        timeout,
        uriOverride: '$_uri/streamid=0',
      );
      if (setup0.status != 200) {
        throw _TalkRtspException('SETUP streamid=0 failed: ${setup0.status}');
      }
      final setup1 = await _request(
        'SETUP',
        {'Transport': 'RTP/AVP/TCP;unicast;interleaved=2-3'},
        timeout,
        uriOverride: '$_uri/streamid=1',
      );
      if (setup1.status != 200) {
        throw _TalkRtspException('SETUP streamid=1 failed: ${setup1.status}');
      }

      final record = await _request('RECORD', const {}, timeout);
      if (record.status != 200) {
        // The camera enforces one talker at a time (FR-CF-131). With both
        // SETUPs done, a non-200 RECORD is that rejection, not a protocol
        // error on our side.
        final busy =
            record.status == 453 ||
            record.status == 455 ||
            record.status == 503;
        await close();
        return busy ? TalkConnectResult.busy : TalkConnectResult.error;
      }
      _recording = true;

      // From here the read loop owns the socket exclusively.
      _reading = true;
      unawaited(_readLoop());

      if (!await downlink.start()) {
        debugPrint(
          '[RtspTalkSession] return-audio player failed to start — continuing uplink-only',
        );
      }
      await _startUplink();
      return TalkConnectResult.connected;
    } catch (e) {
      debugPrint('[RtspTalkSession] connect failed: $e');
      await close();
      return TalkConnectResult.error;
    }
  }

  Future<void> _startUplink() async {
    final stream = await _recorder.startStream(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        sampleRate:
            8000, // AUDIO_SAMPLE_RATE -- must match module_rtsps_talk.c/module_aad exactly
        numChannels: 1,
        bitRate: 24000,
        echoCancel: true,
        noiseSuppress: true,
      ),
    );
    _adtsBuffer = Uint8List(0);
    _micSub = stream.listen(
      _onMicChunk,
      onError: (Object e) =>
          debugPrint('[RtspTalkSession] mic stream error: $e'),
    );
  }

  /// `record` streams AAC-LC with ADTS framing; split into individual
  /// access units, buffering an incomplete trailing frame across chunks.
  void _onMicChunk(Uint8List chunk) {
    if (_closed) return;
    final combined = Uint8List(_adtsBuffer.length + chunk.length)
      ..setRange(0, _adtsBuffer.length, _adtsBuffer)
      ..setRange(_adtsBuffer.length, _adtsBuffer.length + chunk.length, chunk);

    var offset = 0;
    while (offset + 7 <= combined.length) {
      if (combined[offset] != 0xFF || (combined[offset + 1] & 0xF0) != 0xF0) {
        offset++;
        continue;
      }
      final protectionAbsent = combined[offset + 1] & 0x01;
      final headerLen = protectionAbsent == 1 ? 7 : 9;
      if (offset + headerLen > combined.length) break;
      final frameLength =
          ((combined[offset + 3] & 0x03) << 11) |
          (combined[offset + 4] << 3) |
          (combined[offset + 5] >> 5);
      if (frameLength < headerLen) {
        offset++;
        continue;
      }
      if (offset + frameLength > combined.length) break;
      _sendUplinkAu(
        Uint8List.sublistView(
          combined,
          offset + headerLen,
          offset + frameLength,
        ),
      );
      offset += frameLength;
    }
    _adtsBuffer = offset < combined.length
        ? Uint8List.sublistView(combined, offset)
        : Uint8List(0);
  }

  /// One raw AAC AU → one `$`-framed RTP packet on the uplink channel.
  /// Layout matches what `module_rtsps_talk.c`'s `rtsps_talk_send_aac_frame()`
  /// builds in the other direction.
  void _sendUplinkAu(Uint8List au) {
    final socket = _socket;
    if (socket == null || _closed) return;
    final ts = (_ulSeq * _samplesPerFrame) & 0xFFFFFFFF;
    final packet = Uint8List(12 + 4 + au.length);
    packet[0] = 0x80;
    packet[1] = 0x80 | _payloadType; // marker bit set, PT 97
    packet[2] = (_ulSeq >> 8) & 0xFF;
    packet[3] = _ulSeq & 0xFF;
    packet[4] = (ts >> 24) & 0xFF;
    packet[5] = (ts >> 16) & 0xFF;
    packet[6] = (ts >> 8) & 0xFF;
    packet[7] = ts & 0xFF;
    packet[8] = (_ulSsrc >> 24) & 0xFF;
    packet[9] = (_ulSsrc >> 16) & 0xFF;
    packet[10] = (_ulSsrc >> 8) & 0xFF;
    packet[11] = _ulSsrc & 0xFF;
    packet[12] = 0x00;
    packet[13] = 0x10; // AU-headers-length = 16 bits
    final auHeader = (au.length & 0x1FFF) << 3;
    packet[14] = (auHeader >> 8) & 0xFF;
    packet[15] = auHeader & 0xFF;
    packet.setRange(16, 16 + au.length, au);

    final frame = Uint8List(4 + packet.length);
    frame[0] = 0x24; // '$'
    frame[1] = _uplinkChannel;
    frame[2] = (packet.length >> 8) & 0xFF;
    frame[3] = packet.length & 0xFF;
    frame.setRange(4, 4 + packet.length, packet);
    try {
      socket.add(frame);
    } catch (e) {
      debugPrint('[RtspTalkSession] uplink write failed: $e');
    }
    _ulSeq = (_ulSeq + 1) & 0xFFFF;
  }

  Future<void> _readLoop() async {
    try {
      while (!_closed) {
        final marker = await _readExact(1);
        if (marker[0] != 0x24) {
          final resp = await _parseResponseAfterFirstByte(marker);
          final pending = _pendingResponse;
          if (pending != null && !pending.isCompleted) {
            _pendingResponse = null;
            pending.complete(resp);
          }
          continue;
        }
        final hdr = await _readExact(3);
        final channel = hdr[0];
        final length = (hdr[1] << 8) | hdr[2];
        final payload = await _readExact(length);
        if (channel == _downlinkChannel) _handleDownlinkRtp(payload);
        // channel 1/3 = RTCP -- ignored.
      }
    } catch (e) {
      final pending = _pendingResponse;
      if (pending != null && !pending.isCompleted) {
        _pendingResponse = null;
        pending.completeError(e);
      }
      if (_recording && !_closed && !_onEnded.isClosed) _onEnded.add(null);
    }
  }

  /// RFC 3640 AU-hbr depacketizer (identical shape to
  /// `RtspLiveViewSession`'s own audio depacketization).
  void _handleDownlinkRtp(Uint8List packet) {
    if (packet.length < 12) return;
    if ((packet[1] & 0x7F) != _payloadType) return;
    final rtpPayload = packet.sublist(12);
    if (rtpPayload.length < 2) return;
    final auHeadersBits = (rtpPayload[0] << 8) | rtpPayload[1];
    final auHeadersBytes = (auHeadersBits + 7) ~/ 8;
    if (2 + auHeadersBytes > rtpPayload.length) return;
    final auCount = auHeadersBits ~/ 16;
    if (auCount == 0) return;
    final sizes = <int>[];
    for (var i = 0; i < auCount; i++) {
      final o = 2 + i * 2;
      sizes.add(((rtpPayload[o] << 8) | rtpPayload[o + 1]) >> 3);
    }
    var offset = 2 + auHeadersBytes;
    for (final size in sizes) {
      if (offset + size > rtpPayload.length) break;
      downlink.feed(rtpPayload.sublist(offset, offset + size));
      offset += size;
    }
  }

  // --- RTSP request/response -----------------------------------------------

  String _digestHeader(String method, String uri) {
    final ha1 = md5
        .convert(utf8.encode('$_username:ONVIF:$_password'))
        .toString();
    final ha2 = md5.convert(utf8.encode('$method:$uri')).toString();
    final response = md5.convert(utf8.encode('$ha1:$_nonce:$ha2')).toString();
    return 'Digest username="$_username", realm="ONVIF", nonce="$_nonce", uri="$uri", response="$response"';
  }

  Future<_TalkRtspResponse> _request(
    String method,
    Map<String, String> extraHeaders,
    Duration timeout, {
    String? uriOverride,
  }) async {
    final socket = _socket;
    if (socket == null) throw _TalkRtspException('socket closed');
    // The digest URI is always the base resource, even for a per-track
    // SETUP request line.
    final requestUri = uriOverride ?? _uri;
    _cseq++;
    final lines = <String>['$method $requestUri RTSP/1.0', 'CSeq: $_cseq'];
    if (_nonce != null) {
      lines.add('Authorization: ${_digestHeader(method, _uri)}');
    }
    // No Session header: module_rtsps_talk.c does not issue one in its
    // SETUP responses and two_way_talk_rtsp_test.py's RECORD sends none
    // either -- adding one risks a 454.
    extraHeaders.forEach((k, v) => lines.add('$k: $v'));
    final req = '${lines.join('\r\n')}\r\n\r\n';

    final Future<_TalkRtspResponse> respFuture;
    if (_reading) {
      final completer = Completer<_TalkRtspResponse>();
      _pendingResponse = completer;
      respFuture = completer.future;
    } else {
      respFuture = _readResponseDirect();
    }
    socket.add(utf8.encode(req));
    await socket.flush();

    final resp = await respFuture.timeout(timeout);
    if (resp.status == 401 && _nonce == null) {
      final wwwAuth =
          resp.headers['WWW-Authenticate'] ??
          resp.headers['Www-Authenticate'] ??
          '';
      final nonceMatch = RegExp('nonce="([^"]+)"').firstMatch(wwwAuth);
      if (nonceMatch != null) {
        _nonce = nonceMatch.group(1);
        return _request(
          method,
          extraHeaders,
          timeout,
          uriOverride: uriOverride,
        );
      }
    }
    return resp;
  }

  Future<_TalkRtspResponse> _readResponseDirect() async {
    Uint8List marker;
    while (true) {
      marker = await _readExact(1);
      if (marker[0] != 0x24) break;
      final hdr = await _readExact(3);
      await _readExact((hdr[1] << 8) | hdr[2]);
    }
    return _parseResponseAfterFirstByte(marker);
  }

  Future<_TalkRtspResponse> _parseResponseAfterFirstByte(
    Uint8List firstByte,
  ) async {
    final firstLine = await _readLine(prefix: firstByte);
    final statusMatch = RegExp(r'^RTSP/1\.0 (\d+)').firstMatch(firstLine);
    if (statusMatch == null) {
      throw _TalkRtspException('malformed status line: $firstLine');
    }
    final status = int.parse(statusMatch.group(1)!);
    final headers = <String, String>{};
    while (true) {
      final line = await _readLine();
      if (line.isEmpty) break;
      final idx = line.indexOf(':');
      if (idx > 0) {
        headers[line.substring(0, idx).trim()] = line.substring(idx + 1).trim();
      }
    }
    final cl = headers['Content-Length'] ?? headers['Content-length'];
    if (cl != null) await _readExact(int.parse(cl));
    return _TalkRtspResponse(status, headers);
  }

  Future<String> _readLine({Uint8List? prefix}) async {
    final builder = BytesBuilder();
    if (prefix != null) builder.add(prefix);
    while (true) {
      final b = await _readExact(1);
      if (b[0] == 0x0D) {
        final lf = await _readExact(1);
        if (lf[0] == 0x0A) break;
        builder.addByte(b[0]);
        builder.addByte(lf[0]);
        continue;
      }
      builder.addByte(b[0]);
    }
    return utf8.decode(builder.toBytes(), allowMalformed: true);
  }

  Future<Uint8List> _readExact(int n) async {
    while (_recvBytes.length - _recvOffset < n) {
      final chunk = await _nextChunk();
      final combined = BytesBuilder()
        ..add(_recvBytes.sublist(_recvOffset))
        ..add(chunk);
      _recvBytes = combined.toBytes();
      _recvOffset = 0;
    }
    final result = _recvBytes.sublist(_recvOffset, _recvOffset + n);
    _recvOffset += n;
    return result;
  }

  Future<Uint8List> _nextChunk() {
    _incomingSub ??= _incoming.stream.listen(
      (chunk) {
        if (_chunkWaiters.isNotEmpty) {
          _chunkWaiters.removeAt(0).complete(chunk);
        } else {
          _chunkQueue.add(chunk);
        }
      },
      onDone: () {
        while (_chunkWaiters.isNotEmpty) {
          _chunkWaiters
              .removeAt(0)
              .completeError(_TalkRtspException('connection closed'));
        }
      },
    );
    if (_chunkQueue.isNotEmpty) return Future.value(_chunkQueue.removeAt(0));
    final completer = Completer<Uint8List>();
    _chunkWaiters.add(completer);
    return completer.future;
  }

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    await _micSub?.cancel();
    _micSub = null;
    try {
      await _recorder.stop();
    } catch (_) {}
    await _recorder.dispose();
    if (_recording && _socket != null) {
      try {
        await _request('TEARDOWN', const {}, const Duration(seconds: 3));
      } catch (_) {}
    }
    _recording = false;
    await downlink.stop();
    await _socketSub?.cancel();
    await _incomingSub?.cancel();
    if (!_incoming.isClosed) await _incoming.close();
    if (!_onEnded.isClosed) await _onEnded.close();
    try {
      await _socket?.close();
    } catch (_) {}
    _socket = null;
  }
}

class _TalkRtspResponse {
  const _TalkRtspResponse(this.status, this.headers);
  final int status;
  final Map<String, String> headers;
}

class _TalkRtspException implements Exception {
  _TalkRtspException(this.message);
  final String message;
  @override
  String toString() => 'RtspTalkSession: $message';
}
