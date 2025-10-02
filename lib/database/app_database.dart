import 'dart:io';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  static final AppDatabase _instance = AppDatabase._internal();
  factory AppDatabase() => _instance;
  static Database? _database;
  static bool _isInitializing = false; // ← AGREGADO: Flag para evitar inicializaciones múltiples

  AppDatabase._internal();

  Future<Map<String, dynamic>?> getRegistroByCodMetrica(String codMetrica) async {
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

  Future<String> generateSessionId(String seca) async {
    try {
      final db = await database;

      final result = await db.rawQuery(
          'SELECT MAX(CAST(session_id AS INTEGER)) as max_id '
              'FROM registros_calibracion '
              'WHERE seca = ? AND session_id IS NOT NULL AND session_id != "" '
              'AND session_id GLOB \"[0-9]*\"',
          [seca]
      );

      final maxId = result.first['max_id'] as int? ?? 0;
      final nextId = maxId + 1;

      return nextId.toString().padLeft(4, '0');
    } catch (e) {
      debugPrint('Error generando sessionId: $e');
      return DateTime.now().millisecondsSinceEpoch.toString();
    }
  }

  Future<List<Map<String, dynamic>>> getAllRegistrosCalibracion() async {
    try {
      final db = await database;
      return await db.query('registros_calibracion', orderBy: 'fecha_servicio DESC');
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

  Future<Map<String, dynamic>?> getRegistroBySeca(String seca, String sessionId) async {
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
        debugPrint('✅ Registro ACTUALIZADO - SECA: ${registro['seca']}, Session: ${registro['session_id']}');
      } else {
        await db.insert('registros_calibracion', registro);
        debugPrint('✅ NUEVO registro INSERTADO - SECA: ${registro['seca']}, Session: ${registro['session_id']}');
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
      debugPrint('🔧 Creando tabla registros_calibracion...');

      await db.execute('''
      CREATE TABLE registros_calibracion (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        --INF CLIENTE Y PERSONAL
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
        precarga1 REAL DEFAULT '',
        p_indicador1 REAL DEFAULT '',
        precarga2 REAL DEFAULT '',
        p_indicador2 REAL DEFAULT '',
        precarga3 REAL DEFAULT '',
        p_indicador3 REAL DEFAULT '',
        precarga4 REAL DEFAULT '',
        p_indicador4 REAL DEFAULT '',
        precarga5 REAL DEFAULT '',
        p_indicador5 REAL DEFAULT '',
        precarga6 REAL DEFAULT '',
        p_indicador6 REAL DEFAULT '',
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
        posicion1 REAL DEFAULT '',
        indicacion1 REAL DEFAULT '',
        retorno1 REAL DEFAULT '',
        posicion2 REAL DEFAULT '',
        indicacion2 REAL DEFAULT '',
        retorno2 REAL DEFAULT '',
        posicion3 REAL DEFAULT '',
        indicacion3 REAL DEFAULT '',
        retorno3 REAL DEFAULT '',
        posicion4 REAL DEFAULT '',
        indicacion4 REAL DEFAULT '',
        retorno4 REAL DEFAULT '',
        posicion5 REAL DEFAULT '',
        indicacion5 REAL DEFAULT '',
        retorno5 REAL DEFAULT '',
        posicion6 REAL DEFAULT '',
        indicacion6 REAL DEFAULT '',
        retorno6 REAL DEFAULT '',
        
        repetibilidad_comentario TEXT DEFAULT '',
        repetibilidad1 REAL DEFAULT '',
        indicacion1_1 REAL DEFAULT '',
        retorno1_1 REAL DEFAULT '',      
        indicacion1_2 REAL DEFAULT '',
        retorno1_2 REAL DEFAULT '',
        indicacion1_3 REAL DEFAULT '',
        retorno1_3 REAL DEFAULT '',
        indicacion1_4 REAL DEFAULT '',
        retorno1_4 REAL DEFAULT '',
        indicacion1_5 REAL DEFAULT '',
        retorno1_5 REAL DEFAULT '',
        indicacion1_6 REAL DEFAULT '',
        retorno1_6 REAL DEFAULT '',
        indicacion1_7 REAL DEFAULT '',
        retorno1_7 REAL DEFAULT '',
        indicacion1_8 REAL DEFAULT '',
        retorno1_8 REAL DEFAULT '',
        indicacion1_9 REAL DEFAULT '',
        retorno1_9 REAL DEFAULT '',
        indicacion1_10 REAL DEFAULT '',
        retorno1_10 REAL DEFAULT '',
       
        repetibilidad2 REAL DEFAULT '',
        indicacion2_1 REAL DEFAULT '',
        retorno2_1 REAL DEFAULT '',
        indicacion2_2 REAL DEFAULT '',
        retorno2_2 REAL DEFAULT '',
        indicacion2_3 REAL DEFAULT '',
        retorno2_3 REAL DEFAULT '',
        indicacion2_4 REAL DEFAULT '',
        retorno2_4 REAL DEFAULT '',
        indicacion2_5 REAL DEFAULT '',
        retorno2_5 REAL DEFAULT '',
        indicacion2_6 REAL DEFAULT '',
        retorno2_6 REAL DEFAULT '',
        indicacion2_7 REAL DEFAULT '',
        retorno2_7 REAL DEFAULT '',
        indicacion2_8 REAL DEFAULT '',
        retorno2_8 REAL DEFAULT '',
        indicacion2_9 REAL DEFAULT '',
        retorno2_9 REAL DEFAULT '',
        indicacion2_10 REAL DEFAULT '',
        retorno2_10 REAL DEFAULT '',
        
        repetibilidad3 REAL DEFAULT '',
        indicacion3_1 REAL DEFAULT '',
        retorno3_1 REAL DEFAULT '',
        indicacion3_2 REAL DEFAULT '',
        retorno3_2 REAL DEFAULT '',
        indicacion3_3 REAL DEFAULT '',
        retorno3_3 REAL DEFAULT '',
        indicacion3_4 REAL DEFAULT '',
        retorno3_4 REAL DEFAULT '',
        indicacion3_5 REAL DEFAULT '',
        retorno3_5 REAL DEFAULT '',
        indicacion3_6 REAL DEFAULT '',
        retorno3_6 REAL DEFAULT '',
        indicacion3_7 REAL DEFAULT '',
        retorno3_7 REAL DEFAULT '',
        indicacion3_8 REAL DEFAULT '',
        retorno3_8 REAL DEFAULT '',
        indicacion3_9 REAL DEFAULT '',
        retorno3_9 REAL DEFAULT '',
        indicacion3_10 REAL DEFAULT '',
        retorno3_10 REAL DEFAULT '',
        
        linealidad_comentario TEXT DEFAULT '',
        metodo TEXT DEFAULT '',
        metodo_carga TEXT DEFAULT '',
        lin1 REAL DEFAULT '',
        ind1 REAL DEFAULT '',
        retorno_lin1 REAL DEFAULT '',
        lin2 REAL DEFAULT '',
        ind2 REAL DEFAULT '',
        retorno_lin2 REAL DEFAULT '',
        lin3 REAL DEFAULT '',
        ind3 REAL DEFAULT '',
        retorno_lin3 REAL DEFAULT '',
        lin4 REAL DEFAULT '',
        ind4 REAL DEFAULT '',
        retorno_lin4 REAL DEFAULT '',
        lin5 REAL DEFAULT '',
        ind5 REAL DEFAULT '',
        retorno_lin5 REAL DEFAULT '',
        lin6 REAL DEFAULT '',
        ind6 REAL DEFAULT '',
        retorno_lin6 REAL DEFAULT '',
        lin7 REAL DEFAULT '',
        ind7 REAL DEFAULT '',
        retorno_lin7 REAL DEFAULT '',
        lin8 REAL DEFAULT '',
        ind8 REAL DEFAULT '',
        retorno_lin8 REAL DEFAULT '',
        lin9 REAL DEFAULT '',
        ind9 REAL DEFAULT '',
        retorno_lin9 REAL DEFAULT '',
        lin10 REAL DEFAULT '',
        ind10 REAL DEFAULT '',
        retorno_lin10 REAL DEFAULT '',
        lin11 REAL DEFAULT '',
        ind11 REAL DEFAULT '',
        retorno_lin11 REAL DEFAULT '',
        lin12 REAL DEFAULT '',
        ind12 REAL DEFAULT '',
        retorno_lin12 REAL DEFAULT '',
        lin13 REAL DEFAULT '',
        ind13 REAL DEFAULT '',
        retorno_lin13 REAL DEFAULT '',
        lin14 REAL DEFAULT '',
        ind14 REAL DEFAULT '',
        retorno_lin14 REAL DEFAULT '',
        lin15 REAL DEFAULT '',
        ind15 REAL DEFAULT '',
        retorno_lin15 REAL DEFAULT '',
        lin16 REAL DEFAULT '',
        ind16 REAL DEFAULT '',
        retorno_lin16 REAL DEFAULT '',
        lin17 REAL DEFAULT '',
        ind17 REAL DEFAULT '',
        retorno_lin17 REAL DEFAULT '',
        lin18 REAL DEFAULT '',
        ind18 REAL DEFAULT '',
        retorno_lin18 REAL DEFAULT '',
        lin19 REAL DEFAULT '',
        ind19 REAL DEFAULT '',
        retorno_lin19 REAL DEFAULT '',
        lin20 REAL DEFAULT '',
        ind20 REAL DEFAULT '',
        retorno_lin20 REAL DEFAULT '',
        lin21 REAL DEFAULT '',
        ind21 REAL DEFAULT '',
        retorno_lin21 REAL DEFAULT '',
        lin22 REAL DEFAULT '',
        ind22 REAL DEFAULT '',
        retorno_lin22 REAL DEFAULT '',
        lin23 REAL DEFAULT '',
        ind23 REAL DEFAULT '',
        retorno_lin23 REAL DEFAULT '',
        lin24 REAL DEFAULT '',
        ind24 REAL DEFAULT '',
        retorno_lin24 REAL DEFAULT '',
        lin25 REAL DEFAULT '',
        ind25 REAL DEFAULT '',
        retorno_lin25 REAL DEFAULT '',
        lin26 REAL DEFAULT '',
        ind26 REAL DEFAULT '',
        retorno_lin26 REAL DEFAULT '',
        lin27 REAL DEFAULT '',
        ind27 REAL DEFAULT '',
        retorno_lin27 REAL DEFAULT '',
        lin28 REAL DEFAULT '',
        ind28 REAL DEFAULT '',
        retorno_lin28 REAL DEFAULT '',
        lin29 REAL DEFAULT '',
        ind29 REAL DEFAULT '',
        retorno_lin29 REAL DEFAULT '',
        lin30 REAL DEFAULT '',
        ind30 REAL DEFAULT '',
        retorno_lin30 REAL DEFAULT '',
        lin31 REAL DEFAULT '',
        ind31 REAL DEFAULT '',
        retorno_lin31 REAL DEFAULT '',
        lin32 REAL DEFAULT '',
        ind32 REAL DEFAULT '',
        retorno_lin32 REAL DEFAULT '',
        lin33 REAL DEFAULT '',
        ind33 REAL DEFAULT '',
        retorno_lin33 REAL DEFAULT '',
        lin34 REAL DEFAULT '',
        ind34 REAL DEFAULT '',
        retorno_lin34 REAL DEFAULT '',
        lin35 REAL DEFAULT '',
        ind35 REAL DEFAULT '',
        retorno_lin35 REAL DEFAULT '',
        lin36 REAL DEFAULT '',
        ind36 REAL DEFAULT '',
        retorno_lin36 REAL DEFAULT '',
        lin37 REAL DEFAULT '',
        ind37 REAL DEFAULT '',
        retorno_lin37 REAL DEFAULT '',
        lin38 REAL DEFAULT '',
        ind38 REAL DEFAULT '',
        retorno_lin38 REAL DEFAULT '',
        lin39 REAL DEFAULT '',
        ind39 REAL DEFAULT '',
        retorno_lin39 REAL DEFAULT '',
        lin40 REAL DEFAULT '',
        ind40 REAL DEFAULT '',
        retorno_lin40 REAL DEFAULT '',
        lin41 REAL DEFAULT '',
        ind41 REAL DEFAULT '',
        retorno_lin41 REAL DEFAULT '',
        lin42 REAL DEFAULT '',
        ind42 REAL DEFAULT '',
        retorno_lin42 REAL DEFAULT '',
        lin43 REAL DEFAULT '',
        ind43 REAL DEFAULT '',
        retorno_lin43 REAL DEFAULT '',
        lin44 REAL DEFAULT '',
        ind44 REAL DEFAULT '',
        retorno_lin44 REAL DEFAULT '',
        lin45 REAL DEFAULT '',
        ind45 REAL DEFAULT '',
        retorno_lin45 REAL DEFAULT '',
        lin46 REAL DEFAULT '',
        ind46 REAL DEFAULT '',
        retorno_lin46 REAL DEFAULT '',
        lin47 REAL DEFAULT '',
        ind47 REAL DEFAULT '',
        retorno_lin47 REAL DEFAULT '',
        lin48 REAL DEFAULT '',
        ind48 REAL DEFAULT '',
        retorno_lin48 REAL DEFAULT '',
        lin49 REAL DEFAULT '',
        ind49 REAL DEFAULT '',
        retorno_lin49 REAL DEFAULT '',
        lin50 REAL DEFAULT '',
        ind50 REAL DEFAULT '',
        retorno_lin50 REAL DEFAULT '',
        lin51 REAL DEFAULT '',
        ind51 REAL DEFAULT '',
        retorno_lin51 REAL DEFAULT '',
        lin52 REAL DEFAULT '',
        ind52 REAL DEFAULT '',
        retorno_lin52 REAL DEFAULT '',
        lin53 REAL DEFAULT '',
        ind53 REAL DEFAULT '',
        retorno_lin53 REAL DEFAULT '',
        lin54 REAL DEFAULT '',
        ind54 REAL DEFAULT '',
        retorno_lin54 REAL DEFAULT '',
        lin55 REAL DEFAULT '',
        ind55 REAL DEFAULT '',
        retorno_lin55 REAL DEFAULT '',
        lin56 REAL DEFAULT '',
        ind56 REAL DEFAULT '',
        retorno_lin56 REAL DEFAULT '',
        lin57 REAL DEFAULT '',
        ind57 REAL DEFAULT '',
        retorno_lin57 REAL DEFAULT '',
        lin58 REAL DEFAULT '',
        ind58 REAL DEFAULT '',
        retorno_lin58 REAL DEFAULT '',
        lin59 REAL DEFAULT '',
        ind59 REAL DEFAULT '',
        retorno_lin59 REAL DEFAULT '',
        lin60 REAL DEFAULT '',
        ind60 REAL DEFAULT '',
        retorno_lin60 REAL DEFAULT '',
        
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
        estado_servicio_bal TEXT DEFAULT ''
      )
      ''');

      debugPrint('✅ Tabla registros_calibracion creada exitosamente');
    } catch (e) {
      debugPrint('❌ Error creando tabla: $e');
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
        fileName: 'registros_calibracion_${DateTime.now().toIso8601String()}.csv',
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