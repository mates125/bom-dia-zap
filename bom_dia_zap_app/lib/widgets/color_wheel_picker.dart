import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Paleta enxuta (não é o círculo cromático inteiro, de propósito — mantém
/// leve) usada tanto pela roda quanto por quem precisar comparar cores.
const List<Color> kEditorColors = [
  Colors.white,
  Color(0xFFFFD166),
  Color(0xFFEF476F),
  Color(0xFFFF8C42),
  Color(0xFFFFE156),
  Color(0xFF06D6A0),
  Color(0xFF118AB2),
  Color(0xFF073B4C),
  Color(0xFF8338EC),
  Color(0xFFF72585),
  Color(0xFF6B7280),
  Colors.black,
];

/// Roda de cores: arrasta o dedo ao redor do anel pra escolher entre um
/// número limitado de cores (não é o espectro completo, de propósito, pra
/// não pesar).
class ColorWheelPicker extends StatelessWidget {
  final Color selected;
  final ValueChanged<Color> onChanged;
  final List<Color> colors;
  final double size;

  const ColorWheelPicker({
    super.key,
    required this.selected,
    required this.onChanged,
    this.colors = kEditorColors,
    this.size = 180,
  });

  int get _selectedIndex {
    final index = colors.indexWhere((c) => c == selected);
    return index == -1 ? 0 : index;
  }

  void _handlePosition(Offset localPosition) {
    final center = Offset(size / 2, size / 2);
    final vector = localPosition - center;
    var angle = vector.direction;
    if (angle < 0) angle += 2 * math.pi;
    final step = (2 * math.pi) / colors.length;
    final index = (angle / step).round() % colors.length;
    onChanged(colors[index]);
  }

  @override
  Widget build(BuildContext context) {
    final ringRadius = size / 2 - 18;
    final step = (2 * math.pi) / colors.length;

    return GestureDetector(
      onPanUpdate: (details) => _handlePosition(details.localPosition),
      onTapDown: (details) => _handlePosition(details.localPosition),
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            for (var i = 0; i < colors.length; i++)
              Transform.translate(
                offset: Offset(
                  ringRadius * math.cos(i * step - math.pi / 2),
                  ringRadius * math.sin(i * step - math.pi / 2),
                ),
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: colors[i],
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: i == _selectedIndex ? Colors.white : Colors.white24,
                      width: i == _selectedIndex ? 3 : 1,
                    ),
                  ),
                ),
              ),
            CircleAvatar(radius: 18, backgroundColor: selected),
          ],
        ),
      ),
    );
  }
}
