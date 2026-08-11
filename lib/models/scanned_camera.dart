class ScannedCamera {
  const ScannedCamera({
    required this.id,
    required this.name,
    required this.ipAddress,
    required this.isConfigured,
  });

  final String id;
  final String name;
  final String ipAddress;
  final bool isConfigured;
}
