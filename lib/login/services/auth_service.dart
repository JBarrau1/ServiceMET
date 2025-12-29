// lib/login/services/auth_service.dart

// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:mssql_connection/mssql_connection.dart';
import '../models/user_model.dart';

class AuthService {
  MssqlConnection? _connection;

  Future<bool> userExists(String usuario) async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'usuarios.db');

      final dbExists = await databaseExists(path);
      if (!dbExists) return false;

      final db = await openDatabase(path);
      final results = await db.query(
        'usuarios',
        where: 'usuario = ?',
        whereArgs: [usuario],
        limit: 1,
      );
      await db.close();

      return results.isNotEmpty;
    } catch (e) {
      print('❌ Error verificando usuario: $e');
      return false;
    }
  }

  Future<Map<String, String>?> _getConnectionCredentials() async {
    final prefs = await SharedPreferences.getInstance();

    final ip = prefs.getString('ip');
    final port = prefs.getString('port');
    final database = prefs.getString('database');
    final dbUser = prefs.getString('dbuser');
    final dbPass = prefs.getString('dbpass');

    if (ip == null ||
        port == null ||
        database == null ||
        dbUser == null ||
        dbPass == null) {
      return null;
    }

    return {
      'ip': ip,
      'port': port,
      'database': database,
      'username': dbUser,
      'password': dbPass,
    };
  }

  // ✅ NUEVO: Conectar al servidor
  Future<bool> _connectToServer() async {
    final credentials = await _getConnectionCredentials();
    if (credentials == null) return false;

    try {
      _connection = MssqlConnection.getInstance();

      final connected = await _connection!
          .connect(
            ip: credentials['ip']!,
            port: credentials['port']!,
            databaseName: credentials['database']!,
            username: credentials['username']!,
            password: credentials['password']!,
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => false,
          );

      return connected;
    } catch (e) {
      print('❌ Error conectando: $e');
      return false;
    }
  }

  // ✅ NUEVO: Validar usuario en SQL Server
  Future<UserValidationResult> _validateUserInServer(
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

      final userData =
          UserModel.fromMap(Map<String, dynamic>.from(result.first));

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

  // ✅ NUEVO: Guardar usuario en SQLite (sin eliminar anteriores)
  Future<bool> _saveUserToDatabase(UserModel userData) async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'usuarios.db');

      final db = await openDatabase(
        path,
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE usuarios (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              nombre1 TEXT,
              apellido1 TEXT,
              apellido2 TEXT,
              pass TEXT,
              usuario TEXT UNIQUE,
              titulo_abr TEXT,
              estado TEXT,
              fecha_guardado TEXT
            )
          ''');
        },
      );

      // Insertar o actualizar usuario
      await db.insert(
        'usuarios',
        userData.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      await db.close();
      return true;
    } catch (e) {
      print('❌ Error guardando usuario: $e');
      return false;
    }
  }

  // ✅ NUEVO: Obtener lista de usuarios guardados
  Future<List<UserModel>> getSavedUsers() async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'usuarios.db');

      final dbExists = await databaseExists(path);
      if (!dbExists) return [];

      final db = await openDatabase(path);
      final results =
          await db.query('usuarios', orderBy: 'fecha_guardado DESC');
      await db.close();

      return results.map((map) => UserModel.fromMap(map)).toList();
    } catch (e) {
      print('❌ Error obteniendo usuarios: $e');
      return [];
    }
  }

  // Cargar preferencias guardadas
  Future<Map<String, dynamic>> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'savedUser': prefs.getString('logged_user'),
      'savedUserFullName': prefs.getString('logged_user_nombre'),
      'autoLoginEnabled': prefs.getBool('auto_login_enabled') ?? false,
      'isFirstLogin': prefs.getBool('is_first_login') ?? true,
    };
  }

  // Helper: Obtener usuario guardado
  Future<String?> _getSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('logged_user');
  }

  // Helper: Guardar usuario logueado
  Future<void> _saveLoggedUser(UserModel userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('logged_user', userData.usuario);
    await prefs.setString('logged_user_nombre', userData.fullName);
  }

  // ✅ MODIFICADO: Login con validación local Y remota
  Future<LoginResult> login({
    String? usuario,
    required String password,
    bool isChangingUser = false,
  }) async {
    final user = usuario ?? await _getSavedUser();

    if (user == null || user.isEmpty) {
      return LoginResult(success: false, message: 'Usuario no encontrado');
    }

    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'usuarios.db');

      final dbExists = await databaseExists(path);
      if (!dbExists) {
        return LoginResult(
          success: false,
          message: 'Base de datos de usuarios no existe',
        );
      }

      final db = await openDatabase(path);

      // 1. Buscar usuario localmente
      final results = await db.query(
        'usuarios',
        where: 'usuario = ? AND pass = ?',
        whereArgs: [user, password],
      );

      await db.close();

      // 2. Si el usuario existe localmente
      if (results.isNotEmpty) {
        final userData = UserModel.fromMap(results.first);

        if (!userData.isActive) {
          return LoginResult(
            success: false,
            message: 'Usuario inactivo. Contacte al administrador.',
          );
        }

        await _clearDemoMode();
        await _saveLoggedUser(userData);

        return LoginResult(success: true, message: 'Inicio de sesión exitoso');
      }

      // 3. Si no existe localmente Y está cambiando usuario, validar en servidor
      if (isChangingUser) {
        return LoginResult(
          success: false,
          message: 'Usuario no encontrado localmente. Use "Agregar Usuario"',
        );
      }

      return LoginResult(success: false, message: 'Credenciales incorrectas');
    } catch (e) {
      return LoginResult(success: false, message: 'Error: ${e.toString()}');
    }
  }

  // ✅ NUEVO: Agregar nuevo usuario (validando en servidor)
  Future<LoginResult> addNewUser({
    required String usuario,
    required String password,
  }) async {
    try {
      // 1. Conectar al servidor
      final connected = await _connectToServer();
      if (!connected) {
        return LoginResult(
          success: false,
          message: 'No se pudo conectar al servidor',
        );
      }

      // 2. Validar usuario en servidor
      final validation = await _validateUserInServer(usuario, password);

      // 3. Desconectar
      await _connection?.disconnect();

      if (!validation.success || validation.userData == null) {
        return LoginResult(
          success: false,
          message: validation.message,
        );
      }

      // 4. Guardar usuario en SQLite
      final saved = await _saveUserToDatabase(validation.userData!);

      if (!saved) {
        return LoginResult(
          success: false,
          message: 'Error guardando usuario localmente',
        );
      }

      // 5. Marcar como usuario activo
      await _clearDemoMode();
      await _saveLoggedUser(validation.userData!);

      return LoginResult(
        success: true,
        message: 'Usuario agregado y autenticado exitosamente',
      );
    } catch (e) {
      await _connection?.disconnect();
      return LoginResult(
        success: false,
        message: 'Error: ${e.toString()}',
      );
    }
  }

  // Login en modo demo
  Future<void> loginDemo() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('modoDemo', true);
  }

  // Limpiar modo demo
  Future<void> _clearDemoMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('modoDemo', false);
  }

  // Cambiar usuario (solo deshabilita auto-login)
  Future<void> changeUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_login_enabled', false);
  }

  // Reconfigurar aplicación
  Future<void> reconfigure() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('setup_completed');
    await prefs.remove('setup_date');
    await prefs.remove('auto_login_enabled');
    await prefs.remove('logged_user');
    await prefs.remove('logged_user_nombre');
    await prefs.remove('is_first_login');
  }

  // ✅ NUEVO: Eliminar usuario guardado
  Future<bool> deleteUser(String usuario) async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'usuarios.db');

      final db = await openDatabase(path);
      await db.delete('usuarios', where: 'usuario = ?', whereArgs: [usuario]);

      // ✅ Verificar si quedan usuarios
      final remainingUsers = await db.query('usuarios');
      await db.close();

      // ✅ Si no quedan usuarios, limpiar SharedPreferences
      if (remainingUsers.isEmpty) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('logged_user');
        await prefs.remove('logged_user_nombre');
        await prefs.setBool('auto_login_enabled', false);
        print('✅ Todos los usuarios eliminados, SharedPreferences limpiado');
      }

      return true;
    } catch (e) {
      print('❌ Error eliminando usuario: $e');
      return false;
    }
  }
}

class LoginResult {
  final bool success;
  final String message;

  LoginResult({required this.success, required this.message});
}

class UserValidationResult extends LoginResult {
  final UserModel? userData;

  UserValidationResult({
    required super.success,
    required super.message,
    this.userData,
  });
}
