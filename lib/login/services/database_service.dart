// lib/login/services/database_service.dart

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/material.dart';

class DatabaseService {
  // Crear tablas de precarga
  Future<void> createPrecargaTables(Database db) async {
    await db.execute('''
      CREATE TABLE clientes (
        codigo_cliente TEXT PRIMARY KEY,
        cliente_id TEXT,
        cliente TEXT,
        razonsocial TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE plantas (
        planta TEXT,
        planta_id TEXT,
        cliente_id TEXT,
        dep_id TEXT,
        codigo_planta TEXT,
        dep TEXT,
        dir TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE balanzas (
        cod_metrica TEXT PRIMARY KEY,
        serie TEXT,
        unidad TEXT,
        n_celdas TEXT,
        cap_max1 TEXT,
        d1 TEXT,
        e1 TEXT,
        dec1 TEXT,
        cap_max2 TEXT,
        d2 TEXT,
        e2 TEXT,
        dec2 TEXT,
        cap_max3 TEXT,
        d3 TEXT,
        e3 TEXT,
        dec3 TEXT,
        categoria TEXT,
        tecnologia TEXT,
        clase TEXT,
        tipo TEXT,
        rango TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE inf (
        cod_interno TEXT PRIMARY KEY,
        cod_metrica TEXT,
        instrumento TEXT,
        tipo_instrumento TEXT,
        marca TEXT,
        modelo TEXT,
        serie TEXT,
        estado TEXT,
        detalles TEXT,
        ubicacion TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE equipamientos (
        cod_instrumento TEXT PRIMARY KEY,
        instrumento TEXT,
        cert_fecha TEXT,
        ente_calibrador TEXT,
        estado TEXT
      )
    ''');

    // Tabla servicios con campos dinámicos
    final serviciosFields = [
      'cod_metrica TEXT PRIMARY KEY',
      'seca TEXT',
      'reg_fecha TEXT',
      'reg_usuario TEXT',
      'exc TEXT'
    ];

    for (int i = 1; i <= 30; i++) {
      serviciosFields.add('rep$i TEXT');
    }
    for (int i = 1; i <= 60; i++) {
      serviciosFields.add('lin$i TEXT');
    }

    await db.execute('CREATE TABLE servicios (${serviciosFields.join(', ')})');
  }

  // Insertar datos de precarga
  Future<void> insertPrecargaData(
    Database db,
    String table,
    Map<String, dynamic> data,
  ) async {
    final Map<String, dynamic> rowData;

    switch (table) {
      case 'clientes':
        rowData = {
          'codigo_cliente': data['codigo_cliente']?.toString() ?? '',
          'cliente_id': data['cliente_id']?.toString() ?? '',
          'cliente': data['cliente']?.toString() ?? '',
          'razonsocial': data['razonsocial']?.toString() ?? '',
        };
        break;

      case 'plantas':
        final plantaId = data['planta_id']?.toString() ?? '';
        final depId = data['dep_id']?.toString() ?? '';
        rowData = {
          'planta': data['planta']?.toString() ?? '',
          'planta_id': plantaId,
          'cliente_id': data['cliente_id']?.toString() ?? '',
          'dep_id': depId,
          'codigo_planta': data['codigo_planta']?.toString() ?? '',
          'dep': data['dep']?.toString() ?? '',
          'dir': data['dir']?.toString() ?? '',
        };
        break;

      case 'balanzas':
        rowData = {
          'cod_metrica': data['cod_metrica']?.toString() ?? '',
          'serie': data['serie']?.toString() ?? '',
          'unidad': data['unidad']?.toString() ?? '',
          'n_celdas': data['n_celdas']?.toString() ?? '',
          'cap_max1': data['cap_max1']?.toString() ?? '',
          'd1': data['d1']?.toString() ?? '',
          'e1': data['e1']?.toString() ?? '',
          'dec1': data['dec1']?.toString() ?? '',
          'cap_max2': data['cap_max2']?.toString() ?? '',
          'd2': data['d2']?.toString() ?? '',
          'e2': data['e2']?.toString() ?? '',
          'dec2': data['dec2']?.toString() ?? '',
          'cap_max3': data['cap_max3']?.toString() ?? '',
          'd3': data['d3']?.toString() ?? '',
          'e3': data['e3']?.toString() ?? '',
          'dec3': data['dec3']?.toString() ?? '',
          'categoria': data['categoria']?.toString() ?? '',
          'tecnologia': data['tecnologia']?.toString() ?? '',
          'clase': data['clase']?.toString() ?? '',
          'tipo': data['tipo']?.toString() ?? '',
          'rango': data['rango']?.toString() ?? '',
        };
        break;

      case 'inf':
        rowData = {
          'cod_interno': data['cod_interno']?.toString() ?? '',
          'cod_metrica': data['cod_metrica']?.toString() ?? '',
          'instrumento': data['instrumento']?.toString() ?? '',
          'tipo_instrumento': data['tipo_instrumento']?.toString() ?? '',
          'marca': data['marca']?.toString() ?? '',
          'modelo': data['modelo']?.toString() ?? '',
          'serie': data['serie']?.toString() ?? '',
          'estado': data['estado']?.toString() ?? '',
          'detalles': data['detalles']?.toString() ?? '',
          'ubicacion': data['ubicacion']?.toString() ?? '',
        };
        break;

      case 'equipamientos':
        rowData = {
          'cod_instrumento': data['cod_instrumento']?.toString() ?? '',
          'instrumento': data['instrumento']?.toString() ?? '',
          'cert_fecha': data['cert_fecha']?.toString() ?? '',
          'ente_calibrador': data['ente_calibrador']?.toString() ?? '',
          'estado': data['estado']?.toString() ?? '',
        };
        break;

      case 'servicios':
        final servicioData = <String, dynamic>{
          'cod_metrica': data['cod_metrica']?.toString() ?? '',
          'seca': data['seca']?.toString() ?? '',
          'reg_fecha': data['reg_fecha']?.toString() ?? '',
          'reg_usuario': data['reg_usuario']?.toString() ?? '',
          'exc': data['exc']?.toString() ?? '',
        };

        for (int i = 1; i <= 30; i++) {
          final key = 'rep$i';
          if (data.containsKey(key)) {
            servicioData[key] = data[key]?.toString() ?? '';
          }
        }

        for (int i = 1; i <= 60; i++) {
          final key = 'lin$i';
          if (data.containsKey(key)) {
            servicioData[key] = data[key]?.toString() ?? '';
          }
        }

        rowData = servicioData;
        break;

      default:
        debugPrint('Tabla desconocida: $table');
        return;
    }

    try {
      await db.insert(
        table,
        rowData,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      debugPrint('Error insertando en tabla $table: $e');
      debugPrint('Datos problemáticos: $rowData');
    }
  }

  // Crear tabla de usuarios
  Future<Database> createUsersDatabase() async {
    final dbPath = await getDatabasesPath();
    final usersDbPath = join(dbPath, 'usuarios.db');

    return await openDatabase(
      usersDbPath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE usuarios (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nombre1 TEXT,
            apellido1 TEXT,
            apellido2 TEXT,
            pass TEXT,
            usuario TEXT,
            titulo_abr TEXT,
            estado TEXT,
            fecha_guardado TEXT
          )
        ''');
      },
    );
  }
}
