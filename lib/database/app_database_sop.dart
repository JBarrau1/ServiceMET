import 'dart:io';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelperSop {
  static final DatabaseHelperSop _instance = DatabaseHelperSop._internal();
  factory DatabaseHelperSop() => _instance;
  static Database? _database;

  DatabaseHelperSop._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'servicios_soporte_tecnico.db');
    bool dbExists = await databaseExists( path);

    if (!dbExists) {
      try {
        await Directory(dirname(path)).create(recursive: true);
      } catch (e) {
        print('Error creando directorio: $e');
      }
      _database = await openDatabase(path, version: 1, onCreate: _onCreate);
    } else {
      _database = await openDatabase(path);
    }
    return _database!;
  }

  //=== GESTIÓN DE SESIONES POR CÓDIGO MÉTRICA ===//

  Future<String> generateSessionId(String codMetrica, String tableName) async {
    final db = await database;
    try {
      final result = await db.rawQuery(
          'SELECT MAX(CAST(session_id AS INTEGER)) as max_id '
              'FROM $tableName '
              'WHERE cod_metrica = ? AND session_id IS NOT NULL AND session_id != "" '
              'AND session_id GLOB \"[0-9]*\"',
          [codMetrica]
      );

      final maxId = result.first['max_id'] as int? ?? 0;
      final nextId = maxId + 1;
      return nextId.toString().padLeft(4, '0');
    } catch (e) {
      print('Error generando sessionId: $e');
      return DateTime.now().millisecondsSinceEpoch.toString();
    }
  }

  Future<Map<String, dynamic>?> getUltimoRegistroPorMetrica(String codMetrica, String tableName) async {
    final db = await database;
    final result = await db.query(
      tableName,
      where: 'cod_metrica = ?',
      whereArgs: [codMetrica],
      orderBy: 'id DESC',
      limit: 1,
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<bool> metricaExists(String codMetrica, String tableName) async {
    final db = await database;
    final result = await db.query(
      tableName,
      where: 'cod_metrica = ?',
      whereArgs: [codMetrica],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  Future<Map<String, dynamic>?> getRegistroByMetrica(String codMetrica, String sessionId, String tableName) async {
    final db = await database;
    final result = await db.query(
      tableName,
      where: 'cod_metrica = ? AND session_id = ?',
      whereArgs: [codMetrica, sessionId],
      limit: 1,
    );
    return result.isNotEmpty ? result.first : null;
  }

  //=== FUNCIONES UPSERT PARA CADA TABLA ===//

  Future<void> upsertRegistro(String tableName, Map<String, dynamic> registro) async {
    final db = await database;

    // Verificar si ya existe un registro con el mismo código métrica y session_id
    final existing = await db.query(
      tableName,
      where: 'cod_metrica = ? AND session_id = ?',
      whereArgs: [registro['cod_metrica'], registro['session_id']],
    );

    if (existing.isNotEmpty) {
      // Actualizar registro existente
      await db.update(
        tableName,
        registro,
        where: 'cod_metrica = ? AND session_id = ?',
        whereArgs: [registro['cod_metrica'], registro['session_id']],
      );
      print('✅ Registro ACTUALIZADO - Tabla: $tableName, Código: ${registro['cod_metrica']}, Session: ${registro['session_id']}');
    } else {
      // Insertar nuevo registro
      await db.insert(tableName, registro);
      print('✅ NUEVO registro INSERTADO - Tabla: $tableName, Código: ${registro['cod_metrica']}, Session: ${registro['session_id']}');
    }
  }

  //=== FUNCIONES ESPECÍFICAS PARA CADA TABLA ===//

  // Para inf_cliente_balanza
  Future<void> upsertInfClienteBalanza(Map<String, dynamic> registro) async {
    await upsertRegistro('inf_cliente_balanza', registro);
  }

  // Para relevamiento_de_datos
  Future<void> upsertRelevamientoDatos(Map<String, dynamic> registro) async {
    await upsertRegistro('relevamiento_de_datos', registro);
  }

  // Para ajustes_metrológicos
  Future<void> upsertAjustesMetrologicos(Map<String, dynamic> registro) async {
    await upsertRegistro('ajustes_metrológicos', registro);
  }

  // Para diagnostico
  Future<void> upsertDiagnostico(Map<String, dynamic> registro) async {
    await upsertRegistro('diagnostico', registro);
  }

  // Para mnt_prv_regular_stac
  Future<void> upsertMntPrvRegularStac(Map<String, dynamic> registro) async {
    await upsertRegistro('mnt_prv_regular_stac', registro);
  }

  // Para mnt_prv_regular_stil
  Future<void> upsertMntPrvRegularStil(Map<String, dynamic> registro) async {
    await upsertRegistro('mnt_prv_regular_stil', registro);
  }

  // Para mnt_prv_avanzado_stac
  Future<void> upsertMntPrvAvanzadoStac(Map<String, dynamic> registro) async {
    await upsertRegistro('mnt_prv_avanzado_stac', registro);
  }

  // Para mnt_prv_avanzado_stil
  Future<void> upsertMntPrvAvanzadoStil(Map<String, dynamic> registro) async {
    await upsertRegistro('mnt_prv_avanzado_stil', registro);
  }

  // Para mnt_correctivo
  Future<void> upsertMntCorrectivo(Map<String, dynamic> registro) async {
    await upsertRegistro('mnt_correctivo', registro);
  }

  // Para instalacion
  Future<void> upsertInstalacion(Map<String, dynamic> registro) async {
    await upsertRegistro('instalacion', registro);
  }

  // Para verificaciones_internas
  Future<void> upsertVerificacionesInternas(Map<String, dynamic> registro) async {
    await upsertRegistro('verificaciones_internas', registro);
  }

  //=== FUNCIONES DE CONSULTA GENERALES ===//

  Future<List<Map<String, dynamic>>> getAllRegistros(String tableName) async {
    final db = await database;
    return await db.query(tableName, orderBy: 'id DESC');
  }

  Future<List<Map<String, dynamic>>> getRegistrosPorMetrica(String tableName, String codMetrica) async {
    final db = await database;
    return await db.query(
      tableName,
      where: 'cod_metrica = ?',
      whereArgs: [codMetrica],
      orderBy: 'id DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getRegistrosPorTipoServicio(String tableName, String tipoServicio) async {
    final db = await database;
    return await db.query(
      tableName,
      where: 'tipo_servicio = ?',
      whereArgs: [tipoServicio],
      orderBy: 'id DESC',
    );
  }

  //=== FUNCIONES DE EXPORTACIÓN ===//

  Future<void> exportTableToCSV(String tableName) async {
    final db = await database;
    final List<Map<String, dynamic>> registros = await db.query(tableName);

    if (registros.isEmpty) {
      print('No hay datos para exportar en $tableName');
      return;
    }

    List<List<dynamic>> rows = [];
    rows.add(registros.first.keys.toList()); // Encabezados

    for (var registro in registros) {
      rows.add(registro.values.toList());
    }

    String csv = const ListToCsvConverter().convert(rows);

    String? outputFile = await FilePicker.platform.saveFile(
      dialogTitle: 'Guardar archivo CSV',
      fileName: '${tableName}_${DateTime.now().toIso8601String()}.csv',
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (outputFile != null) {
      await File(outputFile).writeAsString(csv);
      print('Datos de $tableName exportados a $outputFile');
    }
  }

  Future<void> exportAllTablesToCSV() async {
    final tables = [
      'relevamiento_de_datos',
      'ajustes_metrológicos',
      'diagnostico',
      'mnt_prv_regular_stac',
      'mnt_prv_regular_stil',
      'mnt_prv_avanzado_stac',
      'mnt_prv_avanzado_stil',
      'mnt_correctivo',
      'instalacion',
      'verificaciones_internas'
    ];

    for (var table in tables) {
      if (await doesTableExist(table)) {
        await exportTableToCSV(table);
      }
    }
  }

  //=== FUNCIONES DE VERIFICACIÓN ===//

  Future<bool> doesTableExist(String tableName) async {
    final db = await database;
    final result = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
      [tableName],
    );
    return result.isNotEmpty;
  }

  Future<int> getCount(String tableName) async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM $tableName');
    return result.first['count'] as int;
  }

  //=== FUNCIONES DE ELIMINACIÓN ===//

  Future<int> deleteRegistro(String tableName, int id) async {
    final db = await database;
    return await db.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteRegistrosPorMetrica(String tableName, String codMetrica) async {
    final db = await database;
    return await db.delete(
      tableName,
      where: 'cod_metrica = ?',
      whereArgs: [codMetrica],
    );
  }

  //=== ESTRUCTURA ORIGINAL DE TABLAS (RESPETADA COMPLETAMENTE) ===//

  Future<void> _onCreate(Database db, int version) async {
    // Crear todas las tablas exactamente como en el código original
    await _createRelevamientoDeDatos(db);
    await _createAjustesMetrologicos(db);
    await _createDiagnostico(db);
    await _createMntPrvRegularStac(db);
    await _createMntPrvRegularStil(db);
    await _createMntPrvAvanzadoStac(db);
    await _createMntPrvAvanzadoStil(db);
    await _createMntCorrectivo(db);
    await _createInstalacion(db);
    await _createVerificacionesInternas(db);
  }

  Future<void> _createRelevamientoDeDatos(Database db) async {
    await db.execute('''
      CREATE TABLE relevamiento_de_datos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id TEXT DEFAULT '',
        tipo_servicio TEXT DEFAULT '',
        otst TEXT DEFAULT '',
        fecha_servicio TEXT DEFAULT '',
        tec_responsable TEXT DEFAULT '',
        --CLIENTE
        cliente TEXT DEFAULT '',
        razon_social TEXT DEFAULT '',
        planta TEXT DEFAULT '',
        dep_planta TEXT DEFAULT '',
        direccion_planta TEXT DEFAULT '',
        --BALANZA
        cod_metrica TEXT DEFAULT '',
        categoria TEXT DEFAULT '',
        instrumento TEXT DEFAULT '',
        categoria_balanza TEXT DEFAULT '',
        cod_interno TEXT DEFAULT '',
        tipo_equipo TEXT DEFAULT '',
        marca TEXT DEFAULT '',
        modelo TEXT DEFAULT '',
        serie TEXT DEFAULT '',
        unidades TEXT DEFAULT '',
        ubicacion TEXT DEFAULT '',
        num_celdas TEXT DEFAULT '',
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
        foto_balanza TEXT DEFAULT '',
        
        --DATOS SERVICIO ENTORNO
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
        estado_balanza TEXT DEFAULT ''
      )
    ''');
  }

  Future<void> _createAjustesMetrologicos(Database db) async {
    await db.execute('''
    CREATE TABLE ajustes_metrológicos (  
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id TEXT DEFAULT '',
        tipo_servicio TEXT DEFAULT '',
        otst TEXT DEFAULT '',
        fecha_servicio TEXT DEFAULT '',
        tec_responsable TEXT DEFAULT '',
        --CLIENTE
        cliente TEXT DEFAULT '',
        razon_social TEXT DEFAULT '',
        planta TEXT DEFAULT '',
        dep_planta TEXT DEFAULT '',
        direccion_planta TEXT DEFAULT '',
        --BALANZA
        cod_metrica TEXT DEFAULT '',
        categoria TEXT DEFAULT '',
        instrumento TEXT DEFAULT '',
        categoria_balanza TEXT DEFAULT '',
        cod_interno TEXT DEFAULT '',
        tipo_equipo TEXT DEFAULT '',
        marca TEXT DEFAULT '',
        modelo TEXT DEFAULT '',
        serie TEXT DEFAULT '',
        unidades TEXT DEFAULT '',
        ubicacion TEXT DEFAULT '',
        num_celdas TEXT DEFAULT '',
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
        foto_balanza TEXT DEFAULT '',
        
        --DATOS SERVICIO 
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
        
        -- REPETIBILIDAD INICIAL 
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

       
        -- REPETIBILIDAD FINAL
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
        
        -- LINEALIDAD INICIAL
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
        
        -- LINEALIDAD FINAL
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
        estado_balanza TEXT DEFAULT ''
       )
    ''');
  }

  Future<void> _createDiagnostico(Database db) async {
    await db.execute('''
      CREATE TABLE diagnostico (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id TEXT DEFAULT '',
        otst TEXT DEFAULT '',
        fecha_servicio TEXT DEFAULT '',
        tec_responsable TEXT DEFAULT '',
        --CLIENTE
        cliente TEXT DEFAULT '',
        razon_social TEXT DEFAULT '',
        planta TEXT DEFAULT '',
        dep_planta TEXT DEFAULT '',
        direccion_planta TEXT DEFAULT '',
        --BALANZA
        cod_metrica TEXT DEFAULT '',
        categoria TEXT DEFAULT '',
        instrumento TEXT DEFAULT '',
        categoria_balanza TEXT DEFAULT '',
        cod_interno TEXT DEFAULT '',
        tipo_equipo TEXT DEFAULT '',
        marca TEXT DEFAULT '',
        modelo TEXT DEFAULT '',
        serie TEXT DEFAULT '',
        unidades TEXT DEFAULT '',
        ubicacion TEXT DEFAULT '',
        num_celdas TEXT DEFAULT '',
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
        foto_balanza TEXT DEFAULT '', 
        
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
  }

  Future<void> _createMntPrvRegularStac(Database db) async {
    await db.execute('''
      CREATE TABLE mnt_prv_regular_stac (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id TEXT DEFAULT '',
        otst TEXT DEFAULT '',
        fecha_servicio TEXT DEFAULT '',
        tec_responsable TEXT DEFAULT '',
        --CLIENTE
        cliente TEXT DEFAULT '',
        razon_social TEXT DEFAULT '',
        planta TEXT DEFAULT '',
        dep_planta TEXT DEFAULT '',
        direccion_planta TEXT DEFAULT '',
        --BALANZA
        cod_metrica TEXT DEFAULT '',
        categoria TEXT DEFAULT '',
        instrumento TEXT DEFAULT '',
        categoria_balanza TEXT DEFAULT '',
        cod_interno TEXT DEFAULT '',
        tipo_equipo TEXT DEFAULT '',
        marca TEXT DEFAULT '',
        modelo TEXT DEFAULT '',
        serie TEXT DEFAULT '',
        unidades TEXT DEFAULT '',
        ubicacion TEXT DEFAULT '',
        num_celdas TEXT DEFAULT '',
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
        foto_balanza TEXT DEFAULT '',
        
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
  }

  Future<void> _createMntPrvRegularStil(Database db) async {
    await db.execute('''
      CREATE TABLE mnt_prv_regular_stil (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id TEXT DEFAULT '',
        otst TEXT DEFAULT '',
        fecha_servicio TEXT DEFAULT '',
        tec_responsable TEXT DEFAULT '',
        --CLIENTE
        cliente TEXT DEFAULT '',
        razon_social TEXT DEFAULT '',
        planta TEXT DEFAULT '',
        dep_planta TEXT DEFAULT '',
        direccion_planta TEXT DEFAULT '',
        --BALANZA
        cod_metrica TEXT DEFAULT '',
        categoria TEXT DEFAULT '',
        instrumento TEXT DEFAULT '',
        categoria_balanza TEXT DEFAULT '',
        cod_interno TEXT DEFAULT '',
        tipo_equipo TEXT DEFAULT '',
        marca TEXT DEFAULT '',
        modelo TEXT DEFAULT '',
        serie TEXT DEFAULT '',
        unidades TEXT DEFAULT '',
        ubicacion TEXT DEFAULT '',
        num_celdas TEXT DEFAULT '',
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
        foto_balanza TEXT DEFAULT '',
        
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
  }

  Future<void> _createMntPrvAvanzadoStac(Database db) async {
    await db.execute('''
      CREATE TABLE mnt_prv_avanzado_stac (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id TEXT DEFAULT '',
        otst TEXT DEFAULT '',
        fecha_servicio TEXT DEFAULT '',
        tec_responsable TEXT DEFAULT '',
        --CLIENTE
        cliente TEXT DEFAULT '',
        razon_social TEXT DEFAULT '',
        planta TEXT DEFAULT '',
        dep_planta TEXT DEFAULT '',
        direccion_planta TEXT DEFAULT '',
        --BALANZA
        cod_metrica TEXT DEFAULT '',
        categoria TEXT DEFAULT '',
        instrumento TEXT DEFAULT '',
        categoria_balanza TEXT DEFAULT '',
        cod_interno TEXT DEFAULT '',
        tipo_equipo TEXT DEFAULT '',
        marca TEXT DEFAULT '',
        modelo TEXT DEFAULT '',
        serie TEXT DEFAULT '',
        unidades TEXT DEFAULT '',
        ubicacion TEXT DEFAULT '',
        num_celdas TEXT DEFAULT '',
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
        foto_balanza TEXT DEFAULT '',
        
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
  }

  Future<void> _createMntPrvAvanzadoStil(Database db) async {
    await db.execute('''
      CREATE TABLE mnt_prv_avanzado_stil (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id TEXT DEFAULT '',
        otst TEXT DEFAULT '',
        fecha_servicio TEXT DEFAULT '',
        tec_responsable TEXT DEFAULT '',
        --CLIENTE
        cliente TEXT DEFAULT '',
        razon_social TEXT DEFAULT '',
        planta TEXT DEFAULT '',
        dep_planta TEXT DEFAULT '',
        direccion_planta TEXT DEFAULT '',
        --BALANZA
        cod_metrica TEXT DEFAULT '',
        categoria TEXT DEFAULT '',
        instrumento TEXT DEFAULT '',
        categoria_balanza TEXT DEFAULT '',
        cod_interno TEXT DEFAULT '',
        tipo_equipo TEXT DEFAULT '',
        marca TEXT DEFAULT '',
        modelo TEXT DEFAULT '',
        serie TEXT DEFAULT '',
        unidades TEXT DEFAULT '',
        ubicacion TEXT DEFAULT '',
        num_celdas TEXT DEFAULT '',
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
        foto_balanza TEXT DEFAULT '',
        
        -- Inspección Visual
        comentario_general TEXT DEFAULT '',
        recomendacion TEXT DEFAULT '',
        estado_fisico TEXT DEFAULT '',
        estado_operacional TEXT DEFAULT '',
        estado_metrologico TEXT DEFAULT '',
        
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
        
        -- Repetibilidad Inicial
        repetibilidad_count_inicial INTEGER DEFAULT 0,
        repetibilidad_rows_inicial INTEGER DEFAULT 0,
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
        
        -- Linealidad Inicial
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
        
        -- Excentricidad Final
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
        
        -- Repetibilidad Final
        repetibilidad_count_final INTEGER DEFAULT 0,
        repetibilidad_rows_final INTEGER DEFAULT 0,
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
        
        -- Linealidad Final
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
        estado_balanza TEXT DEFAULT ''
      )
    ''');
  }

  Future<void> _createMntCorrectivo(Database db) async {
    await db.execute('''
      CREATE TABLE mnt_correctivo (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id TEXT DEFAULT '',
        otst TEXT DEFAULT '',
        fecha_servicio TEXT DEFAULT '',
        tec_responsable TEXT DEFAULT '',
        --CLIENTE
        cliente TEXT DEFAULT '',
        razon_social TEXT DEFAULT '',
        planta TEXT DEFAULT '',
        dep_planta TEXT DEFAULT '',
        direccion_planta TEXT DEFAULT '',
        --BALANZA
        cod_metrica TEXT DEFAULT '',
        categoria TEXT DEFAULT '',
        instrumento TEXT DEFAULT '',
        categoria_balanza TEXT DEFAULT '',
        cod_interno TEXT DEFAULT '',
        tipo_equipo TEXT DEFAULT '',
        marca TEXT DEFAULT '',
        modelo TEXT DEFAULT '',
        serie TEXT DEFAULT '',
        unidades TEXT DEFAULT '',
        ubicacion TEXT DEFAULT '',
        num_celdas TEXT DEFAULT '',
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
        foto_balanza TEXT DEFAULT '',
        
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
        estado_balanza TEXT DEFAULT ''
      )
    ''');
  }

  Future<void> _createInstalacion(Database db) async {
    await db.execute('''
      CREATE TABLE instalacion (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id TEXT DEFAULT '',
        otst TEXT DEFAULT '',
        fecha_servicio TEXT DEFAULT '',
        tec_responsable TEXT DEFAULT '',
        --CLIENTE
        cliente TEXT DEFAULT '',
        razon_social TEXT DEFAULT '',
        planta TEXT DEFAULT '',
        dep_planta TEXT DEFAULT '',
        direccion_planta TEXT DEFAULT '',
        --BALANZA
        cod_metrica TEXT DEFAULT '',
        categoria TEXT DEFAULT '',
        instrumento TEXT DEFAULT '',
        categoria_balanza TEXT DEFAULT '',
        cod_interno TEXT DEFAULT '',
        tipo_equipo TEXT DEFAULT '',
        marca TEXT DEFAULT '',
        modelo TEXT DEFAULT '',
        serie TEXT DEFAULT '',
        unidades TEXT DEFAULT '',
        ubicacion TEXT DEFAULT '',
        num_celdas TEXT DEFAULT '',
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
        foto_balanza TEXT DEFAULT '',

        --INSTALACION
        entorno_valor TEXT DEFAULT '',
        entorno_comentario TEXT DEFAULT '',
        nivelacion_valor TEXT DEFAULT '',
        nivelacion_comentario TEXT DEFAULT '',
        movilizacion_valor TEXT DEFAULT '',
        movilizacion_comentario TEXT DEFAULT '',
        flujo_pesadas_valor TEXT DEFAULT '',
        flujo_pesadas_comentario TEXT DEFAULT '',

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
  }

  Future<void> _createVerificacionesInternas(Database db) async {
    await db.execute('''
      CREATE TABLE verificaciones_internas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id TEXT DEFAULT '',
        otst TEXT DEFAULT '',
        fecha_servicio TEXT DEFAULT '',
        tec_responsable TEXT DEFAULT '',
        --CLIENTE
        cliente TEXT DEFAULT '',
        razon_social TEXT DEFAULT '',
        planta TEXT DEFAULT '',
        dep_planta TEXT DEFAULT '',
        direccion_planta TEXT DEFAULT '',
        --BALANZA
        cod_metrica TEXT DEFAULT '',
        categoria TEXT DEFAULT '',
        instrumento TEXT DEFAULT '',
        categoria_balanza TEXT DEFAULT '',
        cod_interno TEXT DEFAULT '',
        tipo_equipo TEXT DEFAULT '',
        marca TEXT DEFAULT '',
        modelo TEXT DEFAULT '',
        serie TEXT DEFAULT '',
        unidades TEXT DEFAULT '',
        ubicacion TEXT DEFAULT '',
        num_celdas TEXT DEFAULT '',
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
        foto_balanza TEXT DEFAULT '',
        
        --apartados
        reporte TEXT DEFAULT '',
        evaluacion TEXT DEFAULT '',
      
        excentricidad_estado_general TEXT DEFAULT '',
        repetibilidad_estado_general TEXT DEFAULT '',
        linealidad_estado_general TEXT DEFAULT '',

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
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  Future<void> backupDatabase() async {
    final db = await database;
    final originalPath = join(await getDatabasesPath(), 'servicios_soporte_tecnico.db');
    final backupPath = join(await getDatabasesPath(), 'servicios_soporte_tecnico_backup_${DateTime.now().millisecondsSinceEpoch}.db');

    await File(originalPath).copy(backupPath);
    print('Backup creado en: $backupPath');
  }
}