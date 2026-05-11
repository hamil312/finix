import '../model/weekly_budget.dart';
import '../model/category.dart';
import '../repository/weekly_budget_repository.dart';
import '../repository/transaction_repository.dart';
import '../repository/category_repository.dart';

class WeeklyBudgetController {
  final WeeklyBudgetRepository _repository = WeeklyBudgetRepository();
  final TransactionRepository _transactionRepository = TransactionRepository();
  final CategoryRepository _categoryRepository = CategoryRepository();

  // ─── Crear presupuesto semanal ────────────────────────────────────────────

  Future<int> createWeeklyBudget({
    required int userId,
    required int categoryId,
    required double allocatedAmount,
    DateTime? forDate,
  }) async {
    final date = forDate ?? DateTime.now();
    final start = WeekUtils.weekStart(date);
    final end = WeekUtils.weekEnd(date);

    final existing =
        await _repository.getByUserCategoryWeek(userId, categoryId, start);
    if (existing != null) {
      throw Exception(
          'Ya existe un presupuesto para esa categoría en esta semana');
    }

    final budget = WeeklyBudget(
      userId: userId,
      categoryId: categoryId,
      weekStart: start,
      weekEnd: end,
      allocatedAmount: allocatedAmount,
    );
    return await _repository.create(budget);
  }

  // ─── Leer ─────────────────────────────────────────────────────────────────

  /// Presupuestos de la semana actual del usuario, con gasto calculado.
  Future<List<WeeklyBudget>> getCurrentWeekBudgets(int userId) async {
    final start = WeekUtils.weekStart(DateTime.now());
    final budgets = await _repository.getByUserAndWeek(userId, start);
    return _refreshSpent(budgets, userId);
  }

  /// Presupuestos de una semana específica.
  Future<List<WeeklyBudget>> getBudgetsForWeek(
      int userId, DateTime weekStart) async {
    final budgets =
        await _repository.getByUserAndWeek(userId, weekStart);
    return _refreshSpent(budgets, userId);
  }

  /// Semanas disponibles en el historial del usuario.
  Future<List<Map<String, DateTime>>> getAvailableWeeks(int userId) =>
      _repository.getWeeksForUser(userId);

  // ─── Actualizar gasto desde transacciones ────────────────────────────────

  Future<List<WeeklyBudget>> _refreshSpent(
      List<WeeklyBudget> budgets, int userId) async {
    if (budgets.isEmpty) return budgets;

    final weekStart = budgets.first.weekStart;
    final weekEnd = budgets.first.weekEnd;

    final transactions = await _transactionRepository.getByUserIdAndDateRange(
      userId,
      weekStart,
      weekEnd.add(const Duration(hours: 23, minutes: 59)),
    );

    final updated = <WeeklyBudget>[];
    for (final b in budgets) {
      final spent = transactions
          .where((t) => t.categoryId == b.categoryId)
          .fold(0.0, (sum, t) => sum + t.amount.abs());

      if ((spent - b.spentAmount).abs() > 0.001) {
        await _repository.updateSpentAmount(b.id!, spent);
        updated.add(b.copyWith(spentAmount: spent));
      } else {
        updated.add(b);
      }
    }
    return updated;
  }

  /// Recalcula el gasto de todos los presupuestos de la semana actual.
  Future<void> refreshCurrentWeek(int userId) async {
    await getCurrentWeekBudgets(userId);
  }

  // ─── Editar ───────────────────────────────────────────────────────────────

  Future<void> updateAllocatedAmount(int budgetId, double newAmount) async {
    final budget = await _repository.getById(budgetId);
    if (budget == null) throw Exception('Presupuesto no encontrado');
    await _repository.update(budget.copyWith(allocatedAmount: newAmount));
  }

  Future<void> deleteBudget(int id) => _repository.delete(id);

  // ─── Saldo sobrante: descartar o trasladar ────────────────────────────────

  /// Descarta el saldo sobrante de la semana vencida (no lo traslada).
  Future<void> discardSurplus(int budgetId) async {
    final budget = await _repository.getById(budgetId);
    if (budget == null) throw Exception('Presupuesto no encontrado');
    if (!budget.isExpired) {
      throw Exception('Solo se puede cerrar un presupuesto de semana pasada');
    }
    if (budget.surplusAction != SurplusAction.pending) {
      throw Exception('Este presupuesto ya fue cerrado');
    }
    await _repository.updateSurplusAction(budgetId, SurplusAction.discarded);
  }

  /// Traslada el saldo sobrante a la misma categoría en la siguiente semana.
  /// Crea el presupuesto de la siguiente semana si no existe.
  Future<void> carryOverSurplus(int budgetId) async {
    final budget = await _repository.getById(budgetId);
    if (budget == null) throw Exception('Presupuesto no encontrado');
    if (!budget.isExpired) {
      throw Exception('Solo se puede cerrar un presupuesto de semana pasada');
    }
    if (budget.surplusAction != SurplusAction.pending) {
      throw Exception('Este presupuesto ya fue cerrado');
    }

    final surplus = budget.remaining;
    if (surplus <= 0) {
      // No hay nada que trasladar, solo marcar como descartado
      await _repository.updateSurplusAction(budgetId, SurplusAction.discarded);
      return;
    }

    final nextWeekStart =
        budget.weekEnd.add(const Duration(days: 1));
    final nextWeekEnd = WeekUtils.weekEnd(nextWeekStart);

    // Buscar si ya existe presupuesto para esa semana y categoría
    var next = await _repository.getByUserCategoryWeek(
        budget.userId, budget.categoryId, nextWeekStart);

    if (next != null) {
      // Ya existe: sumar el saldo al carried_over
      await _repository.update(
          next.copyWith(carriedOver: next.carriedOver + surplus));
    } else {
      // Crear presupuesto de la siguiente semana con carried_over
      final newBudget = WeeklyBudget(
        userId: budget.userId,
        categoryId: budget.categoryId,
        weekStart: nextWeekStart,
        weekEnd: nextWeekEnd,
        allocatedAmount: budget.allocatedAmount, // mismo monto base
        carriedOver: surplus,
      );
      await _repository.create(newBudget);
    }

    await _repository.updateSurplusAction(budgetId, SurplusAction.carried);
  }

  // ─── Resumen semanal ──────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getWeekSummary(
      int userId, DateTime weekStart) async {
    final budgets = await getBudgetsForWeek(userId, weekStart);

    double totalAllocated = 0;
    double totalCarried = 0;
    double totalSpent = 0;

    for (final b in budgets) {
      totalAllocated += b.allocatedAmount;
      totalCarried += b.carriedOver;
      totalSpent += b.spentAmount;
    }

    final totalAvailable = totalAllocated + totalCarried;

    return {
      'week_start': weekStart,
      'week_end': WeekUtils.weekEnd(weekStart),
      'total_allocated': totalAllocated,
      'total_carried': totalCarried,
      'total_available': totalAvailable,
      'total_spent': totalSpent,
      'total_remaining': totalAvailable - totalSpent,
      'percent_used':
          totalAvailable > 0 ? (totalSpent / totalAvailable * 100) : 0.0,
      'budgets': budgets,
      'over_budget': budgets.where((b) => b.remaining < 0).toList(),
      'pending_surplus':
          budgets.where((b) => b.isExpired && b.surplusAction == SurplusAction.pending).toList(),
    };
  }

  // ─── Categorías disponibles para presupuestar ─────────────────────────────

  Future<List<Category>> getAvailableCategories(int userId) =>
      _categoryRepository.getByTypeForUser('expense', userId);
}