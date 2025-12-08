import 'dart:io';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  static final AppDatabase _instance = AppDatabase._internal();
  factory AppDatabase() => _instance;
  static Database? _database;
  static bool _isInitializing =
      false; // ← AGREGADO: Flag para evitar inicializaciones múltiples

  AppDatabase._internal();

  Future<Map<String, dynamic>?> getRegistroByCodMetrica(
      String codMetrica) async {
    try {
      final db = await database;

      final List<Map<String, dynamic>> result = await db.query(
        'registros_calibracion',
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

  Future<Map<String, dynamic>?> getUltimoRegistroPorSeca(String seca) async {
    try {
      final db = await database;
      final result = await db.query(
        'registros_calibracion',
        where: 'seca = ?',
        whereArgs: [seca],
        orderBy: 'id DESC',
        limit: 1,
      );
      return result.isNotEmpty ? result.first : null;
    } catch (e) {
      debugPrint('Error al obtener último registro por SECA: $e');
      return null;
    }
  }

  // REEMPLAZAR ESTE MÉTODO COMPLETO
  Future<String> generateSessionId(String seca) async {
    try {
      final db = await database;

      // Buscar el último session_id para este SECA
      final result = await db.rawQuery('''
      SELECT session_id 
      FROM registros_calibracion 
      WHERE seca = ? 
      ORDER BY session_id DESC 
      LIMIT 1
    ''', [seca]);

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

  Future<List<Map<String, dynamic>>> getAllRegistrosCalibracion() async {
    try {
      final db = await database;
      return await db.query('registros_calibracion',
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
        'registros_calibracion',
        where: 'seca = ?',
        whereArgs: [seca],
        limit: 1,
      );
      return result.isNotEmpty;
    } catch (e) {
      debugPrint('Error verificando si SECA existe: $e');
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
      String seca, String sessionId) async {
    try {
      final db = await database;
      final result = await db.query(
        'registros_calibracion',
        where: 'seca = ? AND session_id = ?',
        whereArgs: [seca, sessionId],
        limit: 1,
      );
      return result.isNotEmpty ? result.first : null;
    } catch (e) {
      debugPrint('Error al obtener registro por SECA y sessionId: $e');
      return null;
    }
  }

  Future<void> upsertRegistroCalibracion(Map<String, dynamic> registro) async {
    try {
      final db = await database;

      final existing = await db.query(
        'registros_calibracion',
        where: 'seca = ? AND session_id = ?',
        whereArgs: [registro['seca'], registro['session_id']],
      );

      if (existing.isNotEmpty) {
        await db.update(
          'registros_calibracion',
          registro,
          where: 'seca = ? AND session_id = ?',
          whereArgs: [registro['seca'], registro['session_id']],
        );
        debugPrint(
            '✅ Registro ACTUALIZADO - SECA: ${registro['seca']}, Session: ${registro['session_id']}');
      } else {
        await db.insert('registros_calibracion', registro);
        debugPrint(
            '✅ NUEVO registro INSERTADO - SECA: ${registro['seca']}, Session: ${registro['session_id']}');
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
      String path = join(await getDatabasesPath(), 'calibracion.db');

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
          debugPrint('✅ Base de datos abierta correctamente: $path');
        },
      );

      return database;
    } catch (e) {
      debugPrint('❌ Error inicializando base de datos: $e');
      rethrow;
    } finally {
      _isInitializing = false;
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    try {
      debugPrint('Creando tabla registros_calibracion...');

      await db.execute('''
      CREATE TABLE registros_calibracion (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        --INF ADICIONAL
        cliente TEXT DEFAULT '',
        razon_social TEXT DEFAULT '',
        planta TEXT DEFAULT '',
        dir_planta TEXT DEFAULT '',
        dep_planta TEXT DEFAULT '',
        cod_planta TEXT DEFAULT '',
        personal TEXT DEFAULT '',
        seca TEXT DEFAULT '',
        session_id TEXT DEFAULT '',
        n_reca TEXT DEFAULT '',
        sticker TEXT DEFAULT '',
        
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
        
        --INF TERMOHIGROMETROS Y PESAS PATRON
        equipo1 TEXT DEFAULT '',
        certificado1 TEXT DEFAULT '',
        ente_calibrador1 TEXT DEFAULT '',
        estado1 TEXT DEFAULT '',
        cantidad1 REAL DEFAULT '',
        equipo2 TEXT DEFAULT '',
        certificado2 TEXT DEFAULT '',
        ente_calibrador2 TEXT DEFAULT '',
        estado2 TEXT DEFAULT '',
        cantidad2 REAL DEFAULT '',
        equipo3 TEXT DEFAULT '',
        certificado3 TEXT DEFAULT '',
        ente_calibrador3 TEXT DEFAULT '',
        estado3 TEXT DEFAULT '',
        cantidad3 REAL DEFAULT '',
        equipo4 TEXT DEFAULT '',
        certificado4 TEXT DEFAULT '',
        ente_calibrador4 TEXT DEFAULT '',
        estado4 TEXT DEFAULT '',
        cantidad4 REAL DEFAULT '',
        equipo5 TEXT DEFAULT '',
        certificado5 TEXT DEFAULT '',
        ente_calibrador5 TEXT DEFAULT '',
        estado5 TEXT DEFAULT '',
        cantidad5 REAL DEFAULT '',
        equipo6 TEXT DEFAULT '',
        certificado6 TEXT DEFAULT '',
        ente_calibrador6 TEXT DEFAULT '',
        estado6 TEXT DEFAULT '',
        cantidad6 REAL DEFAULT '',
        equipo7 TEXT DEFAULT '',
        certificado7 TEXT DEFAULT '',
        ente_calibrador7 TEXT DEFAULT '',
        estado7 TEXT DEFAULT '',
        cantidad7 REAL DEFAULT '',
        
        --INF SERVICIO
        fecha_servicio TEXT DEFAULT '',
        hora_inicio TEXT DEFAULT '',
        tiempo_estab TEXT DEFAULT '',
        t_ope_balanza TEXT DEFAULT '',
        vibracion TEXT DEFAULT '',
        vibracion_foto TEXT DEFAULT '',
        vibracion_comentario TEXT DEFAULT '',
        polvo TEXT DEFAULT '',
        polvo_foto TEXT DEFAULT '',
        polvo_comentario TEXT DEFAULT '',
        temp TEXT DEFAULT '',
        temp_foto TEXT DEFAULT '',
        temp_comentario TEXT DEFAULT '',
        humedad TEXT DEFAULT '',
        humedad_foto TEXT DEFAULT '',
        humedad_comentario TEXT DEFAULT '',
        mesada TEXT DEFAULT '',
        mesada_foto TEXT DEFAULT '',
        mesada_comentario TEXT DEFAULT '',
        iluminacion TEXT DEFAULT '',
        iluminacion_foto TEXT DEFAULT '',
        iluminacion_comentario TEXT DEFAULT '',
        limp_foza TEXT DEFAULT '',
        limp_foza_foto TEXT DEFAULT '',
        limp_foza_comentario TEXT DEFAULT '',
        estado_drenaje TEXT DEFAULT '',
        estado_drenaje_foto TEXT DEFAULT '',
        estado_drenaje_comentario TEXT DEFAULT '',
        limp_general TEXT DEFAULT '',
        limp_general_foto TEXT DEFAULT '',
        limp_general_comentario TEXT DEFAULT '',
        golpes_terminal TEXT DEFAULT '',
        golpes_terminal_foto TEXT DEFAULT '',
        golpes_terminal_comentario TEXT DEFAULT '',
        nivelacion TEXT DEFAULT '',
        nivelacion_foto TEXT DEFAULT '',
        nivelacion_comentario TEXT DEFAULT '',
        limp_recepto TEXT DEFAULT '',
        limp_recepto_foto TEXT DEFAULT '',
        limp_recepto_comentario TEXT DEFAULT '',
        golpes_receptor TEXT DEFAULT '',
        golpes_receptor_foto TEXT DEFAULT '',
        golpes_receptor_comentario TEXT DEFAULT '',
        encendido TEXT DEFAULT '',
        encendido_foto TEXT DEFAULT '',
        encendido_comentario TEXT DEFAULT '',
        precarga1 TEXT DEFAULT '',
        p_indicador1 TEXT DEFAULT '',
        precarga2 TEXT DEFAULT '',
        p_indicador2 TEXT DEFAULT '',
        precarga3 TEXT DEFAULT '',
        p_indicador3 TEXT DEFAULT '',
        precarga4 TEXT DEFAULT '',
        p_indicador4 TEXT DEFAULT '',
        precarga5 TEXT DEFAULT '',
        p_indicador5 TEXT DEFAULT '',
        precarga6 TEXT DEFAULT '',
        p_indicador6 TEXT DEFAULT '',
        ajuste TEXT DEFAULT '',
        tipo TEXT DEFAULT '',
        cargas_pesas TEXT DEFAULT '',
        hora TEXT DEFAULT '',
        hri TEXT DEFAULT '',
        ti TEXT DEFAULT '',
        patmi TEXT DEFAULT '',
        
        excentricidad_comentario TEXT DEFAULT '',
        tipo_plataforma TEXT DEFAULT '',
        puntos_ind TEXT DEFAULT '',
        carga TEXT DEFAULT '',
        posicion1 TEXT DEFAULT '',
        indicacion1 TEXT DEFAULT '',
        retorno1 TEXT DEFAULT '',
        posicion2 TEXT DEFAULT '',
        indicacion2 TEXT DEFAULT '',
        retorno2 TEXT DEFAULT '',
        posicion3 TEXT DEFAULT '',
        indicacion3 TEXT DEFAULT '',
        retorno3 TEXT DEFAULT '',
        posicion4 TEXT DEFAULT '',
        indicacion4 TEXT DEFAULT '',
        retorno4 TEXT DEFAULT '',
        posicion5 TEXT DEFAULT '',
        indicacion5 TEXT DEFAULT '',
        retorno5 TEXT DEFAULT '',
        posicion6 TEXT DEFAULT '',
        indicacion6 TEXT DEFAULT '',
        retorno6 TEXT DEFAULT '',
        
        repetibilidad_comentario TEXT DEFAULT '',
        repetibilidad1 TEXT DEFAULT '',
        indicacion1_1 TEXT DEFAULT '',
        retorno1_1 TEXT DEFAULT '',      
        indicacion1_2 TEXT DEFAULT '',
        retorno1_2 TEXT DEFAULT '',
        indicacion1_3 TEXT DEFAULT '',
        retorno1_3 TEXT DEFAULT '',
        indicacion1_4 TEXT DEFAULT '',
        retorno1_4 TEXT DEFAULT '',
        indicacion1_5 TEXT DEFAULT '',
        retorno1_5 TEXT DEFAULT '',
        indicacion1_6 TEXT DEFAULT '',
        retorno1_6 TEXT DEFAULT '',
        indicacion1_7 TEXT DEFAULT '',
        retorno1_7 TEXT DEFAULT '',
        indicacion1_8 TEXT DEFAULT '',
        retorno1_8 TEXT DEFAULT '',
        indicacion1_9 TEXT DEFAULT '',
        retorno1_9 TEXT DEFAULT '',
        indicacion1_10 TEXT DEFAULT '',
        retorno1_10 TEXT DEFAULT '',
       
        repetibilidad2 TEXT DEFAULT '',
        indicacion2_1 TEXT DEFAULT '',
        retorno2_1 TEXT DEFAULT '',
        indicacion2_2 TEXT DEFAULT '',
        retorno2_2 TEXT DEFAULT '',
        indicacion2_3 TEXT DEFAULT '',
        retorno2_3 TEXT DEFAULT '',
        indicacion2_4 TEXT DEFAULT '',
        retorno2_4 TEXT DEFAULT '',
        indicacion2_5 TEXT DEFAULT '',
        retorno2_5 TEXT DEFAULT '',
        indicacion2_6 TEXT DEFAULT '',
        retorno2_6 TEXT DEFAULT '',
        indicacion2_7 TEXT DEFAULT '',
        retorno2_7 TEXT DEFAULT '',
        indicacion2_8 TEXT DEFAULT '',
        retorno2_8 TEXT DEFAULT '',
        indicacion2_9 TEXT DEFAULT '',
        retorno2_9 TEXT DEFAULT '',
        indicacion2_10 TEXT DEFAULT '',
        retorno2_10 TEXT DEFAULT '',
        
        repetibilidad3 TEXT DEFAULT '',
        indicacion3_1 TEXT DEFAULT '',
        retorno3_1 TEXT DEFAULT '',
        indicacion3_2 TEXT DEFAULT '',
        retorno3_2 TEXT DEFAULT '',
        indicacion3_3 TEXT DEFAULT '',
        retorno3_3 TEXT DEFAULT '',
        indicacion3_4 TEXT DEFAULT '',
        retorno3_4 TEXT DEFAULT '',
        indicacion3_5 TEXT DEFAULT '',
        retorno3_5 TEXT DEFAULT '',
        indicacion3_6 TEXT DEFAULT '',
        retorno3_6 TEXT DEFAULT '',
        indicacion3_7 TEXT DEFAULT '',
        retorno3_7 TEXT DEFAULT '',
        indicacion3_8 TEXT DEFAULT '',
        retorno3_8 TEXT DEFAULT '',
        indicacion3_9 TEXT DEFAULT '',
        retorno3_9 TEXT DEFAULT '',
        indicacion3_10 TEXT DEFAULT '',
        retorno3_10 TEXT DEFAULT '',
        
        linealidad_comentario TEXT DEFAULT '',
        metodo TEXT DEFAULT '',
        metodo_carga TEXT DEFAULT '',
        lin1 TEXT DEFAULT '',
        ind1 TEXT DEFAULT '',
        retorno_lin1 TEXT DEFAULT '',
        lin2 TEXT DEFAULT '',
        ind2 TEXT DEFAULT '',
        retorno_lin2 TEXT DEFAULT '',
        lin3 TEXT DEFAULT '',
        ind3 TEXT DEFAULT '',
        retorno_lin3 TEXT DEFAULT '',
        lin4 TEXT DEFAULT '',
        ind4 TEXT DEFAULT '',
        retorno_lin4 TEXT DEFAULT '',
        lin5 TEXT DEFAULT '',
        ind5 TEXT DEFAULT '',
        retorno_lin5 TEXT DEFAULT '',
        lin6 TEXT DEFAULT '',
        ind6 TEXT DEFAULT '',
        retorno_lin6 TEXT DEFAULT '',
        lin7 TEXT DEFAULT '',
        ind7 TEXT DEFAULT '',
        retorno_lin7 TEXT DEFAULT '',
        lin8 TEXT DEFAULT '',
        ind8 TEXT DEFAULT '',
        retorno_lin8 TEXT DEFAULT '',
        lin9 TEXT DEFAULT '',
        ind9 TEXT DEFAULT '',
        retorno_lin9 TEXT DEFAULT '',
        lin10 TEXT DEFAULT '',
        ind10 TEXT DEFAULT '',
        retorno_lin10 TEXT DEFAULT '',
        lin11 TEXT DEFAULT '',
        ind11 TEXT DEFAULT '',
        retorno_lin11 TEXT DEFAULT '',
        lin12 TEXT DEFAULT '',
        ind12 TEXT DEFAULT '',
        retorno_lin12 TEXT DEFAULT '',
        lin13 TEXT DEFAULT '',
        ind13 TEXT DEFAULT '',
        retorno_lin13 TEXT DEFAULT '',
        lin14 TEXT DEFAULT '',
        ind14 TEXT DEFAULT '',
        retorno_lin14 TEXT DEFAULT '',
        lin15 TEXT DEFAULT '',
        ind15 TEXT DEFAULT '',
        retorno_lin15 TEXT DEFAULT '',
        lin16 TEXT DEFAULT '',
        ind16 TEXT DEFAULT '',
        retorno_lin16 TEXT DEFAULT '',
        lin17 TEXT DEFAULT '',
        ind17 TEXT DEFAULT '',
        retorno_lin17 TEXT DEFAULT '',
        lin18 TEXT DEFAULT '',
        ind18 TEXT DEFAULT '',
        retorno_lin18 TEXT DEFAULT '',
        lin19 TEXT DEFAULT '',
        ind19 TEXT DEFAULT '',
        retorno_lin19 TEXT DEFAULT '',
        lin20 TEXT DEFAULT '',
        ind20 TEXT DEFAULT '',
        retorno_lin20 TEXT DEFAULT '',
        lin21 TEXT DEFAULT '',
        ind21 TEXT DEFAULT '',
        retorno_lin21 TEXT DEFAULT '',
        lin22 TEXT DEFAULT '',
        ind22 TEXT DEFAULT '',
        retorno_lin22 TEXT DEFAULT '',
        lin23 TEXT DEFAULT '',
        ind23 TEXT DEFAULT '',
        retorno_lin23 TEXT DEFAULT '',
        lin24 TEXT DEFAULT '',
        ind24 TEXT DEFAULT '',
        retorno_lin24 TEXT DEFAULT '',
        lin25 TEXT DEFAULT '',
        ind25 TEXT DEFAULT '',
        retorno_lin25 TEXT DEFAULT '',
        lin26 TEXT DEFAULT '',
        ind26 TEXT DEFAULT '',
        retorno_lin26 TEXT DEFAULT '',
        lin27 TEXT DEFAULT '',
        ind27 TEXT DEFAULT '',
        retorno_lin27 TEXT DEFAULT '',
        lin28 TEXT DEFAULT '',
        ind28 TEXT DEFAULT '',
        retorno_lin28 TEXT DEFAULT '',
        lin29 TEXT DEFAULT '',
        ind29 TEXT DEFAULT '',
        retorno_lin29 TEXT DEFAULT '',
        lin30 TEXT DEFAULT '',
        ind30 TEXT DEFAULT '',
        retorno_lin30 TEXT DEFAULT '',
        lin31 TEXT DEFAULT '',
        ind31 TEXT DEFAULT '',
        retorno_lin31 TEXT DEFAULT '',
        lin32 TEXT DEFAULT '',
        ind32 TEXT DEFAULT '',
        retorno_lin32 TEXT DEFAULT '',
        lin33 TEXT DEFAULT '',
        ind33 TEXT DEFAULT '',
        retorno_lin33 TEXT DEFAULT '',
        lin34 TEXT DEFAULT '',
        ind34 TEXT DEFAULT '',
        retorno_lin34 TEXT DEFAULT '',
        lin35 TEXT DEFAULT '',
        ind35 TEXT DEFAULT '',
        retorno_lin35 TEXT DEFAULT '',
        lin36 TEXT DEFAULT '',
        ind36 TEXT DEFAULT '',
        retorno_lin36 TEXT DEFAULT '',
        lin37 TEXT DEFAULT '',
        ind37 TEXT DEFAULT '',
        retorno_lin37 TEXT DEFAULT '',
        lin38 TEXT DEFAULT '',
        ind38 TEXT DEFAULT '',
        retorno_lin38 TEXT DEFAULT '',
        lin39 TEXT DEFAULT '',
        ind39 TEXT DEFAULT '',
        retorno_lin39 TEXT DEFAULT '',
        lin40 TEXT DEFAULT '',
        ind40 TEXT DEFAULT '',
        retorno_lin40 TEXT DEFAULT '',
        lin41 TEXT DEFAULT '',
        ind41 TEXT DEFAULT '',
        retorno_lin41 TEXT DEFAULT '',
        lin42 TEXT DEFAULT '',
        ind42 TEXT DEFAULT '',
        retorno_lin42 TEXT DEFAULT '',
        lin43 TEXT DEFAULT '',
        ind43 TEXT DEFAULT '',
        retorno_lin43 TEXT DEFAULT '',
        lin44 TEXT DEFAULT '',
        ind44 TEXT DEFAULT '',
        retorno_lin44 TEXT DEFAULT '',
        lin45 TEXT DEFAULT '',
        ind45 TEXT DEFAULT '',
        retorno_lin45 TEXT DEFAULT '',
        lin46 TEXT DEFAULT '',
        ind46 TEXT DEFAULT '',
        retorno_lin46 TEXT DEFAULT '',
        lin47 TEXT DEFAULT '',
        ind47 TEXT DEFAULT '',
        retorno_lin47 TEXT DEFAULT '',
        lin48 TEXT DEFAULT '',
        ind48 TEXT DEFAULT '',
        retorno_lin48 TEXT DEFAULT '',
        lin49 TEXT DEFAULT '',
        ind49 TEXT DEFAULT '',
        retorno_lin49 TEXT DEFAULT '',
        lin50 TEXT DEFAULT '',
        ind50 TEXT DEFAULT '',
        retorno_lin50 TEXT DEFAULT '',
        lin51 TEXT DEFAULT '',
        ind51 TEXT DEFAULT '',
        retorno_lin51 TEXT DEFAULT '',
        lin52 TEXT DEFAULT '',
        ind52 TEXT DEFAULT '',
        retorno_lin52 TEXT DEFAULT '',
        lin53 TEXT DEFAULT '',
        ind53 TEXT DEFAULT '',
        retorno_lin53 TEXT DEFAULT '',
        lin54 TEXT DEFAULT '',
        ind54 TEXT DEFAULT '',
        retorno_lin54 TEXT DEFAULT '',
        lin55 TEXT DEFAULT '',
        ind55 TEXT DEFAULT '',
        retorno_lin55 TEXT DEFAULT '',
        lin56 TEXT DEFAULT '',
        ind56 TEXT DEFAULT '',
        retorno_lin56 TEXT DEFAULT '',
        lin57 TEXT DEFAULT '',
        ind57 TEXT DEFAULT '',
        retorno_lin57 TEXT DEFAULT '',
        lin58 TEXT DEFAULT '',
        ind58 TEXT DEFAULT '',
        retorno_lin58 TEXT DEFAULT '',
        lin59 TEXT DEFAULT '',
        ind59 TEXT DEFAULT '',
        retorno_lin59 TEXT DEFAULT '',
        lin60 TEXT DEFAULT '',
        ind60 TEXT DEFAULT '',
        retorno_lin60 TEXT DEFAULT '',
        
        ---INF FINAL
        hora_fin TEXT DEFAULT '',
        hri_fin TEXT DEFAULT '',
        ti_fin TEXT DEFAULT '',
        patmi_fin TEXT DEFAULT '',
        mant_soporte TEXT DEFAULT '',
        venta_pesas TEXT DEFAULT '',
        reemplazo TEXT DEFAULT '',
        observaciones TEXT DEFAULT '',
        emp TEXT DEFAULT '',
        indicar TEXT DEFAULT '',
        factor TEXT DEFAULT '',
        regla_aceptacion TEXT DEFAULT '',
        estado_servicio_bal TEXT DEFAULT '',
        tipo_servicio TEXT DEFAULT ''
      )
      ''');

      debugPrint('Tabla registros_calibracion creada exitosamente');
    } catch (e) {
      debugPrint('Error creando tabla: $e');
      rethrow;
    }
  }

  Future<int> insertRegistroCalibracion(Map<String, dynamic> registro) async {
    try {
      final db = await database;
      return await db.insert('registros_calibracion', registro);
    } catch (e) {
      debugPrint('Error insertando registro: $e');
      rethrow;
    }
  }

  Future<void> exportDataToCSV() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> registros =
          await db.query('registros_calibracion');

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
            'registros_calibracion_${DateTime.now().toIso8601String()}.csv',
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
