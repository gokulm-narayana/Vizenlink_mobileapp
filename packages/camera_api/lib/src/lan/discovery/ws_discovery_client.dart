import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:xml/xml.dart';

/// One raw WS-Discovery `ProbeMatch` result — not yet verified as a genuine NuraEye device
/// (that's [NuraeyeClient.areYouNuraeyeDevice]'s job, run separately per candidate).
class WsDiscoveryCandidate {
  const WsDiscoveryCandidate({required this.scheme, required this.host, required this.port});

  final String scheme;
  final String host;
  final int port;

  Uri get deviceServiceUri => Uri(scheme: scheme, host: host, port: port, path: '/onvif/device_service');
}

/// Pure-Dart WS-Discovery client (multicast primary + unicast subnet-sweep fallback) — no
/// `package:flutter` dependency, per this project's LAN/WAN client architecture. Wire format and
/// timing mirror the archived `android_app`'s `WSDiscoveryScanner.java` exactly (cross-checked
/// against `vms/python/ws_discovery_scanner.py`, the same mechanism already proven in production
/// for VMS camera pairing) — see
/// `design/stages/mobile-app-android-2-camera-onboarding/DESIGN.md` §4.1 for the full rationale.
///
/// **Known deviation from the Java/Python references, documented not silent:** those platforms
/// can query a network interface's real subnet prefix length (`InterfaceAddress
/// .getNetworkPrefixLength()` / `netifaces`); `dart:io`'s `NetworkInterface` has no portable
/// equivalent, and this package cannot depend on a `package:flutter`-only plugin to get one. The
/// unicast sweep therefore assumes a `/24` subnet for each local IPv4 interface (host range
/// `.1`-`.254`) rather than deriving the interface's actual prefix — the overwhelmingly common
/// case for home/community LANs, this app's target deployment, but a real (documented)
/// simplification versus the platform-native references.
class WsDiscoveryClient {
  static const multicastAddress = '239.255.255.250';
  static const port = 3702;
  static const _onvifNetworkNamespace = 'http://www.onvif.org/ver10/network/wsdl';
  static const _localName = 'NetworkVideoTransmitter';

  /// Multicast probe, per `SCN-717` — the primary discovery tier.
  Future<List<WsDiscoveryCandidate>> scanMulticast({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    socket.broadcastEnabled = true;
    final results = <String, WsDiscoveryCandidate>{};

    final sub = socket.listen((event) {
      if (event != RawSocketEvent.read) return;
      final datagram = socket.receive();
      if (datagram == null) return;
      final candidate = _parseProbeMatches(utf8.decode(datagram.data, allowMalformed: true));
      if (candidate != null) results[candidate.host] = candidate;
    });

    try {
      socket.send(utf8.encode(_buildProbeMessage()), InternetAddress(multicastAddress), port);
      await Future<void>.delayed(timeout);
    } finally {
      await sub.cancel();
      socket.close();
    }
    return results.values.toList(growable: false);
  }

  /// Unicast subnet sweep, per `SCN-718` — run unconditionally alongside [scanMulticast] and
  /// merged with its results (not gated on multicast finding nothing; multicast on WiFi can fail
  /// partially, see `discovery_screen.dart`'s doc comment). Mirrors
  /// `WSDiscoveryScanner.startScanUnicast()`'s single-shared-socket send+receive pattern and
  /// timing (15s overall cap, 5s straggler wait after the last probe is sent).
  ///
  /// **Sends are paced, not fired in a tight loop — found and fixed 2026-08-20.** Firing all
  /// ~253 unicast probes back-to-back (the original behavior) triggers an ARP-resolution storm:
  /// most destination addresses in a `/24` sweep don't exist, and the kernel has to ARP-resolve
  /// (broadcast + wait) every one of them before it can actually queue the send, which was found
  /// via a real reproduction (a Python mirror of this exact algorithm) to bury/delay replies from
  /// the few real cameras mixed in — a burst sweep against a LAN with 6 known-live cameras found
  /// only 1; the same sweep paced at [sendInterval] found all 6-7 reliably, repeatably. This
  /// applies regardless of transport (WiFi or Ethernet) — it's local network/ARP congestion from
  /// the sweep itself, not a WiFi-specific issue (that's a separate, real gap: this camera's
  /// WiFi radio driver doesn't deliver *multicast* WS-Discovery frames at all, unrelated to this
  /// unicast path — see `kb/raw/2026-08-20-wifi-country-code-and-ws-discovery-multicast-gap.md`).
  Future<List<WsDiscoveryCandidate>> scanUnicast({
    Duration overallCap = const Duration(seconds: 15),
    Duration stragglerWait = const Duration(seconds: 5),
    Duration sendInterval = const Duration(milliseconds: 50),
  }) async {
    final hostAddresses = await _localSubnetHostAddresses();
    if (hostAddresses.isEmpty) return const [];

    final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    final results = <String, WsDiscoveryCandidate>{};

    final sub = socket.listen((event) {
      if (event != RawSocketEvent.read) return;
      final datagram = socket.receive();
      if (datagram == null) return;
      final candidate = _parseProbeMatches(utf8.decode(datagram.data, allowMalformed: true));
      if (candidate != null) results[candidate.host] = candidate;
    });

    final startTime = DateTime.now();
    try {
      final probeBytes = utf8.encode(_buildProbeMessage());
      for (final ip in hostAddresses) {
        socket.send(probeBytes, InternetAddress(ip), port);
        await Future<void>.delayed(sendInterval);
      }
      final elapsed = DateTime.now().difference(startTime);
      final remainingCap = overallCap - elapsed;
      final wait = remainingCap < stragglerWait
          ? (remainingCap.isNegative ? Duration.zero : remainingCap)
          : stragglerWait;
      await Future<void>.delayed(wait);
    } finally {
      await sub.cancel();
      socket.close();
    }
    return results.values.toList(growable: false);
  }

  String _buildProbeMessage() {
    final uuid = _randomUuid();
    return '<?xml version="1.0" encoding="UTF-8"?>'
        '<e:Envelope xmlns:e="http://www.w3.org/2003/05/soap-envelope" '
        'xmlns:w="http://schemas.xmlsoap.org/ws/2004/08/addressing" '
        'xmlns:d="http://schemas.xmlsoap.org/ws/2005/04/discovery" '
        'xmlns:dn="$_onvifNetworkNamespace">'
        '<e:Header>'
        '<w:MessageID>uuid:$uuid</w:MessageID>'
        '<w:To>urn:schemas-xmlsoap-org:ws:2005:04:discovery</w:To>'
        '<w:Action>http://schemas.xmlsoap.org/ws/2005/04/discovery/Probe</w:Action>'
        '</e:Header>'
        '<e:Body>'
        '<d:Probe>'
        '<d:Types>dn:$_localName</d:Types>'
        '</d:Probe>'
        '</e:Body>'
        '</e:Envelope>';
  }

  WsDiscoveryCandidate? _parseProbeMatches(String body) {
    try {
      final doc = XmlDocument.parse(body);
      final xAddrsEl = doc.findAllElements('XAddrs', namespace: '*');
      if (xAddrsEl.isEmpty) return null;
      final xAddrsText = xAddrsEl.first.innerText.trim();
      final firstAddr = xAddrsText.split(RegExp(r'\s+')).firstWhere(
            (a) => a.startsWith('http://') || a.startsWith('https://'),
            orElse: () => '',
          );
      if (firstAddr.isEmpty) return null;
      final uri = Uri.parse(firstAddr);
      return WsDiscoveryCandidate(
        scheme: uri.scheme,
        host: uri.host,
        port: uri.hasPort ? uri.port : (uri.scheme == 'https' ? 443 : 80),
      );
    } on Exception {
      return null;
    }
  }

  Future<List<String>> _localSubnetHostAddresses() async {
    final interfaces = await NetworkInterface.list(
      includeLoopback: false,
      type: InternetAddressType.IPv4,
    );
    final ownAddresses = <String>{};
    final subnets = <String>{};
    for (final interface in interfaces) {
      for (final addr in interface.addresses) {
        if (addr.isLoopback) continue;
        ownAddresses.add(addr.address);
        final parts = addr.address.split('.');
        if (parts.length == 4) {
          subnets.add('${parts[0]}.${parts[1]}.${parts[2]}');
        }
      }
    }
    final hosts = <String>[];
    for (final subnet in subnets) {
      for (var i = 1; i <= 254; i++) {
        final ip = '$subnet.$i';
        if (!ownAddresses.contains(ip)) hosts.add(ip);
      }
    }
    return hosts;
  }

  String _randomUuid() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    String hex(int start, int len) =>
        bytes.skip(start).take(len).map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex(0, 4)}-${hex(4, 2)}-${hex(6, 2)}-${hex(8, 2)}-${hex(10, 6)}';
  }
}
