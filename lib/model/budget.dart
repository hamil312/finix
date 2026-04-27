// filepath: lib\model\budget.dart
class Budget {
  final int? id;
  final int userId;
  final int month;
  final int year;
  final double allocatedAmount;
  final int categoryId;
  final double spentAmount;

  Budget({
    this.id,
    required this.userId,
    required this.month,
    required this.year,
    required this.allocatedAmount,
    required this.categoryId,
    required this.spentAmount,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'month': month,
      'year': year,
      'allocated_amount': allocatedAmount,
      'category_id': categoryId,
      'spent_amount': spentAmount,
    };
  }

  factory Budget.fromMap(Map<String, dynamic> map) {
    return Budget(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      month: map['month'] as int,
      year: map['year'] as int,
      allocatedAmount: (map['allocated_amount'] as num).toDouble(),
      categoryId: map['category_id'] as int,
      spentAmount: (map['spent_amount'] as num).toDouble(),
    );
  }

  Budget copyWith({
    int? id,
    int? userId,
    int? month,
    int? year,
    double? allocatedAmount,
    int? categoryId,
    double? spentAmount,
  }) {
    return Budget(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      month: month ?? this.month,
      year: year ?? this.year,
      allocatedAmount: allocatedAmount ?? this.allocatedAmount,
      categoryId: categoryId ?? this.categoryId,
      spentAmount: spentAmount ?? this.spentAmount,
    );
  }

  double get remainingAmount => allocatedAmount - spentAmount;
  double get percentUsed => allocatedAmount > 0 ? (spentAmount / allocatedAmount) * 100 : 0;
}