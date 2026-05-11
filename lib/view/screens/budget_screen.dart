import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../model/weekly_budget.dart';
import '../../model/category.dart';
import '../../controller/weekly_budget_controller.dart';
import '../../controller/category_controller.dart';
import '../../provider/auth_provider.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _budgetCtrl = WeeklyBudgetController();
  final _categoryCtrl = CategoryController();

  DateTime _selectedWeekStart = WeekUtils.weekStart(DateTime.now());

  List<WeeklyBudget> _budgets = [];
  List<Category> _customCategories = [];
  Map<String, dynamic> _summary = {};
  bool _isLoading = true;

  final _currency =
      NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ─── Datos ────────────────────────────────────────────────────────────────

  int? get _userId =>
      Provider.of<AuthProvider>(context, listen: false).currentUser?.id;

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    final uid = _userId;
    if (uid == null) return;
    try {
      final results = await Future.wait([
        _budgetCtrl.getBudgetsForWeek(uid, _selectedWeekStart),
        _categoryCtrl.getCustomCategories(uid),
        _budgetCtrl.getWeekSummary(uid, _selectedWeekStart),
      ]);
      setState(() {
        _budgets = results[0] as List<WeeklyBudget>;
        _customCategories = results[1] as List<Category>;
        _summary = results[2] as Map<String, dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Error al cargar: $e');
    }
  }

  // ─── UI principal ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Presupuesto'),
        backgroundColor: cs.primaryContainer,
        foregroundColor: cs.onPrimaryContainer,
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh), onPressed: _loadAll),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: cs.onPrimaryContainer,
          indicatorColor: cs.primary,
          tabs: const [
            Tab(text: 'Semanal'),
            Tab(text: 'Categorías'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildWeeklyTab(),
                _buildCategoriesTab(),
              ],
            ),
      floatingActionButton: _buildFab(),
    );
  }

  Widget _buildFab() {
    return AnimatedBuilder(
      animation: _tabController,
      builder: (_, __) => _tabController.index == 0
          ? FloatingActionButton.extended(
              onPressed: _showAddBudgetDialog,
              icon: const Icon(Icons.add),
              label: const Text('Nuevo presupuesto'),
            )
          : FloatingActionButton.extended(
              onPressed: _showAddCategoryDialog,
              icon: const Icon(Icons.add),
              label: const Text('Nueva categoría'),
              backgroundColor: Colors.teal,
            ),
    );
  }

  // ─── TAB 1: Presupuesto semanal ───────────────────────────────────────────

  Widget _buildWeeklyTab() {
    return Column(
      children: [
        _buildWeekSelector(),
        _buildWeeklySummaryBanner(),
        Expanded(
          child: _budgets.isEmpty
              ? _buildEmptyWeek()
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _budgets.length,
                  itemBuilder: (_, i) => _buildBudgetCard(_budgets[i]),
                ),
        ),
      ],
    );
  }

  // ─── Selector de semana ───────────────────────────────────────────────────

  Widget _buildWeekSelector() {
    final isCurrentWeek = _selectedWeekStart ==
        WeekUtils.weekStart(DateTime.now());
    final end = WeekUtils.weekEnd(_selectedWeekStart);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      color: Theme.of(context).colorScheme.surfaceVariant,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              setState(() {
                _selectedWeekStart =
                    _selectedWeekStart.subtract(const Duration(days: 7));
              });
              _loadAll();
            },
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  WeekUtils.weekLabel(_selectedWeekStart, end),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15),
                  textAlign: TextAlign.center,
                ),
                if (isCurrentWeek)
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Semana actual',
                      style: TextStyle(
                          fontSize: 10,
                          color:
                              Theme.of(context).colorScheme.onPrimary),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              setState(() {
                _selectedWeekStart =
                    _selectedWeekStart.add(const Duration(days: 7));
              });
              _loadAll();
            },
          ),
        ],
      ),
    );
  }

  // ─── Banner resumen semanal ───────────────────────────────────────────────

  Widget _buildWeeklySummaryBanner() {
    final totalAvailable =
        (_summary['total_available'] as double?) ?? 0;
    final totalSpent = (_summary['total_spent'] as double?) ?? 0;
    final totalRemaining =
        (_summary['total_remaining'] as double?) ?? 0;
    final percent =
        ((_summary['percent_used'] as double?) ?? 0).clamp(0.0, 100.0);
    final pendingSurplus =
        ((_summary['pending_surplus'] as List?)?.length ?? 0);

    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _summaryChip('Disponible', totalAvailable,
                  Theme.of(context).colorScheme.primary),
              _summaryChip('Gastado', totalSpent, Colors.red.shade600),
              _summaryChip('Restante', totalRemaining,
                  totalRemaining >= 0 ? Colors.green.shade700 : Colors.red),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: percent / 100,
              minHeight: 10,
              backgroundColor: Colors.white38,
              valueColor: AlwaysStoppedAnimation(
                percent >= 90
                    ? Colors.red.shade400
                    : percent >= 70
                        ? Colors.orange.shade400
                        : Colors.green.shade400,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${percent.toStringAsFixed(1)}% consumido',
                  style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context)
                          .colorScheme
                          .onPrimaryContainer)),
              if (pendingSurplus > 0)
                GestureDetector(
                  onTap: _showPendingSurplusDialog,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade600,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$pendingSurplus saldo(s) pendiente(s)',
                      style: const TextStyle(
                          fontSize: 11, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryChip(String label, double value, Color color) => Column(
        children: [
          Text(label,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
          Text(_currency.format(value),
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color)),
        ],
      );

  // ─── Tarjeta de presupuesto ───────────────────────────────────────────────

  Widget _buildBudgetCard(WeeklyBudget b) {
    final percent = b.percentUsed;
    final isOver = b.remaining < 0;
    final categoryColor = _hexToColor(b.categoryColor ?? '#607D8B');

    Color barColor = Colors.green.shade500;
    if (percent >= 90) barColor = Colors.red.shade500;
    else if (percent >= 70) barColor = Colors.orange.shade500;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isOver
            ? BorderSide(color: Colors.red.shade300, width: 1.5)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado con icono y nombre
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: categoryColor.withOpacity(0.2),
                  child: Icon(
                    _iconData(b.categoryIcon ?? 'category'),
                    color: categoryColor,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(b.categoryName ?? 'Categoría',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                ),
                if (b.carriedOver > 0)
                  Tooltip(
                    message:
                        'Incluye ${_currency.format(b.carriedOver)} trasladado',
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '+${_currency.format(b.carriedOver)}',
                        style: TextStyle(
                            fontSize: 11, color: Colors.blue.shade800),
                      ),
                    ),
                  ),
                PopupMenuButton<String>(
                  onSelected: (v) => _handleBudgetAction(v, b),
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                            leading: Icon(Icons.edit_outlined),
                            title: Text('Editar monto'),
                            contentPadding: EdgeInsets.zero)),
                    if (b.isExpired &&
                        b.surplusAction == SurplusAction.pending) ...[
                      const PopupMenuItem(
                          value: 'carry',
                          child: ListTile(
                              leading: Icon(Icons.arrow_forward,
                                  color: Colors.blue),
                              title: Text('Trasladar saldo'),
                              contentPadding: EdgeInsets.zero)),
                      const PopupMenuItem(
                          value: 'discard',
                          child: ListTile(
                              leading: Icon(Icons.delete_sweep,
                                  color: Colors.orange),
                              title: Text('Descartar saldo'),
                              contentPadding: EdgeInsets.zero)),
                    ],
                    const PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                            leading: Icon(Icons.delete_outline,
                                color: Colors.red),
                            title: Text('Eliminar',
                                style: TextStyle(color: Colors.red)),
                            contentPadding: EdgeInsets.zero)),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Montos
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Gastado',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade600)),
                    Text(_currency.format(b.spentAmount),
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isOver
                                ? Colors.red.shade700
                                : Colors.black87)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Disponible',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade600)),
                    Text(_currency.format(b.totalAvailable),
                        style: const TextStyle(fontSize: 14)),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Barra de progreso
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (percent / 100).clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation(barColor),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isOver
                      ? '⚠ Excedido en ${_currency.format(b.remaining.abs())}'
                      : '${percent.toStringAsFixed(1)}% usado',
                  style: TextStyle(
                      fontSize: 11,
                      color:
                          isOver ? Colors.red.shade700 : Colors.grey.shade600),
                ),
                Text(
                  'Resta: ${_currency.format(b.remaining)}',
                  style: TextStyle(
                      fontSize: 11,
                      color: isOver
                          ? Colors.red.shade700
                          : Colors.green.shade700),
                ),
              ],
            ),

            // Badge de saldo cerrado
            if (b.isExpired && b.surplusAction != SurplusAction.pending)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: b.surplusAction == SurplusAction.carried
                      ? Colors.blue.shade100
                      : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  b.surplusAction == SurplusAction.carried
                      ? '✓ Saldo trasladado a siguiente semana'
                      : '✓ Saldo descartado',
                  style: TextStyle(
                      fontSize: 11,
                      color: b.surplusAction == SurplusAction.carried
                          ? Colors.blue.shade800
                          : Colors.grey.shade700),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWeek() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.savings_outlined,
                size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text('Sin presupuestos esta semana',
                style:
                    TextStyle(color: Colors.grey.shade600, fontSize: 16)),
            const SizedBox(height: 8),
            Text('Toca "+" para definir un presupuesto',
                style:
                    TextStyle(color: Colors.grey.shade500, fontSize: 13)),
          ],
        ),
      );

  // ─── TAB 2: Categorías personalizadas ─────────────────────────────────────

  Widget _buildCategoriesTab() {
    return _customCategories.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.label_outline,
                    size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 12),
                Text('Sin categorías personalizadas',
                    style: TextStyle(
                        color: Colors.grey.shade600, fontSize: 16)),
                const SizedBox(height: 8),
                Text('Crea categorías para organizar tus gastos',
                    style: TextStyle(
                        color: Colors.grey.shade500, fontSize: 13)),
              ],
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: _customCategories.length,
            itemBuilder: (_, i) =>
                _buildCategoryCard(_customCategories[i]),
          );
  }

  Widget _buildCategoryCard(Category cat) {
    final color = _hexToColor(cat.colorHex);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(_iconData(cat.icon), color: color, size: 20),
        ),
        title: Text(cat.name,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(cat.type == 'expense' ? 'Gasto' : 'Ingreso'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              onPressed: () => _showEditCategoryDialog(cat),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  size: 20, color: Colors.red),
              onPressed: () => _confirmDeleteCategory(cat),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Diálogo: nuevo presupuesto ───────────────────────────────────────────

  void _showAddBudgetDialog() async {
    final uid = _userId;
    if (uid == null) return;

    final categories =
        await _budgetCtrl.getAvailableCategories(uid);
    if (!mounted) return;

    final formKey = GlobalKey<FormState>();
    int? selectedCategoryId;
    final amountCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Presupuesto — ${WeekUtils.weekLabel(_selectedWeekStart, WeekUtils.weekEnd(_selectedWeekStart))}',
          style: const TextStyle(fontSize: 14),
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(
                  labelText: 'Categoría',
                  prefixIcon: Icon(Icons.label_outline),
                ),
                items: categories.map((c) {
                  return DropdownMenuItem(
                    value: c.id,
                    child: Row(
                      children: [
                        Icon(_iconData(c.icon),
                            size: 16,
                            color: _hexToColor(c.colorHex)),
                        const SizedBox(width: 8),
                        Text(c.name),
                      ],
                    ),
                  );
                }).toList(),
                validator: (v) =>
                    v == null ? 'Selecciona una categoría' : null,
                onChanged: (v) => selectedCategoryId = v,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: amountCtrl,
                decoration: const InputDecoration(
                  labelText: 'Monto asignado (\$)',
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
            ],
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
                await _budgetCtrl.createWeeklyBudget(
                  userId: uid,
                  categoryId: selectedCategoryId!,
                  allocatedAmount: double.parse(amountCtrl.text),
                  forDate: _selectedWeekStart,
                );
                if (ctx.mounted) Navigator.pop(ctx);
                _loadAll();
                _showSuccess('Presupuesto creado');
              } catch (e) {
                _showError('$e');
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  // ─── Diálogo: editar monto ────────────────────────────────────────────────

  void _handleBudgetAction(String action, WeeklyBudget b) async {
    switch (action) {
      case 'edit':
        _showEditAmountDialog(b);
        break;
      case 'carry':
        await _budgetCtrl.carryOverSurplus(b.id!);
        _loadAll();
        _showSuccess(
            'Saldo trasladado a la siguiente semana');
        break;
      case 'discard':
        await _budgetCtrl.discardSurplus(b.id!);
        _loadAll();
        _showSuccess('Saldo descartado');
        break;
      case 'delete':
        await _budgetCtrl.deleteBudget(b.id!);
        _loadAll();
        _showSuccess('Presupuesto eliminado');
        break;
    }
  }

  void _showEditAmountDialog(WeeklyBudget b) {
    final ctrl =
        TextEditingController(text: b.allocatedAmount.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Editar: ${b.categoryName}'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
              labelText: 'Nuevo monto (\$)',
              prefixIcon: Icon(Icons.attach_money)),
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          FilledButton(
            onPressed: () async {
              final n = double.tryParse(ctrl.text);
              if (n == null || n <= 0) {
                _showError('Monto inválido');
                return;
              }
              await _budgetCtrl.updateAllocatedAmount(b.id!, n);
              if (ctx.mounted) Navigator.pop(ctx);
              _loadAll();
              _showSuccess('Presupuesto actualizado');
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  // ─── Diálogo: saldos pendientes ───────────────────────────────────────────

  void _showPendingSurplusDialog() {
    final pending = (_summary['pending_surplus'] as List<WeeklyBudget>?) ?? [];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Saldos sin cerrar'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: pending.length,
            itemBuilder: (_, i) {
              final b = pending[i];
              return ListTile(
                leading: Icon(_iconData(b.categoryIcon ?? 'category'),
                    color: _hexToColor(b.categoryColor ?? '#607D8B')),
                title: Text(b.categoryName ?? ''),
                subtitle: Text('Saldo: ${_currency.format(b.remaining)}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Trasladar',
                      icon: const Icon(Icons.arrow_forward,
                          color: Colors.blue, size: 20),
                      onPressed: () async {
                        await _budgetCtrl.carryOverSurplus(b.id!);
                        if (ctx.mounted) Navigator.pop(ctx);
                        _loadAll();
                        _showSuccess('Saldo trasladado');
                      },
                    ),
                    IconButton(
                      tooltip: 'Descartar',
                      icon: const Icon(Icons.delete_sweep,
                          color: Colors.orange, size: 20),
                      onPressed: () async {
                        await _budgetCtrl.discardSurplus(b.id!);
                        if (ctx.mounted) Navigator.pop(ctx);
                        _loadAll();
                        _showSuccess('Saldo descartado');
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cerrar')),
        ],
      ),
    );
  }

  // ─── Diálogo: nueva categoría ─────────────────────────────────────────────

  void _showAddCategoryDialog() {
    final uid = _userId;
    if (uid == null) return;

    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    String selectedType = 'expense';
    String selectedIcon = 'category';
    String selectedColor = '#607D8B';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Nueva Categoría'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Nombre',
                        prefixIcon: Icon(Icons.label_outline)),
                    textCapitalization: TextCapitalization.sentences,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Campo requerido'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedType,
                    decoration: const InputDecoration(labelText: 'Tipo'),
                    items: const [
                      DropdownMenuItem(
                          value: 'expense', child: Text('Gasto')),
                      DropdownMenuItem(
                          value: 'income', child: Text('Ingreso')),
                    ],
                    onChanged: (v) => setS(() => selectedType = v!),
                  ),
                  const SizedBox(height: 16),
                  const Text('Icono',
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: CategoryIcons.available.entries.map((e) {
                      final isSelected = e.key == selectedIcon;
                      return GestureDetector(
                        onTap: () => setS(() => selectedIcon = e.key),
                        child: Tooltip(
                          message: e.value,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Theme.of(context)
                                      .colorScheme
                                      .primaryContainer
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: isSelected
                                  ? Border.all(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary,
                                      width: 2)
                                  : null,
                            ),
                            child: Icon(_iconData(e.key), size: 20),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text('Color',
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: CategoryColors.available.map((c) {
                      final isSelected = c['hex'] == selectedColor;
                      final color = _hexToColor(c['hex']!);
                      return GestureDetector(
                        onTap: () => setS(() => selectedColor = c['hex']!),
                        child: Tooltip(
                          message: c['name'],
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: isSelected
                                  ? Border.all(
                                      color: Colors.black54, width: 2.5)
                                  : null,
                            ),
                            child: isSelected
                                ? const Icon(Icons.check,
                                    size: 16, color: Colors.white)
                                : null,
                          ),
                        ),
                      );
                    }).toList(),
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
              style:
                  FilledButton.styleFrom(backgroundColor: Colors.teal),
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                try {
                  await _categoryCtrl.createCustomCategory(
                    userId: uid,
                    name: nameCtrl.text.trim(),
                    type: selectedType,
                    icon: selectedIcon,
                    colorHex: selectedColor,
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                  _loadAll();
                  _showSuccess('Categoría creada');
                } catch (e) {
                  _showError('$e');
                }
              },
              child: const Text('Crear'),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Diálogo: editar categoría ────────────────────────────────────────────

  void _showEditCategoryDialog(Category cat) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: cat.name);
    String selectedIcon = cat.icon;
    String selectedColor = cat.colorHex;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Editar Categoría'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Nombre'),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Campo requerido'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  const Text('Icono',
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: CategoryIcons.available.entries.map((e) {
                      final isSelected = e.key == selectedIcon;
                      return GestureDetector(
                        onTap: () => setS(() => selectedIcon = e.key),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Theme.of(context)
                                    .colorScheme
                                    .primaryContainer
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: isSelected
                                ? Border.all(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary,
                                    width: 2)
                                : null,
                          ),
                          child: Icon(_iconData(e.key), size: 20),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text('Color',
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: CategoryColors.available.map((c) {
                      final isSelected = c['hex'] == selectedColor;
                      final color = _hexToColor(c['hex']!);
                      return GestureDetector(
                        onTap: () =>
                            setS(() => selectedColor = c['hex']!),
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: isSelected
                                ? Border.all(
                                    color: Colors.black54, width: 2.5)
                                : null,
                          ),
                          child: isSelected
                              ? const Icon(Icons.check,
                                  size: 16, color: Colors.white)
                              : null,
                        ),
                      );
                    }).toList(),
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
                  await _categoryCtrl.updateCustomCategory(
                    cat.copyWith(
                      name: nameCtrl.text.trim(),
                      icon: selectedIcon,
                      colorHex: selectedColor,
                    ),
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                  _loadAll();
                  _showSuccess('Categoría actualizada');
                } catch (e) {
                  _showError('$e');
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Confirmar eliminar categoría ─────────────────────────────────────────

  Future<void> _confirmDeleteCategory(Category cat) async {
    final uid = _userId;
    if (uid == null) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar categoría'),
        content: Text(
          '¿Eliminar "${cat.name}"?\n\nSi hay transacciones o presupuestos asociados, pueden quedar sin categoría.',
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
    if (ok == true) {
      try {
        await _categoryCtrl.deleteCustomCategory(cat.id!, uid);
        _loadAll();
        _showSuccess('Categoría eliminada');
      } catch (e) {
        _showError('$e');
      }
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  void _showSuccess(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.green.shade600,
      behavior: SnackBarBehavior.floating,
    ));
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.red.shade600,
      behavior: SnackBarBehavior.floating,
    ));
  }

  Color _hexToColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return Colors.blueGrey;
    }
  }

  IconData _iconData(String name) {
    const map = <String, IconData>{
      'restaurant': Icons.restaurant,
      'directions_car': Icons.directions_car,
      'shopping_cart': Icons.shopping_cart,
      'local_hospital': Icons.local_hospital,
      'school': Icons.school,
      'home': Icons.home,
      'sports_esports': Icons.sports_esports,
      'flight': Icons.flight,
      'fitness_center': Icons.fitness_center,
      'pets': Icons.pets,
      'phone_android': Icons.phone_android,
      'attach_money': Icons.attach_money,
      'work': Icons.work,
      'child_care': Icons.child_care,
      'local_cafe': Icons.local_cafe,
      'nightlife': Icons.nightlife,
    };
    return map[name] ?? Icons.category;
  }
}