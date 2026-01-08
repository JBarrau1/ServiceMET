import 'dart:io';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelperMntPrvAvanzadoStac {
  static final DatabaseHelperMntPrvAvanzadoStac _instance =
      DatabaseHelperMntPrvAvanzadoStac._internal();
  factory DatabaseHelperMntPrvAvanzadoStac() => _instance;
  static Database? _database;
  static bool _isInitializing =
      false; // ← AGREGADO: Flag para evitar inicializaciones múltiples
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

  Future<Map<String, dynamic>?> getRegistroByCodMetrica(
      String codMetrica) async {
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
      return await db.query('mnt_prv_avanzado_stac',
          orderBy: 'fecha_servicio DESC');
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

  Future<Map<String, dynamic>?> getRegistroBySeca(
      String otst, String sessionId) async {
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
        debugPrint(
            'Registro ACTUALIZADO - OTST: ${registro['otst']}, Session: ${registro['session_id']}');
      } else {
        await db.insert('mnt_prv_avanzado_stac', registro);
        debugPrint(
            'NUEVO registro INSERTADO - OTST: ${registro['otst']}, Session: ${registro['session_id']}');
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
        inf_bal TEXT DEFAULT '',
        
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
        cap_max1 TEXT DEFAULT '',
        d1 TEXT DEFAULT '',
        e1 TEXT DEFAULT '',
        dec1 TEXT DEFAULT '',
        cap_max2 TEXT DEFAULT '',
        d2 TEXT DEFAULT '',
        e2 TEXT DEFAULT '',
        dec2 TEXT DEFAULT '',
        cap_max3 TEXT DEFAULT '',
        d3 TEXT DEFAULT '',
        e3 TEXT DEFAULT '',
        dec3 TEXT DEFAULT '',
        
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
        fecha_prox_servicio TEXT DEFAULT '',
        
        
        -- Retorno a Cero
        retorno_cero_inicial_valoracion TEXT DEFAULT '',
        estabilizacion_inicial TEXT DEFAULT '',
        retorno_cero_inicial_unidad TEXT DEFAULT '',
        retorno_cero_final_valoracion TEXT DEFAULT '',
        estabilizacion_final TEXT DEFAULT '',
        retorno_cero_final_unidad TEXT DEFAULT '',

        -- Excentricidad Inicial
        tipo_plataforma_inicial TEXT DEFAULT '',
        puntos_ind_inicial TEXT DEFAULT '',
        carga_exc_inicial TEXT DEFAULT '',
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

        tipo_plataforma_final TEXT DEFAULT '',
        puntos_ind_final TEXT DEFAULT '',
        carga_exc_final TEXT DEFAULT '',
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

        repetibilidad_inicial_cantidad_cargas TEXT DEFAULT '',
        repetibilidad_inicial_cantidad_pruebas TEXT DEFAULT '',
        
        -- Carga 1
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
        
        -- Carga 2
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
        
        -- Carga 3
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

       
        -- Repetibilidad Final
        repetibilidad_final_cantidad_cargas INTEGER DEFAULT '',
        repetibilidad_final_cantidad_pruebas INTEGER DEFAULT '',
        
        -- Carga 1
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
        
        -- Carga 2
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
        
        -- Carga 3
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
        retorno3_final_10 REAL DEFAULT '',
        
        -- Linealidad Inicial
        linealidad_inicial_cantidad_puntos INTEGER DEFAULT '',
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
        
        -- Linealidad Final
        linealidad_final_cantidad_puntos INTEGER DEFAULT '',
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
        
        -- Acumulacion
        acumulacion_escombros_estado TEXT DEFAULT '',
        acumulacion_escombros_solucion TEXT DEFAULT '',
        acumulacion_escombros_comentario TEXT DEFAULT '',
        acumulacion_escombros_foto TEXT DEFAULT '',
        
        -- Rieles Laterales
        verificacion_rieles_estado TEXT DEFAULT '',
        verificacion_rieles_solucion TEXT DEFAULT '',
        verificacion_rieles_comentario TEXT DEFAULT '',
        verificacion_rieles_foto TEXT DEFAULT '',
        
        -- Paragolpes Longitudinales
        paragolpes_longitudinales_estado TEXT DEFAULT '',
        paragolpes_longitudinales_solucion TEXT DEFAULT '',
        paragolpes_longitudinales_comentario TEXT DEFAULT '',
        paragolpes_longitudinales_foto TEXT DEFAULT '',
        
        -- Paragolpes Transversales
        paragolpes_transversales_estado TEXT DEFAULT '',
        paragolpes_transversales_solucion TEXT DEFAULT '',
        paragolpes_transversales_comentario TEXT DEFAULT '',
        paragolpes_transversales_foto TEXT DEFAULT '',
        
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
        sistema_tierra_estado TEXT DEFAULT '',
        sistema_tierra_solucion TEXT DEFAULT '',
        sistema_tierra_comentario TEXT DEFAULT '',
        sistema_tierra_foto TEXT DEFAULT '',
        
        -- Conexion Strike
        conexion_strike_shield_estado TEXT DEFAULT '',
        conexion_strike_shield_solucion TEXT DEFAULT '',
        conexion_strike_shield_comentario TEXT DEFAULT '',
        conexion_strike_shield_foto TEXT DEFAULT '',
        
        -- Tensión entre Neutro y Tierra
        tension_neutro_tierra_estado TEXT DEFAULT '',
        tension_neutro_tierra_solucion TEXT DEFAULT '',
        tension_neutro_tierra_comentario TEXT DEFAULT '',
        tension_neutro_tierra_foto TEXT DEFAULT '',
        
        -- Impresión Conectada
        impresora_strike_shield_estado TEXT DEFAULT '',
        impresora_strike_shield_solucion TEXT DEFAULT '',
        impresora_strike_shield_comentario TEXT DEFAULT '',
        impresora_strike_shield_foto TEXT DEFAULT '',
        
        -- Carcasa Limpia
        carcasa_lente_teclado_estado TEXT DEFAULT '',
        carcasa_lente_teclado_solucion TEXT DEFAULT '',
        carcasa_lente_teclado_comentario TEXT DEFAULT '',
        carcasa_lente_teclado_foto TEXT DEFAULT '',
        
        -- Voltaje de Batería (si aplica)
        voltaje_bateria_estado TEXT DEFAULT '',
        voltaje_bateria_solucion TEXT DEFAULT '',
        voltaje_bateria_comentario TEXT DEFAULT '',
        voltaje_bateria_foto TEXT DEFAULT '',
        
        -- Teclado Funcional
        teclado_operativo_estado TEXT DEFAULT '',
        teclado_operativo_solucion TEXT DEFAULT '',
        teclado_operativo_comentario TEXT DEFAULT '',
        teclado_operativo_foto TEXT DEFAULT '',
        
        -- Brillo de Pantalla
        brillo_pantalla_estado TEXT DEFAULT '',
        brillo_pantalla_solucion TEXT DEFAULT '',
        brillo_pantalla_comentario TEXT DEFAULT '',
        brillo_pantalla_foto TEXT DEFAULT '',
        
        -- Registro de Rendimiento
        registros_pdx_estado TEXT DEFAULT '',
        registros_pdx_solucion TEXT DEFAULT '',
        registros_pdx_comentario TEXT DEFAULT '',
        registros_pdx_foto TEXT DEFAULT '',
        
        -- Pantallas MT (si aplica)
        pantallas_servicio_estado TEXT DEFAULT '',
        pantallas_servicio_solucion TEXT DEFAULT '',
        pantallas_servicio_comentario TEXT DEFAULT '',
        pantallas_servicio_foto TEXT DEFAULT '',
        
        -- Archivos Respaldos
        archivos_respaldados_estado TEXT DEFAULT '',
        archivos_respaldados_solucion TEXT DEFAULT '',
        archivos_respaldados_comentario TEXT DEFAULT '',
        archivos_respaldados_foto TEXT DEFAULT '',
        
        -- Backup InSite (si aplica)
        backup_insite_estado TEXT DEFAULT '',
        backup_insite_solucion TEXT DEFAULT '',
        backup_insite_comentario TEXT DEFAULT '',
        backup_insite_foto TEXT DEFAULT '',
        
        -- Terminal Operativo
        terminal_disponibilidad_estado TEXT DEFAULT '',
        terminal_disponibilidad_solucion TEXT DEFAULT '',
        terminal_disponibilidad_comentario TEXT DEFAULT '',
        terminal_disponibilidad_foto TEXT '',
        
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
        fileName:
            'mnt_prv_avanzado_stac${DateTime.now().toIso8601String()}.csv',
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
