class ImageItem {
  final int id;
  final String? title;
  final String imageUrl;
  final String? thumbnailUrl;
  final String? sourceUrl;
  final String? photographer;

  ImageItem({
    required this.id,
    this.title,
    required this.imageUrl,
    this.thumbnailUrl,
    this.sourceUrl,
    this.photographer,
  });

  factory ImageItem.fromJson(Map<String, dynamic> json) {
    return ImageItem(
      id: json['id'] as int,
      title: json['title'] as String?,
      imageUrl: json['imageUrl'] as String,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      sourceUrl: json['sourceUrl'] as String?,
      photographer: json['photographer'] as String?,
    );
  }
}
