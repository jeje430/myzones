import 'dart:typed_data';

import 'font_loader_stub.dart'
    if (dart.library.io) 'font_loader_io.dart'
    if (dart.library.html) 'font_loader_web.dart';

Future<Uint8List> loadFontBytes(String url) => fetchFontBytes(url);
