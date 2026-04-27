// filepath: lib\controller\debt_controller.dart
import '../model/debt.dart';
import '../repository/debt_repository.dart';
import '../repository/sync_repository.dart';
import '../utils/database_connection.dart';

class DebtController {
  final DebtRepository _repository = DebtRepository();
  final SyncRepository _syncRepository = SyncRepository();

  Future<int> createDebt({
    required int userId,
    required String name,
    required double total,
    required double interestRate,
    required DateTime dueDate,
    bool saveOffline = false,
  }) async {
    final debt = Debt(
      userId: userId,
      name: name,
      total: total,
      remaining: total,
      interestRate: interestRate,
      dueDate: dueDate,
    );

    if (DatabaseConnection.instance.isConnected && !saveOffline) {
      return await _repository.create(debt);
    } else {
      await _syncRepository.saveLocalDebt(debt);
      return -1;
    }
  }

  Future<Debt?> getDebtById(int id) async {
    return await _repository.getById(id);
  }

  Future<List<Debt>> getUserDebts(int userId) async {
    return await _repository.getByUserId(userId);
  }

  Future<List<Debt>> getActiveDebts(int userId) async {
    return await _repository.getActiveByUserId(userId);
  }

  Future<void> updateDebt(Debt debt) async {
    await _repository.update(debt);
  }

  Future<void> deleteDebt(int id) async {
    await _repository.delete(id);
  }

  /// Realiza un pago a una deuda
  Future<void> makePayment(int debtId, double amount) async {
    final debt = await _repository.getById(debtId);
    if (debt == null) {
      throw Exception('Deuda no encontrada');
    }

    final newRemaining = debt.remaining - amount;
    await _repository.updateRemaining(debtId, newRemaining < 0 ? 0 : newRemaining);
  }

  /// Obtiene el total de deudas de un usuario
  Future<double> getTotalDebt(int userId) async {
    return await _repository.getTotalDebtByUserId(userId);
  }

  /// Obtiene un resumen del estado de deudas
  Future<Map<String, dynamic>> getDebtSummary(int userId) async {
    final debts = await getActiveDebts(userId);
    
    double totalDebt = 0;
    double totalPaid = 0;
    int count = debts.length;
    
    for (var debt in debts) {
      totalDebt += debt.remaining;
      totalPaid += (debt.total - debt.remaining);
    }

    // Deuda más cercana a vencer
    Debt? nearestDue;
    if (debts.isNotEmpty) {
      debts.sort((a, b) => a.dueDate.compareTo(b.dueDate));
      nearestDue = debts.first;
    }

    return {
      'total_debt': totalDebt,
      'total_paid': totalPaid,
      'active_debts_count': count,
      'nearest_due': nearestDue,
      'debts': debts,
    };
  }

  /// Calcula el interés acumulado de una deuda
  Future<double> calculateAccumulatedInterest(int debtId) async {
    final debt = await _repository.getById(debtId);
    if (debt == null) return 0;

    // Calcular días transcurridos desde la creación
    final daysSinceCreation = DateTime.now().difference(debt.dueDate).inDays;
    if (daysSinceCreation <= 0) return 0;

    // Interés simple: (principal * tasa * días) / 365
    final interest = (debt.remaining * debt.interestRate * daysSinceCreation) / 36500;
    return interest;
  }
}