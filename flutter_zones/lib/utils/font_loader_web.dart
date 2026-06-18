import 'dart:html' as html;
import 'dart:typed_data';

Future<Uint8List> fetchFontBytes(String url) async {
  final request = html.HttpRequest();
  request.responseType = 'arraybuffer';
  request.open('GET', url);

  await request.onLoadEnd.first;

  if (request.status != 200) {
    throw Exception('Failed to load font (HTTP ${request.status})');
  }

  final response = request.response;
  if (response is ByteBuffer) {
    return Uint8List.view(response);
  }

  throw Exception('Invalid font response type');
}
