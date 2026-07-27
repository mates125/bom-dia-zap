import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import '../models/image_item.dart';
import '../services/ad_service.dart';
import '../utils/save_image.dart';
import '../widgets/color_wheel_picker.dart';

typedef _FontBuilder = TextStyle Function({
  required double fontSize,
  required Color color,
});

class _FontOption {
  final String label;
  final _FontBuilder build;

  const _FontOption(this.label, this.build);
}

final List<_FontOption> _fontOptions = [
  _FontOption(
    'Great Vibes',
    ({required fontSize, required color}) =>
        GoogleFonts.greatVibes(fontSize: fontSize, color: color),
  ),
  _FontOption(
    'Poppins',
    ({required fontSize, required color}) => GoogleFonts.poppins(
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
      color: color,
    ),
  ),
  _FontOption(
    'Playfair Display',
    ({required fontSize, required color}) => GoogleFonts.playfairDisplay(
      fontSize: fontSize,
      fontWeight: FontWeight.w600,
      color: color,
    ),
  ),
  _FontOption(
    'Bebas Neue',
    ({required fontSize, required color}) =>
        GoogleFonts.bebasNeue(fontSize: fontSize, color: color),
  ),
  _FontOption(
    'Caveat',
    ({required fontSize, required color}) => GoogleFonts.caveat(
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
      color: color,
    ),
  ),
];

const int _maxTextBoxes = 5;

class _TextBoxData {
  String text;
  int fontIndex;
  double fontSize;
  Color color;
  Alignment alignment;

  _TextBoxData({
    required this.text,
    this.fontIndex = 0,
    this.fontSize = 40,
    this.color = Colors.white,
    this.alignment = Alignment.center,
  });
}

/// Tela 2 do editor premium: escreve até 5 frases, escolhe fonte/tamanho/cor
/// de cada uma e arrasta cada texto pra posição que quiser em cima do fundo
/// escolhido.
class CustomEditorScreen extends StatefulWidget {
  final ImageItem background;

  const CustomEditorScreen({super.key, required this.background});

  @override
  State<CustomEditorScreen> createState() => _CustomEditorScreenState();
}

class _CustomEditorScreenState extends State<CustomEditorScreen> {
  final _boundaryKey = GlobalKey();

  final List<_TextBoxData> _textBoxes = [_TextBoxData(text: 'Bom dia!')];
  final List<TextEditingController> _controllers = [
    TextEditingController(text: 'Bom dia!'),
  ];
  int _selectedIndex = 0;
  bool _isExporting = false;

  String get _filename =>
      'bom-dia-zap-personalizado-${DateTime.now().millisecondsSinceEpoch}.jpg';

  _TextBoxData get _selected => _textBoxes[_selectedIndex];

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addTextBox() {
    if (_textBoxes.length >= _maxTextBoxes) return;

    setState(() {
      final offset = 0.18 * _textBoxes.length;
      _textBoxes.add(
        _TextBoxData(
          text: 'Novo texto',
          alignment: Alignment(0, (-0.6 + offset).clamp(-1.0, 1.0)),
        ),
      );
      _controllers.add(TextEditingController(text: 'Novo texto'));
      _selectedIndex = _textBoxes.length - 1;
    });
  }

  void _removeSelectedTextBox() {
    if (_textBoxes.length <= 1) return;

    setState(() {
      _textBoxes.removeAt(_selectedIndex);
      _controllers.removeAt(_selectedIndex).dispose();
      _selectedIndex = _selectedIndex.clamp(0, _textBoxes.length - 1);
    });
  }

  void _onPanUpdate(int index, DragUpdateDetails details, Size canvasSize) {
    setState(() {
      _selectedIndex = index;
      final box = _textBoxes[index];
      final dx = box.alignment.x + details.delta.dx / (canvasSize.width / 2);
      final dy = box.alignment.y + details.delta.dy / (canvasSize.height / 2);
      box.alignment = Alignment(dx.clamp(-1.0, 1.0), dy.clamp(-1.0, 1.0));
    });
  }

  Future<Uint8List> _exportImage() async {
    // Esconde a seleção (borda de destaque) antes de capturar, senão ela
    // aparece na imagem exportada.
    setState(() => _isExporting = true);
    await WidgetsBinding.instance.endOfFrame;

    final boundary = _boundaryKey.currentContext!.findRenderObject()
        as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 3);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    if (mounted) setState(() => _isExporting = false);
    return byteData!.buffer.asUint8List();
  }

  Future<void> _handleDownload() async {
    if (_isExporting) return;
    try {
      final bytes = await _exportImage();
      await saveImageBytes(bytes, _filename);
      AdService.instance.registerActionAndMaybeShow();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Imagem salva!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível salvar a imagem.')),
      );
    }
  }

  Future<void> _handleShare() async {
    if (_isExporting) return;
    try {
      final bytes = await _exportImage();

      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(bytes, mimeType: 'image/jpeg', name: _filename),
          ],
        ),
      );
      AdService.instance.registerActionAndMaybeShow();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível compartilhar a imagem.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Criar minha imagem')),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: AspectRatio(
                  aspectRatio: 4 / 5,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final canvasSize = constraints.biggest;
                      return RepaintBoundary(
                        key: _boundaryKey,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              CachedNetworkImage(
                                imageUrl: widget.background.sourceUrl ??
                                    widget.background.imageUrl,
                                fit: BoxFit.cover,
                                errorWidget: (context, url, error) => Container(
                                  color: Colors.black26,
                                  child: const Icon(Icons.broken_image_outlined),
                                ),
                              ),
                              for (var i = 0; i < _textBoxes.length; i++)
                                _buildDraggableText(i, canvasSize),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 8,
                  children: [
                    for (var i = 0; i < _textBoxes.length; i++)
                      ChoiceChip(
                        label: Text('Texto ${i + 1}'),
                        selected: _selectedIndex == i,
                        onSelected: (_) => setState(() => _selectedIndex = i),
                      ),
                    ActionChip(
                      avatar: const Icon(Icons.add, size: 18),
                      label: const Text('Adicionar'),
                      onPressed:
                          _textBoxes.length >= _maxTextBoxes ? null : _addTextBox,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        key: ValueKey('text-field-$_selectedIndex'),
                        controller: _controllers[_selectedIndex],
                        decoration: const InputDecoration(labelText: 'Sua frase'),
                        textAlign: TextAlign.center,
                        maxLength: 60,
                        onChanged: (value) =>
                            setState(() => _selected.text = value),
                      ),
                    ),
                    if (_textBoxes.length > 1)
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        tooltip: 'Remover esta caixa',
                        onPressed: _removeSelectedTextBox,
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: DropdownButtonFormField<int>(
                  initialValue: _selected.fontIndex,
                  decoration: const InputDecoration(labelText: 'Fonte'),
                  items: [
                    for (var i = 0; i < _fontOptions.length; i++)
                      DropdownMenuItem(
                        value: i,
                        child: Text(_fontOptions[i].label),
                      ),
                  ],
                  onChanged: (value) =>
                      setState(() => _selected.fontIndex = value ?? 0),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Text('Tamanho'),
                    Expanded(
                      child: Slider(
                        value: _selected.fontSize,
                        min: 20,
                        max: 72,
                        onChanged: (value) =>
                            setState(() => _selected.fontSize = value),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: ColorWheelPicker(
                  selected: _selected.color,
                  onChanged: (color) => setState(() => _selected.color = color),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isExporting ? null : _handleDownload,
                        icon: const Icon(Icons.download_rounded),
                        label: const Text('Baixar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _isExporting ? null : _handleShare,
                        icon: const Icon(Icons.share_rounded),
                        label: const Text('Compartilhar'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDraggableText(int index, Size canvasSize) {
    final box = _textBoxes[index];
    final font = _fontOptions[box.fontIndex];
    final isSelected = index == _selectedIndex && !_isExporting;

    return GestureDetector(
      onPanStart: (_) => setState(() => _selectedIndex = index),
      onPanUpdate: (details) => _onPanUpdate(index, details, canvasSize),
      onTap: () => setState(() => _selectedIndex = index),
      child: Align(
        alignment: box.alignment,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            border: isSelected
                ? Border.all(color: Colors.white54, width: 1)
                : null,
          ),
          child: Text(
            box.text.isEmpty ? ' ' : box.text,
            textAlign: TextAlign.center,
            style: font.build(fontSize: box.fontSize, color: box.color),
          ),
        ),
      ),
    );
  }
}
