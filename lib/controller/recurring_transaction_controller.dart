import '../model/recurring_transaction.dart';
import '../repository/recurring_transaction_repository.dart';

class RecurringTransactionController {
  final RecurringTransactionRepository _repository = RecurringTransactionRepository();

  DateTime _calculateNextDueDate(DateTime current, RecurringFrequency frequency) {
    switch (frequency) {
      case RecurringFrequency.daily:
        return current.add(const Duration(days: 1));
      case RecurringFrequency.weekly:
        return current.add(const Duration(days: 7));
      case RecurringFrequency.biweekly:
        return current.add(const Duration(days: 14));
      case RecurringFrequency.monthly:
        return DateTime(current.year, current.month + 1, current.day);
      case RecurringFrequency.yearly:
        return DateTime(current.year + 1, current.month, current.day);
    }
  }

  Future<int> createRecurringTransaction({
    required int userId,
    required double amount,
    required String description,
    required int categoryId,
    required RecurringFrequency frequency,
    required DateTime startDate,
    DateTime? endDate,
  }) async {
    final nextDueDate = _calculateNextDueDate(startDate, frequency);
    final recurring = RecurringTransaction(
      userId: userId,
      amount: amount,
      date: startDate,
      description: description,
      categoryId: categoryId,
      frequency: frequency,
      startDate: startDate,
      endDate: endDate,
      nextDueDate: nextDueDate,
    );

    return await _repository.create(recurring);
  }

  Future<RecurringTransaction?> getRecurringTransactionById(int id) async {
    return await _repository.getById(id);
  }

  Future<List<RecurringTransaction>> getUserRecurringTransactions(int userId) async {
    return await _repository.getByUserId(userId);
  }

  Future<List<RecurringTransaction>> getActiveUserRecurringTransactions(int userId) async {
    return await _repository.getActiveByUserId(userId);
  }

  Future<void> updateRecurringTransaction(RecurringTransaction transaction) async {
    await _repository.update(transaction);
  }

  Future<void> deleteRecurringTransaction(int id) async {
    await _repository.delete(id);
  }

  Future<void> deactivateRecurringTransaction(int id) async {
    await _repository.deactivate(id);
  }

  Future<void> activateRecurringTransaction(int id) async {
    // Para activar, necesitamos obtener el recurring y actualizar isActive
    final recurring = await _repository.getById(id);
    if (recurring != null) {
      final updated = recurring.copyWith(isActive: true);
      await _repository.update(updated);
    }
  }
}