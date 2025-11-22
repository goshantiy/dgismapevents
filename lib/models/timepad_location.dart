class TimepadLocation {
  final String? city;
  final String? address;
  final double? latitude;
  final double? longitude;

  TimepadLocation({
    this.city,
    this.address,
    this.latitude,
    this.longitude,
  });

  factory TimepadLocation.fromJson(Map<String, dynamic> json) {
    return TimepadLocation(
      city: json['city'],
      address: json['address'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'city': city,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  bool get hasCoordinates => latitude != null && longitude != null;
}
