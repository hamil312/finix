// filepath: lib\controller\transaction_controller.dart
import '../model/transaction.dart';
import '../repository/transaction_repository.dart';
import '../repository/budget_repository.dart';
import '../repository/sync_repository.dart';
import '../utils/database_connection.dart';

class TransactionController {
  final TransactionRepository _repository = TransactionRepository();
  final BudgetRepository _budgetRepository = BudgetRepository();
  final SyncRepository _syncRepository = SyncRepository();

  Future<int> createTransaction({
    required int userId,
    required double amount,
    required String description,
    required int categoryId,
    DateTime? date,
    bool saveOffline = false,
  }) async {
    final transaction = Transaction(
      userId: userId,
      amount: amount,
      date: date ?? DateTime.now(),
      description: description,
      categoryId: categoryId,
    );

    // Intentar guardar en la base de datos
    if (DatabaseConnection.instance.isConnected && !saveOffline) {
      final id = await _repository.create(transaction);
      
      // Actualizar el presupuesto si aplica
      await _updateBudgetSpent(userId, categoryId, amount);
      
      return id;
    } else {
      // Guardar offline
      await _syncRepository.saveLocalTransaction(transaction);
      return -1; // ID temporal para offline
    }
  }

  Future<void> _updateBudgetSpent(int userId, int categoryId, double amount) async {
    final now = DateTime.now();
    final budget = await _budgetRepository.getByUserCategoryMonthYear(
      userId,
      categoryId,
      now.month,
      now.year,
    );

    if (budget != null) {
      await _budgetRepository.updateSpentAmount(
        budget.id!,
        budget.spentAmount + amount,
      );
    }
  }

  Future<Transaction?> getTransactionById(int id) async {
    return await _repository.getById(id);
  }

  Future<List<Transaction>> getUserTransactions(int userId) async {
    return await _repository.getByUserId(userId);
  }

  Future<List<Transaction>> getUserTransactionsByDateRange(
    int userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    return await _repository.getByUserIdAndDateRange(userId, startDate, endDate);
  }

  Future<List<Transaction>> getCategoryTransactions(int categoryId) async {
    return await _repository.getByCategoryId(categoryId);
  }

  Future<void> updateTransaction(Transaction transaction) async {
    await _repository.update(transaction);
  }

  Future<void> deleteTransaction(int id) async {
    await _repository.delete(id);
  }

  Future<double> getTotalExpensesByUser(int userId) async {
    return await _repository.getTotalByUserId(userId);
  }

  Future<Map<String, double>> getExpensesByCategory(int userId) async {
    final transactions = await _repository.getByUserId(userId);
    final Map<String, double> expensesByCategory = {};

    for (var transaction in transactions) {
      final categoryKey = 'category_${transaction.categoryId}';
      expensesByCategory[categoryKey] = 
          (expensesByCategory[categoryKey] ?? 0) + transaction.amount;
    }

    return expensesByCategory;
  }
}