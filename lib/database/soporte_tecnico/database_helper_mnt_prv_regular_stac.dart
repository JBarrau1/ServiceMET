import 'dart:io';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';


class DatabaseHelperMntPrvRegularStac {
  static final DatabaseHelperMntPrvRegularStac _instance = DatabaseHelperMntPrvRegularStac._internal();
  factory DatabaseHelperMntPrvRegularStac() => _instance;
  static Database? _database;
  static bool _isInitializing = false; // ← AGREGADO: Flag para evitar inicializaciones múltiples
  String get tableName => 'mnt_prv_regular_stac';

  DatabaseHelperMntPrvRegularStac._internal();

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
        'mnt_prv_regular_stac',
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
        'mnt_prv_regular_stac',
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
      FROM mnt_prv_regular_stac 
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
      return await db.query('mnt_prv_regular_stac', orderBy: 'fecha_servicio DESC');
    } catch (e) {
      debugPrint('Error al obtener todos los registros: $e');
      return [];
    }
  }

  Future<bool> secaExists(String seca) async {
    try {
      final db = await database;
      final result = await db.query(
        'mnt_prv_regular_stac',
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
        'mnt_prv_regular_stac',
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
        'mnt_prv_regular_stac',
        where: 'otst = ? AND session_id = ?',
        whereArgs: [registro['otst'], registro['session_id']],
      );

      if (existing.isNotEmpty) {
        await db.update(
          'mnt_prv_regular_stac',
          registro,
          where: 'otst = ? AND session_id = ?',
          whereArgs: [registro['otst'], registro['session_id']],
        );
        debugPrint('Registro ACTUALIZADO - OTST: ${registro['otst']}, Session: ${registro['session_id']}');
      } else {
        await db.insert('mnt_prv_regular_stac', registro);
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
      String path = join(await getDatabasesPath(), 'mnt_prv_regular_stac.db');

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
      debugPrint('Creando tabla mnt_prv_regular_stac...');

      await db.execute('''
      CREATE TABLE mnt_prv_regular_stac (
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
        fecha_prox_servicio TEXT DEFAULT '',
        
        -- Comentarios y Recomendaciones
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

        -- ========================================
        -- EXCENTRICIDAD INICIAL
        -- ========================================
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
        
        -- ========================================
        -- EXCENTRICIDAD FINAL
        -- ========================================
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

        -- ========================================
        -- REPETIBILIDAD INICIAL
        -- ========================================
        repetibilidad_inicial_cantidad_cargas TEXT DEFAULT '',
        repetibilidad_inicial_cantidad_pruebas TEXT DEFAULT '',
        
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

        -- ========================================
        -- REPETIBILIDAD FINAL
        -- ========================================
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
        
        -- ========================================
        -- LINEALIDAD INICIAL
        -- ========================================
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
        
        -- ========================================
        -- LINEALIDAD FINAL
        -- ========================================
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
        
        -- ========================================
        -- NUEVOS CAMPOS: LOZAS Y FUNDACIONES
        -- ========================================
        losas_aproximacion_estado TEXT DEFAULT '',
        losas_aproximacion_solucion TEXT DEFAULT '',
        losas_aproximacion_comentario TEXT DEFAULT '',
        losas_aproximacion_foto TEXT DEFAULT '',
        
        fundaciones_estado TEXT DEFAULT '',
        fundaciones_solucion TEXT DEFAULT '',
        fundaciones_comentario TEXT DEFAULT '',
        fundaciones_foto TEXT DEFAULT '',
        
        -- ========================================
        -- NUEVOS CAMPOS: LIMPIEZA Y DRENAJE
        -- ========================================
        limpieza_perimetro_estado TEXT DEFAULT '',
        limpieza_perimetro_solucion TEXT DEFAULT '',
        limpieza_perimetro_comentario TEXT DEFAULT '',
        limpieza_perimetro_foto TEXT DEFAULT '',
        
        fosa_humedad_estado TEXT DEFAULT '',
        fosa_humedad_solucion TEXT DEFAULT '',
        fosa_humedad_comentario TEXT DEFAULT '',
        fosa_humedad_foto TEXT DEFAULT '',
        
        drenaje_libre_estado TEXT DEFAULT '',
        drenaje_libre_solucion TEXT DEFAULT '',
        drenaje_libre_comentario TEXT DEFAULT '',
        drenaje_libre_foto TEXT DEFAULT '',
        
        bomba_sumidero_estado TEXT DEFAULT '',
        bomba_sumidero_solucion TEXT DEFAULT '',
        bomba_sumidero_comentario TEXT DEFAULT '',
        bomba_sumidero_foto TEXT DEFAULT '',
        
        -- ========================================
        -- NUEVOS CAMPOS: CHEQUEO
        -- ========================================
        corrosion_estado TEXT DEFAULT '',
        corrosion_solucion TEXT DEFAULT '',
        corrosion_comentario TEXT DEFAULT '',
        corrosion_foto TEXT DEFAULT '',
        
        grietas_estado TEXT DEFAULT '',
        grietas_solucion TEXT DEFAULT '',
        grietas_comentario TEXT DEFAULT '',
        grietas_foto TEXT DEFAULT '',
        
        tapas_pernos_estado TEXT DEFAULT '',
        tapas_pernos_solucion TEXT DEFAULT '',
        tapas_pernos_comentario TEXT DEFAULT '',
        tapas_pernos_foto TEXT DEFAULT '',
        
        desgaste_estres_estado TEXT DEFAULT '',
        desgaste_estres_solucion TEXT DEFAULT '',
        desgaste_estres_comentario TEXT DEFAULT '',
        desgaste_estres_foto TEXT DEFAULT '',
        
        acumulacion_escombros_estado TEXT DEFAULT '',
        acumulacion_escombros_solucion TEXT DEFAULT '',
        acumulacion_escombros_comentario TEXT DEFAULT '',
        acumulacion_escombros_foto TEXT DEFAULT '',
        
        verificacion_rieles_estado TEXT DEFAULT '',
        verificacion_rieles_solucion TEXT DEFAULT '',
        verificacion_rieles_comentario TEXT DEFAULT '',
        verificacion_rieles_foto TEXT DEFAULT '',
        
        paragolpes_longitudinales_estado TEXT DEFAULT '',
        paragolpes_longitudinales_solucion TEXT DEFAULT '',
        paragolpes_longitudinales_comentario TEXT DEFAULT '',
        paragolpes_longitudinales_foto TEXT DEFAULT '',
        
        paragolpes_transversales_estado TEXT DEFAULT '',
        paragolpes_transversales_solucion TEXT DEFAULT '',
        paragolpes_transversales_comentario TEXT DEFAULT '',
        paragolpes_transversales_foto TEXT DEFAULT '',
        
        -- ========================================
        -- NUEVOS CAMPOS: VERIFICACIONES ELÉCTRICAS
        -- ========================================
        cable_home_run_estado TEXT DEFAULT '',
        cable_home_run_solucion TEXT DEFAULT '',
        cable_home_run_comentario TEXT DEFAULT '',
        cable_home_run_foto TEXT DEFAULT '',
        
        cable_celula_celula_estado TEXT DEFAULT '',
        cable_celula_celula_solucion TEXT DEFAULT '',
        cable_celula_celula_comentario TEXT DEFAULT '',
        cable_celula_celula_foto TEXT DEFAULT '',
        
        conexion_celdas_estado TEXT DEFAULT '',
        conexion_celdas_solucion TEXT DEFAULT '',
        conexion_celdas_comentario TEXT DEFAULT '',
        conexion_celdas_foto TEXT DEFAULT '',
        
        funda_conector_estado TEXT DEFAULT '',
        funda_conector_solucion TEXT DEFAULT '',
        funda_conector_comentario TEXT DEFAULT '',
        funda_conector_foto TEXT DEFAULT '',
        
        conector_terminacion_estado TEXT DEFAULT '',
        conector_terminacion_solucion TEXT DEFAULT '',
        conector_terminacion_comentario TEXT DEFAULT '',
        conector_terminacion_foto TEXT DEFAULT '',
        
        cables_seguros_estado TEXT DEFAULT '',
        cables_seguros_solucion TEXT DEFAULT '',
        cables_seguros_comentario TEXT DEFAULT '',
        cables_seguros_foto TEXT DEFAULT '',
        
        funda_apretada_estado TEXT DEFAULT '',
        funda_apretada_solucion TEXT DEFAULT '',
        funda_apretada_comentario TEXT DEFAULT '',
        funda_apretada_foto TEXT DEFAULT '',
        
        conector_capuchon_estado TEXT DEFAULT '',
        conector_capuchon_solucion TEXT DEFAULT '',
        conector_capuchon_comentario TEXT DEFAULT '',
        conector_capuchon_foto TEXT DEFAULT '',
        
        -- ========================================
        -- NUEVOS CAMPOS: PROTECCIÓN CONTRA RAYOS
        -- ========================================
        sistema_tierra_estado TEXT DEFAULT '',
        sistema_tierra_solucion TEXT DEFAULT '',
        sistema_tierra_comentario TEXT DEFAULT '',
        sistema_tierra_foto TEXT DEFAULT '',
        
        conexion_strike_shield_estado TEXT DEFAULT '',
        conexion_strike_shield_solucion TEXT DEFAULT '',
        conexion_strike_shield_comentario TEXT DEFAULT '',
        conexion_strike_shield_foto TEXT DEFAULT '',
        
        tension_neutro_tierra_estado TEXT DEFAULT '',
        tension_neutro_tierra_solucion TEXT DEFAULT '',
        tension_neutro_tierra_comentario TEXT DEFAULT '',
        tension_neutro_tierra_foto TEXT DEFAULT '',
        
        impresora_strike_shield_estado TEXT DEFAULT '',
        impresora_strike_shield_solucion TEXT DEFAULT '',
        impresora_strike_shield_comentario TEXT DEFAULT '',
        impresora_strike_shield_foto TEXT DEFAULT '',
        
        -- ========================================
        -- NUEVOS CAMPOS: TERMINAL
        -- ========================================
        carcasa_lente_teclado_estado TEXT DEFAULT '',
        carcasa_lente_teclado_solucion TEXT DEFAULT '',
        carcasa_lente_teclado_comentario TEXT DEFAULT '',
        carcasa_lente_teclado_foto TEXT DEFAULT '',
        
        voltaje_bateria_estado TEXT DEFAULT '',
        voltaje_bateria_solucion TEXT DEFAULT '',
        voltaje_bateria_comentario TEXT DEFAULT '',
        voltaje_bateria_foto TEXT DEFAULT '',
        
        teclado_operativo_estado TEXT DEFAULT '',
        teclado_operativo_solucion TEXT DEFAULT '',
        teclado_operativo_comentario TEXT DEFAULT '',
        teclado_operativo_foto TEXT DEFAULT '',
        
        brillo_pantalla_estado TEXT DEFAULT '',
        brillo_pantalla_solucion TEXT DEFAULT '',
        brillo_pantalla_comentario TEXT DEFAULT '',
        brillo_pantalla_foto TEXT DEFAULT '',
        
        registros_pdx_estado TEXT DEFAULT '',
        registros_pdx_solucion TEXT DEFAULT '',
        registros_pdx_comentario TEXT DEFAULT '',
        registros_pdx_foto TEXT DEFAULT '',
        
        pantallas_servicio_estado TEXT DEFAULT '',
        pantallas_servicio_solucion TEXT DEFAULT '',
        pantallas_servicio_comentario TEXT DEFAULT '',
        pantallas_servicio_foto TEXT DEFAULT '',
        
        archivos_respaldados_estado TEXT DEFAULT '',
        archivos_respaldados_solucion TEXT DEFAULT '',
        archivos_respaldados_comentario TEXT DEFAULT '',
        archivos_respaldados_foto TEXT DEFAULT '',
        
        terminal_disponibilidad_estado TEXT DEFAULT '',
        terminal_disponibilidad_solucion TEXT DEFAULT '',
        terminal_disponibilidad_comentario TEXT DEFAULT '',
        terminal_disponibilidad_foto TEXT DEFAULT '',

        calibracion_balanza_estado TEXT DEFAULT '',
        calibracion_balanza_solucion TEXT DEFAULT '',
        calibracion_balanza_comentario TEXT DEFAULT '',
        calibracion_balanza_foto TEXT DEFAULT '',
        
        otros TEXT DEFAULT '',
        otros_foto TEXT DEFAULT '',
        conclusion TEXT DEFAULT '',
        estado_servicio TEXT DEFAULT ''
      )
      ''');

      debugPrint('Tabla mnt_prv_regular_stac creada exitosamente');
    } catch (e) {
      debugPrint('Error creando tabla: $e');
      rethrow;
    }
  }

  Future<int> insertRegistroRelevamiento(Map<String, dynamic> registro) async {
    try {
      final db = await database;
      return await db.insert('mnt_prv_regular_stac', registro);
    } catch (e) {
      debugPrint('Error insertando registro: $e');
      rethrow;
    }
  }

  Future<void> exportDataToCSV() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> registros =
      await db.query('mnt_prv_regular_stac');

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
        fileName: 'mnt_prv_regular_stac${DateTime.now().toIso8601String()}.csv',
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