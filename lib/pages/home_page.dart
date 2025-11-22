import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dgis_mobile_sdk_full/dgis.dart' as sdk;
import 'package:geolocator/geolocator.dart';
import '../constants/app_colors.dart';
import '../models/timepad_event.dart';
import '../services/ai_recommendation_service.dart';
import '../widgets/ai_recommendations_sheet.dart';
import '../config/api_config.dart';

/// Главный экран с картой 2GIS
/// Поддерживает мобильные и десктопные платформы
class HomePage extends StatefulWidget {
  final sdk.Context? sdkContext;
  final AiRecommendationService? aiService;
  final Function(TimepadEvent)? onEventMarkerTapped;
  final Function(void Function(List<TimepadEvent>))? onAddEventMarkersCallback;
  final Map<String, dynamic>? apiConfig;

  const HomePage({
    super.key,
    required this.sdkContext,
    this.aiService,
    this.onEventMarkerTapped,
    this.onAddEventMarkersCallback,
    this.apiConfig,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<TimepadEvent> _eventsWithMarkers = [];
  TimepadEvent? _selectedEvent;
  sdk.CameraPosition? _initialPosition;
  final _mapWidgetController = sdk.MapWidgetController();
  sdk.Map? _sdkMap;
  sdk.MapObjectManager? _mapObjectManager;
  sdk.SearchManager? _searchManager;

  @override
  void initState() {
    super.initState();
    // Регистрируем callback для добавления маркеров
    widget.onAddEventMarkersCallback?.call(addEventMarkers);
    _initializeLocation();
    _initializeMap();
  }

  void _initializeMap() {
    if (widget.sdkContext != null) {
      _searchManager = sdk.SearchManager.createOnlineManager(widget.sdkContext!);
      
      // Добавляем обработчик кликов на объекты карты
      _mapWidgetController.addObjectTappedCallback((sdk.RenderedObjectInfo info) async {
        debugPrint('[HomePage] Object tapped');
        final obj = info.item;
        
        debugPrint('[HomePage] Object type: ${obj.item.runtimeType}');
        
        // Проверяем userData объекта (маркеры имеют тип SimpleMapObject)
        final userData = obj.item.userData;
        debugPrint('[HomePage] Object userData: $userData (type: ${userData.runtimeType})');
        debugPrint('[HomePage] Available events: ${_eventsWithMarkers.length}');
        
        if (userData != null && userData is int) {
          final eventId = userData;
          debugPrint('[HomePage] Marker tapped, event ID: $eventId');
          
          // Ищем событие по ID
          TimepadEvent? tappedEvent;
          try {
            tappedEvent = _eventsWithMarkers.firstWhere(
              (e) => e.id == eventId,
            );
            debugPrint('[HomePage] Event found: ${tappedEvent.name}');
            widget.onEventMarkerTapped?.call(tappedEvent);
          } catch (e) {
            debugPrint('[HomePage] Event not found for ID: $eventId');
            debugPrint('[HomePage] Error: $e');
            // Логируем первые несколько ID для отладки
            if (_eventsWithMarkers.isNotEmpty) {
              debugPrint('[HomePage] First event ID: ${_eventsWithMarkers.first.id}');
              debugPrint('[HomePage] First 5 event IDs: ${_eventsWithMarkers.take(5).map((e) => e.id).toList()}');
            }
          }
        } else {
          debugPrint('[HomePage] Object has no valid userData (expected int)');
        }
      });
      
      _mapWidgetController.getMapAsync((map) {
        _sdkMap = map;
        _mapObjectManager = sdk.MapObjectManager(map);
        debugPrint('[HomePage] Map initialized, ready to add markers');
        // Добавляем маркеры если они уже были загружены
        if (_eventsWithMarkers.isNotEmpty) {
          _addMarkersToMap(_eventsWithMarkers);
        }
      });
    }
  }

  Future<void> _initializeLocation() async {
    debugPrint('[HomePage] _initializeLocation started');
    try {
      // Проверяем доступность сервисов геолокации
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      debugPrint('[HomePage] Location service enabled: $serviceEnabled');
      
      if (!serviceEnabled) {
        debugPrint('[HomePage] Location services are disabled');
        return;
      }

      // Проверяем разрешения
      LocationPermission permission = await Geolocator.checkPermission();
      debugPrint('[HomePage] Current permission: $permission');
      
      if (permission == LocationPermission.denied) {
        debugPrint('[HomePage] Requesting permission...');
        permission = await Geolocator.requestPermission();
        debugPrint('[HomePage] Permission after request: $permission');
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('[HomePage] Разрешение на геолокацию отклонено навсегда');
        return;
      }

      if (permission == LocationPermission.denied) {
        debugPrint('[HomePage] Разрешение на геолокацию отклонено');
        return;
      }

      // Получаем текущую позицию
      debugPrint('[HomePage] Getting current position...');
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      debugPrint('[HomePage] Текущая позиция: ${position.latitude}, ${position.longitude}');
      debugPrint('[HomePage] Но используем Москву для прототипа');

      setState(() {
        _initialPosition = sdk.CameraPosition(
          point: sdk.GeoPoint(
            latitude: sdk.Latitude(55.751244),
            longitude: sdk.Longitude(37.618423),
          ),
          zoom: sdk.Zoom(12.0),
        );
      });
      
      debugPrint('[HomePage] Position set to Moscow');
    } catch (e, stackTrace) {
      debugPrint('[HomePage] Ошибка получения геолокации: $e');
      debugPrint('[HomePage] Stack trace: $stackTrace');
    }
  }

  @override
  void dispose() {
    // Очищаем события при удалении виджета
    _eventsWithMarkers.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('[HomePage] build: aiService=${widget.aiService != null}, sdkContext=${widget.sdkContext != null}');
    // Проверка платформы
    final isMobilePlatform = Platform.isAndroid || Platform.isIOS;
    debugPrint('[HomePage] isMobilePlatform=$isMobilePlatform');

    // Если десктопная платформа - показываем заглушку
    if (!isMobilePlatform) {
      return _buildDesktopPlaceholder();
    }

    // Если SDK не инициализирован - показываем заглушку
    if (widget.sdkContext == null) {
      return _buildErrorPlaceholder();
    }

    // Показываем карту на мобильных платформах
    debugPrint('[HomePage] Показываем карту с AI кнопкой: ${widget.aiService != null}');
    return Stack(
      children: [
        _buildMapWidget(),
        if (widget.aiService != null) ...[
          Positioned(
            bottom: 24,
            right: 16,
            child: SizedBox(
              width: 48,
              height: 48,
              child: FloatingActionButton(
                onPressed: _showAiRecommendations,
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                elevation: 3,
                child: const Icon(Icons.auto_awesome, size: 24),
                tooltip: 'AI советы',
              ),
            ),
          ),
        ] else ...[
          Positioned(
            bottom: 24,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(8),
              color: Colors.red,
              child: const Text('AI сервис null', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ],
    );
  }

  /// Виджет карты для мобильных платформ
  Widget _buildMapWidget() {
    try {
      // Используем текущую позицию или дефолтную (Москва)
      final position = _initialPosition ?? sdk.CameraPosition(
        point: sdk.GeoPoint(
          latitude: sdk.Latitude(55.751244),
          longitude: sdk.Longitude(37.618423),
        ),
        zoom: sdk.Zoom(12.0),
      );

      final mapOptions = sdk.MapOptions(
        position: position,
      );

      return sdk.MapWidget(
        mapOptions: mapOptions,
        sdkContext: widget.sdkContext!,
        controller: _mapWidgetController,
      );
    } catch (e) {
      debugPrint('Ошибка отображения карты: $e');
      return _buildErrorPlaceholder();
    }
  }

  /// Добавить маркеры событий на карту
  /// Фильтрует события с координатами и подготавливает их для отображения
  void addEventMarkers(List<TimepadEvent> events) {
    debugPrint('[HomePage] addEventMarkers called with ${events.length} events');
    
    // Логируем первое событие для проверки
    if (events.isNotEmpty) {
      final first = events.first;
      debugPrint('[HomePage] First event: ${first.name}');
      debugPrint('[HomePage] Location: ${first.location?.city}, has coords: ${first.location?.hasCoordinates}');
      if (first.location != null) {
        debugPrint('[HomePage] Coords: lat=${first.location!.latitude}, lon=${first.location!.longitude}');
        debugPrint('[HomePage] Address: ${first.location!.address}');
      }
    }
    
    setState(() {
      _eventsWithMarkers.clear();
      _eventsWithMarkers.addAll(events);
    });

    debugPrint('[HomePage] Prepared ${events.length} events for geocoding');
    
    // Добавляем маркеры на карту если она уже создана
    // Теперь передаем ВСЕ события, геокодирование будет внутри _addMarkersToMap
    if (_mapObjectManager != null) {
      _addMarkersToMap(events);
    }
  }

  /// Добавляет маркеры на карту
  Future<void> _addMarkersToMap(List<TimepadEvent> events) async {
    debugPrint('[HomePage] _addMarkersToMap started with ${events.length} events');
    
    if (_mapObjectManager == null || widget.sdkContext == null || _searchManager == null) {
      debugPrint('[HomePage] MapObjectManager, sdkContext or SearchManager not initialized');
      debugPrint('[HomePage] _mapObjectManager: $_mapObjectManager');
      debugPrint('[HomePage] widget.sdkContext: ${widget.sdkContext}');
      debugPrint('[HomePage] _searchManager: $_searchManager');
      if (_sdkMap == null) {
        debugPrint('[HomePage] Map instance is also null');
      }
      return;
    }

    // Удаляем старые маркеры
    _mapObjectManager!.removeAll();
    debugPrint('[HomePage] Removed old markers');

    // Загружаем иконку из assets
    final imageLoader = sdk.ImageLoader(widget.sdkContext!);
    sdk.Image? icon;
    try {
      debugPrint('[HomePage] Loading icon from assets/icon1.svg');
      icon = await imageLoader.loadSVGFromAsset('assets/icon2.svg');
      debugPrint('[HomePage] Icon loaded successfully');
    } catch (e, stackTrace) {
      debugPrint('[HomePage] Error loading icon: $e');
      debugPrint('[HomePage] Stack trace: $stackTrace');
      return;
    }

    int addedCount = 0;
    int geocodedCount = 0;
    int skippedNoAddress = 0;
    int failedGeocode = 0;
    
    for (final event in events) {
      // Пропускаем события без адреса
      if (event.location?.address == null || event.location!.address!.isEmpty) {
        skippedNoAddress++;
        debugPrint('[HomePage] Skipping event without address: ${event.name}');
        continue;
      }

      try {
        // Формируем полный адрес для поиска
        final city = event.location!.city ?? 'Москва';
        final address = event.location!.address!;
        final fullAddress = '$city, $address';
        
        debugPrint('[HomePage] [$geocodedCount] Geocoding: $fullAddress for event: ${event.name}');
        
        // Создаем поисковый запрос для геокодирования
        debugPrint('[HomePage] Creating search query...');
        final searchQuery = sdk.SearchQueryBuilder
          .fromQueryText(fullAddress)
          .setAllowedResultTypes([sdk.ObjectType.building]) // Только здания
          .build();
        
        debugPrint('[HomePage] Executing search...');
        final searchResultFuture = _searchManager!.search(searchQuery);
        final searchResult = await searchResultFuture.value;
        
        debugPrint('[HomePage] Search completed');
        
        // Проверяем наличие результатов
        final firstPage = searchResult.firstPage;
        if (firstPage == null) {
          debugPrint('[HomePage] firstPage is null for: $fullAddress');
          failedGeocode++;
          continue;
        }
        
        debugPrint('[HomePage] firstPage.items.length: ${firstPage.items.length}');
        
        if (firstPage.items.isEmpty) {
          debugPrint('[HomePage] No results for: $fullAddress');
          failedGeocode++;
          continue;
        }
        
        // Берем первый результат
        final directoryObject = firstPage.items.first;
        debugPrint('[HomePage] Got DirectoryObject: ${directoryObject.title}');
        
        if (directoryObject.markerPosition == null) {
          debugPrint('[HomePage] No coordinates in result for: $fullAddress');
          debugPrint('[HomePage] DirectoryObject details: title=${directoryObject.title}, subtitle=${directoryObject.subtitle}');
          failedGeocode++;
          continue;
        }
        
        final point = directoryObject.markerPosition!;
        debugPrint('[HomePage] Found coordinates: lat=${point.point.latitude.value}, lon=${point.point.longitude.value}');
        geocodedCount++;
        
        // Формируем текст цены для маркера
        String priceText;
        if (event.ticketPrice == null || (event.ticketPrice!.min ?? 0) == 0) {
          priceText = 'Бесплатно';
        } else {
          final minPrice = event.ticketPrice!.min?.toInt() ?? 0;
          priceText = 'от $minPrice р';
        }
        debugPrint('[HomePage] Price text: $priceText');
        
        debugPrint('[HomePage] Creating marker...');
        final marker = sdk.Marker(
          sdk.MarkerOptions(
            position: point,
            icon: icon,
            iconWidth: const sdk.LogicalPixel(40),
            userData: event.id,
            text: priceText,
            textStyle: const sdk.TextStyle(
              textPlacement: sdk.TextPlacement.topCenter,
              fontSize: sdk.LogicalPixel(12),
              color: sdk.Color(0xFFFFFFFF), // Белый текст
            ),
            zIndex: sdk.ZIndex(1),
          ),
        );

        debugPrint('[HomePage] Adding marker to map...');
        _mapObjectManager!.addObject(marker);
        addedCount++;
        debugPrint('[HomePage] Marker added successfully for: ${event.name}');
      } catch (e, stackTrace) {
        debugPrint('[HomePage] Error geocoding/adding marker for ${event.name}: $e');
        debugPrint('[HomePage] Stack trace: $stackTrace');
        failedGeocode++;
      }
    }

    debugPrint('[HomePage] ===== Geocoding Summary =====');
    debugPrint('[HomePage] Total events: ${events.length}');
    debugPrint('[HomePage] Skipped (no address): $skippedNoAddress');
    debugPrint('[HomePage] Geocoded successfully: $geocodedCount');
    debugPrint('[HomePage] Failed to geocode: $failedGeocode');
    debugPrint('[HomePage] Markers added to map: $addedCount');
    debugPrint('[HomePage] ============================');
  }

  /// Получить выбранное событие
  TimepadEvent? get selectedEvent => _selectedEvent;

  /// Очистить выбранное событие
  void clearSelectedEvent() {
    setState(() {
      _selectedEvent = null;
    });
  }

  String getCurrentCity() {
    // TODO: Реализовать определение города по центру карты или геолокации
    // Например, return 'Новосибирск';
    return 'Москва';
  }

  /// Показать AI рекомендации
  void _showAiRecommendations() {
    if (widget.aiService == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('AI сервис недоступен'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final city = getCurrentCity();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AiRecommendationsSheet(
        aiService: widget.aiService!,
        initialCity: city,
        apiConfig: widget.apiConfig != null ? ApiConfig.fromJson(widget.apiConfig!) : null,
      ),
    );
  }

  /// Заглушка для десктопных платформ
  Widget _buildDesktopPlaceholder() {
    return Container(
      color: AppColors.placeholderBackground,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.map,
              size: 80,
              color: AppColors.placeholderText,
            ),
            const SizedBox(height: 24),
            Text(
              'Карта 2GIS',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.placeholderText,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Доступно только на мобильных устройствах',
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

  /// Заглушка при ошибке инициализации SDK
  Widget _buildErrorPlaceholder() {
    return Container(
      color: AppColors.placeholderBackground,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: AppColors.placeholderText,
            ),
            const SizedBox(height: 24),
            Text(
              'Карта недоступна',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.placeholderText,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'SDK не инициализирован.\nПроверьте API ключ.',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.placeholderText,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

}
