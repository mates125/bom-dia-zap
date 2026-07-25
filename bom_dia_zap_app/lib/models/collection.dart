class Collection {
  final int id;
  final String name;
  final bool isDefault;
  final int imageCount;

  Collection({
    required this.id,
    required this.name,
    required this.isDefault,
    required this.imageCount,
  });

  factory Collection.fromJson(Map<String, dynamic> json) {
    return Collection(
      id: json['id'] as int,
      name: json['name'] as String,
      isDefault: json['isDefault'] as bool,
      imageCount: json['imageCount'] as int,
    );
  }
}
