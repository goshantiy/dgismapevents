class TimepadImage {
  final String defaultUrl;
  final String? uploadedUrl;

  TimepadImage({
    required this.defaultUrl,
    this.uploadedUrl,
  });

  factory TimepadImage.fromJson(Map<String, dynamic> json) {
    return TimepadImage(
      defaultUrl: json['default_url'] ?? '',
      uploadedUrl: json['uploaded_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'default_url': defaultUrl,
      'uploaded_url': uploadedUrl,
    };
  }

  String get imageUrl => uploadedUrl ?? defaultUrl;
}
