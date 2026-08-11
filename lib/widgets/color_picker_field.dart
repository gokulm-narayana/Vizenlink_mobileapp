import 'package:flutter/material.dart';

/// Tappable color swatch that opens an HSV color-picker dialog (hue strip +
/// saturation/value square) when tapped. Plain-Flutter implementation — no
/// external color-picker package.
class ColorPickerField extends StatelessWidget {
  const ColorPickerField({
    super.key,
    required this.settingsKey,
    required this.color,
    required this.enabled,
    required this.onChanged,
  });

  final Key settingsKey;
  final Color color;
  final bool enabled;
  final ValueChanged<Color> onChanged;

  Future<void> _openPicker(BuildContext context) async {
    final picked = await showDialog<Color>(
      context: context,
      builder: (context) => _ColorPickerDialog(initialColor: color),
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: settingsKey,
      onTap: enabled ? () => _openPicker(context) : null,
      child: Opacity(
        opacity: enabled ? 1 : 0.4,
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.outlineVariant.withValues(alpha: 0.6),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorPickerDialog extends StatefulWidget {
  const _ColorPickerDialog({required this.initialColor});

  final Color initialColor;

  @override
  State<_ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<_ColorPickerDialog> {
  late HSVColor _hsv = HSVColor.fromColor(widget.initialColor);

  Color get _color => _hsv.toColor();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pick a color'),
      content: SizedBox(
        width: 260,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SaturationValueSquare(
              hsv: _hsv,
              onChanged: (hsv) => setState(() => _hsv = hsv),
            ),
            const SizedBox(height: 16),
            _HueSlider(
              hue: _hsv.hue,
              onChanged: (hue) => setState(() => _hsv = _hsv.withHue(hue)),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _color,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '#${_color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_color),
          child: const Text('Select'),
        ),
      ],
    );
  }
}

class _SaturationValueSquare extends StatelessWidget {
  const _SaturationValueSquare({required this.hsv, required this.onChanged});

  final HSVColor hsv;
  final ValueChanged<HSVColor> onChanged;

  void _handle(Offset localPosition, Size size) {
    final saturation = (localPosition.dx / size.width).clamp(0.0, 1.0);
    final value = 1 - (localPosition.dy / size.height).clamp(0.0, 1.0);
    onChanged(hsv.withSaturation(saturation).withValue(value));
  }

  @override
  Widget build(BuildContext context) {
    final hueColor = HSVColor.fromAHSV(1, hsv.hue, 1, 1).toColor();
    return AspectRatio(
      aspectRatio: 1.6,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.biggest;
          return GestureDetector(
            onPanDown: (details) => _handle(details.localPosition, size),
            onPanUpdate: (details) => _handle(details.localPosition, size),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: LinearGradient(colors: [Colors.white, hueColor]),
              ),
              foregroundDecoration: const BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(8)),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black],
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: hsv.saturation * size.width - 6,
                    top: (1 - hsv.value) * size.height - 6,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: const [
                          BoxShadow(color: Colors.black38, blurRadius: 2),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HueSlider extends StatelessWidget {
  const _HueSlider({required this.hue, required this.onChanged});

  final double hue;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 16,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
        trackShape: const _RainbowTrackShape(),
      ),
      child: Slider(value: hue, min: 0, max: 360, onChanged: onChanged),
    );
  }
}

class _RainbowTrackShape extends RoundedRectSliderTrackShape {
  const _RainbowTrackShape();

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isEnabled = false,
    bool isDiscrete = false,
    double additionalActiveTrackHeight = 2,
  }) {
    final trackRect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFFFF0000),
          Color(0xFFFFFF00),
          Color(0xFF00FF00),
          Color(0xFF00FFFF),
          Color(0xFF0000FF),
          Color(0xFFFF00FF),
          Color(0xFFFF0000),
        ],
      ).createShader(trackRect);
    context.canvas.drawRRect(
      RRect.fromRectAndRadius(trackRect, Radius.circular(trackRect.height / 2)),
      paint,
    );
  }
}
