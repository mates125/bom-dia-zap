class User {
  final int id;
  final String email;
  final bool isPremium;

  User({required this.id, required this.email, required this.isPremium});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      email: json['email'] as String,
      isPremium: json['isPremium'] as bool,
    );
  }
}
