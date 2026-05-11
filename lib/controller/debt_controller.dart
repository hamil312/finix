// soporte para: pagos parciales, pagos totales y recordatorios.

import '../model/debt.dart';
import '../model/debt_payment.dart';
import '../repository/debt_repository.dart';
import '../repository/debt_payment_repository.dart';
import '../repository/sync_repository.dart';
import '../services/notification_service.dart';
import '../utils/database_connection.dart';

class DebtController {
  final DebtRepository _repository = DebtRepository();
  final DebtPaymentRepository _paymentRepository = DebtPaymentRepository();
  final SyncRepository _syncRepository = SyncRepository();
  final NotificationService _notifications = NotificationService();

  // ─── CRUD de Deudas ──────────────────────────────────────────────────────

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
      final id = await _repository.create(debt);
      // Programar recordatorios automáticamente al crear
      final created = debt.copyWith(id: id);
      await _notifications.scheduleDebtReminders(created);
      return id;
    } else {
      await _syncRepository.saveLocalDebt(debt);
      return -1;
    }
  }

  Future<Debt?> getDebtById(int id) => _repository.getById(id);

  Future<List<Debt>> getUserDebts(int userId) =>
      _repository.getByUserId(userId);

  Future<List<Debt>> getActiveDebts(int userId) =>
      _repository.getActiveByUserId(userId);

  Future<void> updateDebt(Debt debt) async {
    await _repository.update(debt);
    // Actualizar recordatorios con la nueva fecha de vencimiento
    await _notifications.scheduleDebtReminders(debt);
  }

  Future<void> deleteDebt(int id) async {
    await _notifications.cancelDebtReminders(id);
    await _repository.delete(id);
  }

  // ─── Pagos ───────────────────────────────────────────────────────────────

  /// Registra un pago parcial sobre la deuda.
  /// Lanza [Exception] si el monto supera el saldo pendiente.
  Future<DebtPayment> makePartialPayment({
    required int debtId,
    required double amount,
    String? note,
    DateTime? paymentDate,
  }) async {
    final debt = await _repository.getById(debtId);
    if (debt == null) throw Exception('Deuda no encontrada');

    if (amount <= 0) throw Exception('El monto debe ser mayor a cero');
    if (amount > debt.remaining) {
      throw Exception(
        'El monto (\$${amount.toStringAsFixed(2)}) supera el saldo pendiente '
        '(\$${debt.remaining.toStringAsFixed(2)}). '
        'Usa "Pago Total" si deseas saldar la deuda completa.',
      );
    }

    final payment = DebtPayment(
      debtId: debtId,
      amount: amount,
      paymentDate: paymentDate ?? DateTime.now(),
      note: note,
      isFullPayment: false,
    );

    final paymentId = await _paymentRepository.create(payment);
    final newRemaining = debt.remaining - amount;
    await _repository.updateRemaining(debtId, newRemaining);

    // Si tras el pago parcial ya no queda saldo, cancelar recordatorios
    if (newRemaining <= 0) {
      await _notifications.cancelDebtReminders(debtId);
    }

    return payment.copyWith(id: paymentId);
  }

  /// Registra el pago total de la deuda (salda el saldo completo).
  Future<DebtPayment> makeFullPayment({
    required int debtId,
    String? note,
    DateTime? paymentDate,
  }) async {
    final debt = await _repository.getById(debtId);
    if (debt == null) throw Exception('Deuda no encontrada');
    if (debt.remaining <= 0) throw Exception('Esta deuda ya está pagada');

    final payment = DebtPayment(
      debtId: debtId,
      amount: debt.remaining,
      paymentDate: paymentDate ?? DateTime.now(),
      note: note ?? 'Pago total',
      isFullPayment: true,
    );

    final paymentId = await _paymentRepository.create(payment);
    await _repository.updateRemaining(debtId, 0);
    await _notifications.cancelDebtReminders(debtId);

    return payment.copyWith(id: paymentId);
  }

  /// Obtiene el historial de pagos de una deuda ordenado por fecha desc.
  Future<List<DebtPayment>> getPaymentHistory(int debtId) =>
      _paymentRepository.getByDebtId(debtId);

  // ─── Resumen y estadísticas ───────────────────────────────────────────────

  Future<double> getTotalDebt(int userId) =>
      _repository.getTotalDebtByUserId(userId);

  Future<Map<String, dynamic>> getDebtSummary(int userId) async {
    final debts = await getActiveDebts(userId);

    double totalDebt = 0;
    double totalPaid = 0;

    for (final debt in debts) {
      totalDebt += debt.remaining;
      totalPaid += debt.paidAmount;
    }

    Debt? nearestDue;
    if (debts.isNotEmpty) {
      final sorted = List<Debt>.from(debts)
        ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
      nearestDue = sorted.first;
    }

    return {
      'total_debt': totalDebt,
      'total_paid': totalPaid,
      'active_debts_count': debts.length,
      'nearest_due': nearestDue,
      'debts': debts,
    };
  }

  Future<double> calculateAccumulatedInterest(int debtId) async {
    final debt = await _repository.getById(debtId);
    if (debt == null) return 0;

    final daysSince = DateTime.now().difference(debt.dueDate).inDays;
    if (daysSince <= 0) return 0;

    // Interés simple: (principal × tasa% × días) / 36500
    return (debt.remaining * debt.interestRate * daysSince) / 36500;
  }

  // ─── Notificaciones ───────────────────────────────────────────────────────

  /// Reprograma recordatorios de todas las deudas activas del usuario.
  /// Llamar al iniciar la app desde main.dart.
  Future<void> rescheduleAllReminders(int userId) async {
    final activeDebts = await getActiveDebts(userId);
    await _notifications.rescheduleAllDebtReminders(activeDebts);
  }
}