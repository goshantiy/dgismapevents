import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/ai_config.dart';

/// Модель рекомендации места отдыха
class PlaceRecommendation {
  final String name;
  final String description;
  final String category;
  final List<String> tags;
  final String? address;
  final DateTime? date;
  final String? location;

  PlaceRecommendation({
    required this.name,
    required this.description,
    required this.category,
    this.tags = const [],
    this.address,
    this.date,
    this.location,
  });

  factory PlaceRecommendation.fromText(String text) {
    // Простой парсинг текстового ответа от AI
    final lines = text.split('\n').where((l) => l.trim().isNotEmpty).toList();
    String? name;
    String? description;
    String? address;
    DateTime? date;
    String? location;
    String category = 'Отдых';
    for (final line in lines) {
      if (name == null) {
        name = line.replaceFirst(RegExp(r'^\d+\.\s*'), '').trim();
        continue;
      }
      if (line.toLowerCase().contains('описание:')) {
        description = line.replaceFirst(RegExp(r'описание:', caseSensitive: false), '').trim();
      } else if (line.toLowerCase().contains('адрес:')) {
        address = line.replaceFirst(RegExp(r'адрес:', caseSensitive: false), '').trim();
      } else if (line.toLowerCase().contains('дата:')) {
        final dateStr = line.replaceFirst(RegExp(r'дата:', caseSensitive: false), '').trim();
        date = DateTime.tryParse(dateStr);
      } else if (line.toLowerCase().contains('место:')) {
        location = line.replaceFirst(RegExp(r'место:', caseSensitive: false), '').trim();
      } else if (line.toLowerCase().contains('категория:')) {
        category = line.replaceFirst(RegExp(r'категория:', caseSensitive: false), '').trim();
      }
    }
    return PlaceRecommendation(
      name: name ?? 'Место',
      description: description ?? text,
      category: category,
      address: address,
      date: date,
      location: location,
      tags: ['AI рекомендация'],
    );
  }
}

/// Сервис для получения AI рекомендаций мест отдыха через chat.2gis.dev
class AiRecommendationService {
  final http.Client _client;
  final String _apiKey;
  final AiConfig _config;

  String _selectedModel = '';

  String get _baseUrl => _config.apiUrl;

  AiRecommendationService({
    required String apiKey,
    required AiConfig config,
    http.Client? client,
  })  : _apiKey = apiKey,
        _config = config,
        _client = client ?? http.Client();

  Map<String, String> _getHeaders() {
    return {
      'Authorization': 'Bearer $_apiKey',
      'Content-Type': 'application/json',
    };
  }

  /// Получить список доступных моделей с chat.2gis.dev
  Future<List<String>> fetchAvailableModels() async {
    try {
      debugPrint('[AiRecommendationService] Запрос списка моделей...');
      final uri = Uri.parse('$_baseUrl/models');
      debugPrint('[AiRecommendationService] URL моделей: $uri');
      
      final response = await _client.get(uri, headers: _getHeaders());
      debugPrint('[AiRecommendationService] Статус ответа моделей: ${response.statusCode}');
      debugPrint('[AiRecommendationService] Тело ответа моделей: ${response.body}');
      
      if (response.statusCode != 200) {
        throw AiServiceException('Failed to fetch models: HTTP ${response.statusCode}');
      }
      
      final jsonData = jsonDecode(response.body);
      List<String> models = [];
      
      if (jsonData is List) {
        models = List<String>.from(jsonData);
      } else if (jsonData is Map) {
        if (jsonData['data'] is List) {
          // OpenAI-compatible format: {"data": [{"id": "model-name"}, ...]}
          models = (jsonData['data'] as List)
              .map((m) => m is Map ? (m['id'] ?? m['name'] ?? '') : m.toString())
              .where((m) => m.isNotEmpty)
              .cast<String>()
              .toList();
        } else if (jsonData['models'] is List) {
          models = List<String>.from(jsonData['models']);
        }
      }
      
      debugPrint('[AiRecommendationService] Найдено моделей: ${models.length}');
      debugPrint('[AiRecommendationService] Доступные модели: $models');
      return models;
    } catch (e) {
      debugPrint('[AiRecommendationService] Ошибка получения моделей: $e');
      rethrow;
    }
  }

  /// Инициализировать модель (выбрать самую новую доступную)
  Future<void> initModel() async {
    if (_selectedModel.isNotEmpty) return;
    try {
      final models = await fetchAvailableModels();
      
      // Приоритет выбора моделей
      final preferredModels = [
        _config.defaultModel,
        'gpt-4o',
        'gpt-4-turbo',
        'gpt-4',
        'gpt-3.5-turbo',
      ];
      
      for (final preferred in preferredModels) {
        if (models.contains(preferred)) {
          _selectedModel = preferred;
          debugPrint('[AiRecommendationService] Выбрана модель: $_selectedModel');
          return;
        }
      }
      
      // Если ни одна из предпочтительных моделей не найдена, берем первую доступную
      if (models.isNotEmpty) {
        _selectedModel = models.first;
        debugPrint('[AiRecommendationService] Выбрана первая доступная модель: $_selectedModel');
      } else {
        throw AiServiceException('No available models found');
      }
    } catch (e) {
      debugPrint('[AiRecommendationService] Ошибка инициализации модели: $e, использую дефолтную');
      _selectedModel = _config.defaultModel;
    }
  }

  /// Получить рекомендации мест отдыха на основе предпочтений пользователя
  /// 
  /// [preferences] - предпочтения пользователя (например, "хочу расслабиться", "активный отдых")
  /// [city] - город для поиска мест (по умолчанию "Москва")
  /// [limit] - максимальное количество рекомендаций
  Future<List<PlaceRecommendation>> getRecommendations({
    required String preferences,
    String city = 'Москва',
    int limit = 40,
  }) async {
    try {
      // Формируем промпт для AI
      final prompt = _buildPrompt(preferences, city, limit);

      // Отправляем запрос к API
      final uri = Uri.parse('$_baseUrl/chat/completions');
      
      final requestBody = {
        'model': _selectedModel,
        'messages': [
          {
            'role': 'system',
            'content': _config.systemPrompt,
          },
          {
            'role': 'user',
            'content': prompt,
          },
        ],
        'temperature': 0.7,
        'max_tokens': 1000,
      };

      final response = await _client
          .post(
            uri,
            headers: _getHeaders(),
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        throw AiServiceException(
          'Failed to get AI recommendations: HTTP ${response.statusCode}\n${response.body}',
        );
      }

      // Парсим ответ
      final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
      final choices = jsonData['choices'] as List<dynamic>?;

      if (choices == null || choices.isEmpty) {
        throw AiParseException('Invalid response format: missing or empty "choices" field');
      }

      final message = choices[0]['message'] as Map<String, dynamic>?;
      final content = message?['content'] as String?;

      if (content == null || content.isEmpty) {
        throw AiParseException('Empty response from AI');
      }

      // Разбираем ответ на отдельные рекомендации
      return _parseRecommendations(content, limit);
    } on http.ClientException catch (e) {
      throw AiServiceException('Network error: ${e.message}');
    } on FormatException catch (e) {
      throw AiParseException('Failed to parse response: ${e.message}');
    } catch (e) {
      if (e is AiServiceException || e is AiParseException) {
        rethrow;
      }
      throw AiServiceException('Unexpected error: $e');
    }
  }

  /// Получить рекомендации мест отдыха на основе событий Timepad и предпочтений пользователя
  /// [events] - список событий из Timepad
  /// [preferences] - предпочтения пользователя
  /// [city] - город для поиска мест (по умолчанию "Москва")
  /// [limit] - максимальное количество рекомендаций
  Future<List<PlaceRecommendation>> getRecommendationsFromEvents({
    required List<Map<String, dynamic>> events,
    required String preferences,
    String city = 'Москва',
    int limit = 5,
    String? category,
  }) async {
    try {
      debugPrint('[AiRecommendationService] ========== AI ЗАПРОС ==========');
      debugPrint('[AiRecommendationService] Город: $city');
      debugPrint('[AiRecommendationService] Категория: ${category ?? "не указана"}');
      debugPrint('[AiRecommendationService] Предпочтения: $preferences');
      debugPrint('[AiRecommendationService] Количество событий: ${events.length}');
      debugPrint('[AiRecommendationService] Лимит рекомендаций: $limit');
      
      // Формируем промпт для AI
      final prompt = _buildEventPrompt(events, preferences, city, limit, category);
      debugPrint('[AiRecommendationService] Промпт длина: ${prompt.length} символов');

      // Отправляем запрос к API
      final uri = Uri.parse('$_baseUrl/chat/completions');
      debugPrint('[AiRecommendationService] URL: $uri');
      debugPrint('[AiRecommendationService] Модель: $_selectedModel');
      
      final requestBody = {
        'model': _selectedModel,
        'messages': [
          {
            'role': 'system',
            'content': _config.eventSystemPrompt,
          },
          {
            'role': 'user',
            'content': prompt,
          },
        ],
        'temperature': 0.7,
        'max_tokens': 2000,
      };

      debugPrint('[AiRecommendationService] Отправка запроса...');
      debugPrint('[AiRecommendationService] Тело запроса: ${jsonEncode(requestBody).substring(0, 500)}...');
      final response = await _client
          .post(
            uri,
            headers: _getHeaders(),
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 30));

      debugPrint('[AiRecommendationService] Статус ответа: ${response.statusCode}');
      debugPrint('[AiRecommendationService] Полный ответ: ${response.body}');
      if (response.statusCode != 200) {
        debugPrint('[AiRecommendationService] Ошибка: ${response.body}');
        throw AiServiceException(
          'Failed to get AI recommendations: HTTP ${response.statusCode}\n${response.body}',
        );
      }

      // Парсим ответ
      debugPrint('[AiRecommendationService] Парсинг ответа...');
      final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
      final choices = jsonData['choices'] as List<dynamic>?;

      if (choices == null || choices.isEmpty) {
        debugPrint('[AiRecommendationService] Ошибка: отсутствуют choices в ответе');
        throw AiParseException('Invalid response format: missing or empty "choices" field');
      }

      final message = choices[0]['message'] as Map<String, dynamic>?;
      final content = message?['content'] as String?;

      if (content == null || content.isEmpty) {
        throw AiParseException('Empty response from AI');
      }

      // Разбираем ответ на отдельные рекомендации
      return _parseRecommendations(content, limit);
    } on http.ClientException catch (e) {
      throw AiServiceException('Network error: ${e.message}');
    } on FormatException catch (e) {
      throw AiParseException('Failed to parse response: ${e.message}');
    } catch (e) {
      if (e is AiServiceException || e is AiParseException) {
        rethrow;
      }
      throw AiServiceException('Unexpected error: $e');
    }
  }

  /// Формирует промпт для AI на основе предпочтений пользователя
  String _buildPrompt(String preferences, String city, int limit) {
    return '''
Порекомендуй $limit интересных мест в городе $city для отдыха на основе следующих предпочтений:
"$preferences"

Для каждого места укажи:
1. Название
2. Краткое описание (1-2 предложения)
3. Почему это место подходит

Формат ответа:
1. [Название места]
   Описание: ...
   Почему подходит: ...

2. [Название места]
   Описание: ...
   Почему подходит: ...

И так далее.
''';
  }

  /// Формирует промпт для AI на основе событий и предпочтений пользователя
  String _buildEventPrompt(List<Map<String, dynamic>> events, String preferences, String city, int limit, String? category) {
    final eventsJson = const JsonEncoder.withIndent('  ').convert(events);
    final categoryNote = category != null ? '\nКатегория: $category (обрати особое внимание на события этой категории)' : '';
    return '''
Вот список событий в городе $city:$categoryNote
$eventsJson

Предпочтения пользователя:
"$preferences"

Выбери $limit лучших событий из списка, которые максимально соответствуют предпочтениями пользователя${category != null ? ' и категории "$category"' : ''}.

ОЧЕНЬ ВАЖНО: В ответе указывай ТОЛЬКО ID событий через запятую, ничего больше!

Пример ответа: 3557315, 3562140, 3558923
''';
  }

  /// Парсит текстовый ответ AI в список рекомендаций
  List<PlaceRecommendation> _parseRecommendations(String content, int limit) {
    final recommendations = <PlaceRecommendation>[];
    // Разбиваем по номерам (1. 2. 3. и т.д.)
    final regex = RegExp(r'\d+\.\s*\[?([^\]]+)\]?\s*\n([\s\S]*?)(?=\n\d+\.|\Z)', multiLine: true);
    final matches = regex.allMatches(content);
    for (final match in matches) {
      if (recommendations.length >= limit) break;
      final name = match.group(1)?.trim() ?? '';
      final details = match.group(2)?.trim() ?? '';
      recommendations.add(PlaceRecommendation.fromText('$name\n$details'));
    }
    // Если парсинг по номерам не сработал, пробуем разбить по двойным переносам
    if (recommendations.isEmpty) {
      final blocks = content.split(RegExp(r'\n\n+'));
      for (final block in blocks) {
        if (recommendations.length >= limit) break;
        if (block.trim().isEmpty) continue;
        recommendations.add(PlaceRecommendation.fromText(block.trim()));
      }
    }
    // Если совсем ничего не получилось, возвращаем весь текст как одну рекомендацию
    if (recommendations.isEmpty && content.isNotEmpty) {
      recommendations.add(PlaceRecommendation.fromText(content));
    }
    return recommendations;
  }

  void dispose() {
    _client.close();
  }
}

class AiServiceException implements Exception {
  final String message;
  AiServiceException(this.message);

  @override
  String toString() => 'AiServiceException: $message';
}

class AiParseException implements Exception {
  final String message;
  AiParseException(this.message);

  @override
  String toString() => 'AiParseException: $message';
}
