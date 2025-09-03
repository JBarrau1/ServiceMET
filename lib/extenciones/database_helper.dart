import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // Cambiamos a la base de datos usuarios.db
    String path = join(await getDatabasesPath(), 'usuarios.db');
    return await openDatabase(path, version: 1);
  }

  Future<Map<String, dynamic>?> getUserData() async {
    final db = await database;
    try {
      // Consultamos la tabla 'usuario' (ajusta el nombre si es diferente)
      final List<Map<String, dynamic>> maps = await db.query('usuarios');
      if (maps.isNotEmpty) {
        return maps.first; // Retornamos el primer usuario encontrado
      }
      return null;
    } catch (e) {
      print("Error al obtener datos de usuario: $e");
      return null;
    }
  }
}
