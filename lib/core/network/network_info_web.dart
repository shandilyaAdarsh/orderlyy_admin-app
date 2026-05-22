// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

Future<bool> checkConnection() async {
  try {
    return html.window.navigator.onLine ?? true;
  } catch (_) {
    return true;
  }
}
