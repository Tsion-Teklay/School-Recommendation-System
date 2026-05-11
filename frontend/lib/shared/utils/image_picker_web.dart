// ignore_for_file: deprecated_member_use
//
// dart:html is deprecated in favor of package:web, but it still works in
// Flutter 3.x and avoids adding a new dependency. We can migrate to
// package:web once the rest of the codebase moves off dart:html.

import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

class PickedImage {
  final String filename;
  final Uint8List bytes;
  final String? contentType;
  const PickedImage({
    required this.filename,
    required this.bytes,
    this.contentType,
  });
}

/// Open the browser's native file chooser (image-only) and resolve with the
/// chosen file's bytes. Returns `null` if the user cancelled.
Future<PickedImage?> pickImageFromUser() async {
  final input = html.FileUploadInputElement()
    ..accept = 'image/png,image/jpeg,image/webp,image/*'
    ..multiple = false;
  // Attach to DOM so Safari fires the change event reliably; clean up
  // immediately after the picker resolves so we don't leak nodes.
  input.style.display = 'none';
  html.document.body?.append(input);
  final completer = Completer<PickedImage?>();
  // The browser does not fire `cancel` events for the file picker, so
  // there's no clean "user pressed Cancel" signal. Callers can resolve
  // that ambiguity at the UX layer by showing a "Pick another?" button.
  input.onChange.first.then((_) async {
    final files = input.files;
    if (files == null || files.isEmpty) {
      completer.complete(null);
      return;
    }
    final file = files.first;
    final reader = html.FileReader();
    reader.readAsArrayBuffer(file);
    await reader.onLoadEnd.first;
    final result = reader.result;
    Uint8List? bytes;
    if (result is Uint8List) {
      bytes = result;
    } else if (result is List<int>) {
      bytes = Uint8List.fromList(result);
    }
    if (bytes == null) {
      completer.complete(null);
      return;
    }
    completer.complete(PickedImage(
      filename: file.name,
      bytes: bytes,
      contentType: file.type.isEmpty ? null : file.type,
    ));
  });
  input.click();
  final picked = await completer.future;
  input.remove();
  return picked;
}
