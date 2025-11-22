import 'package:intl/intl.dart';

/// Форматирует дату события в локализованный формат
///
/// Возвращает строку в формате "15 дек, 19:00" для русской локали
/// Если дата null, возвращает "Дата уточняется"
String formatEventDate(DateTime? date) {
  if (date == null) {
    return 'Дата уточняется';
  }

  // Форматируем день и месяц
  final dayFormat = DateFormat('d MMM', 'ru_RU');
  final timeFormat = DateFormat('HH:mm', 'ru_RU');

  final dayMonth = dayFormat.format(date);
  final time = timeFormat.format(date);

  return '$dayMonth, $time';
}
