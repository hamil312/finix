import '../model/category.dart';
import '../utils/database_connection.dart';

class CategoryRepository {
  final DatabaseConnection _db = DatabaseConnection.instance;

  Future<int> create(Category category) async {
    const sql = '''
      INSERT INTO categories
        (name, type, default_allocation_percent, is_custom, user_id, icon, color_hex)
      VALUES (@name, @type, @default_allocation_percent, @is_custom, @user_id, @icon, @color_hex)
      RETURNING id
    ''';
    final result = await _db.query(sql, [
      category.name,
      category.type,
      category.defaultAllocationPercent,
      category.isCustom,
      category.userId,
      category.icon,
      category.colorHex,
    ]);
    return result.first['id'] as int;
  }

  Future<Category?> getById(int id) async {
    const sql = 'SELECT * FROM categories WHERE id = @id';
    final result = await _db.queryOne(sql, [id]);
    return result != null ? Category.fromMap(result) : null;
  }

  /// Devuelve categorías del sistema + las personalizadas del usuario
  Future<List<Category>> getAllForUser(int userId) async {
    const sql = '''
      SELECT * FROM categories
      WHERE is_custom = FALSE OR (is_custom = TRUE AND user_id = @user_id)
      ORDER BY is_custom ASC, name ASC
    ''';
    final results = await _db.query(sql, [userId]);
    return results.map((m) => Category.fromMap(m)).toList();
  }

  /// Solo categorías del sistema (is_custom = false)
  Future<List<Category>> getAll() async {
    const sql = 'SELECT * FROM categories ORDER BY name';
    final results = await _db.query(sql);
    return results.map((m) => Category.fromMap(m)).toList();
  }

  Future<List<Category>> getByType(String type) async {
    const sql =
        'SELECT * FROM categories WHERE type = @type ORDER BY name';
    final results = await _db.query(sql, [type]);
    return results.map((m) => Category.fromMap(m)).toList();
  }

  /// Categorías de un tipo filtradas para un usuario (sistema + propias)
  Future<List<Category>> getByTypeForUser(String type, int userId) async {
    const sql = '''
      SELECT * FROM categories
      WHERE type = @type
        AND (is_custom = FALSE OR (is_custom = TRUE AND user_id = @user_id))
      ORDER BY is_custom ASC, name ASC
    ''';
    final results = await _db.query(sql, [type, userId]);
    return results.map((m) => Category.fromMap(m)).toList();
  }

  /// Solo las categorías personalizadas de un usuario
  Future<List<Category>> getCustomByUser(int userId) async {
    const sql = '''
      SELECT * FROM categories
      WHERE is_custom = TRUE AND user_id = @user_id
      ORDER BY name
    ''';
    final results = await _db.query(sql, [userId]);
    return results.map((m) => Category.fromMap(m)).toList();
  }

  Future<int> update(Category category) async {
    const sql = '''
      UPDATE categories
      SET name = @name,
          type = @type,
          default_allocation_percent = @default_allocation_percent,
          icon = @icon,
          color_hex = @color_hex
      WHERE id = @id
    ''';
    return await _db.execute(sql, [
      category.name,
      category.type,
      category.defaultAllocationPercent,
      category.icon,
      category.colorHex,
      category.id,
    ]);
  }

  /// Solo permite eliminar categorías personalizadas del propio usuario
  Future<int> deleteCustom(int id, int userId) async {
    const sql = '''
      DELETE FROM categories
      WHERE id = @id AND is_custom = TRUE AND user_id = @user_id
    ''';
    return await _db.execute(sql, [id, userId]);
  }

  Future<int> delete(int id) async {
    const sql = 'DELETE FROM categories WHERE id = @id';
    return await _db.execute(sql, [id]);
  }
}