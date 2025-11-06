import 'dart:io';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';


class DatabaseHelperDiagnostico {
  static final DatabaseHelperDiagnostico _instance = DatabaseHelperDiagnostico._internal();
  factory DatabaseHelperDiagnostico() => _instance;
  static Database? _database;
  static bool _isInitializing = false; // ← AGREGADO: Flag para evitar inicializaciones múltiples
  String get tableName => 'diagnostico';

  DatabaseHelperDiagnostico._internal();

  Future<bool> metricaExists(String otst) async {
    return await secaExists(otst);
  }

  Future<Map<String, dynamic>?> getUltimoRegistroPorMetrica(String otst) async {
    return await getUltimoRegistroPorSeca(otst);
  }

  Future<void> upsertRegistro(Map<String, dynamic> registro) async {
    await upsertRegistroRelevamiento(registro);
  }

  Future<Map<String, dynamic>?> getRegistroByCodMetrica(String codMetrica) async {
    try {
      final db = await database;

      final List<Map<String, dynamic>> result = await db.query(
        'diagnostico',
        where: 'cod_metrica = ?',
        whereArgs: [codMetrica],
        orderBy: 'id DESC',
        limit: 1,
      );

      return result.isNotEmpty ? result.first : null;

    } catch (e) {
      debugPrint('Error al buscar registro por codMetrica: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getUltimoRegistroPorSeca(String otst) async {
    try {
      final db = await database;
      final result = await db.query(
        'diagnostico',
        where: 'otst = ?',
        whereArgs: [otst],
        orderBy: 'id DESC',
        limit: 1,
      );
      return result.isNotEmpty ? result.first : null;
    } catch (e) {
      debugPrint('Error al obtener último registro por OTST: $e');
      return null;
    }
  }

  // REEMPLAZAR ESTE MÉTODO COMPLETO
  Future<String> generateSessionId(String otst) async {
    try {
      final db = await database;

      // Buscar el último session_id para este SECA
      final result = await db.rawQuery('''
      SELECT session_id 
      FROM diagnostico 
      WHERE otst = ? 
      ORDER BY session_id DESC 
      LIMIT 1
    ''', [otst]);

      if (result.isEmpty) {
        // Primera sesión para este SECA
        return '0001';
      }

      // Extraer el número del último session_id
      final lastSessionId = result.first['session_id'] as String;
      final lastNumber = int.tryParse(lastSessionId) ?? 0;

      // Generar el siguiente número
      final nextNumber = lastNumber + 1;

      // Formatear con ceros a la izquierda (0001, 0002, etc.)
      return nextNumber.toString().padLeft(4, '0');

    } catch (e) {
      debugPrint('Error generando sessionId: $e');
      // En caso de error, generar uno basado en timestamp
      return DateTime.now().millisecondsSinceEpoch.toString().substring(8);
    }
  }

  Future<List<Map<String, dynamic>>> getAllRegistrosRelevamiento() async {
    try {
      final db = await database;
      return await db.query('diagnostico', orderBy: 'fecha_servicio DESC');
    } catch (e) {
      debugPrint('Error al obtener todos los registros: $e');
      return [];
    }
  }

  Future<bool> secaExists(String seca) async {
    try {
      final db = await database;
      final result = await db.query(
        'diagnostico',
        where: 'otst = ?',
        whereArgs: [seca],
        limit: 1,
      );
      return result.isNotEmpty;
    } catch (e) {
      debugPrint('Error verificando si OTST existe: $e');
      return false;
    }
  }

  Future<bool> doesTableExist(String tableName) async {
    try {
      final db = await database;
      final result = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
          [tableName]);
      return result.isNotEmpty;
    } catch (e) {
      debugPrint('Error verificando si tabla existe: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> getRegistroBySeca(String otst, String sessionId) async {
    try {
      final db = await database;
      final result = await db.query(
        'diagnostico',
        where: 'otst = ? AND session_id = ?',
        whereArgs: [otst, sessionId],
        limit: 1,
      );
      return result.isNotEmpty ? result.first : null;
    } catch (e) {
      debugPrint('Error al obtener registro por OTST y sessionId: $e');
      return null;
    }
  }

  Future<void> upsertRegistroRelevamiento(Map<String, dynamic> registro) async {
    try {
      final db = await database;

      final existing = await db.query(
        'diagnostico',
        where: 'otst = ? AND session_id = ?',
        whereArgs: [registro['otst'], registro['session_id']],
      );

      if (existing.isNotEmpty) {
        await db.update(
          'diagnostico',
          registro,
          where: 'otst = ? AND session_id = ?',
          whereArgs: [registro['otst'], registro['session_id']],
        );
        debugPrint('Registro ACTUALIZADO - OTST: ${registro['otst']}, Session: ${registro['session_id']}');
      } else {
        await db.insert('diagnostico', registro);
        debugPrint('NUEVO registro INSERTADO - OTST: ${registro['otst']}, Session: ${registro['session_id']}');
      }
    } catch (e) {
      debugPrint('Error en upsertRegistroCalibracion: $e');
      rethrow; // Re-lanzar el error para que lo maneje quien llama
    }
  }

  // ← MÉTODO CORREGIDO: Getter de database más robusto
  Future<Database> get database async {
    if (_database != null && _database!.isOpen) {
      return _database!;
    }

    // Evitar múltiples inicializaciones concurrentes
    if (_isInitializing) {
      // Esperar hasta que la inicialización termine
      while (_isInitializing) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
      if (_database != null && _database!.isOpen) {
        return _database!;
      }
    }

    _database = await _initDatabase();
    return _database!;
  }

  // ← MÉTODO CORREGIDO: Inicialización más simple y robusta
  Future<Database> _initDatabase() async {
    if (_isInitializing) {
      throw Exception('Database already initializing');
    }

    _isInitializing = true;

    try {
      String path = join(await getDatabasesPath(), 'diagnostico.db');

      // Crear directorio si no existe
      final directory = Directory(dirname(path));
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      // Abrir/crear la base de datos
      final database = await openDatabase(
        path,
        version: 1,
        onCreate: _onCreate,
        onOpen: (db) {
          debugPrint('Base de datos abierta correctamente: $path');
        },
      );

      return database;
    } catch (e) {
      debugPrint('Error inicializando base de datos: $e');
      rethrow;
    } finally {
      _isInitializing = false;
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    try {
      debugPrint('Creando tabla diagnostico...');

      await db.execute('''
      CREATE TABLE diagnostico (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        --INF CLIENTE Y PERSONAL
        tipo_servicio TEXT DEFAULT '',   
        cliente TEXT DEFAULT '',
        razon_social TEXT DEFAULT '',
        planta TEXT DEFAULT '',
        dir_planta TEXT DEFAULT '',
        dep_planta TEXT DEFAULT '',
        cod_planta TEXT DEFAULT '',
        personal TEXT DEFAULT '',
        otst TEXT DEFAULT '',
        session_id TEXT DEFAULT '',
        
        --INF BALANZA
        foto_balanza TEXT DEFAULT '',
        categoria_balanza TEXT DEFAULT '',
        cod_metrica TEXT DEFAULT '',
        cod_int TEXT DEFAULT '',
        tipo_equipo TEXT DEFAULT '',
        marca TEXT DEFAULT '',
        modelo TEXT DEFAULT '',
        serie TEXT DEFAULT '',
        unidades TEXT DEFAULT '',
        ubicacion TEXT DEFAULT '',
        cap_max1 REAL DEFAULT '',
        d1 REAL DEFAULT '',
        e1 REAL DEFAULT '',
        dec1 REAL DEFAULT '',
        cap_max2 REAL DEFAULT '',
        d2 REAL DEFAULT '',
        e2 REAL DEFAULT '',
        dec2 REAL DEFAULT '',
        cap_max3 REAL DEFAULT '',
        d3 REAL DEFAULT '',
        e3 REAL DEFAULT '',
        dec3 REAL DEFAULT '',
        
        --DATOS SERVICIO
        fecha_servicio TEXT DEFAULT '',
        hora_inicio TEXT DEFAULT '',
        hora_fin TEXT DEFAULT '',
        
        --Comentarios
        comentario_1 TEXT DEFAULT '',
        comentario_2 TEXT DEFAULT '',
        comentario_3 TEXT DEFAULT '',
        comentario_4 TEXT DEFAULT '',
        comentario_5 TEXT DEFAULT '',
        comentario_6 TEXT DEFAULT '',
        comentario_7 TEXT DEFAULT '',
        comentario_8 TEXT DEFAULT '',
        comentario_9 TEXT DEFAULT '',
        comentario_10 TEXT DEFAULT '',
        
        -- Retorno a Cero
        retorno_cero_inicial_valoracion TEXT DEFAULT '',
        retorno_cero_inicial_carga REAL DEFAULT '',
        retorno_cero_inicial_unidad TEXT DEFAULT '',

        -- Excentricidad Inicial
        excentricidad_inicial_tipo_plataforma TEXT DEFAULT '',
        excentricidad_inicial_opcion_prueba TEXT DEFAULT '',
        excentricidad_inicial_carga TEXT DEFAULT '',
        excentricidad_inicial_ruta_imagen TEXT DEFAULT '',
        excentricidad_inicial_cantidad_posiciones TEXT DEFAULT '',
        excentricidad_inicial_pos1_numero TEXT DEFAULT '',
        excentricidad_inicial_pos1_indicacion TEXT DEFAULT '',
        excentricidad_inicial_pos1_retorno TEXT DEFAULT '',
        excentricidad_inicial_pos1_error TEXT DEFAULT '',
        excentricidad_inicial_pos2_numero TEXT DEFAULT '',
        excentricidad_inicial_pos2_indicacion TEXT DEFAULT '',
        excentricidad_inicial_pos2_retorno TEXT DEFAULT '',
        excentricidad_inicial_pos2_error TEXT DEFAULT '',
        excentricidad_inicial_pos3_numero TEXT DEFAULT '',
        excentricidad_inicial_pos3_indicacion TEXT DEFAULT '',
        excentricidad_inicial_pos3_retorno TEXT DEFAULT '',
        excentricidad_inicial_pos3_error TEXT DEFAULT '',
        excentricidad_inicial_pos4_numero TEXT DEFAULT '',
        excentricidad_inicial_pos4_indicacion TEXT DEFAULT '',
        excentricidad_inicial_pos4_retorno TEXT DEFAULT '',
        excentricidad_inicial_pos4_error TEXT DEFAULT '',
        excentricidad_inicial_pos5_numero TEXT DEFAULT '',
        excentricidad_inicial_pos5_indicacion TEXT DEFAULT '',
        excentricidad_inicial_pos5_retorno TEXT DEFAULT '',
        excentricidad_inicial_pos5_error TEXT DEFAULT '',
        excentricidad_inicial_pos6_numero TEXT DEFAULT '',
        excentricidad_inicial_pos6_indicacion TEXT DEFAULT '',
        excentricidad_inicial_pos6_retorno TEXT DEFAULT '',
        excentricidad_inicial_pos6_error TEXT DEFAULT '',
        
        --repetibilidad
        repetibilidad_inicial_cantidad_cargas TEXT DEFAULT '',
        repetibilidad_inicial_cantidad_pruebas TEXT DEFAULT '',

        -- IDA
        excentricidad_inicial_punto1_ida_numero TEXT DEFAULT '',
        excentricidad_inicial_punto1_ida_indicacion TEXT DEFAULT '',
        excentricidad_inicial_punto1_ida_retorno TEXT DEFAULT '',

        excentricidad_inicial_punto2_ida_numero TEXT DEFAULT '',
        excentricidad_inicial_punto2_ida_indicacion TEXT DEFAULT '',
        excentricidad_inicial_punto2_ida_retorno TEXT DEFAULT '',

        excentricidad_inicial_punto3_ida_numero TEXT DEFAULT '',
        excentricidad_inicial_punto3_ida_indicacion TEXT DEFAULT '',
        excentricidad_inicial_punto3_ida_retorno TEXT DEFAULT '',

        excentricidad_inicial_punto4_ida_numero TEXT DEFAULT '',
        excentricidad_inicial_punto4_ida_indicacion TEXT DEFAULT '',
        excentricidad_inicial_punto4_ida_retorno TEXT DEFAULT '',

        excentricidad_inicial_punto5_ida_numero TEXT DEFAULT '',
        excentricidad_inicial_punto5_ida_indicacion TEXT DEFAULT '',
        excentricidad_inicial_punto5_ida_retorno TEXT DEFAULT '',

        excentricidad_inicial_punto6_ida_numero TEXT DEFAULT '',
        excentricidad_inicial_punto6_ida_indicacion TEXT DEFAULT '',
        excentricidad_inicial_punto6_ida_retorno TEXT DEFAULT '',

        -- VUELTA
        excentricidad_inicial_punto7_vuelta_numero TEXT DEFAULT '',
        excentricidad_inicial_punto7_vuelta_indicacion TEXT DEFAULT '',
        excentricidad_inicial_punto7_vuelta_retorno TEXT DEFAULT '',

        excentricidad_inicial_punto8_vuelta_numero TEXT DEFAULT '',
        excentricidad_inicial_punto8_vuelta_indicacion TEXT DEFAULT '',
        excentricidad_inicial_punto8_vuelta_retorno TEXT DEFAULT '',

        excentricidad_inicial_punto9_vuelta_numero TEXT DEFAULT '',
        excentricidad_inicial_punto9_vuelta_indicacion TEXT DEFAULT '',
        excentricidad_inicial_punto9_vuelta_retorno TEXT DEFAULT '',

        excentricidad_inicial_punto10_vuelta_numero TEXT DEFAULT '',
        excentricidad_inicial_punto10_vuelta_indicacion TEXT DEFAULT '',
        excentricidad_inicial_punto10_vuelta_retorno TEXT DEFAULT '',

        excentricidad_inicial_punto11_vuelta_numero TEXT DEFAULT '',
        excentricidad_inicial_punto11_vuelta_indicacion TEXT DEFAULT '',
        excentricidad_inicial_punto11_vuelta_retorno TEXT DEFAULT '',

        excentricidad_inicial_punto12_vuelta_numero TEXT DEFAULT '',
        excentricidad_inicial_punto12_vuelta_indicacion TEXT DEFAULT '',
        excentricidad_inicial_punto12_vuelta_retorno TEXT DEFAULT '',
        
        -- Carga 1
        repetibilidad_inicial_carga1_valor TEXT DEFAULT '',
        repetibilidad_inicial_carga1_prueba1_indicacion TEXT DEFAULT '',
        repetibilidad_inicial_carga1_prueba1_retorno TEXT DEFAULT '',
        repetibilidad_inicial_carga1_prueba2_indicacion TEXT DEFAULT '',
        repetibilidad_inicial_carga1_prueba2_retorno TEXT DEFAULT '',
        repetibilidad_inicial_carga1_prueba3_indicacion TEXT DEFAULT '',
        repetibilidad_inicial_carga1_prueba3_retorno TEXT DEFAULT '',
        repetibilidad_inicial_carga1_prueba4_indicacion TEXT DEFAULT '',
        repetibilidad_inicial_carga1_prueba4_retorno TEXT DEFAULT '',
        repetibilidad_inicial_carga1_prueba5_indicacion TEXT DEFAULT '',
        repetibilidad_inicial_carga1_prueba5_retorno TEXT DEFAULT '',
        repetibilidad_inicial_carga1_prueba6_indicacion TEXT DEFAULT '',
        repetibilidad_inicial_carga1_prueba6_retorno TEXT DEFAULT '',
        repetibilidad_inicial_carga1_prueba7_indicacion TEXT DEFAULT '',
        repetibilidad_inicial_carga1_prueba7_retorno TEXT DEFAULT '',
        repetibilidad_inicial_carga1_prueba8_indicacion TEXT DEFAULT '',
        repetibilidad_inicial_carga1_prueba8_retorno TEXT DEFAULT '',
        repetibilidad_inicial_carga1_prueba9_indicacion TEXT DEFAULT '',
        repetibilidad_inicial_carga1_prueba9_retorno TEXT DEFAULT '',
        repetibilidad_inicial_carga1_prueba10_indicacion TEXT DEFAULT '',
        repetibilidad_inicial_carga1_prueba10_retorno TEXT DEFAULT '',
        
        -- Carga 2
        repetibilidad_inicial_carga2_valor TEXT DEFAULT '',
        repetibilidad_inicial_carga2_prueba1_indicacion TEXT DEFAULT '',
        repetibilidad_inicial_carga2_prueba1_retorno TEXT DEFAULT '',
        repetibilidad_inicial_carga2_prueba2_indicacion TEXT DEFAULT '',
        repetibilidad_inicial_carga2_prueba2_retorno TEXT DEFAULT '',
        repetibilidad_inicial_carga2_prueba3_indicacion TEXT DEFAULT '',
        repetibilidad_inicial_carga2_prueba3_retorno TEXT DEFAULT '',
        repetibilidad_inicial_carga2_prueba4_indicacion TEXT DEFAULT '',
        repetibilidad_inicial_carga2_prueba4_retorno TEXT DEFAULT '',
        repetibilidad_inicial_carga2_prueba5_indicacion TEXT DEFAULT '',
        repetibilidad_inicial_carga2_prueba5_retorno TEXT DEFAULT '',
        repetibilidad_inicial_carga2_prueba6_indicacion TEXT DEFAULT '',
        repetibilidad_inicial_carga2_prueba6_retorno TEXT DEFAULT '',
        repetibilidad_inicial_carga2_prueba7_indicacion TEXT DEFAULT '',
        repetibilidad_inicial_carga2_prueba7_retorno TEXT DEFAULT '',
        repetibilidad_inicial_carga2_prueba8_indicacion TEXT DEFAULT '',
        repetibilidad_inicial_carga2_prueba8_retorno TEXT DEFAULT '',
        repetibilidad_inicial_carga2_prueba9_indicacion TEXT DEFAULT '',
        repetibilidad_inicial_carga2_prueba9_retorno TEXT DEFAULT '',
        repetibilidad_inicial_carga2_prueba10_indicacion TEXT DEFAULT '',
        repetibilidad_inicial_carga2_prueba10_retorno TEXT DEFAULT '',
        
        -- Carga 3
        repetibilidad_inicial_carga3_valor TEXT DEFAULT '',
        repetibilidad_inicial_carga3_prueba1_indicacion TEXT DEFAULT '',
        repetibilidad_inicial_carga3_prueba1_retorno TEXT DEFAULT '',
        repetibilidad_inicial_carga3_prueba2_indicacion TEXT DEFAULT '',
        repetibilidad_inicial_carga3_prueba2_retorno TEXT DEFAULT '',
        repetibilidad_inicial_carga3_prueba3_indicacion TEXT DEFAULT '',
        repetibilidad_inicial_carga3_prueba3_retorno TEXT DEFAULT '',
        repetibilidad_inicial_carga3_prueba4_indicacion TEXT DEFAULT '',
        repetibilidad_inicial_carga3_prueba4_retorno TEXT DEFAULT '',
        repetibilidad_inicial_carga3_prueba5_indicacion TEXT DEFAULT '',
        repetibilidad_inicial_carga3_prueba5_retorno TEXT DEFAULT '',
        repetibilidad_inicial_carga3_prueba6_indicacion TEXT DEFAULT '',
        repetibilidad_inicial_carga3_prueba6_retorno TEXT DEFAULT '',
        repetibilidad_inicial_carga3_prueba7_indicacion TEXT DEFAULT '',
        repetibilidad_inicial_carga3_prueba7_retorno TEXT DEFAULT '',
        repetibilidad_inicial_carga3_prueba8_indicacion TEXT DEFAULT '',
        repetibilidad_inicial_carga3_prueba8_retorno TEXT DEFAULT '',
        repetibilidad_inicial_carga3_prueba9_indicacion TEXT DEFAULT '',
        repetibilidad_inicial_carga3_prueba9_retorno TEXT DEFAULT '',
        repetibilidad_inicial_carga3_prueba10_indicacion TEXT DEFAULT '',
        repetibilidad_inicial_carga3_prueba10_retorno TEXT DEFAULT '',

        -- Linealidad Inicial
        linealidad_inicial_cantidad_puntos INTEGER DEFAULT '',
        linealidad_inicial_punto1_lt REAL DEFAULT '',
        linealidad_inicial_punto1_indicacion REAL DEFAULT '',
        linealidad_inicial_punto1_retorno REAL DEFAULT '',
        linealidad_inicial_punto1_error REAL DEFAULT '',
        linealidad_inicial_punto2_lt REAL DEFAULT '',
        linealidad_inicial_punto2_indicacion REAL DEFAULT '',
        linealidad_inicial_punto2_retorno REAL DEFAULT '',
        linealidad_inicial_punto2_error REAL DEFAULT '',
        linealidad_inicial_punto3_lt REAL DEFAULT '',
        linealidad_inicial_punto3_indicacion REAL DEFAULT '',
        linealidad_inicial_punto3_retorno REAL DEFAULT '',
        linealidad_inicial_punto3_error REAL DEFAULT '',
        linealidad_inicial_punto4_lt REAL DEFAULT '',
        linealidad_inicial_punto4_indicacion REAL DEFAULT '',
        linealidad_inicial_punto4_retorno REAL DEFAULT '',
        linealidad_inicial_punto4_error REAL DEFAULT '',
        linealidad_inicial_punto5_lt REAL DEFAULT '',
        linealidad_inicial_punto5_indicacion REAL DEFAULT '',
        linealidad_inicial_punto5_retorno REAL DEFAULT '',
        linealidad_inicial_punto5_error REAL DEFAULT '',
        linealidad_inicial_punto6_lt REAL DEFAULT '',
        linealidad_inicial_punto6_indicacion REAL DEFAULT '',
        linealidad_inicial_punto6_retorno REAL DEFAULT '',
        linealidad_inicial_punto6_error REAL DEFAULT '',
        linealidad_inicial_punto7_lt REAL DEFAULT '',
        linealidad_inicial_punto7_indicacion REAL DEFAULT '',
        linealidad_inicial_punto7_retorno REAL DEFAULT '',
        linealidad_inicial_punto7_error REAL DEFAULT '',
        linealidad_inicial_punto8_lt REAL DEFAULT '',
        linealidad_inicial_punto8_indicacion REAL DEFAULT '',
        linealidad_inicial_punto8_retorno REAL DEFAULT '',
        linealidad_inicial_punto8_error REAL DEFAULT '',
        linealidad_inicial_punto9_lt REAL DEFAULT '',
        linealidad_inicial_punto9_indicacion REAL DEFAULT '',
        linealidad_inicial_punto9_retorno REAL DEFAULT '',
        linealidad_inicial_punto9_error REAL DEFAULT '',
        linealidad_inicial_punto10_lt REAL DEFAULT '',
        linealidad_inicial_punto10_indicacion REAL DEFAULT '',
        linealidad_inicial_punto10_retorno REAL DEFAULT '',
        linealidad_inicial_punto10_error REAL DEFAULT '',
        linealidad_inicial_punto11_lt REAL DEFAULT '',
        linealidad_inicial_punto11_indicacion REAL DEFAULT '',
        linealidad_inicial_punto11_retorno REAL DEFAULT '',
        linealidad_inicial_punto11_error REAL DEFAULT '',
        linealidad_inicial_punto12_lt REAL DEFAULT '',
        linealidad_inicial_punto12_indicacion REAL DEFAULT '',
        linealidad_inicial_punto12_retorno REAL DEFAULT '',
        linealidad_inicial_punto12_error REAL DEFAULT '',
        estado_balanza TEXT DEFAULT ''
      )
      ''');

      debugPrint('Tabla diagnostico creada exitosamente');
    } catch (e) {
      debugPrint('Error creando tabla: $e');
      rethrow;
    }
  }

  Future<int> insertRegistroRelevamiento(Map<String, dynamic> registro) async {
    try {
      final db = await database;
      return await db.insert('diagnostico', registro);
    } catch (e) {
      debugPrint('Error insertando registro: $e');
      rethrow;
    }
  }

  Future<void> exportDataToCSV() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> registros =
      await db.query('diagnostico');

      if (registros.isEmpty) {
        debugPrint('No hay datos para exportar');
        return;
      }

      List<List<dynamic>> rows = [];
      rows.add(registros.first.keys.toList());

      for (var registro in registros) {
        rows.add(registro.values.toList());
      }

      String csv = const ListToCsvConverter().convert(rows);

      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Guardar archivo CSV',
        fileName: 'diagnostico${DateTime.now().toIso8601String()}.csv',
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (outputFile != null) {
        await File(outputFile).writeAsString(csv);
        debugPrint('Datos exportados a $outputFile');
      }
    } catch (e) {
      debugPrint('Error exportando datos: $e');
      rethrow;
    }
  }

  // ← MÉTODO AGREGADO: Para cerrar la base de datos correctamente
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}