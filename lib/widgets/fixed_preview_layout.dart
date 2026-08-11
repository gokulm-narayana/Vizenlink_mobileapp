import 'package:flutter/material.dart';

/// Body layout for camera-settings screens that show a [preview] above a
/// list of controls: the preview stays fixed at the top (padded, outside
/// any scroll view) while only [scrollableChildren] scroll underneath it —
/// so dragging the controls (or a draggable OSD chip that happens to start
/// near the preview) never moves the preview itself.
class FixedPreviewLayout extends StatelessWidget {
  const FixedPreviewLayout({
    super.key,
    required this.preview,
    required this.scrollableChildren,
  });

  final Widget preview;
  final List<Widget> scrollableChildren;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: preview,
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: scrollableChildren,
          ),
        ),
      ],
    );
  }
}
