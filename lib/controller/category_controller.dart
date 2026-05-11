import '../model/category.dart';
import '../repository/category_repository.dart';

class CategoryController {
  final CategoryRepository _repository = CategoryRepository();

  // ─── Categorías del sistema ───────────────────────────────────────────────

  Future<List<Category>> getAllCategories() => _repository.getAll();

  Future<List<Category>> getAllForUser(int userId) =>
      _repository.getAllForUser(userId);

  Future<List<Category>> getExpenseCategories() =>
      _repository.getByType('expense');

  Future<List<Category>> getIncomeCategories() =>
      _repository.getByType('income');

  Future<List<Category>> getExpenseCategoriesForUser(int userId) =>
      _repository.getByTypeForUser('expense', userId);

  Future<List<Category>> getIncomeCategoriesForUser(int userId) =>
      _repository.getByTypeForUser('income', userId);

  Future<Category?> getCategoryById(int id) => _repository.getById(id);

  // ─── Categorías personalizadas ────────────────────────────────────────────

  /// Crea una categoría personalizada para el usuario.
  Future<int> createCustomCategory({
    required int userId,
    required String name,
    required String type,
    String icon = 'category',
    String colorHex = '#607D8B',
    double defaultAllocationPercent = 0,
  }) async {
    // Validar que no exista ya una con el mismo nombre para este usuario
    final existing = await _repository.getAllForUser(userId);
    final duplicate = existing.any(
      (c) => c.name.toLowerCase() == name.toLowerCase() && c.type == type,
    );
    if (duplicate) {
      throw Exception('Ya existe una categoría "$name" de tipo "$type"');
    }

    final category = Category(
      name: name.trim(),
      type: type,
      defaultAllocationPercent: defaultAllocationPercent,
      isCustom: true,
      userId: userId,
      icon: icon,
      colorHex: colorHex,
    );
    return await _repository.create(category);
  }

  /// Obtiene solo las categorías personalizadas del usuario.
  Future<List<Category>> getCustomCategories(int userId) =>
      _repository.getCustomByUser(userId);

  /// Edita una categoría personalizada (solo nombre, icono y color).
  Future<void> updateCustomCategory(Category category) async {
    if (!category.isCustom) {
      throw Exception('No se pueden editar las categorías del sistema');
    }
    await _repository.update(category);
  }

  /// Elimina una categoría personalizada del usuario.
  Future<void> deleteCustomCategory(int categoryId, int userId) async {
    final affected = await _repository.deleteCustom(categoryId, userId);
    if (affected == 0) {
      throw Exception(
          'No se encontró la categoría o no tienes permiso para eliminarla');
    }
  }

  // Mantener compatibilidad con código existente
  Future<void> updateCategory(Category category) => _repository.update(category);
  Future<void> deleteCategory(int id) => _repository.delete(id);
  Future<int> create({
    required String name,
    required String type,
    required double defaultAllocationPercent,
  }) async {
    final category = Category(
      name: name,
      type: type,
      defaultAllocationPercent: defaultAllocationPercent,
    );
    return await _repository.create(category);
  }
}