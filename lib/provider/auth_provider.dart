// filepath: lib\provider\auth_provider.dart
import 'package:flutter/material.dart';
import '../model/user.dart';
import '../model/session.dart';
import '../controller/user_controller.dart';
import '../controller/transaction_controller.dart';
import '../utils/database_connection.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  final UserController _userController = UserController();
  final TransactionController _transactionController = TransactionController();
  
  Session? _session;
  bool _isLoading = false;
  String? _error;

  Session? get session => _session;
  bool get isAuthenticated => _session != null && _session!.isValid;
  bool get isLoading => _isLoading;
  String? get error => _error;
  User? get currentUser => _session?.user;

  /// Registra un nuevo usuario
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
    String currency = 'USD',
    double monthlyIncome = 0,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (password != confirmPassword) {
        throw Exception('Las contraseñas no coinciden');
      }

      if (password.length < 6) {
        throw Exception('La contraseña debe tener al menos 6 caracteres');
      }

      if (!DatabaseConnection.instance.isConnected) {
        throw Exception('No hay conexión a la base de datos. Verifica tu conexión e intenta de nuevo.');
      }

      final userId = await _userController.register(
        name: name,
        email: email,
        password: password,
        currency: currency,
        monthlyIncome: monthlyIncome,
      );

      // Obtener el usuario recién creado
      final user = await _userController.getUserById(userId);
      if (user != null) {
        _session = Session(
          user: user,
          token: 'token_$userId',
          loginTime: DateTime.now(),
        );
        
        // Guardar sesión localmente
        await _saveSessionLocally();
        notifyListeners();
        return true;
      }
      
      throw Exception('Error al crear la cuenta');
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Inicia sesión con email y contraseña
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (!DatabaseConnection.instance.isConnected) {
        throw Exception('No hay conexión a la base de datos');
      }

      final user = await _userController.login(email, password);
      if (user == null) {
        throw Exception('Email o contraseña incorrectos');
      }

      _session = Session(
        user: user,
        token: 'token_${user.id}',
        loginTime: DateTime.now(),
      );

      // Guardar sesión localmente
      await _saveSessionLocally();

      // Procesar transacciones recurrentes pendientes
      if (user.id != null) {
        await _transactionController.processRecurringTransactions(user.id!);
      }

      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Cierra la sesión actual
  Future<void> logout() async {
    _session = null;
    _error = null;
    
    // Limpiar sesión local
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_session');
    
    notifyListeners();
  }

  /// Guarda la sesión localmente
  Future<void> _saveSessionLocally() async {
    if (_session == null) return;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_id', _session!.user.id ?? -1);
    await prefs.setString('user_email', _session!.user.email);
    await prefs.setString('user_name', _session!.user.name);
  }

  /// Restaura la sesión desde almacenamiento local
  Future<void> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    
    if (userId == null || userId == -1) {
      _session = null;
      notifyListeners();
      return;
    }

    if (!DatabaseConnection.instance.isConnected) {
      _session = null;
      notifyListeners();
      return;
    }

    try {
      final user = await _userController.getUserById(userId);
      if (user != null) {
        _session = Session(
          user: user,
          token: 'token_$userId',
          loginTime: DateTime.now(),
        );

        // Procesar transacciones recurrentes pendientes
        await _transactionController.processRecurringTransactions(userId);
      }
    } catch (e) {
      _session = null;
    }
    
    notifyListeners();
  }

  /// Limpia el error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}