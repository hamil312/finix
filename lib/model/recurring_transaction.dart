// filepath: lib\model\recurring_transaction.dart
import 'transaction.dart';
import '../utils/type_converter.dart';

enum RecurringFrequency { daily, weekly, biweekly, monthly, yearly }

class RecurringTransaction extends Transaction {
  final RecurringFrequency frequency;
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime nextDueDate;
  final bool isActive;

  RecurringTransaction({
    super.id,
    required super.userId,
    required super.amount,
    required super.date,
    required super.description,
    required super.categoryId,
    required this.frequency,
    required this.startDate,
    this.endDate,
    required this.nextDueDate,
    this.isActive = true,
  });

  @override
  Map<String, dynamic> toMap() {
    return {
      ...super.toMap(),
      'frequency': frequency.name,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'next_due_date': nextDueDate.toIso8601String(),
      'is_active': isActive,
    };
  }

  factory RecurringTransaction.fromMap(Map<String, dynamic> map) {
    return RecurringTransaction(
      id: TypeConverter.toIntOrNull(map['id']),
      userId: TypeConverter.toInt(map['user_id']),
      amount: TypeConverter.toDouble(map['amount']),
      date: DateTime.parse((map['date'] ?? DateTime.now().toIso8601String()).toString()),
      description: TypeConverter.toStringi(map['description']),
      categoryId: TypeConverter.toInt(map['category_id']),
      frequency: RecurringFrequency.values.firstWhere(
        (e) => e.name == map['frequency'],
      ),
      startDate: DateTime.parse((map['start_date'] ?? DateTime.now().toIso8601String()).toString()),
      endDate: map['end_date'] != null 
          ? DateTime.parse(map['end_date'].toString()) 
          : null,
      nextDueDate: DateTime.parse((map['next_due_date'] ?? DateTime.now().toIso8601String()).toString()),
      isActive: map['is_active'] as bool? ?? true,
    );
  }

  @override
  RecurringTransaction copyWith({
    int? id,
    int? userId,
    double? amount,
    DateTime? date,
    String? description,
    int? categoryId,
    RecurringFrequency? frequency,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? nextDueDate,
    bool? isActive,
  }) {
    return RecurringTransaction(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      frequency: frequency ?? this.frequency,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      isActive: isActive ?? this.isActive,
    );
  }
}