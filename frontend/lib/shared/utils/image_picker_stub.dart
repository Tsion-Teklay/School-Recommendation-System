import 'dart:typed_data';

/// Returned by [pickImageFromUser] when the user successfully selects a file.
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

/// Non-web stub. Throws so calling screens surface a clear "wire me on
/// mobile" error rather than silently failing.
Future<PickedImage?> pickImageFromUser() async {
  throw UnsupportedError(
    'Image picking is only wired for Flutter web builds right now. '
    'Run with `flutter run -d chrome` to attach images.',
  );
}
