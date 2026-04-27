// filepath: lib\repository\category_repository.dart
import '../model/category.dart';
import '../utils/database_connection.dart';

class CategoryRepository {
  final DatabaseConnection _db = DatabaseConnection.instance;

  Future<int> create(Category category) async {
    const sql = '''
      INSERT INTO categories (name, type, default_allocation_percent)
      VALUES (@name, @type, @default_allocation_percent)
      RETURNING id
    ''';
    final result = await _db.query(sql, [
      category.name,
      category.type,
      category.defaultAllocationPercent,
    ]);
    return result.first['id'] as int;
  }

  Future<Category?> getById(int id) async {
    const sql = 'SELECT * FROM categories WHERE id = @id';
    final result = await _db.queryOne(sql, [id]);
    return result != null ? Category.fromMap(result) : null;
  }

  Future<List<Category>> getAll() async {
    const sql = 'SELECT * FROM categories ORDER BY name';
    final results = await _db.query(sql);
    return results.map((map) => Category.fromMap(map)).toList();
  }

  Future<List<Category>> getByType(String type) async {
    const sql = 'SELECT * FROM categories WHERE type = @type ORDER BY name';
    final results = await _db.query(sql, [type]);
    return results.map((map) => Category.fromMap(map)).toList();
  }

  Future<int> update(Category category) async {
    const sql = '''
      UPDATE categories 
      SET name = @name, type = @type, default_allocation_percent = @default_allocation_percent
      WHERE id = @id
    ''';
    return await _db.execute(sql, [
      category.name,
      category.type,
      category.defaultAllocationPercent,
      category.id,
    ]);
  }

  Future<int> delete(int id) async {
    const sql = 'DELETE FROM categories WHERE id = @id';
    return await _db.execute(sql, [id]);
  }
}