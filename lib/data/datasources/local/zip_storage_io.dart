import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ZipStorage {
  Future<String> save(Uint8List bytes, String filename) async {
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/$filename';
    await File(path).writeAsBytes(bytes, flush: true);
    return path;
  }

  Future<void> share(String path) async {
    await Share.shareXFiles([XFile(path)]);
  }
}
