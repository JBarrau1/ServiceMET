import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:mssql_connection/mssql_connection.dart';
import 'package:crypto/crypto.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _usuarioController = TextEditingController();
  final TextEditingController _passController = TextEditingController();

  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _portController = TextEditingController();
  final TextEditingController _dbController = TextEditingController();
  final TextEditingController _dbUserController = TextEditingController();
  final TextEditingController _dbPassController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  final _configFormKey = GlobalKey<FormState>();

  bool recordarCredenciales = false;
  bool showConfig = false;
  bool _loading = false;
  bool _obscurePassword = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final connection = MssqlConnection.getInstance();

  @override
  void initState() {
    super.initState();
    _loadPrefs();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _usuarioController.dispose();
    _passController.dispose();
    _ipController.dispose();
    _portController.dispose();
    _dbController.dispose();
    _dbUserController.dispose();
    _dbPassController.dispose();
    super.dispose();
  }

  String hashPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  String sanitizeInput(String input) {
    return input.replaceAll("'", "''")
        .replaceAll(";", "")
        .replaceAll("--", "")
        .replaceAll("/*", "")
        .replaceAll("*/", "")
        .replaceAll("xp_", "")
        .replaceAll("sp_", "")
        .trim();
  }

  bool isValidInput(String input) {
    final dangerousPatterns = [
      'drop', 'delete', 'insert', 'update', 'create', 'alter',
      'exec', 'execute', 'union', 'select', 'script'
    ];
    final lowerInput = input.toLowerCase();
    return !dangerousPatterns.any((pattern) => lowerInput.contains(pattern));
  }

  Future<bool> _hasInternetConnection() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      return false;
    }
  }

  // CORREGIDO: Cargar preferencias incluyendo contraseña si recordar está activado
  Future<void> _loadPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Cargar configuración de conexión
    _ipController.text = prefs.getString('ip') ?? '';
    _portController.text = prefs.getString('port') ?? '1433';
    _dbController.text = prefs.getString('database') ?? '';
    _dbUserController.text = prefs.getString('dbuser') ?? '';
    _dbPassController.text = prefs.getString('dbpass') ?? '';

    // Cargar credenciales de usuario SI recordar está activado
    recordarCredenciales = prefs.getBool('recordar') ?? false;
    if (recordarCredenciales) {
      _usuarioController.text = prefs.getString('usuario') ?? '';
      _passController.text = prefs.getString('contrasena') ?? ''; // CARGAR CONTRASEÑA TAMBIÉN
    }

    setState(() {});
  }

  // CORREGIDO: Guardar preferencias incluyendo TODAS las contraseñas
  Future<void> _savePrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Guardar configuración de conexión (INCLUYENDO contraseña BD)
    await prefs.setString('ip', _ipController.text);
    await prefs.setString('port', _portController.text);
    await prefs.setString('database', _dbController.text);
    await prefs.setString('dbuser', _dbUserController.text);

    // CORREGIDO: Guardar contraseña de BD siempre que no esté vacía
    if (_dbPassController.text.isNotEmpty) {
      await prefs.setString('dbpass', _dbPassController.text);
    }

    // Guardar estado de recordar
    await prefs.setBool('recordar', recordarCredenciales);

    // CORREGIDO: Guardar credenciales de usuario SI recordar está activado
    if (recordarCredenciales) {
      await prefs.setString('usuario', _usuarioController.text);
      await prefs.setString('contrasena', _passController.text); // GUARDAR CONTRASEÑA EN TEXTO PLANO
    } else {
      await prefs.remove('usuario');
      await prefs.remove('contrasena');
    }
  }

  Future<void> _saveUserToSQLite(Map<String, dynamic> userData) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'usuarios.db');

    Database? db;
    try {
      db = await openDatabase(path, version: 1,
          onCreate: (Database db, int version) async {
            await db.execute('''
        CREATE TABLE IF NOT EXISTS usuarios (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nombre1 TEXT,
          apellido1 TEXT,
          pass TEXT,
          usuario TEXT,
          titulo_abr TEXT,
          estado TEXT,
          fecha_guardado TEXT
        )
      ''');
          });

      await db.delete('usuarios');
      final userDataConFecha = {
        ...userData,
        'fecha_guardado': DateTime.now().toIso8601String(),
      };
      await db.insert('usuarios', userDataConFecha);
    } catch (e) {
      print('Error guardando en SQLite: $e');
    } finally {
      await db?.close();
    }
  }

  // NUEVO: Verificar usuario en SQLite (modo offline)
  Future<Map<String, dynamic>?> _verificarUsuarioEnSQLite(String usuario, String pass) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'usuarios.db');

    try {
      // Verificar si la BD existe
      final dbExists = await databaseExists(path);
      print('💾 ¿Base de datos SQLite existe? $dbExists');

      if (!dbExists) {
        print('⚠️ No hay base de datos SQLite. Se requiere login online exitoso primero.');
        return null;
      }

      final db = await openDatabase(path);

      // Verificar si la tabla existe
      final tables = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='usuarios'"
      );
      print('📊 Tablas encontradas: $tables');

      if (tables.isEmpty) {
        print('⚠️ Tabla "usuarios" no existe en SQLite');
        await db.close();
        return null;
      }

      final List<Map<String, dynamic>> results = await db.query(
        'usuarios',
        where: 'usuario = ? AND pass = ?',
        whereArgs: [usuario, pass],
      );

      print('🔍 Resultados SQLite: ${results.length} registros encontrados');

      await db.close();

      if (results.isNotEmpty) {
        return results.first;
      }
    } catch (e) {
      print('❌ Error consultando SQLite: $e');
    }
    return null;
  }

  // CORREGIDO: Login unificado con detección inteligente de timeout
  Future<void> _loginUnified(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final usuario = _usuarioController.text.trim();
    final pass = _passController.text.trim();

    // Variable para controlar si mostrar diálogo de timeout
    bool showTimeoutDialog = false;
    Timer? timeoutTimer;

    try {
      // PASO 1: Verificar si hay conexión a internet
      final hasInternet = await _hasInternetConnection();

      if (hasInternet) {
        print('📡 Conexión a internet detectada. Intentando login online...');

        // Timer para mostrar opción de modo offline después de 10 segundos
        timeoutTimer = Timer(const Duration(seconds: 10), () {
          if (_loading && mounted) {
            showTimeoutDialog = true;
            _mostrarDialogoModoOffline(context, usuario, pass);
          }
        });

        final successOnline = await _loginOnline(context, usuario, pass);

        // Cancelar timer si login fue exitoso o falló rápido
        timeoutTimer.cancel();

        if (successOnline) {
          setState(() => _loading = false);
          return;
        }

        // Si no se mostró el diálogo y falló online, intentar offline
        if (!showTimeoutDialog) {
          print('⚠️ Login online falló. Intentando modo offline...');
        }
      } else {
        print('📵 Sin conexión a internet. Modo offline.');
      }

      // PASO 2: Modo OFFLINE (si no se mostró el diálogo)
      if (!showTimeoutDialog) {
        final successOffline = await _loginOffline(context, usuario, pass);

        if (!successOffline && !hasInternet) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sin conexión. Debe iniciar sesión en línea al menos una vez.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }

    } catch (e) {
      timeoutTimer?.cancel();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      if (!showTimeoutDialog) {
        setState(() => _loading = false);
      }
    }
  }

  // NUEVO: Diálogo para ofrecer modo offline cuando tarda mucho
  void _mostrarDialogoModoOffline(BuildContext context, String usuario, String pass) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.wifi_off_rounded, color: Colors.orange[700], size: 28),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Conexión lenta',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'El servidor está tardando en responder.',
                style: TextStyle(fontSize: 15),
              ),
              const SizedBox(height: 12),
              const Text(
                '¿Deseas continuar esperando o intentar acceder en modo offline?',
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                // Seguir esperando, no hacer nada
                print('⏳ Usuario decidió seguir esperando...');
              },
              child: Text(
                'Seguir esperando',
                style: GoogleFonts.inter(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                print('🔄 Usuario optó por modo offline...');

                // Desconectar intento online
                await connection.disconnect();

                // Intentar login offline
                final successOffline = await _loginOffline(context, usuario, pass);

                if (!successOffline) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('No hay credenciales guardadas para acceso offline'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }

                setState(() => _loading = false);
              },
              icon: const Icon(Icons.offline_bolt, size: 20),
              label: const Text('Modo Offline'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[700],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _loginOnline(BuildContext context, String usuario, String pass) async {
    try {
      if (!isValidInput(usuario) || !isValidInput(pass)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Caracteres no válidos detectados')),
        );
        return false;
      }

      final ip = _ipController.text.trim();
      final port = _portController.text.trim();
      final dbName = _dbController.text.trim();
      final dbUser = _dbUserController.text.trim();
      final dbPass = _dbPassController.text.trim();

      // Validar que todos los campos de configuración estén llenos
      if (ip.isEmpty || port.isEmpty || dbName.isEmpty || dbUser.isEmpty || dbPass.isEmpty) {
        print('⚠️ Configuración de conexión incompleta');
        return false;
      }

      final usuarioSeguro = sanitizeInput(usuario);
      final passSeguro = sanitizeInput(pass);
      final timeoutDuration = const Duration(seconds: 15);

      final connected = await connection
          .connect(
        ip: ip,
        port: port,
        databaseName: dbName,
        username: dbUser,
        password: dbPass,
      )
          .timeout(timeoutDuration, onTimeout: () {
        print('⏱️ Timeout en conexión');
        return false;
      });

      if (!connected) {
        print('❌ No se pudo conectar al servidor');
        return false;
      }

      final query = '''
      SELECT nombre1, apellido1, pass, usuario, titulo_abr, estado 
      FROM data_users 
      WHERE usuario = '$usuarioSeguro' AND pass = '$passSeguro'
    ''';

      print('🔍 Query ejecutado: $query');
      print('📤 Usuario enviado: "$usuarioSeguro"');
      print('📤 Password enviado: "$passSeguro"');

      final resultJson = await connection
          .getData(query)
          .timeout(timeoutDuration, onTimeout: () {
        print('⏱️ Timeout en consulta');
        return '[]';
      });

      print('📥 Respuesta del servidor: $resultJson');

      if (resultJson.isEmpty || resultJson == '[]' || resultJson == 'null') {
        print('❌ Respuesta vacía del servidor');
        return false;
      }

      final List<dynamic> result = jsonDecode(resultJson);

      if (result.isNotEmpty) {
        final userData = Map<String, dynamic>.from(result.first);

        // GUARDAR EN SQLite para login offline
        await _saveUserToSQLite(userData);
        await _savePrefs();

        // Limpiar flag de modo demo
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool('modoDemo', false);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Inicio de sesión exitoso (Online)'),
            backgroundColor: Color(0xFF0E8833),
          ),
        );

        Navigator.pushReplacementNamed(context, '/home');
        return true;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Usuario o contraseña incorrecta'),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }
    } on TimeoutException catch (e) {
      print('⏱️ Timeout en login online: ${e.message}');
      return false;
    } catch (e) {
      print('❌ Error en login online: ${e.toString()}');
      return false;
    } finally {
      await connection.disconnect();
    }
  }

  Future<bool> _loginOffline(BuildContext context, String usuario, String pass) async {
    try {
      // INTENTAR con SQLite primero
      final usuarioSQLite = await _verificarUsuarioEnSQLite(usuario, pass);

      if (usuarioSQLite != null) {
        await _savePrefs(); // Actualizar preferencias

        // Limpiar flag de modo demo
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool('modoDemo', false);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Inicio de sesión exitoso (Offline - SQLite)'),
            backgroundColor: Color(0xFF0E8833),
          ),
        );

        Navigator.pushReplacementNamed(context, '/home');
        return true;
      }

      // FALLBACK: Verificar con SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final usuarioGuardado = prefs.getString('usuario');
      final contrasenaGuardada = prefs.getString('contrasena');

      if (usuarioGuardado != null && contrasenaGuardada != null) {
        if (usuario == usuarioGuardado && pass == contrasenaGuardada) {
          await prefs.setBool('modoDemo', false);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✓ Inicio de sesión exitoso (Offline - Prefs)'),
              backgroundColor: Color(0xFF0E8833),
            ),
          );

          Navigator.pushReplacementNamed(context, '/home');
          return true;
        }
      }

      // Credenciales incorrectas
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Usuario o contraseña incorrecta'),
          backgroundColor: Colors.red,
        ),
      );
      return false;

    } catch (e) {
      print('❌ Error en login offline: ${e.toString()}');
      return false;
    }
  }

  // NUEVO: Método para modo demo
  Future<void> _loginDemo(BuildContext context) async {
    setState(() => _loading = true);

    // Simular pequeña espera
    await Future.delayed(const Duration(milliseconds: 800));

    // Guardar flag de modo demo
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('modoDemo', true);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✓ Ingresando en Modo DEMO'),
        backgroundColor: Color(0xFFFF9800),
      ),
    );

    setState(() => _loading = false);
    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        height: size.height,
        width: size.width,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
              const Color(0xFF1a1a1a),
              const Color(0xFF2d2d2d),
            ]
                : [
              const Color(0xFFF5F7FA),
              const Color(0xFFE8EDF2),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  const SizedBox(height: 40),
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
                      height: 80,
                    ),
                  ),
                  const SizedBox(height: 40),

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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bienvenido.',
                            style: GoogleFonts.inter(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Ingresa tus credenciales para continuar',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: isDark ? Colors.white60 : Colors.black54,
                              fontWeight: FontWeight.w400,
                            ),
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
                            controller: _usuarioController,
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
                                return 'Por favor ingrese su usuario';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          // Campo Contraseña (CORREGIDO: teclado numérico)
                          Text(
                            'Contraseña (numérica)',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _passController,
                            obscureText: _obscurePassword,
                            keyboardType: TextInputType.number, // TECLADO NUMÉRICO
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
                                return 'Por favor ingrese su contraseña';
                              }
                              if (value.length < 4) {
                                return 'La contraseña debe tener al menos 4 caracteres';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Recordar credenciales
                          Row(
                            children: [
                              SizedBox(
                                height: 20,
                                width: 20,
                                child: Checkbox(
                                  value: recordarCredenciales,
                                  onChanged: (bool? value) {
                                    setState(() {
                                      recordarCredenciales = value ?? false;
                                    });
                                  },
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  activeColor: const Color(0xFF0E8833),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Recordar mis credenciales',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: isDark ? Colors.white60 : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),

                          // Botón Iniciar sesión
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0E8833),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                shadowColor: const Color(0xFF0E8833).withOpacity(0.3),
                              ),
                              onPressed: _loading ? null : () => _loginUnified(context),
                              child: _loading
                                  ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                                  : Text(
                                'Iniciar sesión',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Botón Modo DEMO (discreto)
                  TextButton(
                    onPressed: _loading ? null : () => _loginDemo(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.science_outlined,
                          size: 16,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Modo DEMO',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white38 : Colors.black38,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Botón configuración
                  TextButton.icon(
                    onPressed: () {
                      setState(() => showConfig = !showConfig);
                    },
                    icon: Icon(
                      showConfig ? Icons.keyboard_arrow_up : Icons.settings_outlined,
                      size: 20,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                    label: Text(
                      showConfig ? 'Ocultar configuración' : 'Configuración de conexión',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ),

                  // Panel de configuración
                  if (showConfig) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2d2d2d) : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _configFormKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Configuración del servidor',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 20),
                            _buildConfigField('IP del servidor', _ipController, Icons.dns_outlined, isDark),
                            const SizedBox(height: 16),
                            _buildConfigField('Puerto', _portController, Icons.cable_outlined, isDark, isNumber: true),
                            const SizedBox(height: 16),
                            _buildConfigField('Base de datos', _dbController, Icons.storage_outlined, isDark),
                            const SizedBox(height: 16),
                            _buildConfigField('Usuario BD', _dbUserController, Icons.admin_panel_settings_outlined, isDark),
                            const SizedBox(height: 16),
                            _buildConfigField('Contraseña BD', _dbPassController, Icons.vpn_key_outlined, isDark, isPassword: true),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Footer
                  Column(
                    children: [
                      Text(
                        'versión 10.1.2_1_141025',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: isDark ? Colors.white38 : Colors.black38,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'DESARROLLADO POR: J.FARFAN',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: isDark ? Colors.white30 : Colors.black26,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '© 2025 METRICA LTDA',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: isDark ? Colors.white30 : Colors.black26,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
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
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: isPassword,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: isDark ? Colors.white : Colors.black87,
          ),
          decoration: InputDecoration(
            hintText: 'Ingresa $label',
            hintStyle: GoogleFonts.inter(
              color: isDark ? Colors.white30 : Colors.black26,
              fontSize: 13,
            ),
            filled: true,
            fillColor: isDark ? const Color(0xFF1a1a1a) : const Color(0xFFF5F7FA),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            prefixIcon: Icon(
              icon,
              color: isDark ? Colors.white70 : Colors.black38,
              size: 20,
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Campo requerido';
            }
            return null;
          },
          // NUEVO: Auto-guardar al cambiar el texto
          onChanged: (value) async {
            await _savePrefs();
            print('💾 Configuración guardada automáticamente');
          },
        ),
      ],
    );
  }
}