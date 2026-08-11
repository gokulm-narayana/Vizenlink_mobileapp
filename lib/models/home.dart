import 'camera.dart';

class Home {
  const Home({
    required this.id,
    required this.name,
    this.cameras = const [],
    this.rooms = const [],
  });

  final String id;
  final String name;
  final List<Camera> cameras;
  final List<String> rooms;

  Home copyWith({String? name, List<Camera>? cameras, List<String>? rooms}) {
    return Home(
      id: id,
      name: name ?? this.name,
      cameras: cameras ?? this.cameras,
      rooms: rooms ?? this.rooms,
    );
  }
}
