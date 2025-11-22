import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dgis_mobile_sdk_full/dgis.dart' as dgis;
import 'package:intl/date_symbol_data_local.dart';
import 'config/api_config.dart';
import 'config/ai_config.dart';
import 'pages/main_navigation_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Инициализируем локализацию для форматирования дат
  await initializeDateFormatting('ru_RU', null);

  // Загружаем API ключ из assets
  String? apiKey;
  try {
    apiKey = await rootBundle.loadString('assets/dgissdk.key');
    debugPrint('API ключ загружен: ${apiKey.isNotEmpty ? "✓" : "✗"}');
  } catch (e) {
    debugPrint('Ошибка загрузки API ключа: $e');
  }

  // Инициализируем 2GIS SDK
  dgis.Context? sdkContext;

  try {
    if (apiKey != null && apiKey.isNotEmpty) {
      debugPrint('Инициализируем 2GIS SDK...');
      sdkContext = await dgis.DGis.initialize();
      debugPrint('2GIS SDK инициализирован: ✓');
      debugPrint('Кастомные стили будут загружены автоматически из assets');
    } else {
      debugPrint('API ключ пустой или не найден');
    }
  } catch (e) {
    debugPrint('Ошибка инициализации SDK: $e');
  }

  // Загружаем конфигурацию API
  ApiConfig? apiConfig;
  try {
    apiConfig = await ApiConfig.load();
    debugPrint('API конфигурация загружена: ✓');
    debugPrint('gis_ai_api_key: ${apiConfig.gisAiApiKey.isNotEmpty ? "есть" : "пустой"}');
  } on ApiConfigException catch (e) {
    debugPrint('Ошибка загрузки API конфигурации: $e');
    debugPrint('Приложение будет работать без функционала событий');
  } catch (e) {
    debugPrint('Неожиданная ошибка при загрузке API конфигурации: $e');
  }

  // Создаем AI конфигурацию
  final aiConfig = AiConfig.defaultConfig();
  debugPrint('AI конфигурация создана: ✓');

  runApp(MyApp(
    sdkContext: sdkContext,
    apiConfig: apiConfig,
    aiConfig: aiConfig,
  ));
}

class MyApp extends StatelessWidget {
  final dgis.Context? sdkContext;
  final ApiConfig? apiConfig;
  final AiConfig? aiConfig;

  const MyApp({
    super.key,
    this.sdkContext,
    this.apiConfig,
    this.aiConfig,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '2GIS Maps & GeoJSON',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: MainNavigationPage(
        sdkContext: sdkContext,
        apiConfig: apiConfig,
        aiConfig: aiConfig,
      ),
    );
  }
}
