import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../model/transaction.dart';
import '../../model/recurring_transaction.dart';
import '../../model/category.dart';
import '../../controller/transaction_controller.dart';
import '../../controller/recurring_transaction_controller.dart';
import '../../controller/category_controller.dart';
import '../../provider/auth_provider.dart';
import 'package:intl/intl.dart';

class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({super.key});

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Transaction> _transactions = [];
  List<RecurringTransaction> _recurringTransactions = [];
  List<Category> _categories = [];
  bool _isLoading = true;

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

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUser?.id;
    if (userId == null) return;

    final transactionController = TransactionController();
    final recurringController = RecurringTransactionController();
    final categoryController = CategoryController();

    try {
      final transactions = await transactionController.getUserTransactions(userId);
      final recurring = await recurringController.getUserRecurringTransactions(userId);
      final categories = await categoryController.getAllCategories();

      setState(() {
        _transactions = transactions.where((t) => t.amount < 0).toList(); // Solo gastos
        _recurringTransactions = recurring;
        _categories = categories.where((c) => c.type == 'expense').toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar datos: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gastos'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Únicos'),
            Tab(text: 'Recurrentes'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildUniqueExpensesTab(),
                _buildRecurringExpensesTab(),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildUniqueExpensesTab() {
    if (_transactions.isEmpty) {
      return const Center(child: Text('No hay gastos únicos'));
    }

    return ListView.builder(
      itemCount: _transactions.length,
      itemBuilder: (context, index) {
        final transaction = _transactions[index];
        final category = _categories.firstWhere(
          (c) => c.id == transaction.categoryId,
          orElse: () => Category(id: 0, name: 'Desconocida', type: 'expense', defaultAllocationPercent: 0.0),
        );

        return ListTile(
          title: Text(transaction.description),
          subtitle: Text('${category.name} - ${DateFormat('dd/MM/yyyy').format(transaction.date)}'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('\$${transaction.amount.abs().toStringAsFixed(2)}'),
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _showEditTransactionDialog(transaction),
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => _deleteTransaction(transaction.id!),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecurringExpensesTab() {
    if (_recurringTransactions.isEmpty) {
      return const Center(child: Text('No hay gastos recurrentes'));
    }

    return ListView.builder(
      itemCount: _recurringTransactions.length,
      itemBuilder: (context, index) {
        final recurring = _recurringTransactions[index];
        final category = _categories.firstWhere(
          (c) => c.id == recurring.categoryId,
          orElse: () => Category(id: 0, name: 'Desconocida', type: 'expense', defaultAllocationPercent: 0.0),
        );

        return ListTile(
          title: Text(recurring.description),
          subtitle: Text('${category.name} - ${recurring.frequency.name} - Próximo: ${DateFormat('dd/MM/yyyy').format(recurring.nextDueDate)}'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('\$${recurring.amount.abs().toStringAsFixed(2)}'),
              Switch(
                value: recurring.isActive,
                onChanged: (value) => _toggleRecurringActive(recurring, value),
              ),
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _showEditRecurringDialog(recurring),
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => _deleteRecurring(recurring.id!),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Agregar Gasto'),
        content: const Text('¿Qué tipo de gasto deseas agregar?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showAddTransactionDialog();
            },
            child: const Text('Único'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showAddRecurringDialog();
            },
            child: const Text('Recurrente'),
          ),
        ],
      ),
    );
  }

  void _showAddTransactionDialog() {
    final formKey = GlobalKey<FormState>();
    double amount = 0;
    String description = '';
    int? selectedCategoryId;
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Agregar Gasto Único'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Monto'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Campo requerido';
                  final num = double.tryParse(value);
                  if (num == null || num <= 0) return 'Monto inválido';
                  return null;
                },
                onSaved: (value) => amount = double.parse(value!),
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Descripción'),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Campo requerido';
                  return null;
                },
                onSaved: (value) => description = value!,
              ),
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(labelText: 'Categoría'),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category.id,
                    child: Text(category.name),
                  );
                }).toList(),
                validator: (value) => value == null ? 'Selecciona una categoría' : null,
                onChanged: (value) => selectedCategoryId = value,
              ),
              ListTile(
                title: const Text('Fecha'),
                subtitle: Text(DateFormat('dd/MM/yyyy').format(selectedDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (date != null) {
                    setState(() => selectedDate = date);
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                formKey.currentState!.save();
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                final userId = authProvider.currentUser?.id;
                if (userId != null && selectedCategoryId != null) {
                  final controller = TransactionController();
                  try {
                    await controller.createTransaction(
                      userId: userId,
                      amount: -amount.abs(), // Gastos negativos
                      description: description,
                      categoryId: selectedCategoryId!,
                      date: selectedDate,
                    );
                    Navigator.of(context).pop();
                    _loadData();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Gasto agregado')),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  }
                }
              }
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }

  void _showEditTransactionDialog(Transaction transaction) {
    final formKey = GlobalKey<FormState>();
    double amount = transaction.amount.abs();
    String description = transaction.description;
    int selectedCategoryId = transaction.categoryId;
    DateTime selectedDate = transaction.date;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Gasto Único'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: amount.toString(),
                decoration: const InputDecoration(labelText: 'Monto'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Campo requerido';
                  final num = double.tryParse(value);
                  if (num == null || num <= 0) return 'Monto inválido';
                  return null;
                },
                onSaved: (value) => amount = double.parse(value!),
              ),
              TextFormField(
                initialValue: description,
                decoration: const InputDecoration(labelText: 'Descripción'),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Campo requerido';
                  return null;
                },
                onSaved: (value) => description = value!,
              ),
              DropdownButtonFormField<int>(
                value: selectedCategoryId,
                decoration: const InputDecoration(labelText: 'Categoría'),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category.id,
                    child: Text(category.name),
                  );
                }).toList(),
                validator: (value) => value == null ? 'Selecciona una categoría' : null,
                onChanged: (value) => selectedCategoryId = value!,
              ),
              ListTile(
                title: const Text('Fecha'),
                subtitle: Text(DateFormat('dd/MM/yyyy').format(selectedDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (date != null) {
                    setState(() => selectedDate = date);
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                formKey.currentState!.save();
                final updatedTransaction = transaction.copyWith(
                  amount: -amount.abs(),
                  description: description,
                  categoryId: selectedCategoryId,
                  date: selectedDate,
                );
                final controller = TransactionController();
                try {
                  await controller.updateTransaction(updatedTransaction);
                  Navigator.of(context).pop();
                  _loadData();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Gasto actualizado')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              }
            },
            child: const Text('Actualizar'),
          ),
        ],
      ),
    );
  }

  void _showAddRecurringDialog() {
    final formKey = GlobalKey<FormState>();
    double amount = 0;
    String description = '';
    int? selectedCategoryId;
    RecurringFrequency selectedFrequency = RecurringFrequency.monthly;
    DateTime startDate = DateTime.now();
    DateTime? endDate;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Agregar Gasto Recurrente'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Monto'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Campo requerido';
                    final num = double.tryParse(value);
                    if (num == null || num <= 0) return 'Monto inválido';
                    return null;
                  },
                  onSaved: (value) => amount = double.parse(value!),
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Descripción'),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Campo requerido';
                    return null;
                  },
                  onSaved: (value) => description = value!,
                ),
                DropdownButtonFormField<int>(
                  decoration: const InputDecoration(labelText: 'Categoría'),
                  items: _categories.map((category) {
                    return DropdownMenuItem(
                      value: category.id,
                      child: Text(category.name),
                    );
                  }).toList(),
                  validator: (value) => value == null ? 'Selecciona una categoría' : null,
                  onChanged: (value) => selectedCategoryId = value,
                ),
                DropdownButtonFormField<RecurringFrequency>(
                  value: selectedFrequency,
                  decoration: const InputDecoration(labelText: 'Frecuencia'),
                  items: RecurringFrequency.values.map((freq) {
                    return DropdownMenuItem(
                      value: freq,
                      child: Text(freq.name),
                    );
                  }).toList(),
                  onChanged: (value) => selectedFrequency = value!,
                ),
                ListTile(
                  title: const Text('Fecha de Inicio'),
                  subtitle: Text(DateFormat('dd/MM/yyyy').format(startDate)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: startDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (date != null) {
                      setState(() => startDate = date);
                    }
                  },
                ),
                ListTile(
                  title: const Text('Fecha de Fin (Opcional)'),
                  subtitle: endDate != null ? Text(DateFormat('dd/MM/yyyy').format(endDate!)) : const Text('Sin fin'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: endDate ?? DateTime.now().add(const Duration(days: 365)),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (date != null) {
                      setState(() => endDate = date);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                formKey.currentState!.save();
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                final userId = authProvider.currentUser?.id;
                if (userId != null && selectedCategoryId != null) {
                  final controller = RecurringTransactionController();
                  try {
                    await controller.createRecurringTransaction(
                      userId: userId,
                      amount: -amount.abs(),
                      description: description,
                      categoryId: selectedCategoryId!,
                      frequency: selectedFrequency,
                      startDate: startDate,
                      endDate: endDate,
                    );
                    Navigator.of(context).pop();
                    _loadData();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Gasto recurrente agregado')),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  }
                }
              }
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }

  void _showEditRecurringDialog(RecurringTransaction recurring) {
    final formKey = GlobalKey<FormState>();
    double amount = recurring.amount.abs();
    String description = recurring.description;
    int selectedCategoryId = recurring.categoryId;
    RecurringFrequency selectedFrequency = recurring.frequency;
    DateTime startDate = recurring.startDate;
    DateTime? endDate = recurring.endDate;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Gasto Recurrente'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  initialValue: amount.toString(),
                  decoration: const InputDecoration(labelText: 'Monto'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Campo requerido';
                    final num = double.tryParse(value);
                    if (num == null || num <= 0) return 'Monto inválido';
                    return null;
                  },
                  onSaved: (value) => amount = double.parse(value!),
                ),
                TextFormField(
                  initialValue: description,
                  decoration: const InputDecoration(labelText: 'Descripción'),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Campo requerido';
                    return null;
                  },
                  onSaved: (value) => description = value!,
                ),
                DropdownButtonFormField<int>(
                  value: selectedCategoryId,
                  decoration: const InputDecoration(labelText: 'Categoría'),
                  items: _categories.map((category) {
                    return DropdownMenuItem(
                      value: category.id,
                      child: Text(category.name),
                    );
                  }).toList(),
                  validator: (value) => value == null ? 'Selecciona una categoría' : null,
                  onChanged: (value) => selectedCategoryId = value!,
                ),
                DropdownButtonFormField<RecurringFrequency>(
                  value: selectedFrequency,
                  decoration: const InputDecoration(labelText: 'Frecuencia'),
                  items: RecurringFrequency.values.map((freq) {
                    return DropdownMenuItem(
                      value: freq,
                      child: Text(freq.name),
                    );
                  }).toList(),
                  onChanged: (value) => selectedFrequency = value!,
                ),
                ListTile(
                  title: const Text('Fecha de Inicio'),
                  subtitle: Text(DateFormat('dd/MM/yyyy').format(startDate)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: startDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (date != null) {
                      setState(() => startDate = date);
                    }
                  },
                ),
                ListTile(
                  title: const Text('Fecha de Fin (Opcional)'),
                  subtitle: endDate != null ? Text(DateFormat('dd/MM/yyyy').format(endDate!)) : const Text('Sin fin'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: endDate ?? DateTime.now().add(const Duration(days: 365)),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (date != null) {
                      setState(() => endDate = date);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                formKey.currentState!.save();
                final updatedRecurring = recurring.copyWith(
                  amount: -amount.abs(),
                  description: description,
                  categoryId: selectedCategoryId,
                  frequency: selectedFrequency,
                  startDate: startDate,
                  endDate: endDate,
                );
                final controller = RecurringTransactionController();
                try {
                  await controller.updateRecurringTransaction(updatedRecurring);
                  Navigator.of(context).pop();
                  _loadData();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Gasto recurrente actualizado')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              }
            },
            child: const Text('Actualizar'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTransaction(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Gasto'),
        content: const Text('¿Estás seguro de que deseas eliminar este gasto?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final controller = TransactionController();
      try {
        await controller.deleteTransaction(id);
        _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gasto eliminado')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al eliminar: $e')),
          );
        }
      }
    }
  }

  Future<void> _deleteRecurring(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Gasto Recurrente'),
        content: const Text('¿Estás seguro de que deseas eliminar este gasto recurrente?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final controller = RecurringTransactionController();
      try {
        await controller.deleteRecurringTransaction(id);
        _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gasto recurrente eliminado')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al eliminar: $e')),
          );
        }
      }
    }
  }

  Future<void> _toggleRecurringActive(RecurringTransaction recurring, bool isActive) async {
    final controller = RecurringTransactionController();
    try {
      if (isActive) {
        await controller.activateRecurringTransaction(recurring.id!);
      } else {
        await controller.deactivateRecurringTransaction(recurring.id!);
      }
      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar: $e')),
        );
      }
    }
  }
}