import 'package:flutter/material.dart';

class ColorSliderPicker extends StatefulWidget {
  final String initialHex;
  final ValueChanged<String> onColorChanged;

  const ColorSliderPicker({
    super.key,
    this.initialHex = '#3B82F6',
    required this.onColorChanged,
  });

  @override
  State<ColorSliderPicker> createState() => _ColorSliderPickerState();
}

class _ColorSliderPickerState extends State<ColorSliderPicker> {
  late Color _currentColor;
  late double _hue;
  late double _saturation;
  late double _value;

  static const List<Color> _presetColors = [
    Color(0xFF0BA5A7), // Teal Primary HomeCare
    Color(0xFF3B82F6), // Blue
    Color(0xFF8B5CF6), // Purple
    Color(0xFFEC4899), // Pink
    Color(0xFFEF4444), // Red
    Color(0xFFF59E0B), // Amber / Orange
    Color(0xFF10B981), // Emerald Green
    Color(0xFF6366F1), // Indigo
    Color(0xFF06B6D4), // Cyan
    Color(0xFF14B8A6), // Mint
    Color(0xFF64748B), // Slate Grey
    Color(0xFF1E293B), // Dark Navy
  ];

  @override
  void initState() {
    super.initState();
    _currentColor = _parseHexColor(widget.initialHex);
    final hsv = HSVColor.fromColor(_currentColor);
    _hue = hsv.hue;
    _saturation = hsv.saturation > 0 ? hsv.saturation : 0.85;
    _value = hsv.value > 0 ? hsv.value : 0.95;
  }

  @override
  void didUpdateWidget(covariant ColorSliderPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialHex != widget.initialHex) {
      final newColor = _parseHexColor(widget.initialHex);
      if (_colorToHex(newColor) != _colorToHex(_currentColor)) {
        _currentColor = newColor;
        final hsv = HSVColor.fromColor(_currentColor);
        _hue = hsv.hue;
        _saturation = hsv.saturation > 0 ? hsv.saturation : 0.85;
        _value = hsv.value > 0 ? hsv.value : 0.95;
      }
    }
  }

  static Color _parseHexColor(
    String? hexString, {
    Color defaultColor = const Color(0xFF3B82F6),
  }) {
    if (hexString == null || hexString.trim().isEmpty) return defaultColor;
    try {
      final clean = hexString.trim().replaceAll('#', '');
      if (clean.length == 6) {
        return Color(int.parse('FF$clean', radix: 16));
      } else if (clean.length == 8) {
        return Color(int.parse(clean, radix: 16));
      }
      return defaultColor;
    } catch (_) {
      return defaultColor;
    }
  }

  static String _colorToHex(Color color) {
    final r = (color.r * 255).round().toRadixString(16).padLeft(2, '0');
    final g = (color.g * 255).round().toRadixString(16).padLeft(2, '0');
    final b = (color.b * 255).round().toRadixString(16).padLeft(2, '0');
    return '#$r$g$b'.toUpperCase();
  }

  void _updateColor() {
    final newColor =
        HSVColor.fromAHSV(1.0, _hue, _saturation, _value).toColor();
    setState(() {
      _currentColor = newColor;
    });
    widget.onColorChanged(_colorToHex(newColor));
  }

  @override
  Widget build(BuildContext context) {
    final hexString = _colorToHex(_currentColor);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Color Preview & Hex Label
          Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _currentColor,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: _currentColor.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Warna Kategori',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hexString,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _currentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Aktif',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _currentColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 1. Rainbow Hue Spectrum Slider ("seret-seret")
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Warna Spektrum (Geser/Seret):',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
              ),
              Text(
                '${_hue.round()}°',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            height: 24,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFFF0000), // Red 0°
                  Color(0xFFFFFF00), // Yellow 60°
                  Color(0xFF00FF00), // Green 120°
                  Color(0xFF00FFFF), // Cyan 180°
                  Color(0xFF0000FF), // Blue 240°
                  Color(0xFFFF00FF), // Magenta 300°
                  Color(0xFFFF0000), // Red 360°
                ],
              ),
            ),
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 24,
                trackShape: const RoundedRectSliderTrackShape(),
                thumbShape: const RoundSliderThumbShape(
                  enabledThumbRadius: 14,
                  elevation: 4,
                ),
                overlayShape: SliderComponentShape.noOverlay,
                thumbColor: Colors.white,
                activeTrackColor: Colors.transparent,
                inactiveTrackColor: Colors.transparent,
              ),
              child: Slider(
                value: _hue,
                min: 0.0,
                max: 360.0,
                onChanged: (val) {
                  _hue = val;
                  _updateColor();
                },
              ),
            ),
          ),

          const SizedBox(height: 12),

          // 2. Brightness / Shading Slider ("seret-seret")
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Kecerahan (Geser/Seret):',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
              ),
              Text(
                '${(_value * 100).round()}%',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            height: 20,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: LinearGradient(
                colors: [
                  Colors.black,
                  HSVColor.fromAHSV(1.0, _hue, _saturation, 1.0).toColor(),
                  Colors.white,
                ],
              ),
            ),
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 20,
                trackShape: const RoundedRectSliderTrackShape(),
                thumbShape: const RoundSliderThumbShape(
                  enabledThumbRadius: 12,
                  elevation: 3,
                ),
                overlayShape: SliderComponentShape.noOverlay,
                thumbColor: Colors.white,
                activeTrackColor: Colors.transparent,
                inactiveTrackColor: Colors.transparent,
              ),
              child: Slider(
                value: _value,
                min: 0.25,
                max: 1.0,
                onChanged: (val) {
                  _value = val;
                  _updateColor();
                },
              ),
            ),
          ),

          const SizedBox(height: 14),

          // 3. Preset Palette Chips
          const Text(
            'Pilihan Cepat:',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                _presetColors.map((color) {
                  final isCurr =
                      _colorToHex(_currentColor) == _colorToHex(color);
                  return GestureDetector(
                    onTap: () {
                      final hsv = HSVColor.fromColor(color);
                      _hue = hsv.hue;
                      _saturation = hsv.saturation > 0 ? hsv.saturation : 0.85;
                      _value = hsv.value > 0 ? hsv.value : 0.95;
                      _updateColor();
                    },
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isCurr ? Colors.black87 : Colors.white,
                          width: isCurr ? 2.5 : 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child:
                          isCurr
                              ? const Center(
                                child: Icon(
                                  Icons.check,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              )
                              : null,
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }
}
