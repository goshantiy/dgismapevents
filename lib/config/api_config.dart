import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

/// Exception thrown when there's an error loading or parsing the API configuration
class ApiConfigException implements Exception {
  final String message;

  ApiConfigException(this.message);

  @override
  String toString() => 'ApiConfigException: $message';
}

/// Configuration class for API tokens and settings
class ApiConfig {
  final String timepadApiToken;
  final String gisAiApiKey;

  ApiConfig({
    required this.timepadApiToken,
    required this.gisAiApiKey,
  });

  /// Load API configuration from assets/config/api_config.json
  static Future<ApiConfig> load() async {
    try {
      debugPrint('[ApiConfig] Загружаем конфиг из assets/config/api_config.json');
      final String configString = await rootBundle.loadString('assets/config/api_config.json');
      debugPrint('[ApiConfig] Содержимое файла: $configString');
      final Map<String, dynamic> json = jsonDecode(configString);
      debugPrint('[ApiConfig] JSON: $json');
      return ApiConfig.fromJson(json);
    } on FormatException catch (e) {
      debugPrint('[ApiConfig] Ошибка формата JSON: ${e.message}');
      throw ApiConfigException('Invalid JSON format in API config: ${e.message}');
    } catch (e) {
      debugPrint('[ApiConfig] Ошибка загрузки: $e');
      if (e.toString().contains('Unable to load asset')) {
        throw ApiConfigException('API config file not found at assets/config/api_config.json');
      }
      throw ApiConfigException('Failed to load API config: $e');
    }
  }

  /// Create ApiConfig from JSON map
  factory ApiConfig.fromJson(Map<String, dynamic> json) {
    debugPrint('[ApiConfig] fromJson: $json');
    if (!json.containsKey('timepad_api_token')) {
      debugPrint('[ApiConfig] Нет поля timepad_api_token');
      throw ApiConfigException('Missing required field: timepad_api_token');
    }
    final token = json['timepad_api_token'];
    debugPrint('[ApiConfig] timepad_api_token: $token');
    if (token == null || token.toString().isEmpty) {
      debugPrint('[ApiConfig] timepad_api_token пустой');
      throw ApiConfigException('timepad_api_token cannot be empty');
    }
    if (!json.containsKey('gis_ai_api_key')) {
      debugPrint('[ApiConfig] Нет поля gis_ai_api_key');
      throw ApiConfigException('Missing required field: gis_ai_api_key');
    }
    final aiKey = json['gis_ai_api_key'];
    debugPrint('[ApiConfig] gis_ai_api_key: $aiKey');
    if (aiKey == null || aiKey.toString().isEmpty) {
      debugPrint('[ApiConfig] gis_ai_api_key пустой');
      throw ApiConfigException('gis_ai_api_key cannot be empty');
    }
    return ApiConfig(
      timepadApiToken: token.toString(),
      gisAiApiKey: aiKey.toString(),
    );
  }

  /// Convert ApiConfig to JSON map
  Map<String, dynamic> toJson() {
    return {
      'timepad_api_token': timepadApiToken,
      'gis_ai_api_key': gisAiApiKey,
    };
  }
}
