import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mssql_connection/mssql_connection.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class InitialSetupScreen extends StatefulWidget {
  const InitialSetupScreen({super.key});

  @override
  State<InitialSetupScreen> createState() => _InitialSetupScreenState();
}

class _InitialSetupScreenState extends State<InitialSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final PageController _pageController = PageController();

  // Controladores de campos
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _portController = TextEditingController(text: '1433');
  final TextEditingController _dbController = TextEditingController();
  final TextEditingController _dbUserController = TextEditingController();
  final TextEditingController _dbPassController = TextEditingController();

// 👇 AGREGAR ESTOS NUEVOS CONTROLADORES
  final TextEditingController _appUserController = TextEditingController();
  final TextEditingController _appPassController = TextEditingController();

  int _currentStep = 0;
  bool _loading = false;
  bool _obscurePassword = true;

  // Progress indicators
  final ValueNotifier<String> _statusMessage = ValueNotifier<String>('');
  final ValueNotifier<double> _progressValue = ValueNotifier<double>(0.0);

  MssqlConnection? _connection;

  @override
  void dispose() {
    _pageController.dispose();
    _ipController.dispose();
    _portController.dispose();
    _dbController.dispose();
    _dbUserController.dispose();
    _dbPassController.dispose();

    _appUserController.dispose();
    _appPassController.dispose();
    _statusMessage.dispose();
    _progressValue.dispose();
    _connection?.disconnect();
    super.dispose();
  }

  // Validación de IP
  bool _isValidIP(String ip) {
    final ipRegex = RegExp(r'^(\d{1,3}\.){3}\d{1,3}$');
    if (!ipRegex.hasMatch(ip)) return false;

    final parts = ip.split('.');
    for (var part in parts) {
      final num = int.tryParse(part);
      if (num == null || num < 0 || num > 255) return false;
    }
    return true;
  }

  // Validación de puerto
  bool _isValidPort(String port) {
    final portNum = int.tryParse(port);
    return portNum != null && portNum > 0 && portNum <= 65535;
  }

  Future<bool> _validateUserCredentials(BuildContext context) async {
    setState(() => _loading = true);
    _statusMessage.value = 'Validando credenciales de usuario...';
    _progressValue.value = 0.0;

    try {
      final usuario = _appUserController.text.trim();
      final pass = _appPassController.text.trim();

      if (usuario.isEmpty || pass.isEmpty) {
        _showError(context, 'Usuario y contraseña son requeridos');
        return false;
      }

      // Buscar en la base de datos de usuarios ya descargada
      final dbPath = await getDatabasesPath();
      final usersDbPath = join(dbPath, 'usuarios.db');

      final dbExists = await databaseExists(usersDbPath);
      if (!dbExists) {
        _showError(context, 'Error: Base de datos de usuarios no encontrada');
        return false;
      }

      final db = await openDatabase(usersDbPath);

      final List<Map<String, dynamic>> results = await db.query(
        'usuarios',
        where: 'usuario = ? AND pass = ?',
        whereArgs: [usuario, pass],
      );

      await db.close();

      if (results.isEmpty) {
        _showError(context, 'Usuario o contraseña incorrecta');
        return false;
      }

      final userData = results.first;

      // Verificar que el usuario esté activo
      if (userData['estado'] != 'Activo') {
        _showError(context, 'Usuario inactivo. Contacte al administrador.');
        return false;
      }

      // Guardar datos del usuario autenticado
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('logged_user', usuario);
      await prefs.setString('logged_user_nombre',
          '${userData['titulo_abr'] ?? ''} ${userData['nombre1'] ?? ''} ${userData['apellido1'] ?? ''}'.trim());
      await prefs.setString('logged_user_titulo', userData['titulo_abr'] ?? '');
      await prefs.setBool('auto_login_enabled', true);

      _statusMessage.value = 'Usuario validado correctamente';
      _progressValue.value = 1.0;

      return true;

    } catch (e) {
      _showError(context, 'Error validando usuario: ${e.toString()}');
      return false;
    } finally {
      setState(() => _loading = false);
    }
  }

  // PASO 1: Validar conexión
  // PASO 1: Validar conexión (SIN descargar nada aún)
  Future<bool> _validateConnection(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return false;

    setState(() => _loading = true);
    _statusMessage.value = 'Validando conexión al servidor...';
    _progressValue.value = 0.1;

    try {
      _connection = MssqlConnection.getInstance();

      final connected = await _connection!.connect(
        ip: _ipController.text.trim(),
        port: _portController.text.trim(),
        databaseName: _dbController.text.trim(),
        username: _dbUserController.text.trim(),
        password: _dbPassController.text.trim(),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () => false,
      );

      if (!connected) {
        _showError(context, 'No se pudo conectar al servidor. Verifique los datos.');
        return false;
      }

      _progressValue.value = 0.3;
      _statusMessage.value = 'Conexión exitosa. Verificando permisos...';


      _progressValue.value = 0.5;
      _statusMessage.value = 'Conexión validada correctamente';

      return true;

    } catch (e) {
      _showError(context, 'Error al conectar: ${e.toString()}');
      return false;
    } finally {
      setState(() => _loading = false);
    }
  }

  // PASO 2: Validar credenciales del usuario en SQL Server
  Future<Map<String, dynamic>?> _validateUserInServer(BuildContext context) async {
    setState(() => _loading = true);
    _statusMessage.value = 'Validando credenciales de usuario...';
    _progressValue.value = 0.1;

    try {
      final usuario = _appUserController.text.trim();
      final pass = _appPassController.text.trim();

      if (usuario.isEmpty || pass.isEmpty) {
        _showError(context, 'Usuario y contraseña son requeridos');
        return null;
      }

      // Buscar usuario en SQL Server
      final query = '''
      SELECT nombre1, apellido1, apellido2, pass, usuario, titulo_abr, estado 
      FROM data_users 
      WHERE usuario = '$usuario' AND pass = '$pass'
    ''';

      final resultJson = await _connection!.getData(query).timeout(
        const Duration(seconds: 15),
      );

      if (resultJson.isEmpty || resultJson == '[]') {
        _showError(context, 'Usuario o contraseña incorrecta');
        return null;
      }

      final List<dynamic> result = jsonDecode(resultJson);

      if (result.isEmpty) {
        _showError(context, 'Usuario o contraseña incorrecta');
        return null;
      }

      final userData = Map<String, dynamic>.from(result.first);

      // Verificar que el usuario esté ACTIVO
      final estado = userData['estado']?.toString().toUpperCase() ?? '';

      if (estado != 'ACTIVO') {
        _showError(context, 'Usuario inactivo. Contacte al administrador.');
        return null;
      }

      _progressValue.value = 0.3;
      _statusMessage.value = 'Usuario validado correctamente';

      return userData;

    } catch (e) {
      _showError(context, 'Error validando usuario: ${e.toString()}');
      return null;
    }
  }

  // PASO 2: Descargar datos de precarga
  Future<bool> _downloadPrecargaData(BuildContext context) async {
    _statusMessage.value = 'Descargando datos del servidor...';
    _progressValue.value = 0.6;

    try {
      // Queries para precarga
      final queries = {
        'clientes': 'SELECT codigo_cliente, cliente, cliente_id, razonsocial FROM DATA_CLIENTES',
        'plantas': 'SELECT cliente_id, codigo_planta, planta_id, dep, dep_id, planta, dir FROM DATA_PLANTAS',
        'balanzas': 'SELECT * FROM DATA_EQUIPOS_BALANZAS',
        'inf': 'SELECT * FROM DATA_EQUIPOS',
        'equipamientos': 'SELECT * FROM DATA_EQUIPOS_CAL',
        'servicios': 'SELECT * FROM DATA_SERVICIOS_LEC',
      };

      // Abrir/crear base de datos precarga
      final dbPath = await getDatabasesPath();
      final precargaDbPath = join(dbPath, 'precarga_database.db');
      final db = await openDatabase(
        precargaDbPath,
        version: 1,
        onCreate: (db, version) async {
          await _createPrecargaTables(db);
        },
      );

      int tableIndex = 0;
      final totalTables = queries.length;

      for (var entry in queries.entries) {
        final tableName = entry.key;
        final query = entry.value;

        _statusMessage.value = 'Descargando tabla: $tableName...';

        // Ejecutar query
        final resultJson = await _connection!.getData(query).timeout(
          const Duration(seconds: 60),
        );

        if (resultJson.isEmpty || resultJson == '[]') continue;

        final List<dynamic> result = jsonDecode(resultJson);

        // Limpiar tabla y insertar datos
        await db.delete(tableName);

        for (var item in result) {
          await _insertPrecargaData(db, tableName, Map<String, dynamic>.from(item));
        }

        tableIndex++;
        _progressValue.value = 0.6 + (0.3 * tableIndex / totalTables);
      }

      await db.close();

      _progressValue.value = 0.9;
      _statusMessage.value = 'Datos de precarga descargados exitosamente';
      return true;

    } catch (e) {
      _showError(context, 'Error descargando datos: ${e.toString()}');
      return false;
    }
  }

  // PASO 3: Guardar SOLO el usuario autenticado en SQLite
  Future<bool> _saveAuthenticatedUser(BuildContext context, Map<String, dynamic> userData) async {
    _statusMessage.value = 'Guardando datos de usuario...';
    _progressValue.value = 0.5;

    try {
      // Crear base de datos de usuarios
      final dbPath = await getDatabasesPath();
      final usersDbPath = join(dbPath, 'usuarios.db');

      final db = await openDatabase(
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

      // Limpiar e insertar SOLO este usuario
      await db.delete('usuarios');

      await db.insert('usuarios', {
        'nombre1': userData['nombre1']?.toString() ?? '',
        'apellido1': userData['apellido1']?.toString() ?? '',
        'apellido2': userData['apellido2']?.toString() ?? '',
        'pass': userData['pass']?.toString() ?? '',
        'usuario': userData['usuario']?.toString() ?? '',
        'titulo_abr': userData['titulo_abr']?.toString() ?? '',
        'estado': userData['estado']?.toString() ?? '',
        'fecha_guardado': DateTime.now().toIso8601String(),
      });

      await db.close();

      // Guardar datos del usuario autenticado en SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final nombreCompleto = '${userData['titulo_abr'] ?? ''} ${userData['nombre1'] ?? ''} ${userData['apellido1'] ?? ''}'.trim();

      await prefs.setString('logged_user', userData['usuario']?.toString() ?? '');
      await prefs.setString('logged_user_nombre', nombreCompleto);
      await prefs.setString('logged_user_titulo', userData['titulo_abr']?.toString() ?? '');
      await prefs.setBool('auto_login_enabled', true);

      _progressValue.value = 0.6;
      _statusMessage.value = 'Usuario guardado exitosamente';

      return true;

    } catch (e) {
      _showError(context, 'Error guardando usuario: ${e.toString()}');
      return false;
    }
  }

  // PASO 3: Descargar tabla de usuarios
  Future<bool> _downloadUsersData(BuildContext context) async {
    _statusMessage.value = 'Descargando usuarios...';
    _progressValue.value = 0.8;

    try {
      final query = '''
        SELECT nombre1, apellido1, apellido2, pass, usuario, titulo_abr, estado 
        FROM data_users 
        WHERE estado = 'Activo'
      ''';

      final resultJson = await _connection!.getData(query).timeout(
        const Duration(seconds: 30),
      );

      if (resultJson.isEmpty || resultJson == '[]') {
        _showError(context, 'No se encontraron usuarios activos');
        return false;
      }

      final List<dynamic> result = jsonDecode(resultJson);

      // Crear base de datos de usuarios
      final dbPath = await getDatabasesPath();
      final usersDbPath = join(dbPath, 'usuarios.db');
      final db = await openDatabase(
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

      // Limpiar e insertar usuarios
      await db.delete('usuarios');

      for (var user in result) {
        await db.insert('usuarios', {
          ...Map<String, dynamic>.from(user),
          'fecha_guardado': DateTime.now().toIso8601String(),
        });
      }

      await db.close();

      _progressValue.value = 0.9;
      _statusMessage.value = 'Usuarios descargados exitosamente';
      return true;

    } catch (e) {
      _showError(context, 'Error descargando usuarios: ${e.toString()}');
      return false;
    }
  }

  // PASO 4: Guardar configuración
  Future<void> _saveConfiguration() async {
    final prefs = await SharedPreferences.getInstance();

    // Guardar credenciales de conexión
    await prefs.setString('ip', _ipController.text.trim());
    await prefs.setString('port', _portController.text.trim());
    await prefs.setString('database', _dbController.text.trim());
    await prefs.setString('dbuser', _dbUserController.text.trim());
    await prefs.setString('dbpass', _dbPassController.text.trim());

    // Marcar configuración como completada
    await prefs.setBool('setup_completed', true);
    await prefs.setString('setup_date', DateTime.now().toIso8601String());
    await prefs.setString('lastUpdate', DateTime.now().toIso8601String());

    _statusMessage.value = 'Configuración guardada';
    _progressValue.value = 1.0;
  }

  // Ejecutar todo el proceso
  // Ejecutar todo el proceso
  Future<void> _executeSetup(BuildContext context) async {
    // ========== PASO 1: CONFIGURACIÓN DE BD ==========
    if (_currentStep == 0) {
      if (!_formKey.currentState!.validate()) return;

      setState(() => _loading = true);

      try {
        // Validar conexión (NO descargar nada aún)
        if (!await _validateConnection(context)) {
          setState(() => _loading = false);
          return;
        }

        // Avanzar al paso 2
        setState(() {
          _currentStep = 1;
          _loading = false;
        });

      } catch (e) {
        _showError(context, 'Error en configuración: ${e.toString()}');
        setState(() => _loading = false);
      }

      return;
    }

    // ========== PASO 2: CREDENCIALES DE USUARIO ==========
    if (_currentStep == 1) {
      if (!_formKey.currentState!.validate()) return;

      setState(() => _loading = true);

      try {
        // 1. Validar usuario en SQL Server
        final userData = await _validateUserInServer(context);

        if (userData == null) {
          setState(() => _loading = false);
          return;
        }

        // 2. Guardar SOLO este usuario en SQLite
        if (!await _saveAuthenticatedUser(context, userData)) {
          setState(() => _loading = false);
          return;
        }

        // 3. Descargar datos de precarga
        if (!await _downloadPrecargaData(context)) {
          setState(() => _loading = false);
          return;
        }

        // 4. Guardar configuración de conexión
        await _saveConfiguration();

        // 5. Navegar al login
        _statusMessage.value = 'Configuración completada exitosamente';
        _progressValue.value = 1.0;

        await Future.delayed(const Duration(seconds: 1));

        if (mounted) {
          await _connection?.disconnect();
          Navigator.pushReplacementNamed(context, '/login');
        }

      } catch (e) {
        _showError(context, 'Error en configuración: ${e.toString()}');
        setState(() => _loading = false);
      }

      return;
    }
  }

  void _showError(BuildContext context, String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Crear tablas de precarga
  Future<void> _createPrecargaTables(Database db) async {
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
        unique_key TEXT PRIMARY KEY,
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
        categoria TEXT
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
    final serviciosFields = ['cod_metrica TEXT PRIMARY KEY', 'seca TEXT', 'reg_fecha TEXT', 'reg_usuario TEXT', 'exc TEXT'];

    for (int i = 1; i <= 30; i++) {
      serviciosFields.add('rep$i TEXT');
    }
    for (int i = 1; i <= 60; i++) {
      serviciosFields.add('lin$i TEXT');
    }

    await db.execute('CREATE TABLE servicios (${serviciosFields.join(', ')})');
  }

  // Insertar datos de precarga según tabla
  Future<void> _insertPrecargaData(Database db, String table, Map<String, dynamic> data) async {
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
          'unique_key': '${plantaId}_$depId',
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

        // Agregar campos rep dinámicamente
        for (int i = 1; i <= 30; i++) {
          final key = 'rep$i';
          if (data.containsKey(key)) {
            servicioData[key] = data[key]?.toString() ?? '';
          }
        }

        // Agregar campos lin dinámicamente
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
        conflictAlgorithm: ConflictAlgorithm.replace, // ← SOLUCIÓN PARA DUPLICADOS
      );
    } catch (e) {
      debugPrint('Error insertando en tabla $table: $e');
      debugPrint('Datos problemáticos: $rowData');
      // No relanzamos la excepción para continuar con los demás registros
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF1a1a1a), const Color(0xFF2d2d2d)]
                : [const Color(0xFFF5F7FA), const Color(0xFFE8EDF2)],
          ),
        ),
        child: SafeArea(
          child: _loading ? _buildLoadingScreen(isDark) : _buildSetupForm(context, isDark),
        ),
      ),
    );
  }

  Widget _buildLoadingScreen(bool isDark) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(40),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2d2d2d) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_download_rounded,
              size: 64,
              color: const Color(0xFF0E8833),
            ),
            const SizedBox(height: 24),
            Text(
              'Configurando Aplicación',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            ValueListenableBuilder<String>(
              valueListenable: _statusMessage,
              builder: (context, message, _) {
                return Text(
                  message,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            ValueListenableBuilder<double>(
              valueListenable: _progressValue,
              builder: (context, progress, _) {
                return Column(
                  children: [
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey[300],
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0E8833)),
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0E8833),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSetupForm(BuildContext context, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Logo
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Image.asset(
              'images/logo_met.png',
              height: 60,
            ),
          ),
          const SizedBox(height: 32),

          // Indicador de pasos
          Row(
            children: [
              Expanded(
                child: _buildStepIndicator(0, 'Conexión BD', isDark),
              ),
              Container(
                width: 40,
                height: 2,
                color: _currentStep >= 1
                    ? const Color(0xFF0E8833)
                    : (isDark ? Colors.white24 : Colors.black12),
              ),
              Expanded(
                child: _buildStepIndicator(1, 'Usuario', isDark),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Card principal
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2d2d2d) : Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: _currentStep == 0
                  ? _buildConnectionStep(context, isDark)
                  : _buildUserCredentialsStep(context, isDark),
            ),
          ),

          const SizedBox(height: 24),

          // Información
          _buildInfoCard(isDark),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label, bool isDark) {
    final isActive = _currentStep == step;
    final isCompleted = _currentStep > step;

    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isCompleted || isActive
                ? const Color(0xFF0E8833)
                : (isDark ? Colors.white12 : Colors.black12),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, color: Colors.white, size: 20)
                : Text(
              '${step + 1}',
              style: GoogleFonts.inter(
                color: isActive ? Colors.white : (isDark ? Colors.white38 : Colors.black38),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            color: isActive
                ? const Color(0xFF0E8833)
                : (isDark ? Colors.white60 : Colors.black54),
          ),
        ),
      ],
    );
  }

  Widget _buildConnectionStep(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0E8833).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.storage_outlined,
                color: Color(0xFF0E8833),
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Paso 1: Conexión',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  Text(
                    'Configure la conexión al servidor',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),

        // Campos de configuración
        _buildConfigField('IP del Servidor', _ipController, Icons.dns_outlined, isDark),
        const SizedBox(height: 16),
        _buildConfigField('Puerto', _portController, Icons.cable_outlined, isDark, isNumber: true),
        const SizedBox(height: 16),
        _buildConfigField('Base de Datos', _dbController, Icons.storage_outlined, isDark),
        const SizedBox(height: 16),
        _buildConfigField('Usuario BD', _dbUserController, Icons.admin_panel_settings_outlined, isDark),
        const SizedBox(height: 16),
        _buildConfigField('Contraseña BD', _dbPassController, Icons.vpn_key_outlined, isDark, isPassword: true),

        const SizedBox(height: 32),

        // Botón continuar
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0E8833),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: _loading ? null : () { _executeSetup(context); },
            icon: const Icon(Icons.arrow_forward),
            label: Text(
              'Validar Conexión y Continuar',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserCredentialsStep(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0E8833).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.person_outline,
                color: Color(0xFF0E8833),
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Paso 2: Usuario',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  Text(
                    'Ingrese sus credenciales de acceso',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),

        // Campo Usuario
        Text(
          'Usuario',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _appUserController,
          style: GoogleFonts.inter(
            fontSize: 15,
            color: isDark ? Colors.white : Colors.black87,
          ),
          decoration: InputDecoration(
            hintText: 'Ingresa tu usuario',
            hintStyle: GoogleFonts.inter(
              color: isDark ? Colors.white30 : Colors.black26,
            ),
            filled: true,
            fillColor: isDark ? const Color(0xFF1a1a1a) : const Color(0xFFF5F7FA),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 18,
            ),
            prefixIcon: Icon(
              Icons.person_outline_rounded,
              color: isDark ? Colors.white70 : Colors.black38,
              size: 22,
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Usuario es requerido';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),

        // Campo Contraseña
        Text(
          'Contraseña',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _appPassController,
          obscureText: _obscurePassword,
          keyboardType: TextInputType.number,
          style: GoogleFonts.inter(
            fontSize: 15,
            color: isDark ? Colors.white : Colors.black87,
          ),
          decoration: InputDecoration(
            hintText: 'Ingresa tu contraseña',
            hintStyle: GoogleFonts.inter(
              color: isDark ? Colors.white30 : Colors.black26,
            ),
            filled: true,
            fillColor: isDark ? const Color(0xFF1a1a1a) : const Color(0xFFF5F7FA),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 18,
            ),
            prefixIcon: Icon(
              Icons.lock_outline_rounded,
              color: isDark ? Colors.white70 : Colors.black38,
              size: 22,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: isDark ? Colors.white70 : Colors.black38,
                size: 22,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Contraseña es requerida';
            }
            if (value.length < 4) {
              return 'Mínimo 4 caracteres';
            }
            return null;
          },
        ),

        const SizedBox(height: 32),

        // Botones
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: isDark ? Colors.white70 : Colors.black54,
                  side: BorderSide(
                    color: isDark ? Colors.white24 : Colors.black12,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: _loading ? null : () {
                  setState(() => _currentStep = 0);
                },
                icon: const Icon(Icons.arrow_back, size: 20),
                label: Text(
                  'Atrás',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0E8833),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: _loading ? null : () { _executeSetup(context); },
                icon: const Icon(Icons.check_circle_outline, size: 20),
                label: Text(
                  'Finalizar Setup',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0E8833).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF0E8833).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline,
            color: Color(0xFF0E8833),
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _currentStep == 0
                  ? 'Paso 1 de 2: Se conectará al servidor y descargará los datos necesarios.'
                  : 'Paso 2 de 2: Ingrese sus credenciales para configurar el acceso automático.',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: isDark ? Colors.white70 : Colors.black87,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigField(String label, TextEditingController controller, IconData icon, bool isDark, {bool isPassword = false, bool isNumber = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: isPassword && _obscurePassword,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          style: GoogleFonts.inter(
            fontSize: 15,
            color: isDark ? Colors.white : Colors.black87,
          ),
          decoration: InputDecoration(
            hintText: 'Ingresa $label',
            hintStyle: GoogleFonts.inter(
              color: isDark ? Colors.white30 : Colors.black26,
            ),
            filled: true,
            fillColor: isDark ? const Color(0xFF1a1a1a) : const Color(0xFFF5F7FA),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 18,
            ),
            prefixIcon: Icon(
              icon,
              color: isDark ? Colors.white70 : Colors.black38,
              size: 22,
            ),
            suffixIcon: isPassword
                ? IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: isDark ? Colors.white70 : Colors.black38,
                size: 22,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            )
                : null,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Este campo es requerido';
            }

            if (label == 'IP del Servidor' && !_isValidIP(value)) {
              return 'IP inválida';
            }

            if (label == 'Puerto' && !_isValidPort(value)) {
              return 'Puerto inválido (1-65535)';
            }

            return null;
          },
        ),
      ],
    );
  }
}