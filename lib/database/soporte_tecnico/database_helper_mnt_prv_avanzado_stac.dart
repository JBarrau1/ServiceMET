import 'dart:io';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';


class DatabaseHelperMntPrvAvanzadoStac {
  static final DatabaseHelperMntPrvAvanzadoStac _instance = DatabaseHelperMntPrvAvanzadoStac._internal();
  factory DatabaseHelperMntPrvAvanzadoStac() => _instance;
  static Database? _database;
  static bool _isInitializing = false; // ← AGREGADO: Flag para evitar inicializaciones múltiples
  String get tableName => 'mnt_prv_avanzado_stac';

  DatabaseHelperMntPrvAvanzadoStac._internal();

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
        'mnt_prv_avanzado_stac',
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
        'mnt_prv_avanzado_stac',
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
      FROM mnt_prv_avanzado_stac 
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
      return await db.query('mnt_prv_avanzado_stac', orderBy: 'fecha_servicio DESC');
    } catch (e) {
      debugPrint('Error al obtener todos los registros: $e');
      return [];
    }
  }

  Future<bool> secaExists(String seca) async {
    try {
      final db = await database;
      final result = await db.query(
        'mnt_prv_avanzado_stac',
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
        'mnt_prv_avanzado_stac',
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
        'mnt_prv_avanzado_stac',
        where: 'otst = ? AND session_id = ?',
        whereArgs: [registro['otst'], registro['session_id']],
      );

      if (existing.isNotEmpty) {
        await db.update(
          'mnt_prv_avanzado_stac',
          registro,
          where: 'otst = ? AND session_id = ?',
          whereArgs: [registro['otst'], registro['session_id']],
        );
        debugPrint('Registro ACTUALIZADO - OTST: ${registro['otst']}, Session: ${registro['session_id']}');
      } else {
        await db.insert('mnt_prv_avanzado_stac', registro);
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
      String path = join(await getDatabasesPath(), 'mnt_prv_avanzado_stac.db');

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
      debugPrint('Creando tabla mnt_prv_avanzado_stac...');

      await db.execute('''
      CREATE TABLE mnt_prv_avanzado_stac (
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
        
        --DATOS DE SERVICIO
        fecha_servicio TEXT DEFAULT '',
        hora_inicio TEXT DEFAULT '',
        hora_fin TEXT DEFAULT '',
        
        -- Inspección Visual
        comentario_general TEXT DEFAULT '',
        recomendacion TEXT DEFAULT '',
        fisico TEXT DEFAULT '',
        operacional TEXT DEFAULT '',
        metrologico TEXT DEFAULT '',
        
        -- Retorno a Cero
        retorno_cero_inicial_valoracion TEXT DEFAULT '',
        retorno_cero_inicial_carga REAL DEFAULT '',
        retorno_cero_inicial_unidad TEXT DEFAULT '',
        retorno_cero_final_valoracion TEXT DEFAULT '',
        retorno_cero_final_carga REAL DEFAULT '',
        retorno_cero_final_unidad TEXT DEFAULT '',

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
        
        excentricidad_final_tipo_plataforma TEXT DEFAULT '',
        excentricidad_final_opcion_prueba TEXT DEFAULT '',
        excentricidad_final_carga TEXT DEFAULT '',
        excentricidad_final_ruta_imagen TEXT DEFAULT '',
        excentricidad_final_cantidad_posiciones TEXT DEFAULT '',
        excentricidad_final_pos1_numero TEXT DEFAULT '',
        excentricidad_final_pos1_indicacion TEXT DEFAULT '',
        excentricidad_final_pos1_retorno TEXT DEFAULT '',
        excentricidad_final_pos1_error TEXT DEFAULT '',
        excentricidad_final_pos2_numero TEXT DEFAULT '',
        excentricidad_final_pos2_indicacion TEXT DEFAULT '',
        excentricidad_final_pos2_retorno TEXT DEFAULT '',
        excentricidad_final_pos2_error TEXT DEFAULT '',
        excentricidad_final_pos3_numero TEXT DEFAULT '',
        excentricidad_final_pos3_indicacion TEXT DEFAULT '',
        excentricidad_final_pos3_retorno TEXT DEFAULT '',
        excentricidad_final_pos3_error TEXT DEFAULT '',
        excentricidad_final_pos4_numero TEXT DEFAULT '',
        excentricidad_final_pos4_indicacion TEXT DEFAULT '',
        excentricidad_final_pos4_retorno TEXT DEFAULT '',
        excentricidad_final_pos4_error TEXT DEFAULT '',
        excentricidad_final_pos5_numero TEXT DEFAULT '',
        excentricidad_final_pos5_indicacion TEXT DEFAULT '',
        excentricidad_final_pos5_retorno TEXT DEFAULT '',
        excentricidad_final_pos5_error TEXT DEFAULT '',
        excentricidad_final_pos6_numero TEXT DEFAULT '',
        excentricidad_final_pos6_indicacion TEXT DEFAULT '',
        excentricidad_final_pos6_retorno TEXT DEFAULT '',
        excentricidad_final_pos6_error TEXT DEFAULT '',
        
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

        -- IDA
        excentricidad_final_punto1_ida_numero TEXT DEFAULT '',
        excentricidad_final_punto1_ida_indicacion TEXT DEFAULT '',
        excentricidad_final_punto1_ida_retorno TEXT DEFAULT '',

        excentricidad_final_punto2_ida_numero TEXT DEFAULT '',
        excentricidad_final_punto2_ida_indicacion TEXT DEFAULT '',
        excentricidad_final_punto2_ida_retorno TEXT DEFAULT '',

        excentricidad_final_punto3_ida_numero TEXT DEFAULT '',
        excentricidad_final_punto3_ida_indicacion TEXT DEFAULT '',
        excentricidad_final_punto3_ida_retorno TEXT DEFAULT '',

        excentricidad_final_punto4_ida_numero TEXT DEFAULT '',
        excentricidad_final_punto4_ida_indicacion TEXT DEFAULT '',
        excentricidad_final_punto4_ida_retorno TEXT DEFAULT '',

        excentricidad_final_punto5_ida_numero TEXT DEFAULT '',
        excentricidad_final_punto5_ida_indicacion TEXT DEFAULT '',
        excentricidad_final_punto5_ida_retorno TEXT DEFAULT '',

        excentricidad_final_punto6_ida_numero TEXT DEFAULT '',
        excentricidad_final_punto6_ida_indicacion TEXT DEFAULT '',
        excentricidad_final_punto6_ida_retorno TEXT DEFAULT '',

        -- VUELTA
        excentricidad_final_punto7_vuelta_numero TEXT DEFAULT '',
        excentricidad_final_punto7_vuelta_indicacion TEXT DEFAULT '',
        excentricidad_final_punto7_vuelta_retorno TEXT DEFAULT '',

        excentricidad_final_punto8_vuelta_numero TEXT DEFAULT '',
        excentricidad_final_punto8_vuelta_indicacion TEXT DEFAULT '',
        excentricidad_final_punto8_vuelta_retorno TEXT DEFAULT '',

        excentricidad_final_punto9_vuelta_numero TEXT DEFAULT '',
        excentricidad_final_punto9_vuelta_indicacion TEXT DEFAULT '',
        excentricidad_final_punto9_vuelta_retorno TEXT DEFAULT '',

        excentricidad_final_punto10_vuelta_numero TEXT DEFAULT '',
        excentricidad_final_punto10_vuelta_indicacion TEXT DEFAULT '',
        excentricidad_final_punto10_vuelta_retorno TEXT DEFAULT '',

        excentricidad_final_punto11_vuelta_numero TEXT DEFAULT '',
        excentricidad_final_punto11_vuelta_indicacion TEXT DEFAULT '',
        excentricidad_final_punto11_vuelta_retorno TEXT DEFAULT '',

        excentricidad_final_punto12_vuelta_numero TEXT DEFAULT '',
        excentricidad_final_punto12_vuelta_indicacion TEXT DEFAULT '',
        excentricidad_final_punto12_vuelta_retorno TEXT DEFAULT '',
        
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

       
        -- Repetibilidad Final
        repetibilidad_final_cantidad_cargas INTEGER DEFAULT '',
        repetibilidad_final_cantidad_pruebas INTEGER DEFAULT '',
        
        -- Carga 1
        repetibilidad_final_carga1_valor REAL DEFAULT '',
        repetibilidad_final_carga1_prueba1_indicacion REAL DEFAULT '',
        repetibilidad_final_carga1_prueba1_retorno REAL DEFAULT '',
        repetibilidad_final_carga1_prueba2_indicacion REAL DEFAULT '',
        repetibilidad_final_carga1_prueba2_retorno REAL DEFAULT '',
        repetibilidad_final_carga1_prueba3_indicacion REAL DEFAULT '',
        repetibilidad_final_carga1_prueba3_retorno REAL DEFAULT '',
        repetibilidad_final_carga1_prueba4_indicacion REAL DEFAULT '',
        repetibilidad_final_carga1_prueba4_retorno REAL DEFAULT '',
        repetibilidad_final_carga1_prueba5_indicacion REAL DEFAULT '',
        repetibilidad_final_carga1_prueba5_retorno REAL DEFAULT '',
        repetibilidad_final_carga1_prueba6_indicacion REAL DEFAULT '',
        repetibilidad_final_carga1_prueba6_retorno REAL DEFAULT '',
        repetibilidad_final_carga1_prueba7_indicacion REAL DEFAULT '',
        repetibilidad_final_carga1_prueba7_retorno REAL DEFAULT '',
        repetibilidad_final_carga1_prueba8_indicacion REAL DEFAULT '',
        repetibilidad_final_carga1_prueba8_retorno REAL DEFAULT '',
        repetibilidad_final_carga1_prueba9_indicacion REAL DEFAULT '',
        repetibilidad_final_carga1_prueba9_retorno REAL DEFAULT '',
        repetibilidad_final_carga1_prueba10_indicacion REAL DEFAULT '',
        repetibilidad_final_carga1_prueba10_retorno REAL DEFAULT '',
        
        -- Carga 2
        repetibilidad_final_carga2_valor REAL DEFAULT '',
        repetibilidad_final_carga2_prueba1_indicacion REAL DEFAULT '',
        repetibilidad_final_carga2_prueba1_retorno REAL DEFAULT '',
        repetibilidad_final_carga2_prueba2_indicacion REAL DEFAULT '',
        repetibilidad_final_carga2_prueba2_retorno REAL DEFAULT '',
        repetibilidad_final_carga2_prueba3_indicacion REAL DEFAULT '',
        repetibilidad_final_carga2_prueba3_retorno REAL DEFAULT '',
        repetibilidad_final_carga2_prueba4_indicacion REAL DEFAULT '',
        repetibilidad_final_carga2_prueba4_retorno REAL DEFAULT '',
        repetibilidad_final_carga2_prueba5_indicacion REAL DEFAULT '',
        repetibilidad_final_carga2_prueba5_retorno REAL DEFAULT '',
        repetibilidad_final_carga2_prueba6_indicacion REAL DEFAULT '',
        repetibilidad_final_carga2_prueba6_retorno REAL DEFAULT '',
        repetibilidad_final_carga2_prueba7_indicacion REAL DEFAULT '',
        repetibilidad_final_carga2_prueba7_retorno REAL DEFAULT '',
        repetibilidad_final_carga2_prueba8_indicacion REAL DEFAULT '',
        repetibilidad_final_carga2_prueba8_retorno REAL DEFAULT '',
        repetibilidad_final_carga2_prueba9_indicacion REAL DEFAULT '',
        repetibilidad_final_carga2_prueba9_retorno REAL DEFAULT '',
        repetibilidad_final_carga2_prueba10_indicacion REAL DEFAULT '',
        repetibilidad_final_carga2_prueba10_retorno REAL DEFAULT '',
        
        -- Carga 3
        repetibilidad_final_carga3_valor REAL DEFAULT '',
        repetibilidad_final_carga3_prueba1_indicacion REAL DEFAULT '',
        repetibilidad_final_carga3_prueba1_retorno REAL DEFAULT '',
        repetibilidad_final_carga3_prueba2_indicacion REAL DEFAULT '',
        repetibilidad_final_carga3_prueba2_retorno REAL DEFAULT '',
        repetibilidad_final_carga3_prueba3_indicacion REAL DEFAULT '',
        repetibilidad_final_carga3_prueba3_retorno REAL DEFAULT '',
        repetibilidad_final_carga3_prueba4_indicacion REAL DEFAULT '',
        repetibilidad_final_carga3_prueba4_retorno REAL DEFAULT '',
        repetibilidad_final_carga3_prueba5_indicacion REAL DEFAULT '',
        repetibilidad_final_carga3_prueba5_retorno REAL DEFAULT '',
        repetibilidad_final_carga3_prueba6_indicacion REAL DEFAULT '',
        repetibilidad_final_carga3_prueba6_retorno REAL DEFAULT '',
        repetibilidad_final_carga3_prueba7_indicacion REAL DEFAULT '',
        repetibilidad_final_carga3_prueba7_retorno REAL DEFAULT '',
        repetibilidad_final_carga3_prueba8_indicacion REAL DEFAULT '',
        repetibilidad_final_carga3_prueba8_retorno REAL DEFAULT '',
        repetibilidad_final_carga3_prueba9_indicacion REAL DEFAULT '',
        repetibilidad_final_carga3_prueba9_retorno REAL DEFAULT '',
        repetibilidad_final_carga3_prueba10_indicacion REAL DEFAULT '',
        repetibilidad_final_carga3_prueba10_retorno REAL DEFAULT '',
        
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
        
        -- Linealidad Final
        linealidad_final_cantidad_puntos INTEGER DEFAULT '',
        linealidad_final_punto1_lt REAL DEFAULT '',
        linealidad_final_punto1_indicacion REAL DEFAULT '',
        linealidad_final_punto1_retorno REAL DEFAULT '',
        linealidad_final_punto1_error REAL DEFAULT '',
        linealidad_final_punto2_lt REAL DEFAULT '',
        linealidad_final_punto2_indicacion REAL DEFAULT '',
        linealidad_final_punto2_retorno REAL DEFAULT '',
        linealidad_final_punto2_error REAL DEFAULT '',
        linealidad_final_punto3_lt REAL DEFAULT '',
        linealidad_final_punto3_indicacion REAL DEFAULT '',
        linealidad_final_punto3_retorno REAL DEFAULT '',
        linealidad_final_punto3_error REAL DEFAULT '',
        linealidad_final_punto4_lt REAL DEFAULT '',
        linealidad_final_punto4_indicacion REAL DEFAULT '',
        linealidad_final_punto4_retorno REAL DEFAULT '',
        linealidad_final_punto4_error REAL DEFAULT '',
        linealidad_final_punto5_lt REAL DEFAULT '',
        linealidad_final_punto5_indicacion REAL DEFAULT '',
        linealidad_final_punto5_retorno REAL DEFAULT '',
        linealidad_final_punto5_error REAL DEFAULT '',
        linealidad_final_punto6_lt REAL DEFAULT '',
        linealidad_final_punto6_indicacion REAL DEFAULT '',
        linealidad_final_punto6_retorno REAL DEFAULT '',
        linealidad_final_punto6_error REAL DEFAULT '',
        linealidad_final_punto7_lt REAL DEFAULT '',
        linealidad_final_punto7_indicacion REAL DEFAULT '',
        linealidad_final_punto7_retorno REAL DEFAULT '',
        linealidad_final_punto7_error REAL DEFAULT '',
        linealidad_final_punto8_lt REAL DEFAULT '',
        linealidad_final_punto8_indicacion REAL DEFAULT '',
        linealidad_final_punto8_retorno REAL DEFAULT '',
        linealidad_final_punto8_error REAL DEFAULT '',
        linealidad_final_punto9_lt REAL DEFAULT '',
        linealidad_final_punto9_indicacion REAL DEFAULT '',
        linealidad_final_punto9_retorno REAL DEFAULT '',
        linealidad_final_punto9_error REAL DEFAULT '',
        linealidad_final_punto10_lt REAL DEFAULT '',
        linealidad_final_punto10_indicacion REAL DEFAULT '',
        linealidad_final_punto10_retorno REAL DEFAULT '',
        linealidad_final_punto10_error REAL DEFAULT '',
        linealidad_final_punto11_lt REAL DEFAULT '',
        linealidad_final_punto11_indicacion REAL DEFAULT '',
        linealidad_final_punto11_retorno REAL DEFAULT '',
        linealidad_final_punto11_error REAL DEFAULT '',
        linealidad_final_punto12_lt REAL DEFAULT '',
        linealidad_final_punto12_indicacion REAL DEFAULT '',
        linealidad_final_punto12_retorno REAL DEFAULT '',
        linealidad_final_punto12_error REAL DEFAULT '',
        
        -- losas
        losas_aproximacion_estado TEXT DEFAULT '',
        losas_aproximacion_solucion TEXT DEFAULT '',
        losas_aproximacion_comentario TEXT DEFAULT '',
        losas_aproximacion_foto TEXT DEFAULT '',
        
        -- Fundaciones
        fundaciones_estado TEXT DEFAULT '',
        fundaciones_solucion TEXT DEFAULT '',
        fundaciones_comentario TEXT DEFAULT '',
        fundaciones_foto TEXT DEFAULT '',
        
        -- Limpieza del Perímetro
        limpieza_perimetro_estado TEXT DEFAULT '',
        limpieza_perimetro_solucion TEXT DEFAULT '',
        limpieza_perimetro_comentario TEXT DEFAULT '',
        limpieza_perimetro_foto TEXT DEFAULT '',
        
        -- Humedad en Fosa
        fosa_humedad_estado TEXT DEFAULT '',
        fosa_humedad_solucion TEXT DEFAULT '',
        fosa_humedad_comentario TEXT DEFAULT '',
        fosa_humedad_foto TEXT DEFAULT '',
        
        -- Drenaje Libre
        drenaje_libre_estado TEXT DEFAULT '',
        drenaje_libre_solucion TEXT DEFAULT '',
        drenaje_libre_comentario TEXT DEFAULT '',
        drenaje_libre_foto TEXT DEFAULT '',
        
        -- Bomba de Sumidero
        bomba_sumidero_estado TEXT DEFAULT '',
        bomba_sumidero_solucion TEXT DEFAULT '',
        bomba_sumidero_comentario TEXT DEFAULT '',
        bomba_sumidero_foto TEXT DEFAULT '',
        
        -- Corrosión
        corrosion_estado TEXT DEFAULT '',
        corrosion_solucion TEXT DEFAULT '',
        corrosion_comentario TEXT DEFAULT '',
        corrosion_foto TEXT DEFAULT '',
        
        -- Grietas
        grietas_estado TEXT DEFAULT '',
        grietas_solucion TEXT DEFAULT '',
        grietas_comentario TEXT DEFAULT '',
        grietas_foto TEXT DEFAULT '',
        
        -- Topes y Pernos
        tapas_pernos_estado TEXT DEFAULT '',
        tapas_pernos_solucion TEXT DEFAULT '',
        tapas_pernos_comentario TEXT DEFAULT '',
        tapas_pernos_foto TEXT DEFAULT '',
        
        -- Desgaste o Estrés
        desgaste_estres_estado TEXT DEFAULT '',
        desgaste_estres_solucion TEXT DEFAULT '',
        desgaste_estres_comentario TEXT DEFAULT '',
        desgaste_estres_foto TEXT DEFAULT '',
        
        -- Escombros
        escombros_estado TEXT DEFAULT '',
        escombros_solucion TEXT DEFAULT '',
        escombros_comentario TEXT DEFAULT '',
        escombros_foto TEXT DEFAULT '',
        
        -- Rieles Laterales
        rieles_laterales_estado TEXT DEFAULT '',
        rieles_laterales_solucion TEXT DEFAULT '',
        rieles_laterales_comentario TEXT DEFAULT '',
        rieles_laterales_foto TEXT DEFAULT '',
        
        -- Paragolpes Longitudinales
        paragolpes_long_estado TEXT DEFAULT '',
        paragolpes_long_solucion TEXT DEFAULT '',
        paragolpes_long_comentario TEXT DEFAULT '',
        paragolpes_long_foto TEXT DEFAULT '',
        
        -- Paragolpes Transversales
        paragolpes_transv_estado TEXT DEFAULT '',
        paragolpes_transv_solucion TEXT DEFAULT '',
        paragolpes_transv_comentario TEXT DEFAULT '',
        paragolpes_transv_foto TEXT DEFAULT '',
        
        -- Cable Homerun
        cable_homerun_estado TEXT DEFAULT '',
        cable_homerun_solucion TEXT DEFAULT '',
        cable_homerun_comentario TEXT DEFAULT '',
        cable_homerun_foto TEXT DEFAULT '',
        
        -- Cable Celda a Terminal
        conexion_celdas_estado TEXT DEFAULT '',
        conexion_celdas_solucion TEXT DEFAULT '',
        conexion_celdas_comentario TEXT DEFAULT '',
        conexion_celdas_foto TEXT DEFAULT '',
        
        -- Cable Celda a Celda
        cable_celda_celda_estado TEXT DEFAULT '',
        cable_celda_celda_solucion TEXT DEFAULT '',
        cable_celda_celda_comentario TEXT DEFAULT '',
        cable_celda_celda_foto TEXT DEFAULT '',
        
        -- Cables Correctamente Conectados y Asegurados
        cables_conectados_estado TEXT DEFAULT '',
        cables_conectados_solucion TEXT DEFAULT '',
        cables_conectados_comentario TEXT DEFAULT '',
        cables_conectados_foto TEXT DEFAULT '',
        
        -- Funda de Conector
        funda_conector_estado TEXT DEFAULT '',
        funda_conector_solucion TEXT DEFAULT '',
        funda_conector_comentario TEXT DEFAULT '',
        funda_conector_foto TEXT DEFAULT '',
        
        -- Conector y Terminación
        conector_terminacion_estado TEXT DEFAULT '',
        conector_terminacion_solucion TEXT DEFAULT '',
        conector_terminacion_comentario TEXT DEFAULT '',
        conector_terminacion_foto TEXT DEFAULT '',
        
        -- Protección contra Rayos
        proteccion_rayos_estado TEXT DEFAULT '',
        proteccion_rayos_solucion TEXT DEFAULT '',
        proteccion_rayos_comentario TEXT DEFAULT '',
        proteccion_rayos_foto TEXT DEFAULT '',
        
        -- Conexión a Tierra
        conexion_tierra_estado TEXT DEFAULT '',
        conexion_tierra_solucion TEXT DEFAULT '',
        conexion_tierra_comentario TEXT DEFAULT '',
        conexion_tierra_foto TEXT DEFAULT '',
        
        -- Tensión entre Neutro y Tierra
        tension_neutro_estado TEXT DEFAULT '',
        tension_neutro_solucion TEXT DEFAULT '',
        tension_neutro_comentario TEXT DEFAULT '',
        tension_neutro_foto TEXT DEFAULT '',
        
        -- Impresión Conectada
        impresion_conectada_estado TEXT DEFAULT '',
        impresion_conectada_solucion TEXT DEFAULT '',
        impresion_conectada_comentario TEXT DEFAULT '',
        impresion_conectada_foto TEXT DEFAULT '',
        
        -- Carcasa Limpia
        carcasa_limpia_estado TEXT DEFAULT '',
        carcasa_limpia_solucion TEXT DEFAULT '',
        carcasa_limpia_comentario TEXT DEFAULT '',
        carcasa_limpia_foto TEXT DEFAULT '',
        
        -- Voltaje de Batería (si aplica)
        voltaje_bateria_estado TEXT DEFAULT '',
        voltaje_bateria_solucion TEXT DEFAULT '',
        voltaje_bateria_comentario TEXT DEFAULT '',
        voltaje_bateria_foto TEXT DEFAULT '',
        
        -- Teclado Funcional
        teclado_funcional_estado TEXT DEFAULT '',
        teclado_funcional_solucion TEXT DEFAULT '',
        teclado_funcional_comentario TEXT DEFAULT '',
        teclado_funcional_foto TEXT DEFAULT '',
        
        -- Brillo de Pantalla
        brillo_pantalla_estado TEXT DEFAULT '',
        brillo_pantalla_solucion TEXT DEFAULT '',
        brillo_pantalla_comentario TEXT DEFAULT '',
        brillo_pantalla_foto TEXT DEFAULT '',
        
        -- Registro de Rendimiento
        registro_rendimiento_estado TEXT DEFAULT '',
        registro_rendimiento_solucion TEXT DEFAULT '',
        registro_rendimiento_comentario TEXT DEFAULT '',
        registro_rendimiento_foto TEXT DEFAULT '',
        
        -- Pantallas MT (si aplica)
        pantallas_mt_estado TEXT DEFAULT '',
        pantallas_mt_solucion TEXT DEFAULT '',
        pantallas_mt_comentario TEXT DEFAULT '',
        pantallas_mt_foto TEXT DEFAULT '',
        
        -- Backup InSite (si aplica)
        backup_insite_estado TEXT DEFAULT '',
        backup_insite_solucion TEXT DEFAULT '',
        backup_insite_comentario TEXT DEFAULT '',
        backup_insite_foto TEXT DEFAULT '',
        
        -- Terminal Operativo
        terminal_operativo_estado TEXT DEFAULT '',
        terminal_operativo_solucion TEXT DEFAULT '',
        terminal_operativo_comentario TEXT DEFAULT '',
        terminal_operativo_foto TEXT '',
        
        -- Nuevo
        elevado_puente_estado TEXT DEFAULT '',
        elevado_puente_solucion TEXT DEFAULT '',
        elevado_puente_comentario TEXT DEFAULT '',
        elevado_puente_foto TEXT DEFAULT '',
        
        limpieza_estructura_estado TEXT DEFAULT '',
        limpieza_estructura_solucion TEXT DEFAULT '',
        limpieza_estructura_comentario TEXT DEFAULT '',
        limpieza_estructura_foto TEXT DEFAULT '',
        
        bearing_cups_estado TEXT DEFAULT '',
        bearing_cups_solucion TEXT DEFAULT '',
        bearing_cups_comentario TEXT DEFAULT '',
        bearing_cups_foto TEXT DEFAULT '',
        
        celdas_carga_estado TEXT DEFAULT '',
        celdas_carga_solucion TEXT DEFAULT '',
        celdas_carga_comentario TEXT DEFAULT '',
        celdas_carga_foto TEXT DEFAULT '',
        
        lubricacion_cabezas_estado TEXT DEFAULT '',
        lubricacion_cabezas_solucion TEXT DEFAULT '',
        lubricacion_cabezas_comentario TEXT DEFAULT '',
        lubricacion_cabezas_foto TEXT DEFAULT '',
        
        engrasado_bearing_estado TEXT DEFAULT '',
        engrasado_bearing_solucion TEXT DEFAULT '',
        engrasado_bearing_comentario TEXT DEFAULT '',
        engrasado_bearing_foto TEXT DEFAULT '',
        
        lainas_botas_estado TEXT DEFAULT '',
        lainas_botas_solucion TEXT DEFAULT '',
        lainas_botas_comentario TEXT DEFAULT '',
        lainas_botas_foto TEXT DEFAULT '',
        
        -- Calibracion
        calibracion_estado TEXT DEFAULT '',
        calibracion_solucion TEXT DEFAULT '',
        calibracion_comentario TEXT DEFAULT '',
        calibracion_foto TEXT DEFAULT '',
        
        otros TEXT DEFAULT '',
        otros_foto TEXT DEFAULT '',
        conclusion TEXT DEFAULT '',
        estado_balanza TEXT DEFAULT ''
      )
      ''');

      debugPrint('Tabla mnt_prv_avanzado_stac creada exitosamente');
    } catch (e) {
      debugPrint('Error creando tabla: $e');
      rethrow;
    }
  }

  Future<int> insertRegistroRelevamiento(Map<String, dynamic> registro) async {
    try {
      final db = await database;
      return await db.insert('mnt_prv_avanzado_stac', registro);
    } catch (e) {
      debugPrint('Error insertando registro: $e');
      rethrow;
    }
  }

  Future<void> exportDataToCSV() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> registros =
      await db.query('mnt_prv_avanzado_stac');

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
        fileName: 'mnt_prv_avanzado_stac${DateTime.now().toIso8601String()}.csv',
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