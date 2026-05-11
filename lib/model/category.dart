import '../utils/type_converter.dart';

class Category {
  final int? id;
  final String name;
  final String type; // 'expense' | 'income'
  final double defaultAllocationPercent;
  final bool isCustom;      // true = creada por el usuario
  final int? userId;        // null = categoría del sistema
  final String icon;        // nombre de MaterialIcon, ej. 'restaurant'
  final String colorHex;    // ej. '#F44336'

  Category({
    this.id,
    required this.name,
    required this.type,
    required this.defaultAllocationPercent,
    this.isCustom = false,
    this.userId,
    this.icon = 'category',
    this.colorHex = '#607D8B',
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'type': type,
        'default_allocation_percent': defaultAllocationPercent,
        'is_custom': isCustom,
        'user_id': userId,
        'icon': icon,
        'color_hex': colorHex,
      };

  factory Category.fromMap(Map<String, dynamic> map) => Category(
        id: TypeConverter.toIntOrNull(map['id']),
        name: TypeConverter.toStringi(map['name']),
        type: TypeConverter.toStringi(map['type']),
        defaultAllocationPercent:
            TypeConverter.toDouble(map['default_allocation_percent']),
        isCustom: map['is_custom'] as bool? ?? false,
        userId: TypeConverter.toIntOrNull(map['user_id']),
        icon: TypeConverter.toStringi(map['icon'].toString().isNotEmpty ? map['icon'] : 'category'),
        colorHex: TypeConverter.toStringi(map['color_hex'].toString().isNotEmpty ? map['color_hex'] : '#607D8B'),
      );

  Category copyWith({
    int? id,
    String? name,
    String? type,
    double? defaultAllocationPercent,
    bool? isCustom,
    int? userId,
    String? icon,
    String? colorHex,
  }) =>
      Category(
        id: id ?? this.id,
        name: name ?? this.name,
        type: type ?? this.type,
        defaultAllocationPercent:
            defaultAllocationPercent ?? this.defaultAllocationPercent,
        isCustom: isCustom ?? this.isCustom,
        userId: userId ?? this.userId,
        icon: icon ?? this.icon,
        colorHex: colorHex ?? this.colorHex,
      );

  /// Convierte colorHex a Color de Flutter
  // ignore: import_of_legacy_library_into_null_safe
  // Usar en la UI: CategoryUtils.hexToColor(cat.colorHex)
}

/// Iconos disponibles para categorías personalizadas
class CategoryIcons {
  static const Map<String, String> available = {
    'restaurant': 'Comida',
    'directions_car': 'Transporte',
    'shopping_cart': 'Compras',
    'local_hospital': 'Salud',
    'school': 'Educación',
    'home': 'Hogar',
    'sports_esports': 'Entretenimiento',
    'flight': 'Viajes',
    'fitness_center': 'Deporte',
    'pets': 'Mascotas',
    'phone_android': 'Tecnología',
    'attach_money': 'Finanzas',
    'work': 'Trabajo',
    'child_care': 'Familia',
    'local_cafe': 'Café',
    'nightlife': 'Ocio',
    'category': 'Otro',
  };
}

/// Colores disponibles para categorías personalizadas
class CategoryColors {
  static const List<Map<String, String>> available = [
    {'hex': '#F44336', 'name': 'Rojo'},
    {'hex': '#E91E63', 'name': 'Rosa'},
    {'hex': '#9C27B0', 'name': 'Morado'},
    {'hex': '#3F51B5', 'name': 'Índigo'},
    {'hex': '#2196F3', 'name': 'Azul'},
    {'hex': '#00BCD4', 'name': 'Cian'},
    {'hex': '#009688', 'name': 'Verde azulado'},
    {'hex': '#4CAF50', 'name': 'Verde'},
    {'hex': '#8BC34A', 'name': 'Verde claro'},
    {'hex': '#FFEB3B', 'name': 'Amarillo'},
    {'hex': '#FF9800', 'name': 'Naranja'},
    {'hex': '#795548', 'name': 'Marrón'},
    {'hex': '#607D8B', 'name': 'Gris azulado'},
  ];
}