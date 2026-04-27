// filepath: lib\controller\saving_goal_controller.dart
import '../model/saving_goal.dart';
import '../repository/saving_goal_repository.dart';
import '../repository/sync_repository.dart';
import '../utils/database_connection.dart';

class SavingGoalController {
  final SavingGoalRepository _repository = SavingGoalRepository();
  final SyncRepository _syncRepository = SyncRepository();

  Future<int> createSavingGoal({
    required int userId,
    required String name,
    required double targetAmount,
    required DateTime deadline,
    bool saveOffline = false,
  }) async {
    final savingGoal = SavingGoal(
      userId: userId,
      name: name,
      targetAmount: targetAmount,
      currentAmount: 0,
      deadline: deadline,
    );

    if (DatabaseConnection.instance.isConnected && !saveOffline) {
      return await _repository.create(savingGoal);
    } else {
      await _syncRepository.saveLocalSavingGoal(savingGoal);
      return -1;
    }
  }

  Future<SavingGoal?> getSavingGoalById(int id) async {
    return await _repository.getById(id);
  }

  Future<List<SavingGoal>> getUserSavingGoals(int userId) async {
    return await _repository.getByUserId(userId);
  }

  Future<List<SavingGoal>> getActiveSavingGoals(int userId) async {
    return await _repository.getActiveByUserId(userId);
  }

  Future<void> updateSavingGoal(SavingGoal savingGoal) async {
    await _repository.update(savingGoal);
  }

  Future<void> deleteSavingGoal(int id) async {
    await _repository.delete(id);
  }

  /// Registra un aporte a una meta de ahorro
  Future<void> addContribution(int savingGoalId, double amount) async {
    final goal = await _repository.getById(savingGoalId);
    if (goal == null) {
      throw Exception('Meta de ahorro no encontrada');
    }

    if (goal.currentAmount + amount > goal.targetAmount) {
      throw Exception('El aporte excede el monto objetivo');
    }

    await _repository.addContribution(savingGoalId, amount);
  }

  /// Obtiene el total ahorrado por un usuario
  Future<double> getTotalSaved(int userId) async {
    return await _repository.getTotalSavedByUserId(userId);
  }

  /// Obtiene un resumen de las metas de ahorro
  Future<Map<String, dynamic>> getSavingGoalsSummary(int userId) async {
    final goals = await getActiveSavingGoals(userId);
    
    double totalTarget = 0;
    double totalSaved = 0;
    int completed = 0;
    
    for (var goal in goals) {
      totalTarget += goal.targetAmount;
      totalSaved += goal.currentAmount;
      if (goal.currentAmount >= goal.targetAmount) {
        completed++;
      }
    }

    // Calcular progreso general
    final progress = totalTarget > 0 ? (totalSaved / totalTarget) * 100 : 0;

    return {
      'total_target': totalTarget,
      'total_saved': totalSaved,
      'remaining': totalTarget - totalSaved,
      'progress_percent': progress,
      'active_goals': goals.length,
      'completed_goals': completed,
      'goals': goals,
    };
  }

  /// Verifica si una meta de ahorro está completa
  Future<bool> isGoalCompleted(int savingGoalId) async {
    final goal = await _repository.getById(savingGoalId);
    if (goal == null) return false;
    
    return goal.currentAmount >= goal.targetAmount;
  }

  /// Obtiene el tiempo restante para alcanzar una meta
  Future<int> getDaysRemaining(int savingGoalId) async {
    final goal = await _repository.getById(savingGoalId);
    if (goal == null) return 0;
    
    return goal.deadline.difference(DateTime.now()).inDays;
  }
}