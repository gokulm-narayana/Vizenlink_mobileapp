/// Which cameras a non-Owner member/invite can access. Owners always have
/// full access and never carry a scope. `allCameras: true` means every
/// camera across every home, including ones added later; otherwise access
/// is limited to [cameraIds].
class CameraAccessScope {
  const CameraAccessScope({this.allCameras = true, this.cameraIds = const {}});

  final bool allCameras;
  final Set<String> cameraIds;

  CameraAccessScope copyWith({bool? allCameras, Set<String>? cameraIds}) {
    return CameraAccessScope(
      allCameras: allCameras ?? this.allCameras,
      cameraIds: cameraIds ?? this.cameraIds,
    );
  }

  String summary(int totalCameraCount) {
    if (allCameras) return 'All cameras';
    if (cameraIds.isEmpty) return 'No cameras selected';
    return '${cameraIds.length} of $totalCameraCount cameras';
  }
}
