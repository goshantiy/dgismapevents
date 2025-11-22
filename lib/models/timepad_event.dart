import 'timepad_image.dart';
import 'timepad_location.dart';
import 'timepad_organization.dart';
import 'timepad_ticket_price.dart';
import 'timepad_ticket_type.dart';

class TimepadEvent {
  final int id;
  final String name;
  final String? descriptionShort;
  final TimepadImage? posterImage;
  final DateTime? startsAt;
  final TimepadTicketPrice? ticketPrice;
  final List<TimepadTicketType>? ticketTypes;
  final TimepadOrganization? organization;
  final TimepadLocation? location;
  final List<String>? categories;

  TimepadEvent({
    required this.id,
    required this.name,
    this.descriptionShort,
    this.posterImage,
    this.startsAt,
    this.ticketPrice,
    this.ticketTypes,
    this.organization,
    this.location,
    this.categories,
  });

  factory TimepadEvent.fromJson(Map<String, dynamic> json) {
    return TimepadEvent(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      descriptionShort: json['description_short'],
      posterImage: json['poster_image'] != null
          ? TimepadImage.fromJson(json['poster_image'])
          : null,
      startsAt: json['starts_at'] != null
          ? DateTime.tryParse(json['starts_at'])
          : null,
      ticketTypes: json['ticket_types'] != null
          ? (json['ticket_types'] as List<dynamic>)
              .map((t) => TimepadTicketType.fromJson(t as Map<String, dynamic>))
              .toList()
          : null,
      ticketPrice: _calculateTicketPrice(json),
      organization: json['organization'] != null
          ? TimepadOrganization.fromJson(json['organization'])
          : null,
      location: json['location'] != null
          ? TimepadLocation.fromJson(json['location'])
          : null,
      categories: json['categories'] != null
          ? List<String>.from(json['categories'].map((c) => c['name'] ?? c.toString()))
          : null,
    );
  }

  static TimepadTicketPrice? _calculateTicketPrice(Map<String, dynamic> json) {
    if (json['ticket_types'] != null) {
      final types = (json['ticket_types'] as List<dynamic>)
          .map((t) => TimepadTicketType.fromJson(t as Map<String, dynamic>))
          .where((t) => t.isActive)
          .toList();
      
      if (types.isEmpty) return null;
      
      final prices = types.map((t) => t.price).toList();
      return TimepadTicketPrice(
        min: prices.reduce((a, b) => a < b ? a : b),
        max: prices.reduce((a, b) => a > b ? a : b),
      );
    }
    
    if (json['ticket_price'] != null) {
      return TimepadTicketPrice.fromJson(json['ticket_price']);
    }
    
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description_short': descriptionShort,
      'poster_image': posterImage?.toJson(),
      'starts_at': startsAt?.toIso8601String(),
      'ticket_price': ticketPrice?.toJson(),
      'ticket_types': ticketTypes?.map((t) => t.toJson()).toList(),
      'organization': organization?.toJson(),
      'location': location?.toJson(),
      'categories': categories,
    };
  }
}
