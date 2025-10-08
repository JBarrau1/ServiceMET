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

  // NUEVO: Verificar si existe usuario en SQLite
  Future<Map<String, dynamic>?> _verificarUsuarioEnSQLite(String usuario, String pass) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'usuarios.db');

    try {
      final db = await openDatabase(path);
      final List<Map<String, dynamic>> results = await db.query(
        'usuarios',
        where: 'usuario = ? AND pass = ?',
        whereArgs: [usuario, hashPassword(pass)],
      );
      await db.close();

      if (results.isNotEmpty) {
        return results.first;
      }
    } catch (e) {
      print('Error consultando SQLite: $e');
    }
    return null;
  }

  Future<void> _loadPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Cargar configuración de conexión
    _ipController.text = prefs.getString('ip') ?? '';
    _portController.text = prefs.getString('port') ?? '1433';
    _dbController.text = prefs.getString('database') ?? '';
    _dbUserController.text = prefs.getString('dbuser') ?? '';

    // Cargar credenciales de usuario SI recordar está activado
    recordarCredenciales = prefs.getBool('recordar') ?? false;
    if (recordarCredenciales) {
      _usuarioController.text = prefs.getString('usuario') ?? '';
      // La contraseña se carga desde SecureStorage en un caso real
      // Por ahora la dejamos vacía por seguridad
    }

    setState(() {});
  }

  // NUEVO: Guardar contraseñas de forma segura
  Future<void> _savePrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Guardar configuración de conexión
    await prefs.setString('ip', _ipController.text);
    await prefs.setString('port', _portController.text);
    await prefs.setString('database', _dbController.text);
    await prefs.setString('dbuser', _dbUserController.text);

    // Guardar contraseña de BD SI se ingresó una nueva
    if (_dbPassController.text.isNotEmpty) {
      await prefs.setString('dbpass', _dbPassController.text);
    }

    // Guardar credenciales de usuario SI recordar está activado
    await prefs.setBool('recordar', recordarCredenciales);
    if (recordarCredenciales) {
      await prefs.setString('usuario', _usuarioController.text);
      await prefs.setString('contrasena', _passController.text); // Guardar contraseña REAL
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
        'pass': hashPassword(userData['pass']), // Hashear para SQLite
      };
      await db.insert('usuarios', userDataConFecha);
    } catch (e) {
      print('Error guardando en SQLite: $e');
    } finally {
      await db?.close();
    }
  }

  // NUEVO: Método de login modificado - Offline First
  Future<void> _loginUnificado(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final usuario = _usuarioController.text.trim();
    final pass = _passController.text.trim();

    try {
      // Validar entrada
      if (!isValidInput(usuario) || !isValidInput(pass)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Caracteres no válidos detectados')),
        );
        setState(() => _loading = false);
        return;
      }

      // PRIMERO: Intentar login offline (SQLite)
      final usuarioSQLite = await _verificarUsuarioEnSQLite(usuario, pass);
      if (usuarioSQLite != null) {
        await _savePrefs(); // Actualizar preferencias

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Inicio de sesión exitoso (Offline)'),
            backgroundColor: Color(0xFF0E8833),
          ),
        );

        // Limpiar flag de modo demo
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool('modoDemo', false);

        Navigator.pushReplacementNamed(context, '/home');
        setState(() => _loading = false);
        return;
      }

      // SEGUNDO: Si no hay datos offline, intentar online
      final ip = _ipController.text.trim();
      final port = _portController.text.trim();
      final dbName = _dbController.text.trim();
      final dbUser = _dbUserController.text.trim();
      final dbPass = _dbPassController.text.trim().isNotEmpty
          ? _dbPassController.text.trim()
          : (await SharedPreferences.getInstance()).getString('dbpass');

      if (ip.isNotEmpty && port.isNotEmpty && dbName.isNotEmpty &&
          dbUser.isNotEmpty && dbPass != null && dbPass.isNotEmpty) {

        try {
          final usuarioSeguro = sanitizeInput(usuario);
          final passSeguro = sanitizeInput(pass);
          final timeoutDuration = const Duration(seconds: 10);

          final connected = await connection
              .connect(
            ip: ip,
            port: port,
            databaseName: dbName,
            username: dbUser,
            password: dbPass,
          )
              .timeout(timeoutDuration, onTimeout: () => false);

          if (connected) {
            final query = '''
              SELECT nombre1, apellido1, pass, usuario, titulo_abr, estado 
              FROM data_users 
              WHERE usuario = '$usuarioSeguro' AND pass = '$passSeguro'
            ''';

            final resultJson = await connection
                .getData(query)
                .timeout(timeoutDuration, onTimeout: () => '[]');

            final List<dynamic> result = jsonDecode(resultJson);

            if (result.isNotEmpty) {
              final userData = Map<String, dynamic>.from(result.first);

              // GUARDAR EN SQLite PARA PRÓXIMOS LOGINS OFFLINE
              await _saveUserToSQLite(userData);
              await _savePrefs();

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✓ Inicio de sesión exitoso (Online) - Datos guardados'),
                  backgroundColor: Color(0xFF0E8833),
                ),
              );

              await connection.disconnect();

              // Limpiar flag de modo demo
              SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.setBool('modoDemo', false);

              Navigator.pushReplacementNamed(context, '/home');
              setState(() => _loading = false);
              return;
            }
          }

          await connection.disconnect();
        } catch (e) {
          await connection.disconnect();
          print('Error en login online: $e');
        }
      }

      // Si ambos métodos fallan
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Usuario o contraseña incorrectos'),
          backgroundColor: Colors.red,
        ),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  // Método para modo demo
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
                            controller: _passController,
                            obscureText: _obscurePassword,
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

                          // Botón Iniciar sesión UNIFICADO
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
                              onPressed: _loading ? null : () => _loginUnificado(context),
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
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  await _savePrefs();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('✓ Configuración guardada'),
                                      backgroundColor: Color(0xFF0E8833),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.save_outlined, size: 20),
                                label: const Text('Guardar configuración'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0E8833),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
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
                        'versión 10.1.2_0_081025',
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
        ),
      ],
    );
  }
}