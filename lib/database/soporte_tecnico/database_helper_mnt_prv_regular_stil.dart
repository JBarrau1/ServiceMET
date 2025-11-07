import 'dart:io';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';


class DatabaseHelperMntPrvRegularStil {
  static final DatabaseHelperMntPrvRegularStil _instance = DatabaseHelperMntPrvRegularStil._internal();
  factory DatabaseHelperMntPrvRegularStil() => _instance;
  static Database? _database;
  static bool _isInitializing = false; // ← AGREGADO: Flag para evitar inicializaciones múltiples
  String get tableName => 'mnt_prv_regular_stil';

  DatabaseHelperMntPrvRegularStil._internal();

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
        'mnt_prv_regular_stil',
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
        'mnt_prv_regular_stil',
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
      FROM mnt_prv_regular_stil 
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
      return await db.query('mnt_prv_regular_stil', orderBy: 'fecha_servicio DESC');
    } catch (e) {
      debugPrint('Error al obtener todos los registros: $e');
      return [];
    }
  }

  Future<bool> secaExists(String seca) async {
    try {
      final db = await database;
      final result = await db.query(
        'mnt_prv_regular_stil',
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
        'mnt_prv_regular_stil',
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
        'mnt_prv_regular_stil',
        where: 'otst = ? AND session_id = ?',
        whereArgs: [registro['otst'], registro['session_id']],
      );

      if (existing.isNotEmpty) {
        await db.update(
          'mnt_prv_regular_stil',
          registro,
          where: 'otst = ? AND session_id = ?',
          whereArgs: [registro['otst'], registro['session_id']],
        );
        debugPrint('Registro ACTUALIZADO - OTST: ${registro['otst']}, Session: ${registro['session_id']}');
      } else {
        await db.insert('mnt_prv_regular_stil', registro);
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
      String path = join(await getDatabasesPath(), 'mnt_prv_regular_stil.db');

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
      debugPrint('Creando tabla mnt_prv_regular_stil...');

      await db.execute('''
      CREATE TABLE mnt_prv_regular_stil (
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
               
        -- Inspección Visual
        comentario_general TEXT DEFAULT '',
        estado_fisico TEXT DEFAULT '',
        estado_operacional TEXT DEFAULT '',
        estado_metrologico TEXT DEFAULT '',
        recomendacion TEXT DEFAULT '',
        
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
        
        -- PRUEBAS METROLÓGICAS INICIALES
        retorno_cero_inicial TEXT DEFAULT '',
        carga_retorno_cero_inicial TEXT DEFAULT '',
        unidad_retorno_cero_inicial TEXT DEFAULT '',
        
        tipo_plataforma_inicial TEXT DEFAULT '',
        puntos_ind_inicial TEXT DEFAULT '',
        carga_exc_inicial TEXT DEFAULT '',
        
        -- Posiciones de excentricidad inicial (hasta 6 posiciones)
        posicion_inicial_1 TEXT DEFAULT '',
        indicacion_inicial_1 TEXT DEFAULT '',
        retorno_inicial_1 TEXT DEFAULT '',
        
        posicion_inicial_2 TEXT DEFAULT '',
        indicacion_inicial_2 TEXT DEFAULT '',
        retorno_inicial_2 TEXT DEFAULT '',
        
        posicion_inicial_3 TEXT DEFAULT '',
        indicacion_inicial_3 TEXT DEFAULT '',
        retorno_inicial_3 TEXT DEFAULT '',
        
        posicion_inicial_4 TEXT DEFAULT '',
        indicacion_inicial_4 TEXT DEFAULT '',
        retorno_inicial_4 TEXT DEFAULT '',
        
        posicion_inicial_5 TEXT DEFAULT '',
        indicacion_inicial_5 TEXT DEFAULT '',
        retorno_inicial_5 TEXT DEFAULT '',
        
        posicion_inicial_6 TEXT DEFAULT '',
        indicacion_inicial_6 TEXT DEFAULT '',
        retorno_inicial_6 TEXT DEFAULT '',

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
        
        -- Repetibilidad inicial (hasta 3 cargas con 10 mediciones cada una)
        repetibilidad1_inicial TEXT DEFAULT '',
        indicacion1_inicial_1 TEXT DEFAULT '',
        retorno1_inicial_1 TEXT DEFAULT '',
        indicacion1_inicial_2 TEXT DEFAULT '',
        retorno1_inicial_2 TEXT DEFAULT '',
        indicacion1_inicial_3 TEXT DEFAULT '',
        retorno1_inicial_3 TEXT DEFAULT '',
        indicacion1_inicial_4 TEXT DEFAULT '',
        retorno1_inicial_4 TEXT DEFAULT '',
        indicacion1_inicial_5 TEXT DEFAULT '',
        retorno1_inicial_5 TEXT DEFAULT '',
        indicacion1_inicial_6 TEXT DEFAULT '',
        retorno1_inicial_6 TEXT DEFAULT '',
        indicacion1_inicial_7 TEXT DEFAULT '',
        retorno1_inicial_7 TEXT DEFAULT '',
        indicacion1_inicial_8 TEXT DEFAULT '',
        retorno1_inicial_8 TEXT DEFAULT '',
        indicacion1_inicial_9 TEXT DEFAULT '',
        retorno1_inicial_9 TEXT DEFAULT '',
        indicacion1_inicial_10 TEXT DEFAULT '',
        retorno1_inicial_10 TEXT DEFAULT '',
        
        repetibilidad2_inicial TEXT DEFAULT '',
        indicacion2_inicial_1 TEXT DEFAULT '',
        retorno2_inicial_1 TEXT DEFAULT '',
        indicacion2_inicial_2 TEXT DEFAULT '',
        retorno2_inicial_2 TEXT DEFAULT '',
        indicacion2_inicial_3 TEXT DEFAULT '',
        retorno2_inicial_3 TEXT DEFAULT '',
        indicacion2_inicial_4 TEXT DEFAULT '',
        retorno2_inicial_4 TEXT DEFAULT '',
        indicacion2_inicial_5 TEXT DEFAULT '',
        retorno2_inicial_5 TEXT DEFAULT '',
        indicacion2_inicial_6 TEXT DEFAULT '',
        retorno2_inicial_6 TEXT DEFAULT '',
        indicacion2_inicial_7 TEXT DEFAULT '',
        retorno2_inicial_7 TEXT DEFAULT '',
        indicacion2_inicial_8 TEXT DEFAULT '',
        retorno2_inicial_8 TEXT DEFAULT '',
        indicacion2_inicial_9 TEXT DEFAULT '',
        retorno2_inicial_9 TEXT DEFAULT '',
        indicacion2_inicial_10 TEXT DEFAULT '',
        retorno2_inicial_10 TEXT DEFAULT '',
        
        repetibilidad3_inicial TEXT DEFAULT '',
        indicacion3_inicial_1 TEXT DEFAULT '',
        retorno3_inicial_1 TEXT DEFAULT '',
        indicacion3_inicial_2 TEXT DEFAULT '',
        retorno3_inicial_2 TEXT DEFAULT '',
        indicacion3_inicial_3 TEXT DEFAULT '',
        retorno3_inicial_3 TEXT DEFAULT '',
        indicacion3_inicial_4 TEXT DEFAULT '',
        retorno3_inicial_4 TEXT DEFAULT '',
        indicacion3_inicial_5 TEXT DEFAULT '',
        retorno3_inicial_5 TEXT DEFAULT '',
        indicacion3_inicial_6 TEXT DEFAULT '',
        retorno3_inicial_6 TEXT DEFAULT '',
        indicacion3_inicial_7 TEXT DEFAULT '',
        retorno3_inicial_7 TEXT DEFAULT '',
        indicacion3_inicial_8 TEXT DEFAULT '',
        retorno3_inicial_8 TEXT DEFAULT '',
        indicacion3_inicial_9 TEXT DEFAULT '',
        retorno3_inicial_9 TEXT DEFAULT '',
        indicacion3_inicial_10 TEXT DEFAULT '',
        retorno3_inicial_10 TEXT DEFAULT '',
        
        -- Linealidad inicial (hasta 12 puntos)
        lin_inicial_1 TEXT DEFAULT '',
        ind_inicial_1 TEXT DEFAULT '',
        retorno_lin_inicial_1 TEXT DEFAULT '',
        
        lin_inicial_2 TEXT DEFAULT '',
        ind_inicial_2 TEXT DEFAULT '',
        retorno_lin_inicial_2 TEXT DEFAULT '',
        
        lin_inicial_3 TEXT DEFAULT '',
        ind_inicial_3 TEXT DEFAULT '',
        retorno_lin_inicial_3 TEXT DEFAULT '',
        
        lin_inicial_4 TEXT DEFAULT '',
        ind_inicial_4 TEXT DEFAULT '',
        retorno_lin_inicial_4 TEXT DEFAULT '',
        
        lin_inicial_5 TEXT DEFAULT '',
        ind_inicial_5 TEXT DEFAULT '',
        retorno_lin_inicial_5 TEXT DEFAULT '',
        
        lin_inicial_6 TEXT DEFAULT '',
        ind_inicial_6 TEXT DEFAULT '',
        retorno_lin_inicial_6 TEXT DEFAULT '',
        
        lin_inicial_7 TEXT DEFAULT '',
        ind_inicial_7 TEXT DEFAULT '',
        retorno_lin_inicial_7 TEXT DEFAULT '',
        
        lin_inicial_8 TEXT DEFAULT '',
        ind_inicial_8 TEXT DEFAULT '',
        retorno_lin_inicial_8 TEXT DEFAULT '',
        
        lin_inicial_9 TEXT DEFAULT '',
        ind_inicial_9 TEXT DEFAULT '',
        retorno_lin_inicial_9 TEXT DEFAULT '',
        
        lin_inicial_10 TEXT DEFAULT '',
        ind_inicial_10 TEXT DEFAULT '',
        retorno_lin_inicial_10 TEXT DEFAULT '',
        
        lin_inicial_11 TEXT DEFAULT '',
        ind_inicial_11 TEXT DEFAULT '',
        retorno_lin_inicial_11 TEXT DEFAULT '',
        
        lin_inicial_12 TEXT DEFAULT '',
        ind_inicial_12 TEXT DEFAULT '',
        retorno_lin_inicial_12 TEXT DEFAULT '',
        
        -- PRUEBAS METROLÓGICAS FINALES
        retorno_cero_final TEXT DEFAULT '',
        carga_retorno_cero_final TEXT DEFAULT '',
        unidad_retorno_cero_final TEXT DEFAULT '',
        
        tipo_plataforma_final TEXT DEFAULT '',
        puntos_ind_final TEXT DEFAULT '',
        carga_exc_final TEXT DEFAULT '',
        
        -- Posiciones de excentricidad final (hasta 6 posiciones)
        posicion_final_1 TEXT DEFAULT '',
        indicacion_final_1 TEXT DEFAULT '',
        retorno_final_1 TEXT DEFAULT '',
        
        posicion_final_2 TEXT DEFAULT '',
        indicacion_final_2 TEXT DEFAULT '',
        retorno_final_2 TEXT DEFAULT '',
        
        posicion_final_3 TEXT DEFAULT '',
        indicacion_final_3 TEXT DEFAULT '',
        retorno_final_3 TEXT DEFAULT '',
        
        posicion_final_4 TEXT DEFAULT '',
        indicacion_final_4 TEXT DEFAULT '',
        retorno_final_4 TEXT DEFAULT '',
        
        posicion_final_5 TEXT DEFAULT '',
        indicacion_final_5 TEXT DEFAULT '',
        retorno_final_5 TEXT DEFAULT '',
        
        posicion_final_6 TEXT DEFAULT '',
        indicacion_final_6 TEXT DEFAULT '',
        retorno_final_6 TEXT DEFAULT '',
        
        -- Repetibilidad final (hasta 3 cargas con 10 mediciones cada una)
        repetibilidad_count_final INTEGER DEFAULT '',
        repetibilidad_rows_final INTEGER DEFAULT '',
        
        repetibilidad1_final TEXT DEFAULT '',
        indicacion1_final_1 TEXT DEFAULT '',
        retorno1_final_1 TEXT DEFAULT '',
        indicacion1_final_2 TEXT DEFAULT '',
        retorno1_final_2 TEXT DEFAULT '',
        indicacion1_final_3 TEXT DEFAULT '',
        retorno1_final_3 TEXT DEFAULT '',
        indicacion1_final_4 TEXT DEFAULT '',
        retorno1_final_4 TEXT DEFAULT '',
        indicacion1_final_5 TEXT DEFAULT '',
        retorno1_final_5 TEXT DEFAULT '',
        indicacion1_final_6 TEXT DEFAULT '',
        retorno1_final_6 TEXT DEFAULT '',
        indicacion1_final_7 TEXT DEFAULT '',
        retorno1_final_7 TEXT DEFAULT '',
        indicacion1_final_8 TEXT DEFAULT '',
        retorno1_final_8 TEXT DEFAULT '',
        indicacion1_final_9 TEXT DEFAULT '',
        retorno1_final_9 TEXT DEFAULT '',
        indicacion1_final_10 TEXT DEFAULT '',
        retorno1_final_10 TEXT DEFAULT '',
        
        repetibilidad2_final TEXT DEFAULT '',
        indicacion2_final_1 TEXT DEFAULT '',
        retorno2_final_1 TEXT DEFAULT '',
        indicacion2_final_2 TEXT DEFAULT '',
        retorno2_final_2 TEXT DEFAULT '',
        indicacion2_final_3 TEXT DEFAULT '',
        retorno2_final_3 TEXT DEFAULT '',
        indicacion2_final_4 TEXT DEFAULT '',
        retorno2_final_4 TEXT DEFAULT '',
        indicacion2_final_5 TEXT DEFAULT '',
        retorno2_final_5 TEXT DEFAULT '',
        indicacion2_final_6 TEXT DEFAULT '',
        retorno2_final_6 TEXT DEFAULT '',
        indicacion2_final_7 TEXT DEFAULT '',
        retorno2_final_7 TEXT DEFAULT '',
        indicacion2_final_8 TEXT DEFAULT '',
        retorno2_final_8 TEXT DEFAULT '',
        indicacion2_final_9 TEXT DEFAULT '',
        retorno2_final_9 TEXT DEFAULT '',
        indicacion2_final_10 TEXT DEFAULT '',
        retorno2_final_10 TEXT DEFAULT '',
        
        repetibilidad3_final TEXT DEFAULT '',
        indicacion3_final_1 TEXT DEFAULT '',
        retorno3_final_1 TEXT DEFAULT '',
        indicacion3_final_2 TEXT DEFAULT '',
        retorno3_final_2 TEXT DEFAULT '',
        indicacion3_final_3 TEXT DEFAULT '',
        retorno3_final_3 TEXT DEFAULT '',
        indicacion3_final_4 TEXT DEFAULT '',
        retorno3_final_4 TEXT DEFAULT '',
        indicacion3_final_5 TEXT DEFAULT '',
        retorno3_final_5 TEXT DEFAULT '',
        indicacion3_final_6 TEXT DEFAULT '',
        retorno3_final_6 TEXT DEFAULT '',
        indicacion3_final_7 TEXT DEFAULT '',
        retorno3_final_7 TEXT DEFAULT '',
        indicacion3_final_8 TEXT DEFAULT '',
        retorno3_final_8 TEXT DEFAULT '',
        indicacion3_final_9 TEXT DEFAULT '',
        retorno3_final_9 TEXT DEFAULT '',
        indicacion3_final_10 TEXT DEFAULT '',
        retorno3_final_10 TEXT DEFAULT '',
        
        -- Linealidad final (hasta 12 puntos)
        lin_final_1 TEXT DEFAULT '',
        ind_final_1 TEXT DEFAULT '',
        retorno_lin_final_1 TEXT DEFAULT '',
        
        lin_final_2 TEXT DEFAULT '',
        ind_final_2 TEXT DEFAULT '',
        retorno_lin_final_2 TEXT DEFAULT '',
        
        lin_final_3 TEXT DEFAULT '',
        ind_final_3 TEXT DEFAULT '',
        retorno_lin_final_3 TEXT DEFAULT '',
        
        lin_final_4 TEXT DEFAULT '',
        ind_final_4 TEXT DEFAULT '',
        retorno_lin_final_4 TEXT DEFAULT '',
        
        lin_final_5 TEXT DEFAULT '',
        ind_final_5 TEXT DEFAULT '',
        retorno_lin_final_5 TEXT DEFAULT '',
        
        lin_final_6 TEXT DEFAULT '',
        ind_final_6 TEXT DEFAULT '',
        retorno_lin_final_6 TEXT DEFAULT '',
        
        lin_final_7 TEXT DEFAULT '',
        ind_final_7 TEXT DEFAULT '',
        retorno_lin_final_7 TEXT DEFAULT '',
        
        lin_final_8 TEXT DEFAULT '',
        ind_final_8 TEXT DEFAULT '',
        retorno_lin_final_8 TEXT DEFAULT '',
        
        lin_final_9 TEXT DEFAULT '',
        ind_final_9 TEXT DEFAULT '',
        retorno_lin_final_9 TEXT DEFAULT '',
        
        lin_final_10 TEXT DEFAULT '',
        ind_final_10 TEXT DEFAULT '',
        retorno_lin_final_10 TEXT DEFAULT '',
        
        lin_final_11 TEXT DEFAULT '',
        ind_final_11 TEXT DEFAULT '',
        retorno_lin_final_11 TEXT DEFAULT '',
        
        lin_final_12 TEXT DEFAULT '',
        ind_final_12 TEXT DEFAULT '',
        retorno_lin_final_12 TEXT DEFAULT '',
        
        -- Campos adicionales
        personal_apoyo TEXT DEFAULT '',
        estado_final TEXT DEFAULT '',
        conclusion TEXT DEFAULT '',
        estado_balanza TEXT DEFAULT ''
      )
      ''');

      debugPrint('Tabla mnt_prv_regular_stil creada exitosamente');
    } catch (e) {
      debugPrint('Error creando tabla: $e');
      rethrow;
    }
  }

  Future<int> insertRegistroRelevamiento(Map<String, dynamic> registro) async {
    try {
      final db = await database;
      return await db.insert('mnt_prv_regular_stil', registro);
    } catch (e) {
      debugPrint('Error insertando registro: $e');
      rethrow;
    }
  }

  Future<void> exportDataToCSV() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> registros =
      await db.query('mnt_prv_regular_stil');

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
        fileName: 'mnt_prv_regular_stil${DateTime.now().toIso8601String()}.csv',
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