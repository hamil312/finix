// filepath: lib\model\recurring_transaction.dart
import 'transaction.dart';

enum RecurringFrequency { daily, weekly, biweekly, monthly, yearly }

class RecurringTransaction extends Transaction {
  final RecurringFrequency frequency;
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime nextDueDate;

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
  });

  @override
  Map<String, dynamic> toMap() {
    return {
      ...super.toMap(),
      'frequency': frequency.name,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'next_due_date': nextDueDate.toIso8601String(),
    };
  }

  factory RecurringTransaction.fromMap(Map<String, dynamic> map) {
    return RecurringTransaction(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      amount: (map['amount'] as num).toDouble(),
      date: DateTime.parse(map['date'] as String),
      description: map['description'] as String,
      categoryId: map['category_id'] as int,
      frequency: RecurringFrequency.values.firstWhere(
        (e) => e.name == map['frequency'],
      ),
      startDate: DateTime.parse(map['start_date'] as String),
      endDate: map['end_date'] != null 
          ? DateTime.parse(map['end_date'] as String) 
          : null,
      nextDueDate: DateTime.parse(map['next_due_date'] as String),
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
    );
  }
}