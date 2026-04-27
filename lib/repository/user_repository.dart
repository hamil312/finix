// filepath: lib\repository\user_repository.dart
import '../model/user.dart';
import '../utils/database_connection.dart';

class UserRepository {
  final DatabaseConnection _db = DatabaseConnection.instance;

  Future<int> create(User user) async {
    const sql = '''
      INSERT INTO users (name, email, currency, monthly_income, password)
      VALUES (@name, @email, @currency, @monthly_income, @password)
      RETURNING id
    ''';
    final result = await _db.query(sql, [
      user.name,
      user.email,
      user.currency,
      user.monthlyIncome,
      user.password,
    ]);
    return result.first['id'] as int;
  }

  Future<User?> getById(int id) async {
    const sql = 'SELECT * FROM users WHERE id = @id';
    final result = await _db.queryOne(sql, [id]);
    return result != null ? User.fromMap(result) : null;
  }

  Future<User?> getByEmail(String email) async {
    const sql = 'SELECT * FROM users WHERE email = @email';
    final result = await _db.queryOne(sql, [email]);
    return result != null ? User.fromMap(result) : null;
  }

  Future<List<User>> getAll() async {
    const sql = 'SELECT * FROM users ORDER BY name';
    final results = await _db.query(sql);
    return results.map((map) => User.fromMap(map)).toList();
  }

  Future<int> update(User user) async {
    const sql = '''
      UPDATE users 
      SET name = @name, email = @email, currency = @currency, 
          monthly_income = @monthly_income, password = @password,
          updated_at = CURRENT_TIMESTAMP
      WHERE id = @id
    ''';
    return await _db.execute(sql, [
      user.name,
      user.email,
      user.currency,
      user.monthlyIncome,
      user.password,
      user.id,
    ]);
  }

  Future<int> delete(int id) async {
    const sql = 'DELETE FROM users WHERE id = @id';
    return await _db.execute(sql, [id]);
  }

  Future<User?> login(String email, String password) async {
    const sql = 'SELECT * FROM users WHERE email = @email AND password = @password';
    final result = await _db.queryOne(sql, [email, password]);
    return result != null ? User.fromMap(result) : null;
  }
}