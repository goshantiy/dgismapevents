import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/timepad_event.dart';
import '../models/timepad_ticket_type.dart';
import '../utils/date_formatter.dart';
import '../constants/app_colors.dart';

/// Детальная шторка с информацией о событии
class EventDetailSheet extends StatelessWidget {
  final TimepadEvent event;

  const EventDetailSheet({
    Key? key,
    required this.event,
  }) : super(key: key);

  static Future<void> show(BuildContext context, TimepadEvent event) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return EventDetailSheet(event: event);
        },
      ),
    );
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
      ),
      child: Column(
        children: [
          _buildDragHandle(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildImage(),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTitle(),
                        const SizedBox(height: 16),
                        _buildDateTime(),
                        const SizedBox(height: 12),
                        _buildLocation(),
                        const SizedBox(height: 12),
                        _buildPrice(),
                        if (event.organization != null) ...[
                          const SizedBox(height: 16),
                          _buildOrganization(),
                        ],
                        if (event.descriptionShort != null) ...[
                          const SizedBox(height: 16),
                          _buildDescription(),
                        ],
                        if (event.categories != null && event.categories!.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          _buildCategories(),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

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

  Widget _buildPlaceholderImage() {
    return Container(
      color: AppColors.placeholderBackground,
      child: const Center(
        child: Icon(
          Icons.event,
          size: 64,
          color: AppColors.placeholderText,
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      event.name,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildDateTime() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.calendar_today,
            color: AppColors.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Дата и время',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.placeholderText,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                formatEventDate(event.startsAt),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLocation() {
    final address = event.location?.address ?? 'Место уточняется';
    
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.location_on,
            color: AppColors.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Место проведения',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.placeholderText,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                address,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPrice() {
    final ticketTypes = event.ticketTypes;
    
    // Если есть детальная информация о типах билетов
    if (ticketTypes != null && ticketTypes.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.confirmation_number,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Билеты',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...ticketTypes.where((t) => t.isActive).map((ticket) => _buildTicketType(ticket)),
        ],
      );
    }
    
    // Фоллбэк на старый вариант
    final price = event.ticketPrice?.displayPrice ?? 'Бесплатно';
    final isFree = event.ticketPrice?.isFree ?? true;
    
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.confirmation_number,
            color: AppColors.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Стоимость',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.placeholderText,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                price,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isFree ? AppColors.primary : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTicketType(TimepadTicketType ticket) {
    final isFree = ticket.isFree;
    final isAvailable = ticket.isAvailable;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isAvailable ? Colors.grey[50] : Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isAvailable ? AppColors.primary.withOpacity(0.3) : Colors.grey[300]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  ticket.name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isAvailable ? Colors.black87 : Colors.grey[600],
                  ),
                ),
              ),
              Text(
                isFree ? 'Бесплатно' : '${ticket.price.toInt()} ₽',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isFree ? AppColors.primary : (isAvailable ? Colors.black87 : Colors.grey[600]),
                ),
              ),
            ],
          ),
          if (ticket.description != null && ticket.description!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              ticket.description!,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
          ],
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                isAvailable ? Icons.check_circle : Icons.cancel,
                size: 14,
                color: isAvailable ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 4),
              Text(
                isAvailable ? 'Осталось: ${ticket.remaining}' : 'Билеты закончились',
                style: TextStyle(
                  fontSize: 12,
                  color: isAvailable ? Colors.green[700] : Colors.red[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrganization() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Организатор',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.placeholderText,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          event.organization!.name,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Описание',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.placeholderText,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          event.descriptionShort!,
          style: const TextStyle(
            fontSize: 15,
            height: 1.5,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildCategories() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Категории',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.placeholderText,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: event.categories!.map((category) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                category,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
