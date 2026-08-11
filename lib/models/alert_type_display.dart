import 'package:flutter/material.dart';

import 'alert.dart';

/// Shared label/icon mapping for [AlertType], used by both the notification
/// list and detail screens so they stay in sync.
extension AlertTypeDisplay on AlertType {
  String get label {
    switch (this) {
      case AlertType.motion:
        return 'Motion';
      case AlertType.person:
        return 'Person';
      case AlertType.vehicle:
        return 'Vehicle';
      case AlertType.animal:
        return 'Animal';
      case AlertType.package:
        return 'Package';
      case AlertType.faceRecognized:
        return 'Familiar Face';
      case AlertType.strangerDetected:
        return 'Stranger';
      case AlertType.loitering:
        return 'Loitering';
      case AlertType.lineCrossing:
        return 'Line Crossing';
      case AlertType.intrusion:
        return 'Intrusion';
      case AlertType.tampered:
        return 'Tampered';
      case AlertType.cameraMoved:
        return 'Camera Moved';
      case AlertType.viewObscured:
        return 'View Obscured';
      case AlertType.offline:
        return 'Offline';
      case AlertType.online:
        return 'Online';
      case AlertType.unauthorizedAccess:
        return 'Unauthorized Access';
      case AlertType.sdCardRemoved:
        return 'SD Card Removed';
      case AlertType.audioAnomaly:
        return 'Audio';
      case AlertType.lowBattery:
        return 'Low Battery';
      case AlertType.weakSignal:
        return 'Weak Signal';
      case AlertType.storageFull:
        return 'Storage Full';
      case AlertType.firmwareUpdate:
        return 'Firmware Update';
      case AlertType.other:
        return 'Other';
    }
  }

  IconData get icon {
    switch (this) {
      case AlertType.motion:
        return Icons.directions_run_rounded;
      case AlertType.person:
        return Icons.person_rounded;
      case AlertType.vehicle:
        return Icons.directions_car_rounded;
      case AlertType.animal:
        return Icons.pets_rounded;
      case AlertType.package:
        return Icons.inventory_2_rounded;
      case AlertType.faceRecognized:
        return Icons.face_retouching_natural_rounded;
      case AlertType.strangerDetected:
        return Icons.person_search_rounded;
      case AlertType.loitering:
        return Icons.hourglass_bottom_rounded;
      case AlertType.lineCrossing:
        return Icons.timeline_rounded;
      case AlertType.intrusion:
        return Icons.warning_amber_rounded;
      case AlertType.tampered:
        return Icons.visibility_off_rounded;
      case AlertType.cameraMoved:
        return Icons.control_camera_rounded;
      case AlertType.viewObscured:
        return Icons.blur_on_rounded;
      case AlertType.offline:
        return Icons.wifi_off_rounded;
      case AlertType.online:
        return Icons.wifi_rounded;
      case AlertType.unauthorizedAccess:
        return Icons.lock_person_rounded;
      case AlertType.sdCardRemoved:
        return Icons.sd_card_alert_rounded;
      case AlertType.audioAnomaly:
        return Icons.volume_up_rounded;
      case AlertType.lowBattery:
        return Icons.battery_alert_rounded;
      case AlertType.weakSignal:
        return Icons.signal_wifi_bad_rounded;
      case AlertType.storageFull:
        return Icons.storage_rounded;
      case AlertType.firmwareUpdate:
        return Icons.system_update_rounded;
      case AlertType.other:
        return Icons.notifications_rounded;
    }
  }
}
