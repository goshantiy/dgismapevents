import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/app_colors.dart';
import '../models/timepad_event.dart';
import '../services/timepad_service.dart';
import '../services/ai_recommendation_service.dart';
import '../config/api_config.dart';
import '../config/ai_config.dart';
import 'event_card.dart';
import 'calendar_picker.dart';
import 'event_detail_sheet.dart';
import 'ai_recommendations_sheet.dart';

/// Виджет шторки с информацией о событиях
class EventsBottomSheet extends StatefulWidget {
  final VoidCallback onClose;
  final ApiConfig? apiConfig;
  final Function(TimepadEvent)? onEventSelected;
  final Function(List<TimepadEvent>)? onEventsLoaded;
  final ScrollController scrollController;

  const EventsBottomSheet({
    Key? key,
    required this.onClose,
    required this.scrollController,
    this.apiConfig,
    this.onEventSelected,
    this.onEventsLoaded,
  }) : super(key: key);

  /// Статический метод для открытия шторки (deprecated - использовать встроенную шторку)
  static Future<void> show(
    BuildContext context, {
    ApiConfig? apiConfig,
    Function(TimepadEvent)? onEventSelected,
    Function(List<TimepadEvent>)? onEventsLoaded,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false, // Отключаем стандартный drag для modal
      builder: (context) => PopScope(
        canPop: false,
        child: DraggableScrollableSheet(
        initialChildSize: 0.95,
        minChildSize: 0.1,
        maxChildSize: 0.95,
        snap: true,
        snapSizes: const [0.1, 0.25, 0.5, 0.75, 0.95],
        expand: false,
        builder: (context, scrollController) {
          return _EventsBottomSheetContent(
            scrollController: scrollController,
            apiConfig: apiConfig,
            onEventSelected: onEventSelected,
            onEventsLoaded: onEventsLoaded,
          );
        },
        ),
      ),
    );
  }

  @override
  State<EventsBottomSheet> createState() => _EventsBottomSheetState();
}

class _EventsBottomSheetState extends State<EventsBottomSheet> {
  @override
  Widget build(BuildContext context) {
    // Используем встроенный scrollController
    return _EventsBottomSheetContent(
      scrollController: widget.scrollController,
      apiConfig: widget.apiConfig,
      onEventSelected: widget.onEventSelected,
      onEventsLoaded: widget.onEventsLoaded,
    );
  }
}

/// Внутренний виджет с содержимым шторки
class _EventsBottomSheetContent extends StatefulWidget {
  final ScrollController scrollController;
  final ApiConfig? apiConfig;
  final Function(TimepadEvent)? onEventSelected;
  final Function(List<TimepadEvent>)? onEventsLoaded;

  const _EventsBottomSheetContent({
    required this.scrollController,
    this.apiConfig,
    this.onEventSelected,
    this.onEventsLoaded,
  });

  @override
  State<_EventsBottomSheetContent> createState() => _EventsBottomSheetContentState();
}

class _EventsBottomSheetContentState extends State<_EventsBottomSheetContent> {
  TimepadService? _timepadService;
  AiRecommendationService? _aiService;
  List<TimepadEvent> _events = [];
  bool _isLoading = false;
  String? _errorMessage;
  final _cache = EventsCache();
  DateTime? _selectedDate;
  String? _selectedCategory;
  bool _isAiRecommendation = false;
  @override
  void initState() {
    super.initState();
    // Устанавливаем сегодняшнюю дату по умолчанию
    _selectedDate = DateTime.now();
    _initializeAndLoadEvents();
    // Инициализируем AI сервис
    if (widget.apiConfig != null) {
      final aiConfig = AiConfig.defaultConfig();
      _aiService = AiRecommendationService(
        apiKey: widget.apiConfig!.gisAiApiKey,
        config: aiConfig,
      );
      debugPrint('[EventsBottomSheet] AI сервис инициализирован');
    }
  }

  Future<void> _initializeAndLoadEvents() async {
    // Проверяем наличие ApiConfig
    if (widget.apiConfig == null) {
      setState(() {
        _errorMessage =
            'API конфигурация не загружена. Проверьте файл assets/config/api_config.json';
        _isLoading = false;
      });
      return;
    }

    try {
      _timepadService =
          TimepadService(apiToken: widget.apiConfig!.timepadApiToken);
      await _loadEvents();
    } catch (e) {
      setState(() {
        _errorMessage = 'Ошибка инициализации сервиса: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadEvents() async {
    // Проверяем кэш перед запросом
    final cachedEvents = _cache.events;
    if (cachedEvents != null) {
      setState(() {
        _events = cachedEvents;
        _isLoading = false;
      });
      // Передаем кэшированные события в callback
      widget.onEventsLoaded?.call(cachedEvents);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final events = await _timepadService!.getEvents(
        limit: 40,
        city: 'Москва',
        startDate: _selectedDate,
      );

      // Сохраняем в кэш после успешной загрузки
      _cache.cache(events);

      setState(() {
        _events = events;
        _isLoading = false;
      });

      // Передаем загруженные события в callback для отображения маркеров на карте
      widget.onEventsLoaded?.call(events);
      debugPrint('[EventsBottomSheet] Called onEventsLoaded with ${events.length} events');
    } on NetworkException {
      setState(() {
        _errorMessage =
            'Не удалось загрузить события. Проверьте подключение к интернету';
        _isLoading = false;
      });
    } on ParseException {
      setState(() {
        _errorMessage = 'Ошибка обработки данных';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Произошла ошибка: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _retryLoading() {
    setState(() {
      _errorMessage = null;
    });
    _loadEvents();
  }

  /// Обновляет маркеры на карте с учетом текущих фильтров
  void _updateMapMarkers() {
    // Фильтруем события по выбранной дате
    var filteredEvents = _selectedDate != null
        ? _events.where((event) {
            if (event.startsAt == null) return false;
            return event.startsAt!.year == _selectedDate!.year &&
                event.startsAt!.month == _selectedDate!.month &&
                event.startsAt!.day == _selectedDate!.day;
          }).toList()
        : _events;

    // Фильтруем по категории
    if (_selectedCategory != null) {
      filteredEvents = filteredEvents.where((event) {
        final categories = event.categories;
        if (categories == null || categories.isEmpty) {
          return _selectedCategory == 'Другое';
        }
        return categories.contains(_selectedCategory);
      }).toList();
    }

    // Обновляем маркеры на карте
    widget.onEventsLoaded?.call(filteredEvents);
    debugPrint('[EventsBottomSheet] Updated map markers with ${filteredEvents.length} filtered events');
  }

  void _showAiRecommendations() async {
    if (_aiService == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('AI сервис недоступен'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final result = await AiRecommendationsSheet.show(
      context,
      aiService: _aiService!,
      initialCity: 'Москва',
      apiConfig: widget.apiConfig,
      selectedCategory: _selectedCategory,
      selectedDate: _selectedDate,
    );

    // Если AI вернул события, обновляем список
    if (result != null && result.isNotEmpty) {
      setState(() {
        _events = result;
        _cache.cache(result);
        _isAiRecommendation = true;
        // Сбрасываем фильтры при AI поиске
        _selectedDate = null;
        _selectedCategory = null;
      });
      // Передаем события для отображения на карте
      widget.onEventsLoaded?.call(result);
    }
  }

  @override
  void dispose() {
    _timepadService?.dispose();
    _aiService?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
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
          child: CustomScrollView(
            controller: widget.scrollController,
            slivers: [
              // Ручка для перетаскивания (не скроллится)
              SliverToBoxAdapter(
                child: _buildDragHandle(),
              ),
              // Заголовок (не скроллится)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildHeader(),
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 16),
              ),
              // Фильтры (не скроллятся)
              SliverToBoxAdapter(
                child: _buildFilters(),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 16),
              ),
              // Контент (скроллится)
              SliverFillRemaining(
                hasScrollBody: true,
                child: _buildContent(),
              ),
            ],
          ),
        ),
        // AI кнопка
        if (_aiService != null)
          Positioned(
            bottom: 24,
            right: 16,
            child: FloatingActionButton(
              onPressed: _showAiRecommendations,
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              elevation: 4,
              child: const Icon(Icons.auto_awesome, size: 24),
              tooltip: 'AI советы',
            ),
          ),
      ],
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return _buildLoadingState();
    } else if (_errorMessage != null) {
      return _buildErrorState();
    } else if (_events.isEmpty) {
      return _buildEmptyState();
    } else {
      return _buildEventsList();
    }
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        color: AppColors.primary,
      ),
    );
  }

  Widget _buildErrorState() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Произошла ошибка',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.placeholderText,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _retryLoading,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Повторить'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'События не найдены',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.placeholderText,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventsList() {
    // Фильтруем события по выбранной дате
    var filteredEvents = _selectedDate != null
        ? _events.where((event) {
            if (event.startsAt == null) return false;
            return event.startsAt!.year == _selectedDate!.year &&
                event.startsAt!.month == _selectedDate!.month &&
                event.startsAt!.day == _selectedDate!.day;
          }).toList()
        : _events;

    // Фильтруем по категории
    if (_selectedCategory != null) {
      filteredEvents = filteredEvents.where((event) {
        final categories = event.categories;
        if (categories == null || categories.isEmpty) {
          return _selectedCategory == 'Другое';
        }
        return categories.contains(_selectedCategory);
      }).toList();
    }

    // Группируем события по категориям
    final eventsByCategory = <String, List<TimepadEvent>>{};

    for (final event in filteredEvents) {
      final categories = event.categories;
      if (categories != null && categories.isNotEmpty) {
        final category = categories.first;
        eventsByCategory.putIfAbsent(category, () => []).add(event);
      } else {
        eventsByCategory.putIfAbsent('Другое', () => []).add(event);
      }
    }

    if (eventsByCategory.isEmpty) {
      return Center(
        child: Text(
          'Нет событий на выбранную дату',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.placeholderText,
          ),
        ),
      );
    }

    // Если выбрана категория, показываем вертикальный список
    if (_selectedCategory != null) {
      return _buildVerticalEventsList(filteredEvents);
    }

    // Иначе показываем горизонтальные списки по категориям
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: eventsByCategory.length,
      itemBuilder: (context, index) {
        final category = eventsByCategory.keys.elementAt(index);
        final events = eventsByCategory[category]!;

        return _buildCategorySection(category, events);
      },
    );
  }

  /// Вертикальный список событий (при фильтрации по категории)
  Widget _buildVerticalEventsList(List<TimepadEvent> events) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return EventCard(
          event: event,
          isExpanded: true,
          onTap: () {
            EventDetailSheet.show(context, event);
          },
        );
      },
    );
  }

  /// Горизонтальная секция событий по категории
  Widget _buildCategorySection(String category, List<TimepadEvent> events) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            category,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        SizedBox(
          height: 310,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return Container(
                width: 280,
                margin:
                    EdgeInsets.only(right: index < events.length - 1 ? 12 : 0),
                child: EventCard(
                  event: event,
                  onTap: () {
                    EventDetailSheet.show(context, event);
                  },
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  /// Ручка для перетаскивания
  /// Ручка для перетаскивания
  Widget _buildDragHandle() {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 12, bottom: 8),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  /// Заголовок шторки
  Widget _buildHeader() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              _isAiRecommendation ? 'Рекомендовано AI' : 'Куда пойти с 2ГИС!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _isAiRecommendation ? Colors.blue : Colors.black87,
              ),
            ),
            if (_isAiRecommendation) const SizedBox(width: 8),
            if (_isAiRecommendation) const Icon(Icons.auto_awesome, color: Colors.blue, size: 28),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          _isAiRecommendation 
            ? 'Подобрано специально для вас'
            : 'По вашим интересам',
          style: TextStyle(
            fontSize: 16,
            color: _isAiRecommendation ? Colors.blue[700] : AppColors.placeholderText,
          ),
        ),
      ],
    );
  }

  /// Фильтры: календарь и категории
  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildDatePickerButton(),
          ),
          const SizedBox(width: 12),
          _buildCategoryFilterButton(),
        ],
      ),
    );
  }

  /// Кнопка для открытия календаря
  Widget _buildDatePickerButton() {
    return InkWell(
      onTap: () async {
        final selectedDate = await CalendarPicker.show(
          context,
          selectedDate: _selectedDate,
        );
        if (selectedDate != null ||
            selectedDate == null && _selectedDate != null) {
          setState(() {
            _selectedDate = selectedDate;
          });
          // Перезагружаем события при изменении даты
          _loadEvents();
          // Обновляем маркеры с учетом фильтра
          _updateMapMarkers();
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _selectedDate != null
              ? AppColors.primary.withOpacity(0.1)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                _selectedDate != null ? AppColors.primary : Colors.grey[300]!,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_month,
              color:
                  _selectedDate != null ? AppColors.primary : Colors.grey[600],
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _selectedDate != null
                    ? DateFormat('d MMM', 'ru_RU').format(_selectedDate!)
                    : 'Дата',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: _selectedDate != null
                      ? AppColors.primary
                      : Colors.grey[700],
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (_selectedDate != null)
              GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDate = null;
                  });
                  // Перезагружаем события при сбросе даты
                  _loadEvents();
                  // Обновляем маркеры без фильтра даты
                  _updateMapMarkers();
                },
                child: Icon(
                  Icons.close,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Кнопка фильтра по категориям
  Widget _buildCategoryFilterButton() {
    // Получаем все уникальные категории
    final categories = <String>{};
    for (final event in _events) {
      if (event.categories != null && event.categories!.isNotEmpty) {
        categories.addAll(event.categories!);
      } else {
        categories.add('Другое');
      }
    }

    return PopupMenuButton<String>(
      onSelected: (category) {
        setState(() {
          _selectedCategory = _selectedCategory == category ? null : category;
        });
        // Обновляем маркеры с учетом фильтра категории
        _updateMapMarkers();
      },
      itemBuilder: (context) {
        return categories.map((category) {
          return PopupMenuItem<String>(
            value: category,
            child: Row(
              children: [
                if (_selectedCategory == category)
                  const Icon(
                    Icons.check,
                    color: AppColors.primary,
                    size: 20,
                  )
                else
                  const SizedBox(width: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(category),
                ),
              ],
            ),
          );
        }).toList();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _selectedCategory != null
              ? AppColors.primary.withOpacity(0.1)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _selectedCategory != null
                ? AppColors.primary
                : Colors.grey[300]!,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.filter_list,
              color: _selectedCategory != null
                  ? AppColors.primary
                  : Colors.grey[600],
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              _selectedCategory ?? 'Все',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _selectedCategory != null
                    ? AppColors.primary
                    : Colors.grey[700],
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              color: _selectedCategory != null
                  ? AppColors.primary
                  : Colors.grey[600],
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

/// Класс для кэширования событий
class EventsCache {
  List<TimepadEvent>? _cachedEvents;
  DateTime? _cacheTime;
  static const _cacheDuration = Duration(minutes: 5);

  bool get isValid =>
      _cachedEvents != null &&
      _cacheTime != null &&
      DateTime.now().difference(_cacheTime!) < _cacheDuration;

  void cache(List<TimepadEvent> events) {
    _cachedEvents = events;
    _cacheTime = DateTime.now();
  }

  List<TimepadEvent>? get events => isValid ? _cachedEvents : null;

  void clear() {
    _cachedEvents = null;
    _cacheTime = null;
  }
}
