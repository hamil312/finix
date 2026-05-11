import '../utils/type_converter.dart';

enum SurplusAction { pending, discarded, carried }

class WeeklyBudget {
  final int? id;
  final int userId;
  final int categoryId;
  final DateTime weekStart; // Lunes
  final DateTime weekEnd;   // Domingo
  final double allocatedAmount;
  final double spentAmount;
  final double carriedOver;     // Saldo trasladado desde semana anterior
  final SurplusAction surplusAction;

  // Campos opcionales enriquecidos (join con categories)
  final String? categoryName;
  final String? categoryIcon;
  final String? categoryColor;

  WeeklyBudget({
    this.id,
    required this.userId,
    required this.categoryId,
    required this.weekStart,
    required this.weekEnd,
    required this.allocatedAmount,
    this.spentAmount = 0,
    this.carriedOver = 0,
    this.surplusAction = SurplusAction.pending,
    this.categoryName,
    this.categoryIcon,
    this.categoryColor,
  });

  // ─── Cálculos derivados ──────────────────────────────────────────────────

  /// Total disponible = asignado + trasladado
  double get totalAvailable => allocatedAmount + carriedOver;

  /// Saldo restante
  double get remaining => totalAvailable - spentAmount;

  /// Porcentaje gastado sobre el total disponible
  double get percentUsed =>
      totalAvailable > 0 ? (spentAmount / totalAvailable * 100).clamp(0, 100) : 0;

  /// Si el presupuesto ya venció (semana pasada)
  bool get isExpired => weekEnd.isBefore(DateTime.now());

  /// Si esta es la semana actual
  bool get isCurrent {
    final now = DateTime.now();
    return !now.isBefore(weekStart) && !now.isAfter(weekEnd);
  }

  // ─── Serialización ────────────────────────────────────────────────────────

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'category_id': categoryId,
        'week_start': weekStart.toIso8601String().split('T').first,
        'week_end': weekEnd.toIso8601String().split('T').first,
        'allocated_amount': allocatedAmount,
        'spent_amount': spentAmount,
        'carried_over': carriedOver,
        'surplus_action': surplusAction.name,
      };

  factory WeeklyBudget.fromMap(Map<String, dynamic> map) => WeeklyBudget(
        id: TypeConverter.toIntOrNull(map['id']),
        userId: TypeConverter.toInt(map['user_id']),
        categoryId: TypeConverter.toInt(map['category_id']),
        weekStart: TypeConverter.toDateTime(map['week_start']),
        weekEnd: TypeConverter.toDateTime(map['week_end']),
        allocatedAmount: TypeConverter.toDouble(map['allocated_amount']),
        spentAmount: TypeConverter.toDouble(map['spent_amount']),
        carriedOver: TypeConverter.toDouble(map['carried_over']),
        surplusAction: _parseSurplusAction(map['surplus_action']),
        categoryName: map['category_name'] as String?,
        categoryIcon: map['category_icon'] as String?,
        categoryColor: map['category_color'] as String?,
      );

  static SurplusAction _parseSurplusAction(dynamic value) {
    switch (value?.toString()) {
      case 'discarded':
        return SurplusAction.discarded;
      case 'carried':
        return SurplusAction.carried;
      default:
        return SurplusAction.pending;
    }
  }

  WeeklyBudget copyWith({
    int? id,
    int? userId,
    int? categoryId,
    DateTime? weekStart,
    DateTime? weekEnd,
    double? allocatedAmount,
    double? spentAmount,
    double? carriedOver,
    SurplusAction? surplusAction,
    String? categoryName,
    String? categoryIcon,
    String? categoryColor,
  }) =>
      WeeklyBudget(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        categoryId: categoryId ?? this.categoryId,
        weekStart: weekStart ?? this.weekStart,
        weekEnd: weekEnd ?? this.weekEnd,
        allocatedAmount: allocatedAmount ?? this.allocatedAmount,
        spentAmount: spentAmount ?? this.spentAmount,
        carriedOver: carriedOver ?? this.carriedOver,
        surplusAction: surplusAction ?? this.surplusAction,
        categoryName: categoryName ?? this.categoryName,
        categoryIcon: categoryIcon ?? this.categoryIcon,
        categoryColor: categoryColor ?? this.categoryColor,
      );
}

/// Utilidades de semanas
class WeekUtils {
  /// Devuelve el lunes de la semana que contiene [date]
  static DateTime weekStart(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    return d.subtract(Duration(days: d.weekday - 1));
  }

  /// Devuelve el domingo de la semana que contiene [date]
  static DateTime weekEnd(DateTime date) {
    return weekStart(date).add(const Duration(days: 6));
  }

  /// Etiqueta legible: "Semana 23 May – 29 May"
  static String weekLabel(DateTime start, DateTime end) {
    final months = [
      '', 'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    return '${start.day} ${months[start.month]} – ${end.day} ${months[end.month]}';
  }
}