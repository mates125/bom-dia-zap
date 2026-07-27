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

const List<Color> _colorOptions = [Colors.white, Colors.black, Color(0xFFFFD166)];

/// Tela 2 do editor premium: escreve a frase, escolhe fonte/tamanho/cor e
/// arrasta o texto pra posição que quiser em cima do fundo escolhido.
class CustomEditorScreen extends StatefulWidget {
  final ImageItem background;

  const CustomEditorScreen({super.key, required this.background});

  @override
  State<CustomEditorScreen> createState() => _CustomEditorScreenState();
}

class _CustomEditorScreenState extends State<CustomEditorScreen> {
  final _boundaryKey = GlobalKey();
  final _phraseController = TextEditingController(text: 'Bom dia!');

  int _fontIndex = 0;
  double _fontSize = 40;
  Color _color = Colors.white;
  Alignment _textAlignment = Alignment.center;
  bool _isExporting = false;

  String get _filename =>
      'bom-dia-zap-personalizado-${DateTime.now().millisecondsSinceEpoch}.jpg';

  @override
  void dispose() {
    _phraseController.dispose();
    super.dispose();
  }

  void _onPanUpdate(DragUpdateDetails details, Size canvasSize) {
    setState(() {
      final dx = _textAlignment.x + details.delta.dx / (canvasSize.width / 2);
      final dy = _textAlignment.y + details.delta.dy / (canvasSize.height / 2);
      _textAlignment = Alignment(dx.clamp(-1.0, 1.0), dy.clamp(-1.0, 1.0));
    });
  }

  Future<Uint8List> _exportImage() async {
    final boundary = _boundaryKey.currentContext!.findRenderObject()
        as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 3);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  Future<void> _handleDownload() async {
    setState(() => _isExporting = true);
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
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _handleShare() async {
    setState(() => _isExporting = true);
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
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final font = _fontOptions[_fontIndex];

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
                              ),
                              GestureDetector(
                                onPanUpdate: (details) =>
                                    _onPanUpdate(details, canvasSize),
                                child: Align(
                                  alignment: _textAlignment,
                                  child: Padding(
                                    padding:
                                        const EdgeInsets.symmetric(horizontal: 16),
                                    child: Text(
                                      _phraseController.text.isEmpty
                                          ? ' '
                                          : _phraseController.text,
                                      textAlign: TextAlign.center,
                                      style: font.build(
                                        fontSize: _fontSize,
                                        color: _color,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
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
                child: TextField(
                  controller: _phraseController,
                  decoration: const InputDecoration(labelText: 'Sua frase'),
                  textAlign: TextAlign.center,
                  maxLength: 80,
                  onChanged: (_) => setState(() {}),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: DropdownButtonFormField<int>(
                  initialValue: _fontIndex,
                  decoration: const InputDecoration(labelText: 'Fonte'),
                  items: [
                    for (var i = 0; i < _fontOptions.length; i++)
                      DropdownMenuItem(
                        value: i,
                        child: Text(_fontOptions[i].label),
                      ),
                  ],
                  onChanged: (value) => setState(() => _fontIndex = value ?? 0),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Text('Tamanho'),
                    Expanded(
                      child: Slider(
                        value: _fontSize,
                        min: 20,
                        max: 72,
                        onChanged: (value) => setState(() => _fontSize = value),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (final color in _colorOptions)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: GestureDetector(
                          onTap: () => setState(() => _color = color),
                          child: CircleAvatar(
                            radius: 16,
                            backgroundColor: color,
                            child: _color == color
                                ? Icon(
                                    Icons.check,
                                    size: 16,
                                    color: color == Colors.white
                                        ? Colors.black
                                        : Colors.white,
                                  )
                                : null,
                          ),
                        ),
                      ),
                  ],
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
}
