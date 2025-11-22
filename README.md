
# 2GIS Events Map

Приложение на Flutter для отображения событий на карте 2GIS с интеграцией AI-рекомендаций.

## Возможности
- Интерактивная карта 2GIS с маркерами событий
- Загрузка событий из Timepad API
- AI-рекомендации мест для отдыха
- Фильтрация событий по дате и категориям
- Календарь для выбора периода событий
- Детальная информация о событиях с покупкой билетов

## Быстрый старт
1. Клонируйте репозиторий:
   ```bash
   git clone <repository-url>
   cd dgismapevents
   ```
2. Установите зависимости:
   ```bash
   flutter pub get
   ```
3. Настройте конфигурацию:
   - Добавьте API-ключ 2GIS в `assets/dgissdk.key`
   - Создайте файл `assets/config/api_config.json`:
     ```json
     {
       "timepad_api_token": "ваш_токен_timepad",
       "gis_ai_api_key": "ваш_ключ_ai"
     }
     ```
4. Запустите приложение:
   ```bash
   flutter run
   ```

## Структура проекта

### Основные директории

```
lib/
├── config/                      # Конфигурация приложения
│   ├── api_config.dart          # Загрузка API-токенов из assets
│   └── ai_config.dart           # Настройки AI-рекомендаций
│
├── models/                      # Модели данных Timepad API
│   ├── timepad_event.dart       # Событие
│   ├── timepad_location.dart    # Локация события
│   ├── timepad_organization.dart # Организатор
│   ├── timepad_ticket_type.dart # Тип билета
│   ├── timepad_ticket_price.dart # Цена билета
│   └── timepad_image.dart       # Изображение события
│
├── services/                    # Бизнес-логика и API
│   ├── timepad_service.dart     # Работа с Timepad API
│   └── ai_recommendation_service.dart # AI-рекомендации мест
│
├── pages/                       # Экраны приложения
│   ├── main_navigation_page.dart # Главная навигация (карта + события)
│   ├── home_page.dart           # Основная страница с картой
│   └── placeholder_page.dart    # Заглушки для других разделов
│
├── widgets/                     # UI-компоненты
│   ├── event_card.dart          # Карточка события в списке
│   ├── event_detail_sheet.dart  # Модальное окно с деталями события
│   ├── events_bottom_sheet.dart # Нижняя панель со списком событий
│   ├── calendar_picker.dart     # Календарь выбора дат
│   └── ai_recommendations_sheet.dart # Панель AI-рекомендаций
│
├── utils/                       # Утилиты
│   └── date_formatter.dart      # Форматирование дат
│
├── constants/                   # Константы
│   └── app_colors.dart          # Цветовая схема
│
└── main.dart                    # Точка входа приложения

assets/
├── config/
│   └── api_config.json          # Конфигурация API-токенов
├── dgissdk.key                  # API-ключ 2GIS SDK
└── icon*.svg                    # SVG-иконки для маркеров
```

### Описание компонентов

#### Конфигурация (`config/`)
- **api_config.dart** — загружает токены API из JSON-файла в assets
- **ai_config.dart** — настройки для AI-рекомендаций (модель, температура, промпты)

#### Модели данных (`models/`)
Модели соответствуют структуре Timepad API:
- **TimepadEvent** — основная модель события (название, описание, дата, билеты)
- **TimepadLocation** — локация с адресом и координатами
- **TimepadOrganization** — информация об организаторе
- **TimepadTicketType** — типы билетов (продажа, регистрация и т.д.)

#### Сервисы (`services/`)
- **TimepadService** — работа с Timepad API:
  - `getEvents()` — получение списка событий с фильтрацией по городу, категориям, датам
  - Использует токен авторизации из `api_config.json`
  
- **AiRecommendationService** — интеграция с AI:
  - `getRecommendations()` — получение персонализированных рекомендаций мест
  - Использует GigaChat API (можно настроить на другую модель)
  - Формирует промпты на основе предпочтений пользователя

#### Страницы (`pages/`)
- **MainNavigationPage** — главный экран с bottom navigation bar
- **HomePage** — карта 2GIS с маркерами событий, список событий, AI-рекомендации
- **PlaceholderPage** — заглушки для разделов "Избранное", "Профиль" и т.д.

#### Виджеты (`widgets/`)
- **EventCard** — компактная карточка события для списка
- **EventDetailSheet** — модальное окно с полной информацией о событии
- **EventsBottomSheet** — выдвижная панель со списком событий
- **CalendarPicker** — календарь для фильтрации по датам
- **AiRecommendationsSheet** — панель с AI-рекомендациями мест отдыха

## Используемые API

### 1. Timepad API
- **Базовый URL:** `https://api.timepad.ru/v1`
- **Эндпоинт:** `/events`
- **Авторизация:** Bearer token из `api_config.json`
- **Назначение:** получение списка событий и мероприятий
- **Параметры:**
  - `limit` — количество событий
  - `cities` — фильтр по городу (например, "Новосибирск")
  - `categories` — фильтр по категориям
  - `starts_at_min` — минимальная дата начала
  - `fields` — запрашиваемые поля
  - `sort` — сортировка (`+starts_at` — по возрастанию даты)

### 2. 2GIS Mobile SDK
- **Версия:** 12.8.0
- **Авторизация:** API-ключ из `assets/dgissdk.key`
- **Назначение:** отображение интерактивной карты
- **Возможности:**
  - Отображение карты с маркерами
  - Управление камерой (zoom, position)
  - Кастомные стили карты

### 3. AI API (GigaChat / OpenAI-совместимый)
- **Конфигурация:** в `AiConfig`
- **Назначение:** генерация персонализированных рекомендаций мест отдыха
- **Параметры:**
  - Модель: настраивается в `ai_config.dart`
  - Temperature: 0.7 (креативность ответов)
  - Max tokens: ограничение длины ответа

## Основные зависимости

```yaml
dgis_mobile_sdk_full: ^12.8.0  # 2GIS карты
http: ^1.1.0                    # HTTP-клиент для API
intl: ^0.20.2                   # Локализация и форматирование дат
table_calendar: ^3.0.9          # Календарь
geolocator: ^14.0.2             # Геолокация
cached_network_image: ^3.3.0    # Кеширование изображений
flutter_svg: ^2.0.9             # SVG-иконки
```

## Конфигурационные файлы

### assets/config/api_config.json
```json
{
  "timepad_api_token": "ваш_токен_timepad_api",
  "gis_ai_api_key": "ваш_ключ_ai_api"
}
```

### assets/dgissdk.key
Текстовый файл с API-ключом 2GIS SDK.

## Workflow приложения

1. **Инициализация** (`main.dart`):
   - Загрузка API-ключа 2GIS из assets
   - Инициализация 2GIS SDK
   - Загрузка конфигурации API (`api_config.json`)
   - Создание AI-конфигурации

2. **Главная страница** (`home_page.dart`):
   - Отображение карты 2GIS
   - Загрузка событий через TimepadService
   - Размещение маркеров событий на карте
   - Отображение списка событий в нижней панели

3. **Взаимодействие**:
   - Выбор города и категорий для фильтрации
   - Выбор даты через календарь
   - Клик по событию → модальное окно с деталями
   - Запрос AI-рекомендаций на основе предпочтений
