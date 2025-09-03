import 'dart:io';
import 'package:path/path.dart';
import 'package:service_met/database/app_database.dart';
import 'package:sqflite/sqflite.dart';

class CalibrationRepository {
  final AppDatabase _dbHelper = AppDatabase();

  /// Obtiene los datos de calibración por número de serie (secaValue)
  Future<Map<String, dynamic>> getCalibrationData(String secaValue, String sessionId) async {
    final result = await _dbHelper.getRegistroBySeca(secaValue, sessionId);
    return result ?? {};
  }

  /// Guarda o actualiza los datos de calibración
  Future<void> saveCalibrationData(String secaValue, Map<String, dynamic> data) async {
    // Si la tabla requiere que el número de serie esté incluido en el Map:
    final Map<String, dynamic> newData = {
      'seca': secaValue,
      ...data,
    };

    await _dbHelper.upsertRegistroCalibracion(newData);
  }

  /// Crea una copia de seguridad de la base de datos principal
  Future<void> createBackup(String testType) async {
    final mainPath = join(await getDatabasesPath(), 'metrica_service.db');
    final backupPath = join(await getDatabasesPath(), 'metrica_service_${testType}_backup.db');
    await File(mainPath).copy(backupPath);
  }
}
