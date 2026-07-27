import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Anel de cores em ordem de matiz (vermelho → laranja → amarelo → verde →
/// azul → roxo → magenta), como um arco-íris fechado em círculo. Não é o
/// espectro inteiro de propósito — mantém leve.
const List<Color> kWheelColors = [
  Color(0xFFE63946), // vermelho
  Color(0xFFFF8C42), // laranja
  Color(0xFFFFD166), // dourado
  Color(0xFFFFE156), // amarelo
  Color(0xFF2ECC71), // verde
  Color(0xFF06D6A0), // verde-água
  Color(0xFF118AB2), // azul
  Color(0xFF3A0CA3), // índigo
  Color(0xFF8338EC), // roxo
  Color(0xFFF72585), // magenta/rosa
];

/// Branco e preto ficam fora do anel (não têm matiz) como opções rápidas.
const List<Color> kExtraColors = [Colors.white, Colors.black];

const List<Color> kEditorColors = [...kWheelColors, ...kExtraColors];

/// Roda de cores: arrasta o dedo ao redor do anel pra escolher entre um
/// número limitado de cores, mais branco/preto como opções rápidas à parte.
class ColorWheelPicker extends StatelessWidget {
  final Color selected;
  final ValueChanged<Color> onChanged;
  final List<Color> colors;
  final double size;

  const ColorWheelPicker({
    super.key,
    required this.selected,
    required this.onChanged,
    this.colors = kWheelColors,
    this.size = 180,
  });

  int get _selectedIndex => colors.indexWhere((c) => c == selected);

  void _handlePosition(Offset localPosition) {
    final center = Offset(size / 2, size / 2);
    final vector = localPosition - center;
    var angle = vector.direction;
    if (angle < 0) angle += 2 * math.pi;
    final step = (2 * math.pi) / colors.length;
    // A posição visual de cada cor é desenhada com um giro de -pi/2 (índice
    // 0 no topo), então a mesma correção precisa entrar aqui na hora de
    // converter o ângulo do toque de volta pro índice, senão a cor
    // selecionada fica sempre deslocada em relação à cor tocada.
    final index = ((angle + math.pi / 2) / step).round() % colors.length;
    onChanged(colors[index]);
  }

  @override
  Widget build(BuildContext context) {
    final ringRadius = size / 2 - 18;
    final step = (2 * math.pi) / colors.length;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
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
                          color:
                              i == _selectedIndex ? Colors.white : Colors.white24,
                          width: i == _selectedIndex ? 3 : 1,
                        ),
                      ),
                    ),
                  ),
                CircleAvatar(radius: 18, backgroundColor: selected),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (final extra in kExtraColors)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: GestureDetector(
                  onTap: () => onChanged(extra),
                  child: CircleAvatar(
                    radius: 14,
                    backgroundColor: extra,
                    child: selected == extra
                        ? Icon(
                            Icons.check,
                            size: 14,
                            color: extra == Colors.white
                                ? Colors.black
                                : Colors.white,
                          )
                        : null,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
