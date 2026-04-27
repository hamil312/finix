// filepath: lib\repository\saving_goal_repository.dart
import '../model/saving_goal.dart';
import '../utils/database_connection.dart';

class SavingGoalRepository {
  final DatabaseConnection _db = DatabaseConnection.instance;

  Future<int> create(SavingGoal savingGoal) async {
    const sql = '''
      INSERT INTO saving_goals (user_id, name, target_amount, current_amount, deadline)
      VALUES (@user_id, @name, @target_amount, @current_amount, @deadline)
      RETURNING id
    ''';
    final result = await _db.query(sql, [
      savingGoal.userId,
      savingGoal.name,
      savingGoal.targetAmount,
      savingGoal.currentAmount,
      savingGoal.deadline,
    ]);
    return result.first['id'] as int;
  }

  Future<SavingGoal?> getById(int id) async {
    const sql = 'SELECT * FROM saving_goals WHERE id = @id';
    final result = await _db.queryOne(sql, [id]);
    return result != null ? SavingGoal.fromMap(result) : null;
  }

  Future<List<SavingGoal>> getByUserId(int userId) async {
    const sql = 'SELECT * FROM saving_goals WHERE user_id = @user_id ORDER BY deadline';
    final results = await _db.query(sql, [userId]);
    return results.map((map) => SavingGoal.fromMap(map)).toList();
  }

  Future<List<SavingGoal>> getActiveByUserId(int userId) async {
    const sql = '''
      SELECT * FROM saving_goals 
      WHERE user_id = @user_id AND current_amount < target_amount
      ORDER BY deadline
    ''';
    final results = await _db.query(sql, [userId]);
    return results.map((map) => SavingGoal.fromMap(map)).toList();
  }

  Future<double> getTotalSavedByUserId(int userId) async {
    const sql = 'SELECT COALESCE(SUM(current_amount), 0) as total FROM saving_goals WHERE user_id = @user_id';
    final result = await _db.queryOne(sql, [userId]);
    return (result?['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<int> update(SavingGoal savingGoal) async {
    const sql = '''
      UPDATE saving_goals 
      SET user_id = @user_id, name = @name, target_amount = @target_amount, 
          current_amount = @current_amount, deadline = @deadline,
          updated_at = CURRENT_TIMESTAMP
      WHERE id = @id
    ''';
    return await _db.execute(sql, [
      savingGoal.userId,
      savingGoal.name,
      savingGoal.targetAmount,
      savingGoal.currentAmount,
      savingGoal.deadline,
      savingGoal.id,
    ]);
  }

  Future<int> addContribution(int id, double amount) async {
    const sql = '''
      UPDATE saving_goals 
      SET current_amount = current_amount + @amount, updated_at = CURRENT_TIMESTAMP
      WHERE id = @id
    ''';
    return await _db.execute(sql, [amount, id]);
  }

  Future<int> delete(int id) async {
    const sql = 'DELETE FROM saving_goals WHERE id = @id';
    return await _db.execute(sql, [id]);
  }
}