import 'dart:typed_data';
import 'package:gal/gal.dart';

Future<void> saveImageBytes(Uint8List bytes, String filename) async {
  await Gal.putImageBytes(bytes, name: filename);
}
