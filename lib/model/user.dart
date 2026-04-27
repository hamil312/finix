// filepath: lib\model\user.dart
class User {
  final int? id;
  final String name;
  final String email;
  final String currency;
  final double monthlyIncome;
  final String password;

  User({
    this.id,
    required this.name,
    required this.email,
    required this.currency,
    required this.monthlyIncome,
    required this.password,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'currency': currency,
      'monthly_income': monthlyIncome,
      'password': password,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int?,
      name: map['name'] as String,
      email: map['email'] as String,
      currency: map['currency'] as String,
      monthlyIncome: (map['monthly_income'] as num).toDouble(),
      password: map['password'] as String,
    );
  }

  User copyWith({
    int? id,
    String? name,
    String? email,
    String? currency,
    double? monthlyIncome,
    String? password,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      currency: currency ?? this.currency,
      monthlyIncome: monthlyIncome ?? this.monthlyIncome,
      password: password ?? this.password,
    );
  }
}