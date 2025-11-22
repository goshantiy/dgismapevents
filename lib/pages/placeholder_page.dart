import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Заглушка для неактивных разделов приложения
class PlaceholderPage extends StatelessWidget {
  final String title;
  final IconData icon;

  const PlaceholderPage({
    super.key,
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.placeholderBackground,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Иконка
            Icon(
              icon,
              size: 80,
              color: AppColors.placeholderText,
            ),
            const SizedBox(height: 24),
            // Заголовок
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            // Описание
            Text(
              'Скоро будет доступно',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.placeholderText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
