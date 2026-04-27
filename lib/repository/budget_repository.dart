// filepath: lib\repository\budget_repository.dart
import '../model/budget.dart';
import '../utils/database_connection.dart';

class BudgetRepository {
  final DatabaseConnection _db = DatabaseConnection.instance;

  Future<int> create(Budget budget) async {
    const sql = '''
      INSERT INTO budgets (user_id, month, year, allocated_amount, category_id, spent_amount)
      VALUES (@user_id, @month, @year, @allocated_amount, @category_id, @spent_amount)
      RETURNING id
    ''';
    final result = await _db.query(sql, [
      budget.userId,
      budget.month,
      budget.year,
      budget.allocatedAmount,
      budget.categoryId,
      budget.spentAmount,
    ]);
    return result.first['id'] as int;
  }

  Future<Budget?> getById(int id) async {
    const sql = 'SELECT * FROM budgets WHERE id = @id';
    final result = await _db.queryOne(sql, [id]);
    return result != null ? Budget.fromMap(result) : null;
  }

  Future<List<Budget>> getByUserId(int userId) async {
    const sql = 'SELECT * FROM budgets WHERE user_id = @user_id ORDER BY year DESC, month DESC';
    final results = await _db.query(sql, [userId]);
    return results.map((map) => Budget.fromMap(map)).toList();
  }

  Future<List<Budget>> getByUserMonthYear(int userId, int month, int year) async {
    const sql = '''
      SELECT * FROM budgets 
      WHERE user_id = @user_id AND month = @month AND year = @year
    ''';
    final results = await _db.query(sql, [userId, month, year]);
    return results.map((map) => Budget.fromMap(map)).toList();
  }

  Future<Budget?> getByUserCategoryMonthYear(
    int userId,
    int categoryId,
    int month,
    int year,
  ) async {
    const sql = '''
      SELECT * FROM budgets 
      WHERE user_id = @user_id AND category_id = @category_id 
        AND month = @month AND year = @year
    ''';
    final result = await _db.queryOne(sql, [userId, categoryId, month, year]);
    return result != null ? Budget.fromMap(result) : null;
  }

  Future<int> update(Budget budget) async {
    const sql = '''
      UPDATE budgets 
      SET user_id = @user_id, month = @month, year = @year, 
          allocated_amount = @allocated_amount, category_id = @category_id,
          spent_amount = @spent_amount, updated_at = CURRENT_TIMESTAMP
      WHERE id = @id
    ''';
    return await _db.execute(sql, [
      budget.userId,
      budget.month,
      budget.year,
      budget.allocatedAmount,
      budget.categoryId,
      budget.spentAmount,
      budget.id,
    ]);
  }

  Future<int> updateSpentAmount(int id, double spentAmount) async {
    const sql = '''
      UPDATE budgets 
      SET spent_amount = @spent_amount, updated_at = CURRENT_TIMESTAMP
      WHERE id = @id
    ''';
    return await _db.execute(sql, [spentAmount, id]);
  }

  Future<int> delete(int id) async {
    const sql = 'DELETE FROM budgets WHERE id = @id';
    return await _db.execute(sql, [id]);
  }
}