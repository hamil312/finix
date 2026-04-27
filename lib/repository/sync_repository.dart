// filepath: lib\repository\sync_repository.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/transaction.dart';
import '../model/debt.dart';
import '../model/saving_goal.dart';
import '../utils/database_connection.dart';

class SyncRepository {
  final DatabaseConnection _db = DatabaseConnection.instance;
  static const String _pendingSyncKey = 'pending_sync';
  static const String _localTransactionsKey = 'local_transactions';
  static const String _localDebtsKey = 'local_debts';
  static const String _localSavingGoalsKey = 'local_saving_goals';

  // ============ Sincronización Offline ============

  /// Agrega una operación a la cola de sincronización
  Future<void> addToSyncQueue(
    String tableName,
    int recordId,
    String operation,
    Map<String, dynamic>? data,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final queue = await _getSyncQueue();
    
    queue.add({
      'table_name': tableName,
      'record_id': recordId,
      'operation': operation,
      'data': data,
      'created_at': DateTime.now().toIso8601String(),
      'synced': false,
    });
    
    await prefs.setString(_pendingSyncKey, jsonEncode(queue));
  }

  /// Obtiene la cola de sincronización
  Future<List<Map<String, dynamic>>> _getSyncQueue() async {
    final prefs = await SharedPreferences.getInstance();
    final queueString = prefs.getString(_pendingSyncKey);
    if (queueString == null) return [];
    
    final List<dynamic> decoded = jsonDecode(queueString);
    return decoded.cast<Map<String, dynamic>>();
  }

  /// Sincroniza los datos pendientes con el servidor
  Future<void> syncPendingData() async {
    if (!_db.isConnected) {
      print('⚠️ No hay conexión a internet. Sincronización diferida.');
      return;
    }

    final queue = await _getSyncQueue();
    final pendingItems = queue.where((item) => item['synced'] == false).toList();

    for (var item in pendingItems) {
      try {
        await _processSyncItem(item);
        
        // Marcar como sincronizado
        final index = queue.indexOf(item);
        queue[index]['synced'] = true;
      } catch (e) {
        print('❌ Error sincronizando: $e');
      }
    }

    // Limpiar elementos sincronizados
    final remaining = queue.where((item) => item['synced'] == false).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pendingSyncKey, jsonEncode(remaining));
    
    print('✅ Sincronización completada. Pendientes: ${remaining.length}');
  }

  /// Procesa un elemento de la cola de sincronización
  Future<void> _processSyncItem(Map<String, dynamic> item) async {
    final tableName = item['table_name'] as String;
    final operation = item['operation'] as String;
    final data = item['data'] as Map<String, dynamic>?;

    switch (operation) {
      case 'INSERT':
        await _db.execute(_getInsertSql(tableName), [data]);
        break;
      case 'UPDATE':
        await _db.execute(_getUpdateSql(tableName), [data]);
        break;
      case 'DELETE':
        await _db.execute(_getDeleteSql(tableName), [item['record_id']]);
        break;
    }
  }

  String _getInsertSql(String tableName) {
    // Implementar según la tabla
    return '';
  }

  String _getUpdateSql(String tableName) {
    return '';
  }

  String _getDeleteSql(String tableName) {
    return 'DELETE FROM $tableName WHERE id = @id';
  }

  // ============ Almacenamiento Local ============

  /// Guarda una transacción en local storage
  Future<void> saveLocalTransaction(Transaction transaction) async {
    final prefs = await SharedPreferences.getInstance();
    final transactions = await getLocalTransactions();
    
    final newTransaction = {
      ...transaction.toMap(),
      'local_id': DateTime.now().millisecondsSinceEpoch,
      'synced': false,
    };
    
    transactions.add(newTransaction);
    await prefs.setString(_localTransactionsKey, jsonEncode(transactions));
  }

  /// Obtiene todas las transacciones locales
  Future<List<Map<String, dynamic>>> getLocalTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_localTransactionsKey);
    if (data == null) return [];
    
    return (jsonDecode(data) as List).cast<Map<String, dynamic>>();
  }

  /// Guarda una deuda en local storage
  Future<void> saveLocalDebt(Debt debt) async {
    final prefs = await SharedPreferences.getInstance();
    final debts = await getLocalDebts();
    
    final newDebt = {
      ...debt.toMap(),
      'local_id': DateTime.now().millisecondsSinceEpoch,
      'synced': false,
    };
    
    debts.add(newDebt);
    await prefs.setString(_localDebtsKey, jsonEncode(debts));
  }

  /// Obtiene todas las deudas locales
  Future<List<Map<String, dynamic>>> getLocalDebts() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_localDebtsKey);
    if (data == null) return [];
    
    return (jsonDecode(data) as List).cast<Map<String, dynamic>>();
  }

  /// Guarda una meta de ahorro en local storage
  Future<void> saveLocalSavingGoal(SavingGoal goal) async {
    final prefs = await SharedPreferences.getInstance();
    final goals = await getLocalSavingGoals();
    
    final newGoal = {
      ...goal.toMap(),
      'local_id': DateTime.now().millisecondsSinceEpoch,
      'synced': false,
    };
    
    goals.add(newGoal);
    await prefs.setString(_localSavingGoalsKey, jsonEncode(goals));
  }

  /// Obtiene todas las metas de ahorro locales
  Future<List<Map<String, dynamic>>> getLocalSavingGoals() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_localSavingGoalsKey);
    if (data == null) return [];
    
    return (jsonDecode(data) as List).cast<Map<String, dynamic>>();
  }

  /// Limpia los datos locales después de sincronizar
  Future<void> clearLocalData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_localTransactionsKey);
    await prefs.remove(_localDebtsKey);
    await prefs.remove(_localSavingGoalsKey);
    await prefs.remove(_pendingSyncKey);
  }

  /// Obtiene el estado de sincronización
  Future<Map<String, int>> getSyncStatus() async {
    final transactions = await getLocalTransactions();
    final debts = await getLocalDebts();
    final goals = await getLocalSavingGoals();
    final queue = await _getSyncQueue();
    
    return {
      'pending_transactions': transactions.where((t) => t['synced'] == false).length,
      'pending_debts': debts.where((d) => d['synced'] == false).length,
      'pending_saving_goals': goals.where((g) => g['synced'] == false).length,
      'sync_queue': queue.where((q) => q['synced'] == false).length,
    };
  }
}