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

  Future<void> _loadPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _ipController.text = prefs.getString('ip') ?? '';
    _portController.text = prefs.getString('port') ?? '1433';
    _dbController.text = prefs.getString('database') ?? '';
    _dbUserController.text = prefs.getString('dbuser') ?? '';
    _dbPassController.text = '';

    _usuarioController.text = prefs.getString('usuario') ?? '';
    _passController.text = '';

    recordarCredenciales = prefs.getBool('recordar') ?? false;
    setState(() {});
  }

  Future<void> _savePrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('ip', _ipController.text);
    await prefs.setString('port', _portController.text);
    await prefs.setString('database', _dbController.text);
    await prefs.setString('dbuser', _dbUserController.text);
    await prefs.setString('dbpass', hashPassword(_dbPassController.text));
    await prefs.setBool('recordar', recordarCredenciales);

    if (recordarCredenciales) {
      await prefs.setString('usuario', _usuarioController.text);
      await prefs.setString('contrasena', hashPassword(_passController.text));
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

  Future<void> _loginOffline(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final usuario = _usuarioController.text.trim();
    final pass = _passController.text.trim();

    try {
      // Verificar credenciales guardadas
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final usuarioGuardado = prefs.getString('usuario');
      final contrasenaGuardada = prefs.getString('contrasena');

      if (usuarioGuardado == null || contrasenaGuardada == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No hay credenciales guardadas. Debe iniciar sesión en línea al menos una vez.'),
            backgroundColor: Colors.orange,
          ),
        );
        setState(() => _loading = false);
        return;
      }

      // Validar usuario y contraseña
      final passHasheada = hashPassword(pass);

      if (usuario == usuarioGuardado && passHasheada == contrasenaGuardada) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Inicio de sesión exitoso (modo offline)'),
            backgroundColor: Color(0xFF0E8833),
          ),
        );
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Usuario o contraseña incorrecta'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _login(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final ip = _ipController.text.trim();
    final port = _portController.text.trim();
    final dbName = _dbController.text.trim();
    final dbUser = _dbUserController.text.trim();
    final dbPass = _dbPassController.text.trim();
    final usuario = _usuarioController.text.trim();
    final pass = _passController.text.trim();

    try {
      if (!isValidInput(usuario) || !isValidInput(pass)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Caracteres no válidos detectados')),
        );
        return;
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
        throw TimeoutException(
            'La conexión tardó demasiado. Verifique su conexión a internet.');
      });

      if (!connected) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al conectar con el servidor')),
        );
        return;
      }

      final query = '''
      SELECT nombre1, apellido1, pass, usuario, titulo_abr, estado 
      FROM data_users 
      WHERE usuario = '$usuarioSeguro' AND pass = '$passSeguro'
    ''';

      final resultJson = await connection
          .getData(query)
          .timeout(timeoutDuration, onTimeout: () {
        throw TimeoutException(
            'La consulta tardó demasiado. El servidor puede estar lento.');
      });

      final List<dynamic> result = jsonDecode(resultJson);

      if (result.isNotEmpty) {
        final userData = Map<String, dynamic>.from(result.first);
        final userDataSeguro = {
          ...userData,
          'pass': hashPassword(userData['pass']),
        };

        await _saveUserToSQLite(userDataSeguro);
        await _savePrefs();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Inicio de sesión exitoso'),
            backgroundColor: Color(0xFF0E8833),
          ),
        );
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuario o contraseña incorrecta')),
        );
      }
    } on TimeoutException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Tiempo de espera agotado')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      await connection.disconnect();
      setState(() => _loading = false);
    }
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
                              onPressed: _loading ? null : () => _login(context),
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
                          const SizedBox(height: 16),

                          // Botón offline
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF9E2B2E),
                                side: BorderSide(
                                  color: isDark ? const Color(0xFF9E2B2E).withOpacity(0.3) : const Color(0xFF9E2B2E).withOpacity(0.5),
                                  width: 1.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: _loading ? null : () => _loginOffline(context),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.cloud_off_outlined,
                                    size: 20,
                                    color: isDark ? const Color(0xFF9E2B2E).withOpacity(0.8) : const Color(0xFF9E2B2E),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Iniciar sin conexión',
                                    style: GoogleFonts.inter(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

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
                        'versión 10.1.1_4_071025',
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