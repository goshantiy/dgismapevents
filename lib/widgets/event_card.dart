import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/timepad_event.dart';
import '../utils/date_formatter.dart';
import '../constants/app_colors.dart';

/// Виджет карточки события
class EventCard extends StatelessWidget {
  final TimepadEvent event;
  final VoidCallback? onTap;
  final bool isExpanded;

  const EventCard({
    super.key,
    required this.event,
    this.onTap,
    this.isExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isExpanded) {
      return _buildExpandedCard();
    }
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImage(),
            Flexible(
              child: _buildEventInfo(),
            ),
          ],
        ),
      ),
    );
  }

  /// Расширенная карточка для вертикального списка
  Widget _buildExpandedCard() {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 120,
              height: 140,
              child: _buildImage(),
            ),
            Expanded(
              child: _buildExpandedEventInfo(),
            ),
          ],
        ),
      ),
    );
  }

  /// Отображает изображение события
  Widget _buildImage() {
    final imageUrl = event.posterImage?.imageUrl;

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: imageUrl != null
          ? CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: AppColors.placeholderBackground,
                child: const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                  ),
                ),
              ),
              errorWidget: (context, url, error) => _buildPlaceholderImage(),
            )
          : _buildPlaceholderImage(),
    );
  }

  /// Отображает placeholder изображение
  Widget _buildPlaceholderImage() {
    return Container(
      color: AppColors.placeholderBackground,
      child: const Center(
        child: Icon(
          Icons.event,
          size: 48,
          color: AppColors.placeholderText,
        ),
      ),
    );
  }

  /// Отображает информацию о событии
  Widget _buildEventInfo() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Название события
          Text(
            event.name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          
          // Дата события
          Text(
            formatEventDate(event.startsAt),
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.placeholderText,
            ),
          ),
          const SizedBox(height: 4),
          
          // Место проведения
          Row(
            children: [
              const Icon(
                Icons.location_on,
                size: 14,
                color: AppColors.placeholderText,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  _getLocationText(),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.placeholderText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          
          // Цена
          Text(
            event.ticketPrice?.displayPrice ?? 'Бесплатно',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: (event.ticketPrice?.isFree ?? true)
                  ? AppColors.primary
                  : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  /// Расширенная информация о событии для вертикального списка
  Widget _buildExpandedEventInfo() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Название события
          Text(
            event.name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          
          // Описание
          if (event.descriptionShort != null)
            Text(
              event.descriptionShort!,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          const SizedBox(height: 8),
          
          // Дата события
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 14,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Text(
                formatEventDate(event.startsAt),
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.placeholderText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          
          // Место проведения
          Row(
            children: [
              Icon(
                Icons.location_on,
                size: 14,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  _getLocationText(),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.placeholderText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Цена
          Text(
            event.ticketPrice?.displayPrice ?? 'Бесплатно',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: (event.ticketPrice?.isFree ?? true)
                  ? AppColors.primary
                  : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  /// Получает текст места проведения
  String _getLocationText() {
    final address = event.location?.address;
    final organizationName = event.organization?.name;
    
    if (address != null && address.isNotEmpty) {
      return address;
    }
    
    if (organizationName != null && organizationName.isNotEmpty) {
      return organizationName;
    }
    
    return 'Место уточняется';
  }
}
