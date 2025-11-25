import 'dart:io';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelperRelevamiento {
  static final DatabaseHelperRelevamiento _instance =
      DatabaseHelperRelevamiento._internal();
  factory DatabaseHelperRelevamiento() => _instance;
  static Database? _database;
  static bool _isInitializing =
      false; // ← AGREGADO: Flag para evitar inicializaciones múltiples
  String get tableName => 'relevamiento_de_datos';

  DatabaseHelperRelevamiento._internal();

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
        'relevamiento_de_datos',
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
        'relevamiento_de_datos',
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
      FROM relevamiento_de_datos 
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
      return await db.query('relevamiento_de_datos',
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
        'relevamiento_de_datos',
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
        'relevamiento_de_datos',
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
        'relevamiento_de_datos',
        where: 'otst = ? AND session_id = ?',
        whereArgs: [registro['otst'], registro['session_id']],
      );

      if (existing.isNotEmpty) {
        await db.update(
          'relevamiento_de_datos',
          registro,
          where: 'otst = ? AND session_id = ?',
          whereArgs: [registro['otst'], registro['session_id']],
        );
        debugPrint(
            'Registro ACTUALIZADO - OTST: ${registro['otst']}, Session: ${registro['session_id']}');
      } else {
        await db.insert('relevamiento_de_datos', registro);
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
      String path = join(await getDatabasesPath(), 'relevamiento_de_datos.db');

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
      debugPrint('Creando tabla relevamiento_de_datos...');

      await db.execute('''
      CREATE TABLE relevamiento_de_datos (
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
        
        --DATOS SERVICIO ENTORNO
        fecha_servicio TEXT DEFAULT '',
        hora_inicio TEXT DEFAULT '',
        hora_fin TEXT DEFAULT '',
        comentario_general TEXT DEFAULT '',
        recomendaciones TEXT DEFAULT '',
        
        carcasa TEXT DEFAULT '',
        carcasa_comentario TEXT DEFAULT '',
        carcasa_foto TEXT DEFAULT '',
        
        conector_cables TEXT DEFAULT '',
        conector_cables_comentario TEXT DEFAULT '',
        conector_cables_foto TEXT DEFAULT '',
        
        alimentacion TEXT DEFAULT '',
        alimentacion_comentario TEXT DEFAULT '',
        alimentacion_foto TEXT DEFAULT '',
        
        pantalla TEXT DEFAULT '',
        pantalla_comentario TEXT DEFAULT '',
        pantalla_foto TEXT DEFAULT '',
        
        teclado TEXT DEFAULT '',
        teclado_comentario TEXT DEFAULT '',
        teclado_foto TEXT DEFAULT '',
        
        bracket_columna TEXT DEFAULT '',
        bracket_columna_comentario TEXT DEFAULT '',
        bracket_columna_foto TEXT DEFAULT '',
        
        plato_carga TEXT DEFAULT '',
        plato_carga_comentario TEXT DEFAULT '',
        plato_carga_foto TEXT DEFAULT '',
        
        estructura TEXT DEFAULT '',
        estructura_comentario TEXT DEFAULT '',
        estructura_foto TEXT DEFAULT '',
        
        topes_carga TEXT DEFAULT '',
        topes_carga_comentario TEXT DEFAULT '',
        topes_carga_foto TEXT DEFAULT '',
        
        patas TEXT DEFAULT '',
        patas_comentario TEXT DEFAULT '',
        patas_foto TEXT DEFAULT '',
        
        limpieza TEXT DEFAULT '',
        limpieza_comentario TEXT DEFAULT '',
        limpieza_foto TEXT DEFAULT '',
        
        bordes_puntas TEXT DEFAULT '',
        bordes_puntas_comentario TEXT DEFAULT '',
        bordes_puntas_foto TEXT DEFAULT '',
        
        celulas TEXT DEFAULT '',
        celulas_comentario TEXT DEFAULT '',
        celulas_foto TEXT DEFAULT '',
        
        cables TEXT DEFAULT '',
        cables_comentario TEXT DEFAULT '',
        cables_foto TEXT DEFAULT '',
        
        cubierta_silicona TEXT DEFAULT '',
        cubierta_silicona_comentario TEXT DEFAULT '',
        cubierta_silicona_foto TEXT DEFAULT '',
        
        entorno TEXT DEFAULT '',
        entorno_comentario TEXT DEFAULT '',
        entorno_foto TEXT DEFAULT '',
        
        nivelacion TEXT DEFAULT '',
        nivelacion_comentario TEXT DEFAULT '',
        nivelacion_foto TEXT DEFAULT '',
        
        movilizacion TEXT DEFAULT '',
        movilizacion_comentario TEXT DEFAULT '',
        movilizacion_foto TEXT DEFAULT '',
        
        flujo_pesas TEXT DEFAULT '',
        flujo_pesas_comentario TEXT DEFAULT '',
        flujo_pesas_foto TEXT DEFAULT '',
        
        otros TEXT DEFAULT '',
        otros_foto TEXT DEFAULT '',
        
        retorno_cero TEXT DEFAULT '',
        carga_retorno_cero TEXT DEFAULT '',
        
        --EXCENTRICIDAD
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

        --INICIAL
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

        excentricidad_final_punto4_ida_numero TEXT DEFAULT'',
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
        
        -- REPETIBILIDAD
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
        
        --LINEALIDAD
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
        estado_servicio TEXT DEFAULT ''
      )
      ''');

      debugPrint('Tabla relevamiento_de_datos creada exitosamente');
    } catch (e) {
      debugPrint('Error creando tabla: $e');
      rethrow;
    }
  }

  Future<int> insertRegistroRelevamiento(Map<String, dynamic> registro) async {
    try {
      final db = await database;
      return await db.insert('relevamiento_de_datos', registro);
    } catch (e) {
      debugPrint('Error insertando registro: $e');
      rethrow;
    }
  }

  Future<void> exportDataToCSV() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> registros =
          await db.query('relevamiento_de_datos');

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
            'relevamiento_de_datos${DateTime.now().toIso8601String()}.csv',
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
