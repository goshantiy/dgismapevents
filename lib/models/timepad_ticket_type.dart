class TimepadTicketType {
  final int id;
  final String name;
  final String? description;
  final int buyAmountMin;
  final int buyAmountMax;
  final double price;
  final bool isPromocodeBlocked;
  final int remaining;
  final DateTime? saleEndsAt;
  final DateTime? saleStartsAt;
  final String publicKey;
  final bool isActive;
  final double? adPartnerProfit;
  final bool? sendPersonalLinks;
  final int? sold;
  final int? attended;
  final int? limit;
  final String? status;

  TimepadTicketType({
    required this.id,
    required this.name,
    this.description,
    required this.buyAmountMin,
    required this.buyAmountMax,
    required this.price,
    required this.isPromocodeBlocked,
    required this.remaining,
    this.saleEndsAt,
    this.saleStartsAt,
    required this.publicKey,
    required this.isActive,
    this.adPartnerProfit,
    this.sendPersonalLinks,
    this.sold,
    this.attended,
    this.limit,
    this.status,
  });

  factory TimepadTicketType.fromJson(Map<String, dynamic> json) {
    return TimepadTicketType(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'],
      buyAmountMin: json['buy_amount_min'] ?? 0,
      buyAmountMax: json['buy_amount_max'] ?? 0,
      price: (json['price'] ?? 0).toDouble(),
      isPromocodeBlocked: json['is_promocode_locked'] ?? false,
      remaining: json['remaining'] ?? 0,
      saleEndsAt: json['sale_ends_at'] != null
          ? DateTime.tryParse(json['sale_ends_at'])
          : null,
      saleStartsAt: json['sale_starts_at'] != null
          ? DateTime.tryParse(json['sale_starts_at'])
          : null,
      publicKey: json['public_key'] ?? '',
      isActive: json['is_active'] ?? false,
      adPartnerProfit: json['ad_partner_profit']?.toDouble(),
      sendPersonalLinks: json['send_personal_links'],
      sold: json['sold'],
      attended: json['attended'],
      limit: json['limit'],
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'buy_amount_min': buyAmountMin,
      'buy_amount_max': buyAmountMax,
      'price': price,
      'is_promocode_locked': isPromocodeBlocked,
      'remaining': remaining,
      'sale_ends_at': saleEndsAt?.toIso8601String(),
      'sale_starts_at': saleStartsAt?.toIso8601String(),
      'public_key': publicKey,
      'is_active': isActive,
      'ad_partner_profit': adPartnerProfit,
      'send_personal_links': sendPersonalLinks,
      'sold': sold,
      'attended': attended,
      'limit': limit,
      'status': status,
    };
  }

  bool get isFree => price == 0;
  bool get isAvailable => isActive && remaining > 0;
}
