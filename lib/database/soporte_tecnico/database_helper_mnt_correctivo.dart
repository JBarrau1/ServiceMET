import 'dart:io';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';


class DatabaseHelperMntCorrectivo {
  static final DatabaseHelperMntCorrectivo _instance = DatabaseHelperMntCorrectivo._internal();
  factory DatabaseHelperMntCorrectivo() => _instance;
  static Database? _database;
  static bool _isInitializing = false; // ← AGREGADO: Flag para evitar inicializaciones múltiples
  String get tableName => 'mnt_correctivo';

  DatabaseHelperMntCorrectivo._internal();

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
        'mnt_correctivo',
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
        'mnt_correctivo',
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
      FROM mnt_correctivo 
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
      return await db.query('mnt_correctivo', orderBy: 'fecha_servicio DESC');
    } catch (e) {
      debugPrint('Error al obtener todos los registros: $e');
      return [];
    }
  }

  Future<bool> secaExists(String seca) async {
    try {
      final db = await database;
      final result = await db.query(
        'mnt_correctivo',
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
        'mnt_correctivo',
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
        'mnt_correctivo',
        where: 'otst = ? AND session_id = ?',
        whereArgs: [registro['otst'], registro['session_id']],
      );

      if (existing.isNotEmpty) {
        await db.update(
          'mnt_correctivo',
          registro,
          where: 'otst = ? AND session_id = ?',
          whereArgs: [registro['otst'], registro['session_id']],
        );
        debugPrint('Registro ACTUALIZADO - OTST: ${registro['otst']}, Session: ${registro['session_id']}');
      } else {
        await db.insert('mnt_correctivo', registro);
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
      String path = join(await getDatabasesPath(), 'mnt_correctivo.db');

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
      debugPrint('Creando tabla mnt_correctivo...');

      await db.execute('''
      CREATE TABLE mnt_correctivo (
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
        num_celdas TEXT DEFAULT '',
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
        reporte TEXT DEFAULT '',
        evaluacion TEXT DEFAULT '',
        
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
        
        -- Entorno de instalación
        vibracion_estado TEXT DEFAULT '',
        vibracion_solucion TEXT DEFAULT '',
        vibracion_comentario TEXT DEFAULT '',
        vibracion_foto TEXT DEFAULT '',
        
        polvo_estado TEXT DEFAULT '',
        polvo_solucion TEXT DEFAULT '',
        polvo_comentario TEXT DEFAULT '',
        polvo_foto TEXT DEFAULT '',
        
        temperatura_estado TEXT DEFAULT '',
        temperatura_solucion TEXT DEFAULT '',
        temperatura_comentario TEXT DEFAULT '',
        temperatura_foto TEXT DEFAULT '',
        
        humedad_estado TEXT DEFAULT '',
        humedad_solucion TEXT DEFAULT '',
        humedad_comentario TEXT DEFAULT '',
        humedad_foto TEXT DEFAULT '',
        
        mesada_estado TEXT DEFAULT '',
        mesada_solucion TEXT DEFAULT '',
        mesada_comentario TEXT DEFAULT '',
        mesada_foto TEXT DEFAULT '',
        
        iluminacion_estado TEXT DEFAULT '',
        iluminacion_solucion TEXT DEFAULT '',
        iluminacion_comentario TEXT DEFAULT '',
        iluminacion_foto TEXT DEFAULT '',
        
        limpieza_fosa_estado TEXT DEFAULT '',
        limpieza_fosa_solucion TEXT DEFAULT '',
        limpieza_fosa_comentario TEXT DEFAULT '',
        limpieza_fosa_foto TEXT DEFAULT '',
        
        estado_drenaje_estado TEXT DEFAULT '',
        estado_drenaje_solucion TEXT DEFAULT '',
        estado_drenaje_comentario TEXT DEFAULT '',
        estado_drenaje_foto TEXT DEFAULT '',
        
        -- Terminal de pesaje
        carcasa_estado TEXT DEFAULT '',
        carcasa_solucion TEXT DEFAULT '',
        carcasa_comentario TEXT DEFAULT '',
        carcasa_foto TEXT DEFAULT '',
        
        teclado_fisico_estado TEXT DEFAULT '',
        teclado_fisico_solucion TEXT DEFAULT '',
        teclado_fisico_comentario TEXT DEFAULT '',
        teclado_fisico_foto TEXT DEFAULT '',
        
        display_fisico_estado TEXT DEFAULT '',
        display_fisico_solucion TEXT DEFAULT '',
        display_fisico_comentario TEXT DEFAULT '',
        display_fisico_foto TEXT DEFAULT '',
        
        fuente_poder_estado TEXT DEFAULT '',
        fuente_poder_solucion TEXT DEFAULT '',
        fuente_poder_comentario TEXT DEFAULT '',
        fuente_poder_foto TEXT DEFAULT '',
        
        bateria_operacional_estado TEXT DEFAULT '',
        bateria_operacional_solucion TEXT DEFAULT '',
        bateria_operacional_comentario TEXT DEFAULT '',
        bateria_operacional_foto TEXT DEFAULT '',
        
        bracket_estado TEXT DEFAULT '',
        bracket_solucion TEXT DEFAULT '',
        bracket_comentario TEXT DEFAULT '',
        bracket_foto TEXT DEFAULT '',
        
        teclado_operativo_estado TEXT DEFAULT '',
        teclado_operativo_solucion TEXT DEFAULT '',
        teclado_operativo_comentario TEXT DEFAULT '',
        teclado_operativo_foto TEXT DEFAULT '',
        
        display_operativo_estado TEXT DEFAULT '',
        display_operativo_solucion TEXT DEFAULT '',
        display_operativo_comentario TEXT DEFAULT '',
        display_operativo_foto TEXT DEFAULT '',
        
        conector_celda_estado TEXT DEFAULT '',
        conector_celda_solucion TEXT DEFAULT '',
        conector_celda_comentario TEXT DEFAULT '',
        conector_celda_foto TEXT DEFAULT '',
        
        bateria_memoria_estado TEXT DEFAULT '',
        bateria_memoria_solucion TEXT DEFAULT '',
        bateria_memoria_comentario TEXT DEFAULT '',
        bateria_memoria_foto TEXT DEFAULT '',
        
        -- Estado general de la balanza
        limpieza_general_estado TEXT DEFAULT '',
        limpieza_general_solucion TEXT DEFAULT '',
        limpieza_general_comentario TEXT DEFAULT '',
        limpieza_general_foto TEXT DEFAULT '',
        
        golpes_terminal_estado TEXT DEFAULT '',
        golpes_terminal_solucion TEXT DEFAULT '',
        golpes_terminal_comentario TEXT DEFAULT '',
        golpes_terminal_foto TEXT DEFAULT '',
        
        nivelacion_estado TEXT DEFAULT '',
        nivelacion_solucion TEXT DEFAULT '',
        nivelacion_comentario TEXT DEFAULT '',
        nivelacion_foto TEXT DEFAULT '',
        
        limpieza_receptor_estado TEXT DEFAULT '',
        limpieza_receptor_solucion TEXT DEFAULT '',
        limpieza_receptor_comentario TEXT DEFAULT '',
        limpieza_receptor_foto TEXT DEFAULT '',
        
        golpes_receptor_estado TEXT DEFAULT '',
        golpes_receptor_solucion TEXT DEFAULT '',
        golpes_receptor_comentario TEXT DEFAULT '',
        golpes_receptor_foto TEXT DEFAULT '',
        
        encendido_estado TEXT DEFAULT '',
        encendido_solucion TEXT DEFAULT '',
        encendido_comentario TEXT DEFAULT '',
        encendido_foto TEXT DEFAULT '',
        
        -- Balanza/Plataforma
        limitador_movimiento_estado TEXT DEFAULT '',
        limitador_movimiento_solucion TEXT DEFAULT '',
        limitador_movimiento_comentario TEXT DEFAULT '',
        limitador_movimiento_foto TEXT DEFAULT '',
        
        suspension_estado TEXT DEFAULT '',
        suspension_solucion TEXT DEFAULT '',
        suspension_comentario TEXT DEFAULT '',
        suspension_foto TEXT DEFAULT '',
        
        limitador_carga_estado TEXT DEFAULT '',
        limitador_carga_solucion TEXT DEFAULT '',
        limitador_carga_comentario TEXT DEFAULT '',
        limitador_carga_foto TEXT DEFAULT '',
        
        celda_carga_estado TEXT DEFAULT '',
        celda_carga_solucion TEXT DEFAULT '',
        celda_carga_comentario TEXT DEFAULT '',
        celda_carga_foto TEXT DEFAULT '',
        
        -- Caja sumadora
        tapa_caja_estado TEXT DEFAULT '',
        tapa_caja_solucion TEXT DEFAULT '',
        tapa_caja_comentario TEXT DEFAULT '',
        tapa_caja_foto TEXT DEFAULT '',
        
        humedad_interna_estado TEXT DEFAULT '',
        humedad_interna_solucion TEXT DEFAULT '',
        humedad_interna_comentario TEXT DEFAULT '',
        humedad_interna_foto TEXT DEFAULT '',
        
        estado_prensacables_estado TEXT DEFAULT '',
        estado_prensacables_solucion TEXT DEFAULT '',
        estado_prensacables_comentario TEXT DEFAULT '',
        estado_prensacables_foto TEXT DEFAULT '',
        
        estado_borneas_estado TEXT DEFAULT '',
        estado_borneas_solucion TEXT DEFAULT '',
        estado_borneas_comentario TEXT DEFAULT '',
        estado_borneas_foto TEXT DEFAULT '',
        
        pintado_estado TEXT DEFAULT '',
        pintado_solucion TEXT DEFAULT '',
        pintado_comentario TEXT DEFAULT '',
        pintado_foto TEXT DEFAULT '',
        
        limpieza_profunda_estado TEXT DEFAULT '',
        limpieza_profunda_solucion TEXT DEFAULT '',
        limpieza_profunda_comentario TEXT DEFAULT '',
        limpieza_profunda_foto TEXT DEFAULT '',
        
        
        
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
        estado_servicio TEXT DEFAULT ''
      )
      ''');

      debugPrint('Tabla mnt_correctivo creada exitosamente');
    } catch (e) {
      debugPrint('Error creando tabla: $e');
      rethrow;
    }
  }

  Future<int> insertRegistroRelevamiento(Map<String, dynamic> registro) async {
    try {
      final db = await database;
      return await db.insert('mnt_correctivo', registro);
    } catch (e) {
      debugPrint('Error insertando registro: $e');
      rethrow;
    }
  }

  Future<void> exportDataToCSV() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> registros =
      await db.query('mnt_correctivo');

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
        fileName: 'mnt_correctivo${DateTime.now().toIso8601String()}.csv',
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