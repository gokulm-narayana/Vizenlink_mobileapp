import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:video_player/video_player.dart';

/// Plays the two-way-talk **return** audio (camera microphone → phone) for
/// [RtspTalkSession]. The dedicated talk RTSPS module sends the camera's
/// mic as raw AAC-LC access units (RFC 3640 depacketized by the session);
/// this class re-wraps each AU in a 7-byte ADTS header and serves the
/// resulting continuous `audio/aac` byte stream over a `127.0.0.1` HTTP
/// loopback, which a hidden [VideoPlayerController] pulls and decodes with
/// the platform's own AAC decoder (ExoPlayer's `AdtsExtractor` on Android,
/// AVPlayer on iOS).
///
/// This mirrors [RtspLiveViewProxy]'s "remux → loopback HTTP →
/// video_player" shape, minus the fMP4 muxing (raw ADTS needs no
/// container). It is deliberately a separate, self-contained unit so it
/// never touches the live-view video pipeline.
///
/// Fixed format: **AAC-LC, 8000 Hz, mono** — this camera's real, fixed
/// mic/speaker rate (`AUDIO_SAMPLE_RATE`, and what `module_rtsps_talk.c`'s
/// SDP advertises as `MPEG4-GENERIC/8000`). The talk module carries no
/// in-band `AudioSpecificConfig`, so these must match the firmware exactly.
///
/// **Unverified pending hardware** (`TWO_WAY_TALK_GUIDE.md` §5/§8) —
/// endless-ADTS-over-HTTP progressive playback works on ExoPlayer/AVPlayer
/// in principle, but this exact path hasn't been checked on a device yet.
class TalkDownlinkPlayer {
  TalkDownlinkPlayer();

  static const int _sampleRateIndex = 11; // 8000 Hz, ISO/IEC 14496-3 Table 1.22
  static const int _channelConfig = 1; // mono
  static const int _aacProfile =
      2; // AAC-LC (the "object type"); ADTS encodes it as profile-1

  HttpServer? _server;
  HttpResponse? _response;
  VideoPlayerController? _controller;
  bool _started = false;
  bool _closed = false;

  /// Access units that arrived before the player connected to the loopback
  /// socket — flushed once it does. Bounded so a player that never
  /// connects can't grow this without limit.
  final List<Uint8List> _prebuffer = [];
  static const int _maxPrebufferedAus = 250; // ~30 s at 8000 Hz / 1024 samples

  /// Binds the loopback server and starts the hidden player. Returns
  /// `false` (and cleans up) on any failure — the caller treats return
  /// audio as best-effort, the uplink is what matters.
  Future<bool> start() async {
    if (_started || _closed) return _started;
    try {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      _server = server;
      server.listen(
        _handleRequest,
        onError: (Object e) => debugPrint('[TalkDownlink] server error: $e'),
      );

      final url = Uri.http(
        '${InternetAddress.loopbackIPv4.address}:${server.port}',
        '/talk.aac',
      );
      final controller = VideoPlayerController.networkUrl(url);
      _controller = controller;
      await controller.initialize();
      if (_closed) {
        await _teardown();
        return false;
      }
      await controller.setVolume(1.0);
      await controller.play();
      _started = true;
      debugPrint('[TalkDownlink] playing return audio via $url');
      return true;
    } catch (e) {
      debugPrint('[TalkDownlink] start failed: $e');
      await _teardown();
      return false;
    }
  }

  Future<void> _handleRequest(HttpRequest request) async {
    if (request.uri.path != '/talk.aac' || _response != null) {
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
      return;
    }
    final response = request.response;
    response.bufferOutput = false;
    response.headers
      ..contentType = ContentType('audio', 'aac')
      ..set(HttpHeaders.cacheControlHeader, 'no-store')
      ..removeAll(HttpHeaders.contentLengthHeader);
    _response = response;
    // Flush anything captured before the player connected.
    for (final au in _prebuffer) {
      response.add(_adts(au));
    }
    _prebuffer.clear();
    try {
      await response.done;
    } catch (_) {
      // Player disconnected -- normal on stop().
    }
  }

  /// Feed one raw AAC access unit (no ADTS, no AU-header) as depacketized
  /// by [RtspTalkSession].
  void feed(Uint8List rawAacAu) {
    if (_closed || rawAacAu.isEmpty) return;
    final response = _response;
    if (response == null) {
      if (_prebuffer.length < _maxPrebufferedAus) _prebuffer.add(rawAacAu);
      return;
    }
    try {
      response.add(_adts(rawAacAu));
    } catch (e) {
      debugPrint('[TalkDownlink] write failed: $e');
    }
  }

  /// Prepends the 7-byte ADTS header (protection-absent, so no CRC) for
  /// AAC-LC/8000/mono.
  Uint8List _adts(Uint8List au) {
    final frameLen = 7 + au.length;
    final out = Uint8List(frameLen);
    out[0] = 0xFF;
    out[1] = 0xF1; // MPEG-4, Layer 0, protection absent
    out[2] =
        ((_aacProfile - 1) << 6) |
        (_sampleRateIndex << 2) |
        ((_channelConfig >> 2) & 0x01);
    out[3] = ((_channelConfig & 0x03) << 6) | ((frameLen >> 11) & 0x03);
    out[4] = (frameLen >> 3) & 0xFF;
    out[5] =
        ((frameLen & 0x07) << 5) |
        0x1F; // buffer fullness (0x7FF = VBR) upper bits
    out[6] =
        0xFC; // buffer fullness lower bits | number_of_raw_data_blocks_in_frame - 1 (0)
    out.setRange(7, frameLen, au);
    return out;
  }

  Future<void> stop() async {
    if (_closed) return;
    _closed = true;
    await _teardown();
  }

  Future<void> _teardown() async {
    final response = _response;
    _response = null;
    if (response != null) {
      try {
        await response.close();
      } catch (_) {}
    }
    final controller = _controller;
    _controller = null;
    if (controller != null) {
      try {
        await controller.pause();
      } catch (_) {}
      await controller.dispose();
    }
    final server = _server;
    _server = null;
    await server?.close(force: true);
    _prebuffer.clear();
  }
}
