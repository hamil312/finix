// filepath: lib\controller\budget_controller.dart
import '../model/budget.dart';
import '../repository/budget_repository.dart';
import '../repository/transaction_repository.dart';

class BudgetController {
  final BudgetRepository _repository = BudgetRepository();
  final TransactionRepository _transactionRepository = TransactionRepository();

  Future<int> createBudget({
    required int userId,
    required int month,
    required int year,
    required double allocatedAmount,
    required int categoryId,
  }) async {
    // Verificar si ya existe un presupuesto para esa categoría en el mes
    final existing = await _repository.getByUserCategoryMonthYear(
      userId, categoryId, month, year,
    );
    
    if (existing != null) {
      throw Exception('Ya existe un presupuesto para esta categoría en el mes');
    }

    final budget = Budget(
      userId: userId,
      month: month,
      year: year,
      allocatedAmount: allocatedAmount,
      categoryId: categoryId,
      spentAmount: 0,
    );

    return await _repository.create(budget);
  }

  Future<Budget?> getBudgetById(int id) async {
    return await _repository.getById(id);
  }

  Future<List<Budget>> getUserBudgets(int userId) async {
    return await _repository.getByUserId(userId);
  }

  Future<List<Budget>> getUserBudgetsByMonthYear(int userId, int month, int year) async {
    return await _repository.getByUserMonthYear(userId, month, year);
  }

  Future<void> updateBudget(Budget budget) async {
    await _repository.update(budget);
  }

  Future<void> deleteBudget(int id) async {
    await _repository.delete(id);
  }

  /// Actualiza el monto gastado de un presupuesto basándose en las transacciones
  Future<void> refreshBudgetSpentAmount(int budgetId) async {
    final budget = await _repository.getById(budgetId);
    if (budget == null) return;

    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    final transactions = await _transactionRepository.getByUserIdAndDateRange(
      budget.userId,
      startOfMonth,
      endOfMonth,
    );

    // Filtrar por categoría
    final categoryTransactions = transactions
        .where((t) => t.categoryId == budget.categoryId)
        .toList();

    final totalSpent = categoryTransactions.fold<double>(
      0, (sum, t) => sum + t.amount,
    );

    await _repository.updateSpentAmount(budgetId, totalSpent);
  }

  /// Crea presupuestos automáticos basándose en el ingreso mensual
  Future<void> createDefaultBudgets(int userId, double monthlyIncome, List<Map<String, dynamic>> categoryAllocations) async {
    final now = DateTime.now();
    
    for (var allocation in categoryAllocations) {
      final allocatedAmount = monthlyIncome * (allocation['percent'] / 100);
      
      await createBudget(
        userId: userId,
        month: now.month,
        year: now.year,
        allocatedAmount: allocatedAmount,
        categoryId: allocation['category_id'],
      );
    }
  }

  Future<Map<String, dynamic>> getBudgetSummary(int userId, int month, int year) async {
    final budgets = await getUserBudgetsByMonthYear(userId, month, year);
    
    double totalAllocated = 0;
    double totalSpent = 0;
    
    for (var budget in budgets) {
      totalAllocated += budget.allocatedAmount;
      totalSpent += budget.spentAmount;
    }

    return {
      'total_allocated': totalAllocated,
      'total_spent': totalSpent,
      'remaining': totalAllocated - totalSpent,
      'percent_used': totalAllocated > 0 ? (totalSpent / totalAllocated) * 100 : 0,
      'budgets': budgets,
    };
  }
}