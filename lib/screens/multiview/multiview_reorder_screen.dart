import 'package:flutter/material.dart';

import '../../app_state/homes_controller.dart';

/// Full-screen dedicated page for sorting and reordering cameras within a home.
class MultiviewReorderScreen extends StatelessWidget {
  const MultiviewReorderScreen({
    super.key,
    required this.homeId,
    required this.homesController,
  });

  final String homeId;
  final HomesController homesController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          key: const Key('MVSORT-001'),
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(key: Key('MVSORT-002'), 'Reorder Cameras'),
      ),
      body: ValueListenableBuilder<HomesState>(
        valueListenable: homesController,
        builder: (context, state, child) {
          // If the home doesn't exist anymore for some reason, just show empty
          final home = state.homes.where((h) => h.id == homeId).firstOrNull;
          if (home == null) return const SizedBox.shrink();

          return ReorderableListView.builder(
            key: const Key('MVSORT-003'),
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: home.cameras.length,
            onReorderItem: (oldIndex, newIndex) {
              homesController.reorderCameras(homeId, oldIndex, newIndex);
            },
            itemBuilder: (context, index) {
              final camera = home.cameras[index];
              return ListTile(
                key: ValueKey('MVSORT-004-${camera.id}'),
                leading: const Icon(Icons.videocam),
                title: Text(camera.name),
                trailing: const Icon(Icons.drag_handle),
              );
            },
          );
        },
      ),
    );
  }
}
