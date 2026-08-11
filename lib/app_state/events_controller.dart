import 'package:flutter/foundation.dart';

import '../models/event.dart';

class EventsController extends ValueNotifier<List<RecordedEvent>> {
  EventsController() : super(_seedEvents());

  void deleteEvent(String eventId) {
    value = [
      for (final event in value)
        if (event.id != eventId) event,
    ];
  }

  static String _thumbnailFor(String seed) =>
      'https://picsum.photos/seed/$seed/480/270';

  static List<RecordedEvent> _seedEvents() {
    final now = DateTime.now();
    return [
      RecordedEvent(
        id: 'event-1',
        type: EventType.motion,
        cameraId: 'cam-1',
        cameraName: 'Front Door Cam',
        timestamp: now.subtract(const Duration(minutes: 20)),
        duration: const Duration(seconds: 12),
        thumbnailUrl: _thumbnailFor('event-motion-1'),
      ),
      RecordedEvent(
        id: 'event-2',
        type: EventType.person,
        cameraId: 'cam-2',
        cameraName: 'Backyard Cam',
        timestamp: now.subtract(const Duration(hours: 1, minutes: 10)),
        duration: const Duration(seconds: 34),
        thumbnailUrl: _thumbnailFor('event-person-1'),
      ),
      RecordedEvent(
        id: 'event-3',
        type: EventType.vehicle,
        cameraId: 'cam-4',
        cameraName: 'Living Room Cam',
        timestamp: now.subtract(const Duration(hours: 2)),
        duration: const Duration(seconds: 48),
        thumbnailUrl: _thumbnailFor('event-vehicle-1'),
      ),
      RecordedEvent(
        id: 'event-4',
        type: EventType.animal,
        cameraId: 'cam-2',
        cameraName: 'Backyard Cam',
        timestamp: now.subtract(const Duration(hours: 4)),
        duration: const Duration(seconds: 9),
        thumbnailUrl: _thumbnailFor('event-animal-1'),
      ),
      RecordedEvent(
        id: 'event-5',
        type: EventType.package,
        cameraId: 'cam-1',
        cameraName: 'Front Door Cam',
        timestamp: now.subtract(const Duration(hours: 6)),
        duration: const Duration(seconds: 21),
        thumbnailUrl: _thumbnailFor('event-package-1'),
      ),
      RecordedEvent(
        id: 'event-6',
        type: EventType.faceRecognized,
        cameraId: 'cam-1',
        cameraName: 'Front Door Cam',
        timestamp: now.subtract(const Duration(hours: 9)),
        duration: const Duration(seconds: 15),
        thumbnailUrl: _thumbnailFor('event-face-1'),
      ),
      RecordedEvent(
        id: 'event-7',
        type: EventType.strangerDetected,
        cameraId: 'cam-2',
        cameraName: 'Backyard Cam',
        timestamp: now.subtract(const Duration(hours: 11)),
        duration: const Duration(seconds: 27),
        thumbnailUrl: _thumbnailFor('event-stranger-1'),
      ),
      RecordedEvent(
        id: 'event-8',
        type: EventType.loitering,
        cameraId: 'cam-3',
        cameraName: 'Garage Cam',
        timestamp: now.subtract(const Duration(hours: 14)),
        duration: const Duration(minutes: 2, seconds: 5),
        thumbnailUrl: _thumbnailFor('event-loitering-1'),
      ),
      RecordedEvent(
        id: 'event-9',
        type: EventType.lineCrossing,
        cameraId: 'cam-4',
        cameraName: 'Living Room Cam',
        timestamp: now.subtract(const Duration(days: 1, hours: 1)),
        duration: const Duration(seconds: 18),
        thumbnailUrl: _thumbnailFor('event-linecrossing-1'),
      ),
      RecordedEvent(
        id: 'event-10',
        type: EventType.intrusion,
        cameraId: 'cam-3',
        cameraName: 'Garage Cam',
        timestamp: now.subtract(const Duration(days: 1, hours: 5)),
        duration: const Duration(seconds: 40),
        thumbnailUrl: _thumbnailFor('event-intrusion-1'),
      ),
      RecordedEvent(
        id: 'event-11',
        type: EventType.motion,
        cameraId: 'cam-5',
        cameraName: 'Kitchen Cam',
        timestamp: now.subtract(const Duration(days: 2, hours: 2)),
        duration: const Duration(seconds: 11),
        thumbnailUrl: _thumbnailFor('event-motion-2'),
      ),
      RecordedEvent(
        id: 'event-12',
        type: EventType.person,
        cameraId: 'cam-7',
        cameraName: 'Reception Cam',
        timestamp: now.subtract(const Duration(days: 3)),
        duration: const Duration(seconds: 22),
        thumbnailUrl: _thumbnailFor('event-person-2'),
      ),
    ];
  }
}
