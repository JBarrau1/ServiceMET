import 'package:flutter/material.dart';
import '../../../database/app_database.dart';

class CalibrationService {
  final AppDatabase _dbHelper;

  CalibrationService(this._dbHelper);

  Future<double> getD1Value({int? registroId}) async {
    try {
      final db = await _dbHelper.database;

      // Verificar si la tabla existe primero
      final tableExists =
          await _dbHelper.doesTableExist('registros_calibracion');
      if (!tableExists) return 0.1;

      // Si no pasas un ID, tomamos el último registro insertado
      final result = await db.query(
        'registros_calibracion',
        where: registroId != null ? 'id = ?' : null,
        whereArgs: registroId != null ? [registroId] : null,
        columns: ['d1'],
        orderBy: registroId == null ? 'id DESC' : null,
        limit: 1,
      );

      if (result.isNotEmpty && result.first['d1'] != null) {
        return double.tryParse(result.first['d1'].toString()) ?? 0.1;
      }
      return 0.1;
    } catch (e) {
      debugPrint('Error al obtener d1: $e');
      return 0.1;
    }
  }

  Future<double> getPmax1Value() async {
    try {
      final db = await _dbHelper.database;
      final result = await db.query(
        'registros_calibracion',
        columns: ['cap_max1'],
        orderBy: 'id DESC',
        limit: 1,
      );

      if (result.isNotEmpty && result.first['cap_max1'] != null) {
        return double.tryParse(result.first['cap_max1'].toString()) ?? 0.0;
      }
      return 0.0;
    } catch (e) {
      debugPrint('Error al obtener pmax1: $e');
      return 0.0;
    }
  }

  Future<void> saveEccentricityData(Map<String, dynamic> data) async {
    try {
      final db = await _dbHelper.database;
      await db.update(
        'registros_calibracion',
        data,
        where: 'id = ?',
        whereArgs: [1],
      );
    } catch (e) {
      debugPrint('Error al guardar datos de excentricidad: $e');
      rethrow;
    }
  }

  Future<void> saveRepeatabilityData(Map<String, dynamic> data) async {
    try {
      final db = await _dbHelper.database;
      await db.update(
        'registros_calibracion',
        data,
        where: 'id = ?',
        whereArgs: [1],
      );
    } catch (e) {
      debugPrint('Error al guardar datos de repetibilidad: $e');
      rethrow;
    }
  }

  Future<void> saveLinearityData(Map<String, dynamic> data) async {
    try {
      final db = await _dbHelper.database;
      await db.update(
        'registros_calibracion',
        data,
        where: 'id = ?',
        whereArgs: [1],
      );
    } catch (e) {
      debugPrint('Error al guardar datos de linealidad: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getLastServiceData() async {
    try {
      final db = await _dbHelper.database;
      final result = await db.query(
        'registros_calibracion',
        orderBy: 'id DESC',
        limit: 1,
      );

      if (result.isNotEmpty) {
        return result.first;
      }
      return null;
    } catch (e) {
      debugPrint('Error al obtener último servicio: $e');
      return null;
    }
  }
}
