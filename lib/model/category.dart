// filepath: lib\model\category.dart
import '../utils/type_converter.dart';

class Category {
  final int? id;
  final String name;
  final String type; // 'expense' o 'income'
  final double defaultAllocationPercent;

  Category({
    this.id,
    required this.name,
    required this.type,
    required this.defaultAllocationPercent,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'default_allocation_percent': defaultAllocationPercent,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: TypeConverter.toIntOrNull(map['id']),
      name: TypeConverter.toStringi(map['name']),
      type: TypeConverter.toStringi(map['type']),
      defaultAllocationPercent: TypeConverter.toDouble(map['default_allocation_percent']),
    );
  }

  Category copyWith({
    int? id,
    String? name,
    String? type,
    double? defaultAllocationPercent,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      defaultAllocationPercent: defaultAllocationPercent ?? this.defaultAllocationPercent,
    );
  }
}