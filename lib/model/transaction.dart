// filepath: lib\model\transaction.dart
import '../utils/type_converter.dart';

class Transaction {
  final int? id;
  final int userId;
  final double amount;
  final DateTime date;
  final String description;
  final int categoryId;

  Transaction({
    this.id,
    required this.userId,
    required this.amount,
    required this.date,
    required this.description,
    required this.categoryId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'amount': amount,
      'date': date.toIso8601String(),
      'description': description,
      'category_id': categoryId,
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: TypeConverter.toIntOrNull(map['id']),
      userId: TypeConverter.toInt(map['user_id']),
      amount: TypeConverter.toDouble(map['amount']),
      date: DateTime.parse((map['date'] ?? DateTime.now().toIso8601String()).toString()),
      description: TypeConverter.toStringi(map['description']),
      categoryId: TypeConverter.toInt(map['category_id']),
    );
  }

  Transaction copyWith({
    int? id,
    int? userId,
    double? amount,
    DateTime? date,
    String? description,
    int? categoryId,
  }) {
    return Transaction(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
    );
  }
}