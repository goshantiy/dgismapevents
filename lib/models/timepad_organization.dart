class TimepadOrganization {
  final String name;

  TimepadOrganization({
    required this.name,
  });

  factory TimepadOrganization.fromJson(Map<String, dynamic> json) {
    return TimepadOrganization(
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
    };
  }
}
