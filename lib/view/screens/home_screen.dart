// filepath: lib\view\screens\home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../provider/auth_provider.dart';
import '../../controller/budget_controller.dart';
import '../../controller/transaction_controller.dart';
import '../../controller/debt_controller.dart';
import '../../controller/saving_goal_controller.dart';
import 'expense_screen.dart';
import 'debt_screen.dart';
import 'budget_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late BudgetController _budgetController;
  late TransactionController _transactionController;
  late DebtController _debtController;
  late SavingGoalController _savingGoalController;

  dynamic _currentBudgetSummary;
  dynamic _latestTransaction;
  dynamic _nearestDueDebt;
  dynamic _currentSavingGoal;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _budgetController = BudgetController();
    _transactionController = TransactionController();
    _debtController = DebtController();
    _savingGoalController = SavingGoalController();
    _loadDashboardData();
    _rescheduleDebtReminders();
  }

  Future<void> _loadDashboardData() async {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.currentUser?.id;

    if (userId == null) return;

    try {
      setState(() => _isLoading = true);

      // Cargar presupuesto actual
      final now = DateTime.now();
      final budgetSummary = await _budgetController.getBudgetSummary(
        userId,
        now.month,
        now.year,
      );

      // Cargar transacción más reciente
      final transactions = await _transactionController.getUserTransactions(userId);
      final latest = transactions.isNotEmpty ? transactions.first : null;

      // Cargar deuda más próxima a vencer
      final debtSummary = await _debtController.getDebtSummary(userId);

      // Cargar meta de ahorro actual
      final savingGoals = await _savingGoalController.getActiveSavingGoals(userId);
      final current = savingGoals.isNotEmpty ? savingGoals.first : null;

      setState(() {
        _currentBudgetSummary = budgetSummary;
        _latestTransaction = latest;
        _nearestDueDebt = debtSummary['nearest_due'];
        _currentSavingGoal = current;
        _isLoading = false;
      });
    } catch (e) {
      print('Error cargando datos: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _rescheduleDebtReminders() async {
    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId == null) return;
    try {
      await DebtController().rescheduleAllReminders(userId);
    } catch (e) {
      print('⚠️ No se pudieron reprogramar recordatorios: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Evitar que se vuelva a la pantalla de login
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.blue.shade700,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: const Text(
            'FinanzApp',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => _showLogoutDialog(context),
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _loadDashboardData,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Header con usuario
                _buildUserHeader(),
                const SizedBox(height: 24),

                // Botones de navegación
                _buildNavigationButtons(),
                const SizedBox(height: 32),

                // Tarjetas de información
                _buildDashboardCards(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserHeader() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        return Row(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade400, Colors.blue.shade700],
                ),
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(2),
              child: Container(
                decoration: const BoxDecoration(shape: BoxShape.circle),
                child: CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Text(
                    (authProvider.currentUser?.name ?? 'U')[0].toUpperCase(),
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bienvenido',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    authProvider.currentUser?.name ?? 'Usuario',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNavigationButtons() {
    final buttons = [
      ('Gastos', Icons.receipt, Colors.purple),
      ('Deudas', Icons.credit_card, Colors.red),
      ('Objetivos', Icons.add_task, Colors.green),
      ('Presupuestos', Icons.pie_chart, Colors.orange),
      ('Estadísticas', Icons.bar_chart, Colors.teal),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: buttons
            .map(
              (btn) => Padding(
                padding: const EdgeInsets.only(right: 12),
                child: _buildNavButton(btn.$1, btn.$2, btn.$3),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildNavButton(String label, IconData icon, Color color) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      onPressed: () {
        switch (label) {
          case 'Gastos':
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ExpenseScreen()),
            );
            break;
          case 'Deudas':
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const DebtScreen()),
            );
            break;
          case 'Presupuestos':
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const BudgetScreen()),
            );
            break;
          default:
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$label - En desarrollo')),
            );
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardCards() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Column(
      children: [
        // Presupuesto actual
        _buildInfoCard(
          'Presupuesto Actual',
          Icons.pie_chart,
          Colors.blue,
          _buildBudgetContent(),
        ),
        const SizedBox(height: 16),

        // Gasto más reciente
        _buildInfoCard(
          'Gasto Más Reciente',
          Icons.trending_down,
          Colors.red,
          _buildTransactionContent(),
        ),
        const SizedBox(height: 16),

        // Deuda más próxima
        _buildInfoCard(
          'Deuda Próxima a Vencer',
          Icons.warning,
          Colors.orange,
          _buildDebtContent(),
        ),
        const SizedBox(height: 16),

        // Objetivo de ahorro
        _buildInfoCard(
          'Meta de Ahorro Actual',
          Icons.savings,
          Colors.green,
          _buildSavingGoalContent(),
        ),
      ],
    );
  }

  Widget _buildInfoCard(
    String title,
    IconData icon,
    Color color,
    Widget content,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border(
            top: BorderSide(color: color, width: 4),
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetContent() {
    if (_currentBudgetSummary == null) {
      return const Text(
        'Sin presupuesto configurado',
        style: TextStyle(color: Colors.grey),
      );
    }

    final totalAllocated = _currentBudgetSummary['total_allocated'] ?? 0.0;
    final totalSpent = _currentBudgetSummary['total_spent'] ?? 0.0;
    final percentUsed = _currentBudgetSummary['percent_used'] ?? 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '\$${totalSpent.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'de \$${totalAllocated.toStringAsFixed(2)}',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentUsed / 100,
            minHeight: 8,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(
              percentUsed > 80 ? Colors.red : Colors.green,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${percentUsed.toStringAsFixed(1)}% del presupuesto utilizado',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildTransactionContent() {
    if (_latestTransaction == null) {
      return const Text(
        'Sin transacciones registradas',
        style: TextStyle(color: Colors.grey),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _latestTransaction.description,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '\$${_latestTransaction.amount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            Text(
              _formatDate(_latestTransaction.date),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDebtContent() {
    if (_nearestDueDebt == null) {
      return const Text(
        'Sin deudas pendientes',
        style: TextStyle(color: Colors.green),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _nearestDueDebt.name,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Pendiente: \$${_nearestDueDebt.remaining.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            Text(
              'Vence: ${_formatDate(_nearestDueDebt.dueDate)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSavingGoalContent() {
    if (_currentSavingGoal == null) {
      return const Text(
        'Sin objetivos de ahorro',
        style: TextStyle(color: Colors.grey),
      );
    }

    final progress = _currentSavingGoal.targetAmount > 0
        ? (_currentSavingGoal.currentAmount / _currentSavingGoal.targetAmount) *
            100
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _currentSavingGoal.name,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '\$${_currentSavingGoal.currentAmount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'de \$${_currentSavingGoal.targetAmount.toStringAsFixed(2)}',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress / 100,
            minHeight: 8,
            backgroundColor: Colors.grey.shade200,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${progress.toStringAsFixed(1)}% completado',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Deseas cerrar la sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () {
              context.read<AuthProvider>().logout();
              Navigator.pop(context);
            },
            child: const Text('Cerrar Sesión', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}