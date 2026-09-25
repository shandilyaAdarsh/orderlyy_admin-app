import 'dart:typed_data';

import 'dart:js_interop';
import 'package:web/web.dart' as web;

Future<void> saveBytesAsDownload(Uint8List bytes, String filename) async {
  final blob = web.Blob([bytes.toJS].toJS);
  final url = web.URL.createObjectURL(blob);
  final anchor = web.document.createElement('a') as web.HTMLAnchorElement
    ..href = url
    ..download = filename
    ..click();
  web.URL.revokeObjectURL(url);
  anchor.remove();
}
