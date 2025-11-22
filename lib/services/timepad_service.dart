import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/timepad_event.dart';

class TimepadService {
  static const String _baseUrl = 'https://api.timepad.ru/v1';
  final http.Client _client;
  final String _apiToken;

  TimepadService({
    required String apiToken,
    http.Client? client,
  })  : _apiToken = apiToken,
        _client = client ?? http.Client();

  Map<String, String> _getHeaders() {
    return {
      'Authorization': 'Bearer $_apiToken',
      'Content-Type': 'application/json',
    };
  }

  Future<List<TimepadEvent>> getEvents({
    int limit = 40,
    String? city,
    List<String>? categories,
    DateTime? startDate,
  }) async {
    try {
      // Build query parameters
      final queryParams = <String, String>{
        'limit': limit.toString(),
        'fields': 'id,name,description_short,poster_image,starts_at,ticket_types,organization,location,categories',
        'sort': '+starts_at', // Сортировка по дате начала события (от ранних к поздним)
      };

      if (city != null) {
        queryParams['cities'] = city;
      }

      if (categories != null && categories.isNotEmpty) {
        queryParams['categories'] = categories.join(',');
      }

      if (startDate != null) {
        // Форматируем дату как YYYY-MM-DD для API Timepad
        final formattedDate = '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';
        queryParams['starts_at_min'] = formattedDate;
        debugPrint('[TimepadService] Фильтр по дате: $formattedDate');
      }

      // Build URL
      final uri = Uri.parse('$_baseUrl/events').replace(queryParameters: queryParams);
      debugPrint('[TimepadService] Запрос к API: $uri');
      debugPrint('[TimepadService] Заголовки: ${_getHeaders()}');

      // Send GET request with timeout
      final response = await _client
          .get(uri, headers: _getHeaders())
          .timeout(const Duration(seconds: 20));

      debugPrint('[TimepadService] Статус код: ${response.statusCode}');
      debugPrint('[TimepadService] Тело ответа: ${response.body.substring(0, response.body.length > 3000 ? 3000 : response.body.length)}');

      // Check status code
      if (response.statusCode != 200) {
        debugPrint('[TimepadService] Ошибка HTTP: ${response.statusCode}, тело: ${response.body}');
        throw NetworkException(
          'Failed to load events: HTTP ${response.statusCode}',
        );
      }

      // Parse JSON response
      final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
      debugPrint('[TimepadService] JSON успешно распарсен, ключи: ${jsonData.keys}');
      
      final values = jsonData['values'] as List<dynamic>?;

      if (values == null) {
        debugPrint('[TimepadService] Поле "values" отсутствует в ответе');
        throw ParseException('Invalid response format: missing "values" field');
      }

      debugPrint('[TimepadService] Найдено событий: ${values.length}');

      // Логируем первое событие для проверки структуры location
      if (values.isNotEmpty) {
        final firstEvent = values[0] as Map<String, dynamic>;
        debugPrint('[TimepadService] Первое событие location: ${firstEvent['location']}');
      }

      // Convert to TimepadEvent list
      final events = values
          .map((json) => TimepadEvent.fromJson(json as Map<String, dynamic>))
          .toList();
      
      debugPrint('[TimepadService] События успешно преобразованы');
      return events;
    } on http.ClientException catch (e) {
      debugPrint('[TimepadService] ClientException: ${e.message}');
      throw NetworkException('Network error: ${e.message}');
    } on FormatException catch (e) {
      debugPrint('[TimepadService] FormatException: ${e.message}');
      throw ParseException('Failed to parse response: ${e.message}');
    } catch (e) {
      debugPrint('[TimepadService] Unexpected error: $e');
      if (e is NetworkException || e is ParseException) {
        rethrow;
      }
      throw NetworkException('Unexpected error: $e');
    }
  }

  void dispose() {
    _client.close();
  }
}

class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);

  @override
  String toString() => 'NetworkException: $message';
}

class ParseException implements Exception {
  final String message;
  ParseException(this.message);

  @override
  String toString() => 'ParseException: $message';
}
