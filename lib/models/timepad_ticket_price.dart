class TimepadTicketPrice {
  final double? min;
  final double? max;

  TimepadTicketPrice({
    this.min,
    this.max,
  });

  factory TimepadTicketPrice.fromJson(Map<String, dynamic> json) {
    return TimepadTicketPrice(
      min: json['min']?.toDouble(),
      max: json['max']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'min': min,
      'max': max,
    };
  }

  bool get isFree => (min == null || min == 0) && (max == null || max == 0);

  String get displayPrice {
    if (isFree) return 'Бесплатно';
    if (min != null && max != null && min != max) {
      return '${min!.toInt()}–${max!.toInt()} ₽';
    }
    if (min != null) return 'от ${min!.toInt()} ₽';
    if (max != null) return 'до ${max!.toInt()} ₽';
    return 'Бесплатно';
  }
}
