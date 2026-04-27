// filepath: lib\model\transaction.dart
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
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      amount: (map['amount'] as num).toDouble(),
      date: DateTime.parse(map['date'] as String),
      description: map['description'] as String,
      categoryId: map['category_id'] as int,
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