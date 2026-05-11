import '../model/weekly_budget.dart';
import '../utils/database_connection.dart';

class WeeklyBudgetRepository {
  final DatabaseConnection _db = DatabaseConnection.instance;

  // ─── Crear ────────────────────────────────────────────────────────────────

  Future<int> create(WeeklyBudget budget) async {
    const sql = '''
      INSERT INTO weekly_budgets
        (user_id, category_id, week_start, week_end,
         allocated_amount, spent_amount, carried_over, surplus_action)
      VALUES (@user_id, @category_id, @week_start, @week_end,
              @allocated_amount, @spent_amount, @carried_over, @surplus_action)
      RETURNING id
    ''';
    final result = await _db.query(sql, [
      budget.userId,
      budget.categoryId,
      budget.weekStart.toIso8601String().split('T').first,
      budget.weekEnd.toIso8601String().split('T').first,
      budget.allocatedAmount,
      budget.spentAmount,
      budget.carriedOver,
      budget.surplusAction.name,
    ]);
    return result.first['id'] as int;
  }

  // ─── Leer ─────────────────────────────────────────────────────────────────

  Future<WeeklyBudget?> getById(int id) async {
    const sql = '''
      SELECT wb.*, c.name AS category_name, c.icon AS category_icon,
             c.color_hex AS category_color
      FROM weekly_budgets wb
      JOIN categories c ON c.id = wb.category_id
      WHERE wb.id = @id
    ''';
    final result = await _db.queryOne(sql, [id]);
    return result != null ? WeeklyBudget.fromMap(result) : null;
  }

  /// Presupuestos de la semana que contiene [weekStart] para el usuario
  Future<List<WeeklyBudget>> getByUserAndWeek(
      int userId, DateTime weekStart) async {
    const sql = '''
      SELECT wb.*, c.name AS category_name, c.icon AS category_icon,
             c.color_hex AS category_color
      FROM weekly_budgets wb
      JOIN categories c ON c.id = wb.category_id
      WHERE wb.user_id = @user_id AND wb.week_start = @week_start
      ORDER BY c.name
    ''';
    final results = await _db.query(sql, [
      userId,
      weekStart.toIso8601String().split('T').first,
    ]);
    return results.map((m) => WeeklyBudget.fromMap(m)).toList();
  }

  /// Presupuesto de una categoría específica en una semana
  Future<WeeklyBudget?> getByUserCategoryWeek(
      int userId, int categoryId, DateTime weekStart) async {
    const sql = '''
      SELECT wb.*, c.name AS category_name, c.icon AS category_icon,
             c.color_hex AS category_color
      FROM weekly_budgets wb
      JOIN categories c ON c.id = wb.category_id
      WHERE wb.user_id = @user_id
        AND wb.category_id = @category_id
        AND wb.week_start = @week_start
    ''';
    final result = await _db.queryOne(sql, [
      userId,
      categoryId,
      weekStart.toIso8601String().split('T').first,
    ]);
    return result != null ? WeeklyBudget.fromMap(result) : null;
  }

  /// Semanas distintas con presupuesto del usuario (para el historial)
  Future<List<Map<String, DateTime>>> getWeeksForUser(int userId) async {
    const sql = '''
      SELECT DISTINCT week_start, week_end
      FROM weekly_budgets
      WHERE user_id = @user_id
      ORDER BY week_start DESC
    ''';
    final results = await _db.query(sql, [userId]);
    return results
        .map((r) => {
              'week_start': DateTime.parse(r['week_start'].toString()),
              'week_end': DateTime.parse(r['week_end'].toString()),
            })
        .toList();
  }

  // ─── Actualizar ───────────────────────────────────────────────────────────

  Future<int> update(WeeklyBudget budget) async {
    const sql = '''
      UPDATE weekly_budgets
      SET allocated_amount = @allocated_amount,
          spent_amount     = @spent_amount,
          carried_over     = @carried_over,
          surplus_action   = @surplus_action,
          updated_at       = NOW()
      WHERE id = @id
    ''';
    return await _db.execute(sql, [
      budget.allocatedAmount,
      budget.spentAmount,
      budget.carriedOver,
      budget.surplusAction.name,
      budget.id,
    ]);
  }

  Future<int> updateSpentAmount(int id, double spent) async {
    const sql = '''
      UPDATE weekly_budgets
      SET spent_amount = @spent, updated_at = NOW()
      WHERE id = @id
    ''';
    return await _db.execute(sql, [spent, id]);
  }

  Future<int> updateSurplusAction(int id, SurplusAction action) async {
    const sql = '''
      UPDATE weekly_budgets
      SET surplus_action = @action, updated_at = NOW()
      WHERE id = @id
    ''';
    return await _db.execute(sql, [action.name, id]);
  }

  // ─── Eliminar ─────────────────────────────────────────────────────────────

  Future<int> delete(int id) async {
    const sql = 'DELETE FROM weekly_budgets WHERE id = @id';
    return await _db.execute(sql, [id]);
  }
}