import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelperPrecarga {
  static final DatabaseHelperPrecarga _instance =
      DatabaseHelperPrecarga._internal();
  static Database? _database;
  static final String _databaseName =
      'precarga_database.db'; // Nombre de la base de datos

  // Constructor privado
  DatabaseHelperPrecarga._internal();

  // Obtener la instancia única
  factory DatabaseHelperPrecarga() {
    return _instance;
  }

  Future<void> deleteDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _databaseName);

    try {
      await databaseFactory.deleteDatabase(path);
      _database = null; // Resetear la instancia de la base de datos
      print('Precarga eliminada correctamente en: $path');
    } catch (e) {
      print('Error al eliminar la Precarga: $e');
      throw Exception('Error al eliminar la Precarga: $e');
    }
  }

  // Obtener la base de datos
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Inicializar la base de datos
  Future<Database> _initDatabase() async {
    // Obtener la ruta de la base de datos
    String path = join(await getDatabasesPath(), 'precarga_database.db');
    print('Ruta de la base de datos: $path'); // Depuración

    // Abrir la base de datos con permisos de lectura y escritura
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      readOnly: false, // Asegúrate de que no esté en modo solo lectura
    );
  }

  // Crear las tablas
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
    CREATE TABLE IF NOT EXISTS clientes (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      codigo_cliente TEXT,
      cliente_id TEXT,
      cliente TEXT,
      razonsocial TEXT
    )
  ''');
    await db.execute('''
    CREATE TABLE IF NOT EXISTS plantas (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      planta TEXT,
      planta_id TEXT,
      codigo_planta TEXT,
      dep TEXT,
      dir TEXT,
      cliente_id TEXT,
      dep_id TEXT
     
    )
  ''');
    await db.execute('''
    CREATE TABLE IF NOT EXISTS balanzas (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      cod_metrica TEXT,
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
      categoria TEXT
    )
  ''');
    await db.execute('''
    CREATE TABLE IF NOT EXISTS inf (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      cod_interno TEXT,
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
    CREATE TABLE IF NOT EXISTS equipamientos (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      cod_instrumento TEXT,
      instrumento TEXT,
      cert_fecha TEXT,
      ente_calibrador TEXT,
      estado TEXT
    )
  ''');
    await db.execute('''
    CREATE TABLE IF NOT EXISTS servicios (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      cod_interno TEXT,
      cod_metrica TEXT,
      seca TEXT,
      reg_fecha TEXT,
      reg_usuario TEXT,
      exc TEXT,
      rep1 TEXT,
      rep2 TEXT,
      rep3 TEXT,
      rep4 TEXT,
      rep5 TEXT,
      rep6 TEXT,
      rep7 TEXT,
      rep8 TEXT,
      rep9 TEXT,
      rep10 TEXT,
      rep11 TEXT,
      rep12 TEXT,
      rep13 TEXT,
      rep14 TEXT,
      rep15 TEXT,
      rep16 TEXT,
      rep17 TEXT,
      rep18 TEXT,
      rep19 TEXT,
      rep20 TEXT,
      rep21 TEXT,
      rep22 TEXT,
      rep23 TEXT,
      rep24 TEXT,
      rep25 TEXT,
      rep26 TEXT,
      rep27 TEXT,
      rep28 TEXT,
      rep29 TEXT,
      rep30 TEXT,
      lin1 TEXT,
      lin2 TEXT,
      lin3 TEXT,
      lin4 TEXT,
      lin5 TEXT,
      lin6 TEXT,
      lin7 TEXT,
      lin8 TEXT,
      lin9 TEXT,
      lin10 TEXT,
      lin11 TEXT,
      lin12 TEXT,
      lin13 TEXT,
      lin14 TEXT,
      lin15 TEXT,
      lin16 TEXT,
      lin17 TEXT,
      lin18 TEXT,
      lin19 TEXT,
      lin20 TEXT,
      lin21 TEXT,
      lin22 TEXT,
      lin23 TEXT,
      lin24 TEXT,
      lin25 TEXT,
      lin26 TEXT,
      lin27 TEXT,
      lin28 TEXT,
      lin29 TEXT,
      lin30 TEXT,
      lin31 TEXT,
      lin32 TEXT,
      lin33 TEXT,
      lin34 TEXT,
      lin35 TEXT,
      lin36 TEXT,
      lin37 TEXT,
      lin38 TEXT,
      lin39 TEXT,
      lin40 TEXT,
      lin41 TEXT,
      lin42 TEXT,
      lin43 TEXT,
      lin44 TEXT,
      lin45 TEXT,
      lin46 TEXT,
      lin47 TEXT,
      lin48 TEXT,
      lin49 TEXT,
      lin50 TEXT,
      lin51 TEXT,
      lin52 TEXT,
      lin53 TEXT,
      lin54 TEXT,
      lin55 TEXT,
      lin56 TEXT,
      lin57 TEXT,
      lin58 TEXT,
      lin59 TEXT,
      lin60 TEXT
    )
  ''');
  }

  // Métodos para acceder a los datos
  Future<List<Map<String, dynamic>>> getClientes() async {
    final db = await database;
    return await db.query('clientes');
  }

  Future<List<Map<String, dynamic>>> getPlantas() async {
    final db = await database;
    return await db.query('plantas');
  }

  Future<List<Map<String, dynamic>>> getBalanzas() async {
    final db = await database;
    return await db.query('balanzas');
  }

  Future<List<Map<String, dynamic>>> getInf() async {
    final db = await database;
    return await db.query('inf');
  }

  Future<List<Map<String, dynamic>>> getEquipamientos() async {
    final db = await database;
    return await db.query('equipamientos');
  }

  Future<List<Map<String, dynamic>>> getServicios() async {
    final db = await database;
    return await db.query('servicios');
  }
}
