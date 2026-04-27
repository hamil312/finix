// filepath: lib\utils\database_connection.dart
import 'dart:async';
import 'package:postgres/postgres.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class DatabaseConnection {
  static DatabaseConnection? _instance;
  late Connection _connection;
  bool _isConnected = false;

  // Configuración de la base de datos desde variables de entorno
  late final String host;
  late final int port;
  late final String database;
  late final String username;
  late final String password;

  DatabaseConnection._() {
    // Cargar configuración desde .env
    host = dotenv.env['DB_HOST'] ?? 'localhost';
    port = int.tryParse(dotenv.env['DB_PORT'] ?? '5432') ?? 5432;
    database = dotenv.env['DB_NAME'] ?? 'finanzapp';
    username = dotenv.env['DB_USER'] ?? 'postgres';
    password = dotenv.env['DB_PASSWORD'] ?? '';
  }

  static DatabaseConnection get instance {
    _instance ??= DatabaseConnection._();
    return _instance!;
  }

  Future<void> connect() async {
    if (_isConnected) return;

    try {
      _connection = await Connection.open(
        Endpoint(
          host: host,
          port: port,
          database: database,
          username: username,
          password: password,
        ),
        settings: ConnectionSettings(
          sslMode: SslMode.disable,
        ),
      );
      _isConnected = true;
      print('✅ Conectado a PostgreSQL');
    } catch (e) {
      print('❌ Error al conectar a PostgreSQL: $e');
      rethrow;
    }
  }

  Future<void> disconnect() async {
    if (!_isConnected) return;
    await _connection.close();
    _isConnected = false;
    print('🔌 Desconectado de PostgreSQL');
  }

  bool get isConnected => _isConnected;
  Connection get connection => _connection;

  // Métodos genéricos para CRUD
  Future<List<Map<String, dynamic>>> query(String sql, [List<dynamic>? parameters]) async {
    final result = await _connection.execute(
      Sql.named(sql),
      parameters: parameters ?? [],
    );
    
    // Convertir el resultado a una lista de mapas
    final List<Map<String, dynamic>> rows = [];
    for (final row in result) {
      final Map<String, dynamic> rowMap = {};
      for (int i = 0; i < result.schema.columns.length; i++) {
        final columnName = result.schema.columns[i].columnName;
        if (columnName != null) {
          rowMap[columnName] = row[i];
        }
      }
      rows.add(rowMap);
    }
    return rows;
  }

  Future<int> execute(String sql, [List<dynamic>? parameters]) async {
    final result = await _connection.execute(
      Sql.named(sql),
      parameters: parameters ?? [],
    );
    return result.affectedRows;
  }

  Future<Map<String, dynamic>?> queryOne(String sql, [List<dynamic>? parameters]) async {
    final results = await query(sql, parameters);
    return results.isNotEmpty ? results.first : null;
  }
}