import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/api_config.dart';
import '../dto/branding_settings_dto.dart';

class BrandingRepository {
  BrandingRepository._();

  static final BrandingRepository instance = BrandingRepository._();

  Future<BrandingSettings> fetchPublicSettings() async {
    final uri = Uri.parse('${ApiConfig.apiUrl}${ApiConfig.publicBrandingSettings}');

    final response = await http.get(
      uri,
      headers: const {'Accept': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw BrandingFetchException(response.statusCode, response.body);
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const BrandingFetchException(500, 'Invalid branding payload');
    }

    return BrandingSettings.fromJson(decoded);
  }
}

class BrandingFetchException implements Exception {
  const BrandingFetchException(this.statusCode, this.body);

  final int statusCode;
  final String body;

  @override
  String toString() => 'BrandingFetchException($statusCode)';
}
