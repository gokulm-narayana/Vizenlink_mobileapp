import 'package:flutter/material.dart';

import '../../app_state/homes_controller.dart';
import '../../models/home.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_background.dart';

class ManageHomesScreen extends StatelessWidget {
  const ManageHomesScreen({super.key, required this.homesController});

  static const routeName = 'homes/manage';

  final HomesController homesController;

  Future<void> _showNameDialog(
    BuildContext context, {
    required String title,
    required String label,
    required String confirmLabel,
    String initialValue = '',
    required ValueChanged<String> onConfirm,
  }) async {
    final controller = TextEditingController(text: initialValue);
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(labelText: label),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(controller.text.trim()),
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );

    if (name != null && name.isNotEmpty) {
      onConfirm(name);
    }
  }

  Future<void> _confirmDeleteHome(BuildContext context, Home home) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete home?'),
          content: Text(
            'This will remove "${home.name}" and its ${home.cameras.length} camera(s).',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      homesController.deleteHome(home.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<HomesState>(
      valueListenable: homesController,
      builder: (context, state, _) {
        final atHomeLimit = !homesController.canAddHome;

        return GradientBackground(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              key: const Key('HOMES-001'),
              title: const Text('Manage homes'),
            ),
            body: Column(
              children: [
                if (atHomeLimit)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Text(
                      'Maximum of $maxHomes homes reached.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    key: const Key('HOMES-002'),
                    padding: const EdgeInsets.all(16),
                    itemCount: state.homes.length,
                    itemBuilder: (context, index) {
                      final home = state.homes[index];
                      final atRoomLimit = !homesController.canAddRoom(home.id);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GlassCard(
                          padding: EdgeInsets.zero,
                          child: Material(
                            type: MaterialType.transparency,
                            child: Theme(
                              data: Theme.of(
                                context,
                              ).copyWith(dividerColor: Colors.transparent),
                              child: ExpansionTile(
                                key: Key('HOMES-006-${home.id}'),
                                tilePadding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                childrenPadding: const EdgeInsets.only(
                                  bottom: 8,
                                ),
                                title: Text(home.name),
                                subtitle: Text(
                                  '${home.cameras.length} camera(s) · ${home.rooms.length} room(s)',
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      key: Key('HOMES-003-${home.id}'),
                                      tooltip: 'Rename',
                                      icon: const Icon(Icons.edit_outlined),
                                      onPressed: () => _showNameDialog(
                                        context,
                                        title: 'Rename home',
                                        label: 'Home name',
                                        confirmLabel: 'Save',
                                        initialValue: home.name,
                                        onConfirm: (name) => homesController
                                            .renameHome(home.id, name),
                                      ),
                                    ),
                                    IconButton(
                                      key: Key('HOMES-004-${home.id}'),
                                      tooltip: 'Delete',
                                      icon: const Icon(Icons.delete_outline),
                                      onPressed: state.homes.length > 1
                                          ? () => _confirmDeleteHome(
                                              context,
                                              home,
                                            )
                                          : null,
                                    ),
                                    const Icon(Icons.expand_more),
                                  ],
                                ),
                                children: [
                                  for (final room in home.rooms)
                                    ListTile(
                                      key: Key('HOMES-007-${home.id}-$room'),
                                      dense: true,
                                      contentPadding: const EdgeInsets.only(
                                        left: 24,
                                        right: 8,
                                      ),
                                      title: Text(room),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            key: Key(
                                              'HOMES-008-${home.id}-$room',
                                            ),
                                            tooltip: 'Rename room',
                                            icon: const Icon(
                                              Icons.edit_outlined,
                                              size: 20,
                                            ),
                                            onPressed: () => _showNameDialog(
                                              context,
                                              title: 'Rename room',
                                              label: 'Room name',
                                              confirmLabel: 'Save',
                                              initialValue: room,
                                              onConfirm: (name) =>
                                                  homesController.renameRoom(
                                                    home.id,
                                                    room,
                                                    name,
                                                  ),
                                            ),
                                          ),
                                          IconButton(
                                            key: Key(
                                              'HOMES-009-${home.id}-$room',
                                            ),
                                            tooltip: 'Delete room',
                                            icon: const Icon(
                                              Icons.delete_outline,
                                              size: 20,
                                            ),
                                            onPressed: () async {
                                              final confirmed = await showDialog<bool>(
                                                context: context,
                                                builder: (dialogContext) =>
                                                    AlertDialog(
                                                      title: const Text(
                                                        'Delete room?',
                                                      ),
                                                      content: Text(
                                                        'Cameras in "$room" will become unassigned.',
                                                      ),
                                                      actions: [
                                                        TextButton(
                                                          onPressed: () =>
                                                              Navigator.of(
                                                                dialogContext,
                                                              ).pop(false),
                                                          child: const Text(
                                                            'Cancel',
                                                          ),
                                                        ),
                                                        TextButton(
                                                          onPressed: () =>
                                                              Navigator.of(
                                                                dialogContext,
                                                              ).pop(true),
                                                          child: const Text(
                                                            'Delete',
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                              );
                                              if (confirmed == true) {
                                                homesController.deleteRoom(
                                                  home.id,
                                                  room,
                                                );
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      left: 16,
                                      right: 8,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        TextButton.icon(
                                          key: Key('HOMES-010-${home.id}'),
                                          onPressed: atRoomLimit
                                              ? null
                                              : () => _showNameDialog(
                                                  context,
                                                  title: 'Add room',
                                                  label: 'Room name',
                                                  confirmLabel: 'Add',
                                                  onConfirm: (name) =>
                                                      homesController.addRoom(
                                                        home.id,
                                                        name,
                                                      ),
                                                ),
                                          icon: const Icon(Icons.add),
                                          label: const Text('Add room'),
                                        ),
                                        if (atRoomLimit)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              left: 12,
                                              bottom: 8,
                                            ),
                                            child: Text(
                                              'Maximum of $maxRoomsPerHome rooms reached.',
                                              style: Theme.of(
                                                context,
                                              ).textTheme.bodySmall,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            floatingActionButton: FloatingActionButton(
              key: const Key('HOMES-005'),
              tooltip: 'Add home',
              onPressed: atHomeLimit
                  ? null
                  : () => _showNameDialog(
                      context,
                      title: 'Add home',
                      label: 'Home name',
                      confirmLabel: 'Add',
                      onConfirm: homesController.addHome,
                    ),
              backgroundColor: atHomeLimit
                  ? Theme.of(context).disabledColor
                  : null,
              child: const Icon(Icons.add),
            ),
          ),
        );
      },
    );
  }
}
