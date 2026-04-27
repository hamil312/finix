// filepath: lib\repository\debt_repository.dart
import '../model/debt.dart';
import '../utils/database_connection.dart';

class DebtRepository {
  final DatabaseConnection _db = DatabaseConnection.instance;

  Future<int> create(Debt debt) async {
    const sql = '''
      INSERT INTO debts (user_id, name, total, remaining, interest_rate, due_date)
      VALUES (@user_id, @name, @total, @remaining, @interest_rate, @due_date)
      RETURNING id
    ''';
    final result = await _db.query(sql, [
      debt.userId,
      debt.name,
      debt.total,
      debt.remaining,
      debt.interestRate,
      debt.dueDate,
    ]);
    return result.first['id'] as int;
  }

  Future<Debt?> getById(int id) async {
    const sql = 'SELECT * FROM debts WHERE id = @id';
    final result = await _db.queryOne(sql, [id]);
    return result != null ? Debt.fromMap(result) : null;
  }

  Future<List<Debt>> getByUserId(int userId) async {
    const sql = 'SELECT * FROM debts WHERE user_id = @user_id ORDER BY due_date';
    final results = await _db.query(sql, [userId]);
    return results.map((map) => Debt.fromMap(map)).toList();
  }

  Future<List<Debt>> getActiveByUserId(int userId) async {
    const sql = '''
      SELECT * FROM debts 
      WHERE user_id = @user_id AND remaining > 0
      ORDER BY due_date
    ''';
    final results = await _db.query(sql, [userId]);
    return results.map((map) => Debt.fromMap(map)).toList();
  }

  Future<double> getTotalDebtByUserId(int userId) async {
    const sql = 'SELECT COALESCE(SUM(remaining), 0) as total FROM debts WHERE user_id = @user_id';
    final result = await _db.queryOne(sql, [userId]);
    return (result?['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<int> update(Debt debt) async {
    const sql = '''
      UPDATE debts 
      SET user_id = @user_id, name = @name, total = @total, 
          remaining = @remaining, interest_rate = @interest_rate, 
          due_date = @due_date, updated_at = CURRENT_TIMESTAMP
      WHERE id = @id
    ''';
    return await _db.execute(sql, [
      debt.userId,
      debt.name,
      debt.total,
      debt.remaining,
      debt.interestRate,
      debt.dueDate,
      debt.id,
    ]);
  }

  Future<int> updateRemaining(int id, double remaining) async {
    const sql = '''
      UPDATE debts 
      SET remaining = @remaining, updated_at = CURRENT_TIMESTAMP
      WHERE id = @id
    ''';
    return await _db.execute(sql, [remaining, id]);
  }

  Future<int> delete(int id) async {
    const sql = 'DELETE FROM debts WHERE id = @id';
    return await _db.execute(sql, [id]);
  }
}