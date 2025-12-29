// lib/login/services/database_debug_helper.dart

// ignore_for_file: avoid_print

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseDebugHelper {
  /// Verifica el estado de la base de datos precarga
  static Future<Map<String, int>> verifyPrecargaDatabase() async {
    final dbPath = await getDatabasesPath();
    final precargaDbPath = join(dbPath, 'precarga_database.db');

    final exists = await databaseExists(precargaDbPath);

    if (!exists) {
      print('❌ Base de datos precarga_database.db NO EXISTE');
      return {};
    }

    print('✅ Base de datos precarga_database.db existe');

    final db = await openDatabase(precargaDbPath);

    final tables = [
      'clientes',
      'plantas',
      'balanzas',
      'inf',
      'equipamientos',
      'servicios'
    ];
    final counts = <String, int>{};

    print('\n📊 CONTEO DE REGISTROS:');
    print('═' * 60);

    for (var table in tables) {
      try {
        final count = Sqflite.firstIntValue(
                await db.rawQuery('SELECT COUNT(*) FROM $table')) ??
            0;

        counts[table] = count;

        final icon = count > 0 ? '✓' : '⚠';
        print('$icon $table: $count registros');

        // Mostrar sample de 1 registro si existe
        if (count > 0) {
          final sample = await db.query(table, limit: 1);
          print('   Sample: ${sample.first.keys.take(3).join(", ")}...');
        }
      } catch (e) {
        print('✗ $table: ERROR - $e');
        counts[table] = -1;
      }
    }

    print('═' * 60);
    print('Total tablas verificadas: ${tables.length}');
    print('Tablas con datos: ${counts.values.where((c) => c > 0).length}\n');

    await db.close();

    return counts;
  }

  /// Verifica datos específicos de una tabla
  static Future<void> inspectTable(String tableName) async {
    final dbPath = await getDatabasesPath();
    final precargaDbPath = join(dbPath, 'precarga_database.db');

    final exists = await databaseExists(precargaDbPath);
    if (!exists) {
      print('❌ Base de datos no existe');
      return;
    }

    final db = await openDatabase(precargaDbPath);

    try {
      print('\n🔍 INSPECCIÓN DE TABLA: $tableName');
      print('═' * 60);

      // Contar registros
      final count = Sqflite.firstIntValue(
              await db.rawQuery('SELECT COUNT(*) FROM $tableName')) ??
          0;
      print('Total de registros: $count');

      if (count == 0) {
        print('⚠️  Tabla vacía');
        await db.close();
        return;
      }

      // Obtener estructura de la tabla
      final columns = await db.rawQuery('PRAGMA table_info($tableName)');
      print('\nColumnas (${columns.length}):');
      for (var col in columns) {
        print('  - ${col['name']} (${col['type']})');
      }

      // Mostrar primeros 3 registros
      print('\nPrimeros 3 registros:');
      final samples = await db.query(tableName, limit: 3);

      for (var i = 0; i < samples.length; i++) {
        print('\nRegistro ${i + 1}:');
        samples[i].forEach((key, value) {
          final displayValue = value.toString().length > 50
              ? '${value.toString().substring(0, 50)}...'
              : value.toString();
          print('  $key: $displayValue');
        });
      }

      print('═' * 60 + '\n');
    } catch (e) {
      print('❌ Error inspeccionando tabla: $e');
    }

    await db.close();
  }

  /// Limpia la base de datos precarga
  static Future<void> clearPrecargaDatabase() async {
    final dbPath = await getDatabasesPath();
    final precargaDbPath = join(dbPath, 'precarga_database.db');

    final exists = await databaseExists(precargaDbPath);
    if (!exists) {
      print('⚠️  Base de datos no existe, nada que limpiar');
      return;
    }

    await deleteDatabase(precargaDbPath);
    print('✅ Base de datos precarga_database.db eliminada');
  }

  /// Exporta estadísticas de la base de datos
  static Future<String> exportDatabaseStats() async {
    final counts = await verifyPrecargaDatabase();

    final buffer = StringBuffer();
    buffer.writeln('ESTADÍSTICAS BASE DE DATOS PRECARGA');
    buffer.writeln('Fecha: ${DateTime.now()}');
    buffer.writeln('=' * 60);

    int totalRecords = 0;
    counts.forEach((table, count) {
      buffer.writeln('$table: $count registros');
      if (count > 0) totalRecords += count;
    });

    buffer.writeln('=' * 60);
    buffer.writeln('TOTAL DE REGISTROS: $totalRecords');

    final stats = buffer.toString();
    print(stats);

    return stats;
  }
}
