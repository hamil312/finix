// filepath: lib\model\debt.dart
class Debt {
  final int? id;
  final int userId;
  final String name;
  final double total;
  final double remaining;
  final double interestRate;
  final DateTime dueDate;

  Debt({
    this.id,
    required this.userId,
    required this.name,
    required this.total,
    required this.remaining,
    required this.interestRate,
    required this.dueDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'total': total,
      'remaining': remaining,
      'interest_rate': interestRate,
      'due_date': dueDate.toIso8601String(),
    };
  }

  factory Debt.fromMap(Map<String, dynamic> map) {
    return Debt(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      name: map['name'] as String,
      total: (map['total'] as num).toDouble(),
      remaining: (map['remaining'] as num).toDouble(),
      interestRate: (map['interest_rate'] as num).toDouble(),
      dueDate: DateTime.parse(map['due_date'] as String),
    );
  }

  Debt copyWith({
    int? id,
    int? userId,
    String? name,
    double? total,
    double? remaining,
    double? interestRate,
    DateTime? dueDate,
  }) {
    return Debt(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      total: total ?? this.total,
      remaining: remaining ?? this.remaining,
      interestRate: interestRate ?? this.interestRate,
      dueDate: dueDate ?? this.dueDate,
    );
  }

  double get paidAmount => total - remaining;
  double get percentPaid => total > 0 ? ((total - remaining) / total) * 100 : 0;
}