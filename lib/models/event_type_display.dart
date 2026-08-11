import 'package:flutter/material.dart';

import 'event.dart';

/// Shared label/icon mapping for [EventType], used by EventsScreen so its
/// filter row and list items stay in sync.
extension EventTypeDisplay on EventType {
  String get label {
    switch (this) {
      case EventType.motion:
        return 'Motion';
      case EventType.person:
        return 'Person';
      case EventType.vehicle:
        return 'Vehicle';
      case EventType.animal:
        return 'Animal';
      case EventType.package:
        return 'Package';
      case EventType.faceRecognized:
        return 'Familiar Face';
      case EventType.strangerDetected:
        return 'Stranger';
      case EventType.loitering:
        return 'Loitering';
      case EventType.lineCrossing:
        return 'Line Crossing';
      case EventType.intrusion:
        return 'Intrusion';
    }
  }

  IconData get icon {
    switch (this) {
      case EventType.motion:
        return Icons.directions_run_rounded;
      case EventType.person:
        return Icons.person_rounded;
      case EventType.vehicle:
        return Icons.directions_car_rounded;
      case EventType.animal:
        return Icons.pets_rounded;
      case EventType.package:
        return Icons.inventory_2_rounded;
      case EventType.faceRecognized:
        return Icons.face_retouching_natural_rounded;
      case EventType.strangerDetected:
        return Icons.person_search_rounded;
      case EventType.loitering:
        return Icons.hourglass_bottom_rounded;
      case EventType.lineCrossing:
        return Icons.timeline_rounded;
      case EventType.intrusion:
        return Icons.warning_amber_rounded;
    }
  }

  /// Condensed color bucket for the timeline scrubber's clip segments and
  /// legend — keeps the legend to 4 colors instead of one per [EventType].
  Color get timelineColor {
    switch (this) {
      case EventType.motion:
        return const Color(0xFF3B82F6); // blue
      case EventType.person:
      case EventType.faceRecognized:
      case EventType.strangerDetected:
        return const Color(0xFF10B981); // green
      case EventType.loitering:
      case EventType.lineCrossing:
      case EventType.intrusion:
        return const Color(0xFFEF4444); // red
      case EventType.vehicle:
      case EventType.animal:
      case EventType.package:
        return const Color(0xFFF59E0B); // amber
    }
  }

  String get timelineBucketLabel {
    switch (this) {
      case EventType.motion:
        return 'Motion';
      case EventType.person:
      case EventType.faceRecognized:
      case EventType.strangerDetected:
        return 'Person';
      case EventType.loitering:
      case EventType.lineCrossing:
      case EventType.intrusion:
        return 'Alert';
      case EventType.vehicle:
      case EventType.animal:
      case EventType.package:
        return 'Other';
    }
  }
}
