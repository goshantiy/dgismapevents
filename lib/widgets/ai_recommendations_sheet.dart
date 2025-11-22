import 'package:flutter/material.dart';
import '../services/ai_recommendation_service.dart';
import '../services/timepad_service.dart';
import '../config/api_config.dart';
import '../models/timepad_event.dart';

/// Bottom sheet для отображения AI рекомендаций мест отдыха
class AiRecommendationsSheet extends StatefulWidget {
  final AiRecommendationService aiService;
  final String? initialCity;
  final ApiConfig? apiConfig;
  final String? selectedCategory;
  final DateTime? selectedDate;

  const AiRecommendationsSheet({
    super.key,
    required this.aiService,
    this.initialCity = 'Москва',
    this.apiConfig,
    this.selectedCategory,
    this.selectedDate,
  });

  /// Статический метод для открытия шторки
  static Future<List<TimepadEvent>?> show(
    BuildContext context, {
    required AiRecommendationService aiService,
    String? initialCity,
    ApiConfig? apiConfig,
    String? selectedCategory,
    DateTime? selectedDate,
  }) {
    return showModalBottomSheet<List<TimepadEvent>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.95,
        minChildSize: 0.3,
        maxChildSize: 0.95,
        snap: true,
        snapSizes: const [0.3, 0.5, 0.75, 0.95],
        builder: (context, scrollController) {
          return AiRecommendationsSheet(
            aiService: aiService,
            initialCity: initialCity,
            apiConfig: apiConfig,
            selectedCategory: selectedCategory,
            selectedDate: selectedDate,
          );
        },
      ),
    );
  }

  @override
  State<AiRecommendationsSheet> createState() => _AiRecommendationsSheetState();
}

class _AiRecommendationsSheetState extends State<AiRecommendationsSheet> {
  final TextEditingController _preferencesController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  
  List<PlaceRecommendation>? _recommendations;
  bool _isLoading = false;
  String? _error;
  TimepadService? _timepadService;
  bool _modelReady = false;
  String? _modelError;

  @override
  void initState() {
    super.initState();
    _cityController.text = widget.initialCity ?? 'Москва';
    if (widget.apiConfig != null) {
      _timepadService = TimepadService(apiToken: widget.apiConfig!.timepadApiToken);
    }
    _initAiModel();
  }

  Future<void> _initAiModel() async {
    setState(() {
      _modelReady = false;
      _modelError = null;
    });
    try {
      await widget.aiService.initModel();
      setState(() {
        _modelReady = true;
      });
    } catch (e) {
      setState(() {
        _modelError = 'Ошибка инициализации AI модели: $e';
        _modelReady = false;
      });
    }
  }

  Future<void> _getRecommendations() async {
    if (!_modelReady) return;
    final city = _cityController.text.trim();
    if (_preferencesController.text.trim().isEmpty) {
      setState(() {
        _error = 'Пожалуйста, опишите ваши предпочтения';
      });
      return;
    }
    if (_timepadService == null) {
      setState(() {
        _error = 'Timepad API недоступен';
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
      _recommendations = null;
    });
    try {
      debugPrint('[AiRecommendationsSheet] Запрос событий из Timepad...');
      debugPrint('[AiRecommendationsSheet] Город: $city');
      debugPrint('[AiRecommendationsSheet] Дата: ${widget.selectedDate}');
      debugPrint('[AiRecommendationsSheet] Категория: ${widget.selectedCategory}');
      
      final events = await _timepadService!.getEvents(
        city: city,
        limit: 40,
        startDate: widget.selectedDate,
        categories: widget.selectedCategory != null ? [widget.selectedCategory!] : null,
      );
      debugPrint('[AiRecommendationsSheet] Получено событий: ${events.length}');
      
      final eventsJson = events.map((e) => e.toJson()).toList();
      // Получаем рекомендации от AI
      final recommendations = await widget.aiService.getRecommendationsFromEvents(
        events: eventsJson,
        preferences: _preferencesController.text.trim(),
        city: city,
        limit: 40,
        category: widget.selectedCategory,
      );
      
      debugPrint('[AiRecommendationsSheet] AI рекомендации: ${recommendations.length}');
      
      // Парсим ID событий из рекомендаций
      final recommendedIds = <int>{};
      for (final rec in recommendations) {
        // Пытаемся найти ID в названии или описании рекомендации
        final text = '${rec.name} ${rec.description}';
        final matches = RegExp(r'\b\d{7}\b').allMatches(text);
        for (final match in matches) {
          final id = int.tryParse(match.group(0)!);
          if (id != null) recommendedIds.add(id);
        }
      }
      
      debugPrint('[AiRecommendationsSheet] Найденные ID из рекомендаций: $recommendedIds');
      
      // Фильтруем события по рекомендованным ID
      final recommendedEvents = events.where((e) => recommendedIds.contains(e.id)).toList();
      debugPrint('[AiRecommendationsSheet] Отфильтровано событий: ${recommendedEvents.length}');
      
      // Если ничего не найдено, возвращаем все события
      final eventsToReturn = recommendedEvents.isNotEmpty ? recommendedEvents : events;
      
      // Закрываем AI sheet и возвращаем события для отображения в events sheet
      if (mounted && context.mounted) {
        Navigator.pop(context, eventsToReturn);
      }
    } catch (e) {
      setState(() {
        _error = 'Ошибка получения рекомендаций: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Ручка для перетаскивания
          _buildDragHandle(),
          // Заголовок
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.blue, size: 28),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Рекомендации',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Искусственный интеллект подберет места для отдыха',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Остальной контент в скроллящемся виджете
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  if (!_modelReady && _modelError == null)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(width: 16),
                          const Expanded(child: Text('Инициализация AI модели...')),
                        ],
                      ),
                    ),
                  if (_modelError != null)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red),
                          const SizedBox(width: 16),
                          Expanded(child: Text(_modelError!, style: const TextStyle(color: Colors.red))),
                          IconButton(
                            icon: const Icon(Icons.refresh),
                            onPressed: _initAiModel,
                          ),
                        ],
                      ),
                    ),
                  // Форма ввода
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Город',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _cityController,
                          decoration: InputDecoration(
                            hintText: 'Москва',
                            prefixIcon: const Icon(Icons.location_city),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Ваши предпочтения',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _preferencesController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: 'Например: хочу расслабиться на природе, люблю активный отдых, интересуюсь культурой...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isLoading || !_modelReady ? null : _getRecommendations,
                            icon: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Icon(Icons.auto_awesome),
                            label: Text(_isLoading
                                ? 'Получение рекомендаций...'
                                : !_modelReady
                                    ? 'AI недоступен'
                                    : 'Получить рекомендации'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Результаты
                  _buildResults(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            ],
          ),
        ),
      );
    }

    if (_recommendations == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lightbulb_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Опишите ваши предпочтения,\nи AI подберет лучшие места для отдыха',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    if (_recommendations!.isEmpty) {
      return const Center(
        child: Text('Рекомендации не найдены'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _recommendations!.length,
      itemBuilder: (context, index) {
        final recommendation = _recommendations![index];
        return _RecommendationCard(
          recommendation: recommendation,
          index: index,
        );
      },
    );
  }

  /// Ручка для перетаскивания
  Widget _buildDragHandle() {
    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 8),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  final PlaceRecommendation recommendation;
  final int index;

  const _RecommendationCard({
    required this.recommendation,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    recommendation.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Icon(Icons.auto_awesome, color: Colors.amber, size: 20),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              recommendation.description,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                height: 1.4,
              ),
            ),
            if (recommendation.address != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      recommendation.address!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (recommendation.tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: recommendation.tags.map((tag) {
                  return Chip(
                    label: Text(
                      tag,
                      style: const TextStyle(fontSize: 11),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
