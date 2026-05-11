import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../model/debt.dart';
import '../../model/debt_payment.dart';
import '../../controller/debt_controller.dart';
import '../../provider/auth_provider.dart';

class DebtScreen extends StatefulWidget {
  const DebtScreen({super.key});

  @override
  State<DebtScreen> createState() => _DebtScreenState();
}

class _DebtScreenState extends State<DebtScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DebtController _controller = DebtController();

  List<Debt> _activeDebts = [];
  List<Debt> _paidDebts = [];
  bool _isLoading = true;

  final _currencyFmt =
      NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ─── Carga de datos ──────────────────────────────────────────────────────

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final userId = _userId;
    if (userId == null) return;

    try {
      final all = await _controller.getUserDebts(userId);
      setState(() {
        _activeDebts = all.where((d) => d.remaining > 0).toList();
        _paidDebts = all.where((d) => d.remaining <= 0).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Error al cargar deudas: $e');
    }
  }

  int? get _userId =>
      Provider.of<AuthProvider>(context, listen: false).currentUser?.id;

  // ─── Build principal ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Deudas'),
        backgroundColor: colorScheme.errorContainer,
        foregroundColor: colorScheme.onErrorContainer,
        bottom: TabBar(
          controller: _tabController,
          labelColor: colorScheme.onErrorContainer,
          indicatorColor: colorScheme.error,
          tabs: const [
            Tab(text: 'Activas'),
            Tab(text: 'Pagadas'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildSummaryBanner(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildDebtList(_activeDebts, active: true),
                      _buildDebtList(_paidDebts, active: false),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDebtDialog,
        icon: const Icon(Icons.add),
        label: const Text('Nueva deuda'),
        backgroundColor: Theme.of(context).colorScheme.error,
        foregroundColor: Colors.white,
      ),
    );
  }

  // ─── Banner de resumen ───────────────────────────────────────────────────

  Widget _buildSummaryBanner() {
    final totalRemaining =
        _activeDebts.fold(0.0, (sum, d) => sum + d.remaining);
    final totalOriginal = _activeDebts.fold(0.0, (sum, d) => sum + d.total);
    final totalPaid = totalOriginal - totalRemaining;

    return Container(
      width: double.infinity,
      color: Theme.of(context).colorScheme.errorContainer,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _summaryItem('Saldo total', totalRemaining,
              color: Theme.of(context).colorScheme.error),
          _summaryItem('Pagado', totalPaid,
              color: Colors.green.shade700),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${_activeDebts.length} activas',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              Text('${_paidDebts.length} pagadas',
                  style:
                      TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, double value, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
        Text(_currencyFmt.format(value),
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color ?? Colors.black87)),
      ],
    );
  }

  // ─── Lista de deudas ─────────────────────────────────────────────────────

  Widget _buildDebtList(List<Debt> debts, {required bool active}) {
    if (debts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              active ? Icons.check_circle_outline : Icons.hourglass_empty,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              active ? 'No tienes deudas activas' : 'No hay deudas pagadas',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: debts.length,
      itemBuilder: (context, index) => _buildDebtCard(debts[index], active),
    );
  }

  Widget _buildDebtCard(Debt debt, bool active) {
    final percent = debt.percentPaid.clamp(0.0, 100.0);
    final daysUntilDue = debt.dueDate.difference(DateTime.now()).inDays;
    final isOverdue = daysUntilDue < 0 && active;
    final isDueSoon = daysUntilDue >= 0 && daysUntilDue <= 7 && active;

    Color statusColor = Colors.grey;
    String statusText = '';
    if (active) {
      if (isOverdue) {
        statusColor = Colors.red.shade700;
        statusText = 'Vencida hace ${daysUntilDue.abs()} días';
      } else if (isDueSoon) {
        statusColor = Colors.orange.shade700;
        statusText = daysUntilDue == 0
            ? 'Vence HOY'
            : 'Vence en $daysUntilDue días';
      } else {
        statusColor = Colors.blue.shade600;
        statusText = 'Vence en $daysUntilDue días';
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isOverdue
            ? BorderSide(color: Colors.red.shade300, width: 1.5)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado
            Row(
              children: [
                Expanded(
                  child: Text(
                    debt.name,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                if (active)
                  PopupMenuButton<String>(
                    onSelected: (value) => _handleDebtAction(value, debt),
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'partial',
                        child: ListTile(
                          leading: Icon(Icons.payments_outlined),
                          title: Text('Pago parcial'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'full',
                        child: ListTile(
                          leading: Icon(Icons.check_circle_outline,
                              color: Colors.green),
                          title: Text('Pago total'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'history',
                        child: ListTile(
                          leading: Icon(Icons.history),
                          title: Text('Ver historial'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                          leading: Icon(Icons.edit_outlined),
                          title: Text('Editar'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading:
                              Icon(Icons.delete_outline, color: Colors.red),
                          title: Text('Eliminar',
                              style: TextStyle(color: Colors.red)),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  )
                else
                  PopupMenuButton<String>(
                    onSelected: (value) => _handleDebtAction(value, debt),
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'history',
                        child: ListTile(
                          leading: Icon(Icons.history),
                          title: Text('Ver historial'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading:
                              Icon(Icons.delete_outline, color: Colors.red),
                          title: Text('Eliminar',
                              style: TextStyle(color: Colors.red)),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
              ],
            ),

            const SizedBox(height: 8),

            // Montos
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Saldo pendiente',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade600)),
                    Text(
                      _currencyFmt.format(debt.remaining),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: active
                            ? Theme.of(context).colorScheme.error
                            : Colors.green.shade700,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Total original',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade600)),
                    Text(
                      _currencyFmt.format(debt.total),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Barra de progreso
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percent / 100,
                minHeight: 8,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation(
                  active ? Colors.green.shade600 : Colors.green.shade400,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Pagado: ${percent.toStringAsFixed(1)}%',
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade600)),
                Text(_currencyFmt.format(debt.paidAmount),
                    style: TextStyle(
                        fontSize: 11, color: Colors.green.shade700)),
              ],
            ),

            const SizedBox(height: 8),

            // Fecha vencimiento e interés
            Row(
              children: [
                Icon(Icons.calendar_today,
                    size: 13, color: statusColor),
                const SizedBox(width: 4),
                Text(
                  active
                      ? '${DateFormat('dd/MM/yyyy').format(debt.dueDate)} · $statusText'
                      : 'Venció: ${DateFormat('dd/MM/yyyy').format(debt.dueDate)}',
                  style: TextStyle(fontSize: 12, color: statusColor),
                ),
                if (debt.interestRate > 0) ...[
                  const Spacer(),
                  Icon(Icons.percent, size: 13, color: Colors.grey.shade600),
                  Text(
                    ' ${debt.interestRate.toStringAsFixed(1)}% interés',
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ],
            ),

            // Botones rápidos (solo activas)
            if (active) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showPartialPaymentDialog(debt),
                      icon: const Icon(Icons.payments_outlined, size: 16),
                      label: const Text('Pago parcial'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor:
                            Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showFullPaymentDialog(debt),
                      icon: const Icon(Icons.check_circle, size: 16),
                      label: const Text('Pago total'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─── Acciones del menú ────────────────────────────────────────────────────

  void _handleDebtAction(String action, Debt debt) {
    switch (action) {
      case 'partial':
        _showPartialPaymentDialog(debt);
        break;
      case 'full':
        _showFullPaymentDialog(debt);
        break;
      case 'history':
        _showPaymentHistoryDialog(debt);
        break;
      case 'edit':
        _showEditDebtDialog(debt);
        break;
      case 'delete':
        _confirmDeleteDebt(debt);
        break;
    }
  }

  // ─── Dialogo: Agregar deuda ───────────────────────────────────────────────

  void _showAddDebtDialog() {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final totalCtrl = TextEditingController();
    final rateCtrl = TextEditingController(text: '0');
    DateTime dueDate = DateTime.now().add(const Duration(days: 30));

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Nueva Deuda'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nombre de la deuda',
                      hintText: 'ej. Tarjeta de crédito, préstamo banco...',
                      prefixIcon: Icon(Icons.label_outline),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Campo requerido' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: totalCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Monto total (\$)',
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      final n = double.tryParse(v ?? '');
                      if (n == null || n <= 0) return 'Monto inválido';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: rateCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Tasa de interés (% anual)',
                      prefixIcon: Icon(Icons.percent),
                      hintText: '0 si no aplica',
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      final n = double.tryParse(v ?? '');
                      if (n == null || n < 0) return 'Valor inválido';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_today),
                    title: const Text('Fecha de vencimiento'),
                    subtitle: Text(DateFormat('dd/MM/yyyy').format(dueDate),
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: dueDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setDialogState(() => dueDate = picked);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar')),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final userId = _userId;
                if (userId == null) return;
                try {
                  await _controller.createDebt(
                    userId: userId,
                    name: nameCtrl.text.trim(),
                    total: double.parse(totalCtrl.text),
                    interestRate: double.parse(rateCtrl.text),
                    dueDate: dueDate,
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                  _loadData();
                  _showSuccess('Deuda registrada y recordatorios programados');
                } catch (e) {
                  _showError('Error al guardar: $e');
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Dialogo: Editar deuda ────────────────────────────────────────────────

  void _showEditDebtDialog(Debt debt) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: debt.name);
    final rateCtrl =
        TextEditingController(text: debt.interestRate.toString());
    DateTime dueDate = debt.dueDate;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Editar Deuda'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nombre',
                      prefixIcon: Icon(Icons.label_outline),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Campo requerido' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: rateCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Tasa de interés (% anual)',
                      prefixIcon: Icon(Icons.percent),
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      final n = double.tryParse(v ?? '');
                      if (n == null || n < 0) return 'Valor inválido';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_today),
                    title: const Text('Fecha de vencimiento'),
                    subtitle: Text(DateFormat('dd/MM/yyyy').format(dueDate),
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: dueDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setDialogState(() => dueDate = picked);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar')),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final updated = debt.copyWith(
                  name: nameCtrl.text.trim(),
                  interestRate: double.parse(rateCtrl.text),
                  dueDate: dueDate,
                );
                try {
                  await _controller.updateDebt(updated);
                  if (ctx.mounted) Navigator.pop(ctx);
                  _loadData();
                  _showSuccess('Deuda actualizada');
                } catch (e) {
                  _showError('Error al actualizar: $e');
                }
              },
              child: const Text('Actualizar'),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Dialogo: Pago parcial ────────────────────────────────────────────────

  void _showPartialPaymentDialog(Debt debt) {
    final formKey = GlobalKey<FormState>();
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    DateTime paymentDate = DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Registrar Pago Parcial'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info de la deuda
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(debt.name,
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text(
                          'Saldo: ${_currencyFmt.format(debt.remaining)}',
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: amountCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Monto a pagar (\$)',
                      prefixIcon: Icon(Icons.payments_outlined),
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      final n = double.tryParse(v ?? '');
                      if (n == null || n <= 0) return 'Monto inválido';
                      if (n > debt.remaining) {
                        return 'Supera el saldo pendiente (${_currencyFmt.format(debt.remaining)})';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: noteCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nota (opcional)',
                      prefixIcon: Icon(Icons.note_outlined),
                      hintText: 'ej. Transferencia Nequi',
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_today),
                    title: const Text('Fecha del pago'),
                    subtitle: Text(DateFormat('dd/MM/yyyy').format(paymentDate),
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: paymentDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setDialogState(() => paymentDate = picked);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar')),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                try {
                  final payment = await _controller.makePartialPayment(
                    debtId: debt.id!,
                    amount: double.parse(amountCtrl.text),
                    note: noteCtrl.text.trim().isEmpty
                        ? null
                        : noteCtrl.text.trim(),
                    paymentDate: paymentDate,
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                  _loadData();
                  _showSuccess(
                    'Pago de ${_currencyFmt.format(payment.amount)} registrado',
                  );
                } catch (e) {
                  _showError('$e');
                }
              },
              child: const Text('Registrar pago'),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Dialogo: Pago total ──────────────────────────────────────────────────

  void _showFullPaymentDialog(Debt debt) {
    final noteCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pago Total de Deuda'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                children: [
                  const Icon(Icons.check_circle,
                      color: Colors.green, size: 40),
                  const SizedBox(height: 8),
                  Text(
                    '¿Saldar "${debt.name}"?',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Se registrará el pago completo de\n${_currencyFmt.format(debt.remaining)}',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.green.shade800),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: noteCtrl,
              decoration: const InputDecoration(
                labelText: 'Nota (opcional)',
                prefixIcon: Icon(Icons.note_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          FilledButton(
            style:
                FilledButton.styleFrom(backgroundColor: Colors.green.shade600),
            onPressed: () async {
              try {
                await _controller.makeFullPayment(
                  debtId: debt.id!,
                  note: noteCtrl.text.trim().isEmpty
                      ? null
                      : noteCtrl.text.trim(),
                );
                if (ctx.mounted) Navigator.pop(ctx);
                _loadData();
                _showSuccess('🎉 ¡Deuda "${debt.name}" pagada completamente!');
              } catch (e) {
                _showError('$e');
              }
            },
            child: const Text('Confirmar pago total'),
          ),
        ],
      ),
    );
  }

  // ─── Dialogo: Historial de pagos ──────────────────────────────────────────

  void _showPaymentHistoryDialog(Debt debt) async {
    List<DebtPayment>? payments;

    try {
      payments = await _controller.getPaymentHistory(debt.id!);
    } catch (e) {
      _showError('Error al cargar historial: $e');
      return;
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Historial de pagos\n${debt.name}',
            style: const TextStyle(fontSize: 15)),
        content: SizedBox(
          width: double.maxFinite,
          child: payments!.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: Text('Sin pagos registrados')),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: payments.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, index) {
                    final p = payments![index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: p.isFullPayment
                            ? Colors.green.shade100
                            : Colors.blue.shade100,
                        child: Icon(
                          p.isFullPayment
                              ? Icons.check_circle
                              : Icons.payments,
                          color: p.isFullPayment
                              ? Colors.green.shade700
                              : Colors.blue.shade700,
                          size: 20,
                        ),
                      ),
                      title: Text(_currencyFmt.format(p.amount),
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                        '${DateFormat('dd/MM/yyyy').format(p.paymentDate)}'
                        '${p.note != null ? " · ${p.note}" : ""}'
                        '${p.isFullPayment ? " · Pago total" : ""}',
                      ),
                    );
                  },
                ),
        ),
        actions: [
          // Resumen al pie
          if (payments.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 4),
              child: Text(
                'Total pagado: ${_currencyFmt.format(payments.fold(0.0, (s, p) => s + p.amount))}',
                style: TextStyle(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.bold),
              ),
            ),
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cerrar')),
        ],
      ),
    );
  }

  // ─── Confirmar eliminación ────────────────────────────────────────────────

  Future<void> _confirmDeleteDebt(Debt debt) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar deuda'),
        content: Text(
          '¿Eliminar "${debt.name}"? También se eliminarán todos sus pagos registrados.\n\nEsta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _controller.deleteDebt(debt.id!);
        _loadData();
        _showSuccess('Deuda eliminada');
      } catch (e) {
        _showError('Error al eliminar: $e');
      }
    }
  }

  // ─── Helpers UI ───────────────────────────────────────────────────────────

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}