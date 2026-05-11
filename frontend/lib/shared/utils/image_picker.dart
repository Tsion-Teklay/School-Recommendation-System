// Tiny cross-platform image picker. Web uses a hidden <input type=file>;
// non-web targets fall back to a stub that explains the picker isn't wired
// yet (the project's primary target right now is Flutter web — mobile
// image picking can be added in a follow-up by swapping the stub for a
// real `image_picker`-package implementation).
//
// We use Dart's conditional imports so the web build doesn't drag dart:io
// in and the mobile build doesn't drag dart:html in.
export 'image_picker_stub.dart'
    if (dart.library.html) 'image_picker_web.dart';
