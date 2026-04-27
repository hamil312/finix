// filepath: lib\repository\transaction_repository.dart
import '../model/transaction.dart';
import '../utils/database_connection.dart';

class TransactionRepository {
  final DatabaseConnection _db = DatabaseConnection.instance;

  Future<int> create(Transaction transaction) async {
    const sql = '''
      INSERT INTO transactions (user_id, amount, date, description, category_id)
      VALUES (@user_id, @amount, @date, @description, @category_id)
      RETURNING id
    ''';
    final result = await _db.query(sql, [
      transaction.userId,
      transaction.amount,
      transaction.date,
      transaction.description,
      transaction.categoryId,
    ]);
    return result.first['id'] as int;
  }

  Future<Transaction?> getById(int id) async {
    const sql = 'SELECT * FROM transactions WHERE id = @id';
    final result = await _db.queryOne(sql, [id]);
    return result != null ? Transaction.fromMap(result) : null;
  }

  Future<List<Transaction>> getByUserId(int userId) async {
    const sql = 'SELECT * FROM transactions WHERE user_id = @user_id ORDER BY date DESC';
    final results = await _db.query(sql, [userId]);
    return results.map((map) => Transaction.fromMap(map)).toList();
  }

  Future<List<Transaction>> getByUserIdAndDateRange(
    int userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    const sql = '''
      SELECT * FROM transactions 
      WHERE user_id = @user_id AND date BETWEEN @start_date AND @end_date
      ORDER BY date DESC
    ''';
    final results = await _db.query(sql, [userId, startDate, endDate]);
    return results.map((map) => Transaction.fromMap(map)).toList();
  }

  Future<List<Transaction>> getByCategoryId(int categoryId) async {
    const sql = 'SELECT * FROM transactions WHERE category_id = @category_id ORDER BY date DESC';
    final results = await _db.query(sql, [categoryId]);
    return results.map((map) => Transaction.fromMap(map)).toList();
  }

  Future<int> update(Transaction transaction) async {
    const sql = '''
      UPDATE transactions 
      SET user_id = @user_id, amount = @amount, date = @date, 
          description = @description, category_id = @category_id,
          updated_at = CURRENT_TIMESTAMP
      WHERE id = @id
    ''';
    return await _db.execute(sql, [
      transaction.userId,
      transaction.amount,
      transaction.date,
      transaction.description,
      transaction.categoryId,
      transaction.id,
    ]);
  }

  Future<int> delete(int id) async {
    const sql = 'DELETE FROM transactions WHERE id = @id';
    return await _db.execute(sql, [id]);
  }

  Future<double> getTotalByUserId(int userId) async {
    const sql = 'SELECT COALESCE(SUM(amount), 0) as total FROM transactions WHERE user_id = @user_id';
    final result = await _db.queryOne(sql, [userId]);
    return (result?['total'] as num?)?.toDouble() ?? 0.0;
  }
}