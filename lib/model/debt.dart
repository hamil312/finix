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
      // ANTES: (map['total'] as num).toDouble()
      // DESPUÉS: parseo seguro desde String o num
      total: _toDouble(map['total']),
      remaining: _toDouble(map['remaining']),
      interestRate: _toDouble(map['interest_rate']),
      dueDate: DateTime.parse(map['due_date'].toString()),
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

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  double get paidAmount => total - remaining;
  double get percentPaid => total > 0 ? ((total - remaining) / total) * 100 : 0;
}