// filepath: lib\controller\category_controller.dart
import '../model/category.dart';
import '../repository/category_repository.dart';

class CategoryController {
  final CategoryRepository _repository = CategoryRepository();

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

  Future<Category?> getCategoryById(int id) async {
    return await _repository.getById(id);
  }

  Future<List<Category>> getAllCategories() async {
    return await _repository.getAll();
  }

  Future<List<Category>> getExpenseCategories() async {
    return await _repository.getByType('expense');
  }

  Future<List<Category>> getIncomeCategories() async {
    return await _repository.getByType('income');
  }

  Future<void> updateCategory(Category category) async {
    await _repository.update(category);
  }

  Future<void> deleteCategory(int id) async {
    await _repository.delete(id);
  }
}