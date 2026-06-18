import 'dart:typed_data';

import 'pdf_save_stub.dart'
    if (dart.library.io) 'pdf_save_io.dart'
    if (dart.library.html) 'pdf_save_web.dart';

Future<String> savePdfFile(Uint8List bytes, String fileName) =>
    savePdfBytes(bytes, fileName);
