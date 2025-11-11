// lib/login/services/auth_service.dart

import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user_model.dart';

class AuthService {
  // Cargar preferencias guardadas
  Future<Map<String, dynamic>> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'savedUser': prefs.getString('logged_user'),
      'savedUserFullName': prefs.getString('logged_user_nombre'),
      'autoLoginEnabled': prefs.getBool('auto_login_enabled') ?? false,
    };
  }

  // Intentar auto-login
  Future<bool> attemptAutoLogin(String? savedUser) async {
    if (savedUser == null || savedUser.isEmpty) return false;

    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'usuarios.db');

      final dbExists = await databaseExists(path);
      if (!dbExists) return false;

      final db = await openDatabase(path);

      final results = await db.query(
        'usuarios',
        where: 'usuario = ?',
        whereArgs: [savedUser],
      );

      await db.close();

      if (results.isNotEmpty) {
        final userData = UserModel.fromMap(results.first);

        if (userData.isActive) {
          await _clearDemoMode();
          return true;
        }
      }

      return false;
    } catch (e) {
      print('❌ Error en auto-login: $e');
      return false;
    }
  }

  // Login manual con contraseña
  Future<LoginResult> login(String? savedUser, String password) async {
    if (savedUser == null || savedUser.isEmpty) {
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

      final results = await db.query(
        'usuarios',
        where: 'usuario = ? AND pass = ?',
        whereArgs: [savedUser, password],
      );

      await db.close();

      if (results.isEmpty) {
        return LoginResult(success: false, message: 'Contraseña incorrecta');
      }

      final userData = UserModel.fromMap(results.first);

      if (!userData.isActive) {
        return LoginResult(
          success: false,
          message: 'Usuario inactivo. Contacte al administrador.',
        );
      }

      await _clearDemoMode();
      return LoginResult(success: true, message: 'Inicio de sesión exitoso');

    } catch (e) {
      return LoginResult(success: false, message: 'Error: ${e.toString()}');
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

  // Cambiar usuario (limpiar datos)
  Future<void> changeUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auto_login_enabled');
    await prefs.remove('logged_user');
    await prefs.remove('logged_user_nombre');
  }

  // Reconfigurar aplicación
  Future<void> reconfigure() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('setup_completed');
    await prefs.remove('setup_date');
    await prefs.remove('auto_login_enabled');
    await prefs.remove('logged_user');
    await prefs.remove('logged_user_nombre');
  }
}

class LoginResult {
  final bool success;
  final String message;

  LoginResult({required this.success, required this.message});
}