// lib/login/services/setup_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:mssql_connection/mssql_connection.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user_model.dart';
import 'database_service.dart';

class SetupService {
  MssqlConnection? _connection;
  final DatabaseService _dbService = DatabaseService();

  // Validar conexión al servidor
  Future<SetupResult> validateConnection({
    required String ip,
    required String port,
    required String database,
    required String username,
    required String password,
  }) async {
    try {
      _connection = MssqlConnection.getInstance();

      final connected = await _connection!.connect(
        ip: ip,
        port: port,
        databaseName: database,
        username: username,
        password: password,
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () => false,
      );

      if (!connected) {
        return SetupResult(
          success: false,
          message: 'No se pudo conectar al servidor. Verifique los datos.',
        );
      }

      return SetupResult(
        success: true,
        message: 'Conexión validada correctamente',
      );
    } catch (e) {
      return SetupResult(
        success: false,
        message: 'Error al conectar: ${e.toString()}',
      );
    }
  }

  // Validar usuario en SQL Server
  Future<UserValidationResult> validateUserInServer(
      String usuario,
      String pass,
      ) async {
    if (_connection == null) {
      return UserValidationResult(
        success: false,
        message: 'No hay conexión al servidor',
      );
    }

    try {
      final query = '''
        SELECT nombre1, apellido1, apellido2, pass, usuario, titulo_abr, estado 
        FROM data_users 
        WHERE usuario = '$usuario' AND pass = '$pass'
      ''';

      final resultJson = await _connection!.getData(query).timeout(
        const Duration(seconds: 15),
      );

      if (resultJson.isEmpty || resultJson == '[]') {
        return UserValidationResult(
          success: false,
          message: 'Usuario o contraseña incorrecta',
        );
      }

      final List<dynamic> result = jsonDecode(resultJson);

      if (result.isEmpty) {
        return UserValidationResult(
          success: false,
          message: 'Usuario o contraseña incorrecta',
        );
      }

      final userData = UserModel.fromMap(Map<String, dynamic>.from(result.first));

      if (!userData.isActive) {
        return UserValidationResult(
          success: false,
          message: 'Usuario inactivo. Contacte al administrador.',
        );
      }

      return UserValidationResult(
        success: true,
        message: 'Usuario validado correctamente',
        userData: userData,
      );
    } catch (e) {
      return UserValidationResult(
        success: false,
        message: 'Error validando usuario: ${e.toString()}',
      );
    }
  }

  // Guardar usuario autenticado en SQLite
  Future<SetupResult> saveAuthenticatedUser(UserModel userData) async {
    try {
      final db = await _dbService.createUsersDatabase();

      // Limpiar e insertar solo este usuario
      await db.delete('usuarios');
      await db.insert('usuarios', userData.toMap());
      await db.close();

      // Guardar en SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('logged_user', userData.usuario);
      await prefs.setString('logged_user_nombre', userData.fullName);
      await prefs.setString('logged_user_titulo', userData.tituloAbr);
      await prefs.setBool('auto_login_enabled', true);

      return SetupResult(
        success: true,
        message: 'Usuario guardado exitosamente',
      );
    } catch (e) {
      return SetupResult(
        success: false,
        message: 'Error guardando usuario: ${e.toString()}',
      );
    }
  }

  // Descargar datos de precarga
  Future<SetupResult> downloadPrecargaData(
      Function(String message, double progress) onProgress,
      ) async {
    if (_connection == null) {
      return SetupResult(
        success: false,
        message: 'No hay conexión al servidor',
      );
    }

    Database? db;

    try {
      final queries = {
        'clientes': 'SELECT codigo_cliente, cliente, cliente_id, razonsocial FROM DATA_CLIENTES',
        'plantas': 'SELECT cliente_id, codigo_planta, planta_id, dep, dep_id, planta, dir FROM DATA_PLANTAS',
        'balanzas': 'SELECT * FROM DATA_EQUIPOS_BALANZAS',
        'inf': 'SELECT * FROM DATA_EQUIPOS',
        'equipamientos': 'SELECT * FROM DATA_EQUIPOS_CAL',
        'servicios': 'SELECT * FROM DATA_SERVICIOS_LEC',
      };

      onProgress('Preparando base de datos...', 0.55);

      final dbPath = await getDatabasesPath();
      final precargaDbPath = join(dbPath, 'precarga_database.db');

      // Eliminar base de datos existente para empezar limpio
      if (await databaseExists(precargaDbPath)) {
        await deleteDatabase(precargaDbPath);
      }

      db = await openDatabase(
        precargaDbPath,
        version: 1,
        onCreate: (db, version) async {
          await _dbService.createPrecargaTables(db);
        },
      );

      int tableIndex = 0;
      final totalTables = queries.length;

      for (var entry in queries.entries) {
        final tableName = entry.key;
        final query = entry.value;

        onProgress(
            'Descargando $tableName...',
            0.6 + (0.3 * tableIndex / totalTables)
        );

        // Ejecutar query
        final resultJson = await _connection!.getData(query).timeout(
          const Duration(seconds: 90),
        );

        if (resultJson.isEmpty || resultJson == '[]') {
          print('⚠️ Tabla $tableName sin datos o vacía');
          tableIndex++;
          continue;
        }

        final List<dynamic> result = jsonDecode(resultJson);
        print('✅ Tabla $tableName: ${result.length} registros descargados');

        if (result.isEmpty) {
          tableIndex++;
          continue;
        }

        onProgress(
            'Guardando $tableName (${result.length} registros)...',
            0.6 + (0.3 * tableIndex / totalTables)
        );

        // Usar transacción para inserción masiva más rápida
        await db.transaction((txn) async {
          final batch = txn.batch();

          for (var item in result) {
            final itemMap = Map<String, dynamic>.from(item);
            final rowData = _prepareRowData(tableName, itemMap);

            if (rowData != null) {
              batch.insert(
                tableName,
                rowData,
                conflictAlgorithm: ConflictAlgorithm.replace,
              );
            }
          }

          await batch.commit(noResult: true);
        });

        print('✅ Tabla $tableName: ${result.length} registros guardados');
        tableIndex++;
      }

      // Verificar datos guardados
      onProgress('Verificando datos guardados...', 0.95);
      await _verifyDownloadedData(db);

      await db.close();

      return SetupResult(
        success: true,
        message: 'Datos de precarga descargados exitosamente',
      );
    } catch (e) {
      print('❌ Error en downloadPrecargaData: $e');
      if (db != null && db.isOpen) {
        await db.close();
      }
      return SetupResult(
        success: false,
        message: 'Error descargando datos: ${e.toString()}',
      );
    }
  }

  // Preparar datos según la tabla
  Map<String, dynamic>? _prepareRowData(String table, Map<String, dynamic> data) {
    try {
      switch (table) {
        case 'clientes':
          return {
            'codigo_cliente': data['codigo_cliente']?.toString() ?? '',
            'cliente_id': data['cliente_id']?.toString() ?? '',
            'cliente': data['cliente']?.toString() ?? '',
            'razonsocial': data['razonsocial']?.toString() ?? '',
          };

        case 'plantas':
          final plantaId = data['planta_id']?.toString() ?? '';
          final depId = data['dep_id']?.toString() ?? '';
          return {
            'planta': data['planta']?.toString() ?? '',
            'planta_id': plantaId,
            'cliente_id': data['cliente_id']?.toString() ?? '',
            'dep_id': depId,
            'codigo_planta': data['codigo_planta']?.toString() ?? '',
            'dep': data['dep']?.toString() ?? '',
            'dir': data['dir']?.toString() ?? '',
          };

        case 'balanzas':
          return {
            'cod_metrica': data['cod_metrica']?.toString() ?? '',
            'serie': data['serie']?.toString() ?? '',
            'unidad': data['unidad']?.toString() ?? '',
            'n_celdas': data['n_celdas']?.toString() ?? '',
            'cap_max1': data['cap_max1']?.toString() ?? '',
            'd1': data['d1']?.toString() ?? '',
            'e1': data['e1']?.toString() ?? '',
            'dec1': data['dec1']?.toString() ?? '',
            'cap_max2': data['cap_max2']?.toString() ?? '',
            'd2': data['d2']?.toString() ?? '',
            'e2': data['e2']?.toString() ?? '',
            'dec2': data['dec2']?.toString() ?? '',
            'cap_max3': data['cap_max3']?.toString() ?? '',
            'd3': data['d3']?.toString() ?? '',
            'e3': data['e3']?.toString() ?? '',
            'dec3': data['dec3']?.toString() ?? '',
            'categoria': data['categoria']?.toString() ?? '',
          };

        case 'inf':
          return {
            'cod_interno': data['cod_interno']?.toString() ?? '',
            'cod_metrica': data['cod_metrica']?.toString() ?? '',
            'instrumento': data['instrumento']?.toString() ?? '',
            'tipo_instrumento': data['tipo_instrumento']?.toString() ?? '',
            'marca': data['marca']?.toString() ?? '',
            'modelo': data['modelo']?.toString() ?? '',
            'serie': data['serie']?.toString() ?? '',
            'estado': data['estado']?.toString() ?? '',
            'detalles': data['detalles']?.toString() ?? '',
            'ubicacion': data['ubicacion']?.toString() ?? '',
          };

        case 'equipamientos':
          return {
            'cod_instrumento': data['cod_instrumento']?.toString() ?? '',
            'instrumento': data['instrumento']?.toString() ?? '',
            'cert_fecha': data['cert_fecha']?.toString() ?? '',
            'ente_calibrador': data['ente_calibrador']?.toString() ?? '',
            'estado': data['estado']?.toString() ?? '',
          };

        case 'servicios':
          final servicioData = <String, dynamic>{
            'cod_metrica': data['cod_metrica']?.toString() ?? '',
            'seca': data['seca']?.toString() ?? '',
            'reg_fecha': data['reg_fecha']?.toString() ?? '',
            'reg_usuario': data['reg_usuario']?.toString() ?? '',
            'exc': data['exc']?.toString() ?? '',
          };

          // Agregar campos rep dinámicamente
          for (int i = 1; i <= 30; i++) {
            final key = 'rep$i';
            servicioData[key] = data[key]?.toString() ?? '';
          }

          // Agregar campos lin dinámicamente
          for (int i = 1; i <= 60; i++) {
            final key = 'lin$i';
            servicioData[key] = data[key]?.toString() ?? '';
          }

          return servicioData;

        default:
          print('⚠️ Tabla desconocida: $table');
          return null;
      }
    } catch (e) {
      print('❌ Error preparando datos para tabla $table: $e');
      return null;
    }
  }

  // Verificar datos descargados
  Future<void> _verifyDownloadedData(Database db) async {
    final tables = ['clientes', 'plantas', 'balanzas', 'inf', 'equipamientos', 'servicios'];

    print('\n📊 VERIFICACIÓN DE DATOS DESCARGADOS:');
    print('═' * 50);

    for (var table in tables) {
      try {
        final count = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM $table')
        ) ?? 0;
        print('✓ $table: $count registros');
      } catch (e) {
        print('✗ $table: ERROR - $e');
      }
    }
    print('═' * 50 + '\n');
  }

  // Guardar configuración
  Future<void> saveConfiguration({
    required String ip,
    required String port,
    required String database,
    required String dbUser,
    required String dbPass,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('ip', ip);
    await prefs.setString('port', port);
    await prefs.setString('database', database);
    await prefs.setString('dbuser', dbUser);
    await prefs.setString('dbpass', dbPass);
    await prefs.setBool('setup_completed', true);
    await prefs.setString('setup_date', DateTime.now().toIso8601String());
    await prefs.setString('lastUpdate', DateTime.now().toIso8601String());
  }

  // Desconectar
  Future<void> disconnect() async {
    await _connection?.disconnect();
  }
}

class SetupResult {
  final bool success;
  final String message;

  SetupResult({required this.success, required this.message});
}

class UserValidationResult extends SetupResult {
  final UserModel? userData;

  UserValidationResult({
    required bool success,
    required String message,
    this.userData,
  }) : super(success: success, message: message);
}