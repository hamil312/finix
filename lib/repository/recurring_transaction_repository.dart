// filepath: lib\repository\recurring_transaction_repository.dart
import '../model/recurring_transaction.dart';
import '../utils/database_connection.dart';

class RecurringTransactionRepository {
  final DatabaseConnection _db = DatabaseConnection.instance;

  Future<int> create(RecurringTransaction transaction) async {
    const sql = '''
      INSERT INTO recurring_transactions 
        (user_id, amount, description, category_id, frequency, start_date, end_date, next_due_date)
      VALUES (@user_id, @amount, @description, @category_id, @frequency, @start_date, @end_date, @next_due_date)
      RETURNING id
    ''';
    final result = await _db.query(sql, [
      transaction.userId,
      transaction.amount,
      transaction.description,
      transaction.categoryId,
      transaction.frequency.name,
      transaction.startDate,
      transaction.endDate,
      transaction.nextDueDate,
    ]);
    return result.first['id'] as int;
  }

  Future<RecurringTransaction?> getById(int id) async {
    const sql = 'SELECT * FROM recurring_transactions WHERE id = @id';
    final result = await _db.queryOne(sql, [id]);
    return result != null ? RecurringTransaction.fromMap(result) : null;
  }

  Future<List<RecurringTransaction>> getByUserId(int userId) async {
    const sql = 'SELECT * FROM recurring_transactions WHERE user_id = @user_id ORDER BY next_due_date';
    final results = await _db.query(sql, [userId]);
    return results.map((map) => RecurringTransaction.fromMap(map)).toList();
  }

  Future<List<RecurringTransaction>> getActiveByUserId(int userId) async {
    const sql = '''
      SELECT * FROM recurring_transactions 
      WHERE user_id = @user_id AND is_active = true 
      ORDER BY next_due_date
    ''';
    final results = await _db.query(sql, [userId]);
    return results.map((map) => RecurringTransaction.fromMap(map)).toList();
  }

  Future<List<RecurringTransaction>> getDueTransactions() async {
    const sql = '''
      SELECT * FROM recurring_transactions 
      WHERE is_active = true AND next_due_date <= CURRENT_DATE
    ''';
    final results = await _db.query(sql);
    return results.map((map) => RecurringTransaction.fromMap(map)).toList();
  }

  Future<int> update(RecurringTransaction transaction) async {
    const sql = '''
      UPDATE recurring_transactions 
      SET user_id = @user_id, amount = @amount, description = @description, 
          category_id = @category_id, frequency = @frequency, start_date = @start_date,
          end_date = @end_date, next_due_date = @next_due_date, is_active = @is_active,
          updated_at = CURRENT_TIMESTAMP
      WHERE id = @id
    ''';
    return await _db.execute(sql, [
      transaction.userId,
      transaction.amount,
      transaction.description,
      transaction.categoryId,
      transaction.frequency.name,
      transaction.startDate,
      transaction.endDate,
      transaction.nextDueDate,
      transaction.isActive,
      transaction.id,
    ]);
  }

  Future<int> delete(int id) async {
    const sql = 'DELETE FROM recurring_transactions WHERE id = @id';
    return await _db.execute(sql, [id]);
  }

  Future<int> deactivate(int id) async {
    const sql = '''
      UPDATE recurring_transactions 
      SET is_active = false, updated_at = CURRENT_TIMESTAMP
      WHERE id = @id
    ''';
    return await _db.execute(sql, [id]);
  }
}