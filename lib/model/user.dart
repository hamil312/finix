// filepath: lib\model\user.dart
import '../utils/type_converter.dart';

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
      id: TypeConverter.toIntOrNull(map['id']),
      name: TypeConverter.toStringi(map['name']),
      email: TypeConverter.toStringi(map['email']),
      currency: TypeConverter.toStringi(map['currency']),
      monthlyIncome: TypeConverter.toDouble(map['monthly_income']),
      password: TypeConverter.toStringi(map['password']),
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