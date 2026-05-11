import '../model/debt_payment.dart';
import '../utils/database_connection.dart';

class DebtPaymentRepository {
  final DatabaseConnection _db = DatabaseConnection.instance;

  /// Crea la tabla en PostgreSQL si no existe
  static const String createTableSQL = '''
    CREATE TABLE IF NOT EXISTS debt_payments (
      id           SERIAL PRIMARY KEY,
      debt_id      INT NOT NULL REFERENCES debts(id) ON DELETE CASCADE,
      amount       NUMERIC(12,2) NOT NULL,
      payment_date TIMESTAMP NOT NULL DEFAULT NOW(),
      note         VARCHAR(255),
      is_full_payment BOOLEAN DEFAULT FALSE,
      created_at   TIMESTAMP DEFAULT NOW()
    );
  ''';

  Future<int> create(DebtPayment payment) async {
    const sql = '''
      INSERT INTO debt_payments (debt_id, amount, payment_date, note, is_full_payment)
      VALUES (@debt_id, @amount, @payment_date, @note, @is_full_payment)
      RETURNING id
    ''';
    final result = await _db.query(sql, [
      payment.debtId,
      payment.amount,
      payment.paymentDate,
      payment.note,
      payment.isFullPayment,
    ]);
    return result.first['id'] as int;
  }

  Future<List<DebtPayment>> getByDebtId(int debtId) async {
    const sql = '''
      SELECT * FROM debt_payments
      WHERE debt_id = @debt_id
      ORDER BY payment_date DESC
    ''';
    final results = await _db.query(sql, [debtId]);
    return results.map((m) => DebtPayment.fromMap(m)).toList();
  }

  Future<double> getTotalPaidByDebtId(int debtId) async {
    const sql = '''
      SELECT COALESCE(SUM(amount), 0) as total
      FROM debt_payments
      WHERE debt_id = @debt_id
    ''';
    final result = await _db.queryOne(sql, [debtId]);
    return (result?['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<int> delete(int id) async {
    const sql = 'DELETE FROM debt_payments WHERE id = @id';
    return await _db.execute(sql, [id]);
  }
}