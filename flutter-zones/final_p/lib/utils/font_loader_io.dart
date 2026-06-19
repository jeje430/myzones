import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

Future<Uint8List> fetchFontBytes(String url) async {
  final client = HttpClient();
  try {
    final request = await client.getUrl(Uri.parse(url));
    final response = await request.close();
    if (response.statusCode != 200) {
      throw Exception('Failed to load font');
    }
    return consolidateHttpClientResponseBytes(response);
  } finally {
    client.close();
  }
}
