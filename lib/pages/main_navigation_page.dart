import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dgis_mobile_sdk_full/dgis.dart' as sdk;
import '../config/api_config.dart';
import '../config/ai_config.dart';
import '../constants/app_colors.dart';
import '../models/timepad_event.dart';
import '../services/ai_recommendation_service.dart';
import '../widgets/events_bottom_sheet.dart';
import '../widgets/event_detail_sheet.dart';
import 'home_page.dart';
import 'placeholder_page.dart';

/// Главная страница с нижней панелью навигации
/// Управляет переключением между разделами приложения
class MainNavigationPage extends StatefulWidget {
  final sdk.Context? sdkContext;
  final ApiConfig? apiConfig;
  final AiConfig? aiConfig;

  const MainNavigationPage({
    super.key,
    required this.sdkContext,
    this.apiConfig,
    this.aiConfig,
  });

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  // Текущий выбранный индекс
  int _currentIndex = 0;
  
  // Callback для передачи событий в HomePage
  void Function(List<TimepadEvent>)? _addEventMarkersCallback;
  
  // AI сервис
  AiRecommendationService? _aiService;
  
  // Контроллер для DraggableScrollableSheet
  final DraggableScrollableController _sheetController = DraggableScrollableController();

  @override
  void initState() {
    super.initState();
    debugPrint('[MainNavigationPage] initState: apiConfig=${widget.apiConfig != null}, aiConfig=${widget.aiConfig != null}');
    // Инициализируем AI сервис если есть конфигурация
    if (widget.apiConfig != null && widget.aiConfig != null) {
      debugPrint('[MainNavigationPage] Создаем AiRecommendationService');
      debugPrint('[MainNavigationPage] gisAiApiKey: ${widget.apiConfig!.gisAiApiKey.substring(0, 10)}...');
      _aiService = AiRecommendationService(
        apiKey: widget.apiConfig!.gisAiApiKey,
        config: widget.aiConfig!,
      );
      debugPrint('[MainNavigationPage] AiRecommendationService создан: ✓');
    } else {
      debugPrint('[MainNavigationPage] AI сервис не создан - нет конфигурации');
    }
  }

  @override
  void dispose() {
    _aiService?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Основной контент с навигацией
          IndexedStack(
            index: _currentIndex,
            children: [
              // 0: Поиск (карта без шторки)
              HomePage(
                sdkContext: widget.sdkContext,
                aiService: _aiService,
                apiConfig: widget.apiConfig?.toJson(),
                onEventMarkerTapped: _handleEventMarkerTapped,
                onAddEventMarkersCallback: (callback) {
                  // Для страницы поиска не нужен callback
                },
              ),
              // 1: Проезд (заглушка)
              const PlaceholderPage(
                title: 'Проезд',
                icon: Icons.directions_bus,
              ),
              // 2: Навигатор (заглушка)
              const PlaceholderPage(
                title: 'Навигатор',
                icon: Icons.navigation,
              ),
              // 3: Друзья (заглушка)
              const PlaceholderPage(
                title: 'Друзья',
                icon: Icons.people,
              ),
              // 4: Тусить! (главный экран с картой)
              HomePage(
                sdkContext: widget.sdkContext,
                aiService: _aiService,
                apiConfig: widget.apiConfig?.toJson(),
                onEventMarkerTapped: _handleEventMarkerTapped,
                onAddEventMarkersCallback: (callback) {
                  _addEventMarkersCallback = callback;
                },
              ),
            ],
          ),
          // Встроенная шторка событий (показывается только на вкладке "Тусить!")
          if (_currentIndex == 4)
            DraggableScrollableSheet(
              controller: _sheetController,
              initialChildSize: 0.1,
              minChildSize: 0.1,
              maxChildSize: 0.95,
              snap: true,
              snapSizes: const [0.1, 0.25, 0.5, 0.75, 0.95],
              builder: (context, scrollController) {
                return EventsBottomSheet(
                  onClose: () {}, // Не используется
                  apiConfig: widget.apiConfig,
                  onEventSelected: _handleEventSelected,
                  onEventsLoaded: _handleEventsLoaded,
                  scrollController: scrollController,
                );
              },
            ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  /// Построение нижней панели навигации
  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: _onTabTapped,
      type: BottomNavigationBarType.fixed,
      backgroundColor: AppColors.navigationBackground,
      selectedItemColor: AppColors.navigationActive,
      unselectedItemColor: AppColors.navigationInactive,
      selectedFontSize: 12,
      unselectedFontSize: 12,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.search),
          label: 'Поиск',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.directions_bus),
          label: 'Проезд',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.navigation),
          label: 'Навигатор',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.people),
          label: 'Друзья',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.celebration),
          label: 'Куда пойти!',
        ),
      ],
    );
  }

  /// Обработка нажатий на кнопки навигации
  void _onTabTapped(int index) {
    // Для кнопок-заглушек (индексы 1-3)
    if (index >= 1 && index <= 3) {
      // Показываем SnackBar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Скоро будет доступно'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      // Применяем лёгкую тактильную обратную связь
      HapticFeedback.lightImpact();
      return;
    }

    // Для кнопки "Поиск" (индекс 0) и "Тусить!" (индекс 4)
    if (index == 0 || index == 4) {
      // Применяем среднюю тактильную обратную связь
      HapticFeedback.mediumImpact();
      // Переключаемся на вкладку
      setState(() {
        _currentIndex = index;
      });
      // Только для "Тусить!" разворачиваем шторку до 95%
      if (index == 4) {
        Future.delayed(const Duration(milliseconds: 100), () {
          _sheetController.animateTo(
            0.95,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        });
      }
      return;
    }
  }
  
  /// Обработчик загрузки событий из шторки
  /// Передает события в HomePage для отображения маркеров на карте
  void _handleEventsLoaded(List<TimepadEvent> events) {
    // Передаем события в HomePage для добавления маркеров
    _addEventMarkersCallback?.call(events);
  }
  
  /// Обработчик выбора события из списка
  void _handleEventSelected(TimepadEvent event) {
    debugPrint('Выбрано событие: ${event.name}');
    // Можно добавить дополнительную логику при выборе события
  }
  
  /// Обработчик нажатия на маркер события на карте
  void _handleEventMarkerTapped(TimepadEvent event) {
    debugPrint('[MainNavigationPage] Нажатие на маркер события: ${event.name}');
    // При нажатии на маркер открываем детальную информацию о событии
    EventDetailSheet.show(context, event);
  }
}
