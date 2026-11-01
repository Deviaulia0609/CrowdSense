import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

/// Proses 1: resize + kompresi JPEG (DCT 8x8 dikerjakan encoder JPEG native).
class ImageService {
  Future<({String path, int original, int compressed})> compress(String src) async {
    final dir = Directory('${(await getApplicationDocumentsDirectory()).path}/outbox');
    await dir.create(recursive: true);
    final target = '${dir.path}/${DateTime.now().microsecondsSinceEpoch}.jpg';
    final out = await FlutterImageCompress.compressAndGetFile(
      src,
      target,
      minWidth: 1280,
      minHeight: 1280,
      quality: 70,
      format: CompressFormat.jpeg,
    );
    final path = out?.path ?? src;
    return (
      path: path,
      original: await File(src).length(),
      compressed: await File(path).length(),
    );
  }
}
