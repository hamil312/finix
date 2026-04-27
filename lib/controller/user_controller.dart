// filepath: lib\controller\user_controller.dart
import '../model/user.dart';
import '../repository/user_repository.dart';

class UserController {
  final UserRepository _repository = UserRepository();

  Future<int> register({
    required String name,
    required String email,
    required String password,
    String currency = 'USD',
    double monthlyIncome = 0,
  }) async {
    // Validar que el email no exista
    final existingUser = await _repository.getByEmail(email);
    if (existingUser != null) {
      throw Exception('El email ya está registrado');
    }

    final user = User(
      name: name,
      email: email,
      password: password,
      currency: currency,
      monthlyIncome: monthlyIncome,
    );

    return await _repository.create(user);
  }

  Future<User?> login(String email, String password) async {
    final user = await _repository.login(email, password);
    if (user == null) {
      throw Exception('Email o contraseña incorrectos');
    }
    return user;
  }

  Future<User?> getUserById(int id) async {
    return await _repository.getById(id);
  }

  Future<User?> getUserByEmail(String email) async {
    return await _repository.getByEmail(email);
  }

  Future<void> updateUser(User user) async {
    await _repository.update(user);
  }

  Future<void> deleteUser(int id) async {
    await _repository.delete(id);
  }

  Future<void> updateMonthlyIncome(int userId, double monthlyIncome) async {
    final user = await _repository.getById(userId);
    if (user == null) {
      throw Exception('Usuario no encontrado');
    }
    await _repository.update(user.copyWith(monthlyIncome: monthlyIncome));
  }

  Future<void> updateCurrency(int userId, String currency) async {
    final user = await _repository.getById(userId);
    if (user == null) {
      throw Exception('Usuario no encontrado');
    }
    await _repository.update(user.copyWith(currency: currency));
  }
}