import 'package:flutter/material.dart';

import '../../app_state/homes_controller.dart';
import '../../models/camera.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/saving_overlay.dart';
import '../../widgets/settings_save_button.dart' show simulateCameraSave;

/// Stub scanned network, until a real Wi-Fi scan API is wired up (see
/// CLAUDE.md).
class _ScannedNetwork {
  const _ScannedNetwork({
    required this.ssid,
    required this.signalStrength,
    required this.isSecured,
  });

  final String ssid;

  /// 0–4 bar rating, same scale as `Camera.signalStrength`.
  final int signalStrength;
  final bool isSecured;
}

const _scannedNetworks = [
  _ScannedNetwork(ssid: 'HomeNet_5G', signalStrength: 4, isSecured: true),
  _ScannedNetwork(ssid: 'HomeNet_2.4G', signalStrength: 3, isSecured: true),
  _ScannedNetwork(ssid: 'Neighbor_WiFi', signalStrength: 2, isSecured: true),
  _ScannedNetwork(ssid: 'CoffeeShop_Free', signalStrength: 1, isSecured: false),
];

/// Configure Wi-Fi: scans (simulated) for nearby networks, lets the user
/// tap one and enter its password, or enter a network manually. Local-only
/// draft state — no CCTV protocol/backend or real Wi-Fi scan API is wired
/// up yet (see CLAUDE.md). On Connect, simulates a round-trip
/// (`simulateCameraSave`), writes the new network name through
/// `HomesController.updateCameraWifi`, and pops back to Camera Info.
class WifiConfigScreen extends StatefulWidget {
  const WifiConfigScreen({
    super.key,
    required this.camera,
    required this.homesController,
  });

  static const routeName = 'wifi-config';

  final Camera camera;
  final HomesController homesController;

  @override
  State<WifiConfigScreen> createState() => _WifiConfigScreenState();
}

class _WifiConfigScreenState extends State<WifiConfigScreen> {
  bool _isScanning = true;
  _ScannedNetwork? _selectedNetwork;
  bool _isManualEntry = false;
  final _passwordController = TextEditingController();
  final _manualNameController = TextEditingController();
  final _manualPasswordController = TextEditingController();
  bool _isConnecting = false;

  String get _homeId {
    return widget.homesController.value.homes
        .firstWhere((home) => home.cameras.any((c) => c.id == widget.camera.id))
        .id;
  }

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() => _isScanning = false);
    });
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _manualNameController.dispose();
    _manualPasswordController.dispose();
    super.dispose();
  }

  void _selectNetwork(_ScannedNetwork network) {
    setState(() {
      _selectedNetwork = network;
      _isManualEntry = false;
      _passwordController.clear();
    });
  }

  void _openManualEntry() {
    setState(() {
      _isManualEntry = true;
      _selectedNetwork = null;
    });
  }

  Future<void> _connect(String ssid) async {
    setState(() => _isConnecting = true);
    final succeeded = await simulateCameraSave();
    if (!mounted) return;
    setState(() => _isConnecting = false);
    if (succeeded) {
      widget.homesController.updateCameraWifi(_homeId, widget.camera.id, ssid);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Connected to $ssid')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to connect. Try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          key: const Key('WIFI-001'),
          title: const Text('Configure Wi-Fi'),
        ),
        body: SavingOverlay(
          isSaving: _isConnecting,
          label: 'Connecting…',
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (_isScanning)
                const Padding(
                  key: Key('WIFI-002'),
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 12),
                        Text('Scanning for networks…'),
                      ],
                    ),
                  ),
                )
              else ...[
                GlassCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    key: const Key('WIFI-003'),
                    children: [
                      for (final network in _scannedNetworks)
                        _NetworkTile(
                          network: network,
                          selected: _selectedNetwork == network,
                          onTap: () => _selectNetwork(network),
                        ),
                    ],
                  ),
                ),
                if (_selectedNetwork != null) ...[
                  const SizedBox(height: 16),
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Connect to ${_selectedNetwork!.ssid}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          key: const Key('WIFI-004'),
                          controller: _passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            prefixIcon: Icon(Icons.lock_outline),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          key: const Key('WIFI-005'),
                          onPressed:
                              (!_selectedNetwork!.isSecured ||
                                  _passwordController.text.isNotEmpty)
                              ? () => _connect(_selectedNetwork!.ssid)
                              : null,
                          child: const Text('Connect'),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                if (!_isManualEntry)
                  OutlinedButton.icon(
                    key: const Key('WIFI-006'),
                    onPressed: _openManualEntry,
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit manually'),
                  )
                else
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Manual network entry',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          key: const Key('WIFI-007'),
                          controller: _manualNameController,
                          decoration: const InputDecoration(
                            labelText: 'Network name',
                            prefixIcon: Icon(Icons.wifi),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          key: const Key('WIFI-008'),
                          controller: _manualPasswordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            prefixIcon: Icon(Icons.lock_outline),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          key: const Key('WIFI-009'),
                          onPressed: _manualNameController.text.isNotEmpty
                              ? () => _connect(_manualNameController.text)
                              : null,
                          child: const Text('Connect'),
                        ),
                      ],
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _NetworkTile extends StatelessWidget {
  const _NetworkTile({
    required this.network,
    required this.selected,
    required this.onTap,
  });

  final _ScannedNetwork network;
  final bool selected;
  final VoidCallback onTap;

  IconData get _signalIcon => switch (network.signalStrength.clamp(0, 4)) {
    0 => Icons.signal_cellular_0_bar,
    1 => Icons.signal_cellular_alt_1_bar,
    2 => Icons.signal_cellular_alt_2_bar,
    _ => Icons.signal_cellular_alt,
  };

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: selected
          ? colorScheme.primary.withValues(alpha: 0.12)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: ListTile(
          leading: Icon(_signalIcon, color: colorScheme.onSurfaceVariant),
          title: Text(network.ssid),
          trailing: network.isSecured
              ? Icon(
                  Icons.lock_outline,
                  size: 18,
                  color: colorScheme.onSurfaceVariant,
                )
              : null,
        ),
      ),
    );
  }
}
