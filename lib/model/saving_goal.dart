// filepath: lib\model\saving_goal.dart
import '../utils/type_converter.dart';

class SavingGoal {
  final int? id;
  final int userId;
  final String name;
  final double targetAmount;
  final double currentAmount;
  final DateTime deadline;

  SavingGoal({
    this.id,
    required this.userId,
    required this.name,
    required this.targetAmount,
    required this.currentAmount,
    required this.deadline,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'target_amount': targetAmount,
      'current_amount': currentAmount,
      'deadline': deadline.toIso8601String(),
    };
  }

  factory SavingGoal.fromMap(Map<String, dynamic> map) {
    return SavingGoal(
      id: TypeConverter.toIntOrNull(map['id']),
      userId: TypeConverter.toInt(map['user_id']),
      name: TypeConverter.toStringi(map['name']),
      targetAmount: TypeConverter.toDouble(map['target_amount']),
      currentAmount: TypeConverter.toDouble(map['current_amount']),
      deadline: TypeConverter.toDateTime(map['deadline']),
    );
  }

  SavingGoal copyWith({
    int? id,
    int? userId,
    String? name,
    double? targetAmount,
    double? currentAmount,
    DateTime? deadline,
  }) {
    return SavingGoal(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      deadline: deadline ?? this.deadline,
    );
  }
}