import 'package:flutter/material.dart';

import '../app_state/theme_controller.dart';

class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({
    super.key,
    required this.controller,
    required this.designId,
  });

  final ThemeController controller;
  final String designId;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: controller,
      builder: (context, mode, _) {
        return IconButton(
          key: Key(designId),
          tooltip: controller.label,
          icon: Icon(controller.icon),
          onPressed: controller.cycle,
        );
      },
    );
  }
}
