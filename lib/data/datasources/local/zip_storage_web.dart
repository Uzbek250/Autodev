import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

class ZipStorage {
  Future<String> save(Uint8List bytes, String filename) async {
    final blob = html.Blob([bytes], 'application/zip');
    final url = html.Url.createObjectUrlFromBlob(blob);
    return url;
  }

  Future<void> share(String path) async {
    // The Web Share API is handled by share_plus elsewhere when possible.
    // If a browser does not expose it, opening the object URL triggers a
    // normal browser download instead of relying on a native filesystem.
    final anchor = html.AnchorElement(href: path)
      ..download = 'autodev_project.zip'
      ..style.display = 'none';
    html.document.body?.children.add(anchor);
    anchor.click();
    anchor.remove();
    unawaited(Future<void>.delayed(const Duration(seconds: 30), () {
      html.Url.revokeObjectUrl(path);
    }));
  }
}
