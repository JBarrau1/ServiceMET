import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _passController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _loading = false;
  bool _obscurePassword = true;

  String? _savedUser;
  String? _savedUserFullName;
  bool _autoLoginEnabled = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();

    // Cargar preferencias y hacer auto-login
    _loadPrefsAndAutoLogin(context);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _passController.dispose();
    super.dispose();
  }

  Future<void> _loadPrefsAndAutoLogin(context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Cargar datos del usuario guardado
    _savedUser = prefs.getString('logged_user');
    _savedUserFullName = prefs.getString('logged_user_nombre');
    _autoLoginEnabled = prefs.getBool('auto_login_enabled') ?? false;

    setState(() {});

    // Si hay auto-login habilitado, intentar login automático
    if (_autoLoginEnabled && _savedUser != null && _savedUser!.isNotEmpty) {
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) {
        await _attemptAutoLogin(context);
      }
    }
  }

  Future<void> _attemptAutoLogin(BuildContext context) async {
    setState(() => _loading = true);

    try {
      // Obtener contraseña guardada de la BD local
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'usuarios.db');

      final dbExists = await databaseExists(path);
      if (!dbExists) {
        setState(() => _loading = false);
        return;
      }

      final db = await openDatabase(path);

      final List<Map<String, dynamic>> results = await db.query(
        'usuarios',
        where: 'usuario = ?',
        whereArgs: [_savedUser],
      );

      await db.close();

      if (results.isNotEmpty) {
        final userData = results.first;

        // Verificar que está activo
        if (userData['estado']?.toString().toUpperCase() == 'ACTIVO') {
          // Limpiar modo demo
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setBool('modoDemo', false);

          // Login exitoso automático
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Inicio de sesión automático exitoso'),
                backgroundColor: Color(0xFF0E8833),
                duration: Duration(seconds: 1),
              ),
            );

            await Future.delayed(const Duration(milliseconds: 500));
            Navigator.pushReplacementNamed(context, '/home');
          }
          return;
        }
      }

      // Si falla el auto-login, mostrar formulario
      setState(() => _loading = false);

    } catch (e) {
      print('❌ Error en auto-login: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _login(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final pass = _passController.text.trim();

    try {
      // Obtener datos del usuario guardado
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'usuarios.db');

      final dbExists = await databaseExists(path);
      if (!dbExists) {
        _showError(context, 'Base de datos de usuarios no existe');
        setState(() => _loading = false);
        return;
      }

      final db = await openDatabase(path);

      final List<Map<String, dynamic>> results = await db.query(
        'usuarios',
        where: 'usuario = ? AND pass = ?',
        whereArgs: [_savedUser, pass],
      );

      await db.close();

      if (results.isNotEmpty) {
        final userData = results.first;

        // Verificar si el usuario está activo
        if (userData['estado']?.toString().toUpperCase() != 'ACTIVO') {
          _showError(context, 'Usuario inactivo. Contacte al administrador.');
          setState(() => _loading = false);
          return;
        }

        // Limpiar modo demo
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool('modoDemo', false);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Inicio de sesión exitoso'),
              backgroundColor: Color(0xFF0E8833),
            ),
          );

          Navigator.pushReplacementNamed(context, '/home');
        }
        return;
      }

      // Si falla login
      _showError(context, 'Contraseña incorrecta');

    } catch (e) {
      _showError(context, 'Error: ${e.toString()}');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _loginDemo(BuildContext context) async {
    setState(() => _loading = true);

    await Future.delayed(const Duration(milliseconds: 800));

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('modoDemo', true);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresando en Modo DESCONECTADO'),
          backgroundColor: Color(0xFFFF9800),
        ),
      );

      setState(() => _loading = false);
      Navigator.pushReplacementNamed(context, '/home');
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

  Future<void> _showReconfigureDialog(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.settings_backup_restore, color: Colors.orange[700]),
            const SizedBox(width: 12),
            const Text('Reconfigurar'),
          ],
        ),
        content: const Text(
          '¿Desea reconfigurar la aplicación? Esto eliminará la configuración actual y volverá a solicitar los datos de conexión.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[700]),
            child: const Text('Reconfigurar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('setup_completed');
      await prefs.remove('setup_date');
      await prefs.remove('auto_login_enabled');
      await prefs.remove('logged_user');
      await prefs.remove('logged_user_nombre');

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/setup');
      }
    }
  }

  Future<void> _changeUser(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auto_login_enabled');
    await prefs.remove('logged_user');
    await prefs.remove('logged_user_nombre');
    setState(() {
      _savedUser = null;
      _savedUserFullName = null;
      _autoLoginEnabled = false;
      _passController.clear();
    });

    // Navegar al setup
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/setup');
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
                ? [const Color(0xFF1a1a1a), const Color(0xFF2d2d2d)]
                : [const Color(0xFFF5F7FA), const Color(0xFFE8EDF2)],
          ),
        ),
        child: SafeArea(
          child: _loading && _autoLoginEnabled
              ? _buildAutoLoginScreen(isDark)
              : _buildLoginForm(context, isDark),
        ),
      ),
    );
  }

  Widget _buildAutoLoginScreen(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2d2d2d) : Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              Icons.person_outline,
              size: 64,
              color: Color(0xFF0E8833),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Bienvenido de vuelta',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _savedUserFullName ?? '@$_savedUser',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
          const SizedBox(height: 32),
          const SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              color: Color(0xFF0E8833),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Iniciando sesión...',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginForm(BuildContext context, bool isDark) {
    return SingleChildScrollView(
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
              child: Image.asset('images/logo_met.png', height: 80),
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
                      'Ingresa tu contraseña para continuar',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: isDark ? Colors.white60 : Colors.black54,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Usuario guardado (tarjeta verde)
                    if (_savedUser != null && _savedUser!.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0E8833).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF0E8833).withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Color(0xFF0E8833),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _savedUserFullName ?? _savedUser!,
                                    style: GoogleFonts.inter(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    '@$_savedUser',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: isDark ? Colors.white60 : Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: () => _changeUser(context),
                              child: Text(
                                'Cambiar',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF0E8833),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

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
                      keyboardType: TextInputType.number,
                      autofocus: true,
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
                            setState(() => _obscurePassword = !_obscurePassword);
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
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Botón Modo DEMO
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
                    'Modo DESCONECTADO',
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

            // Botón reconfigurar
            TextButton.icon(
              onPressed: _loading ? null : () => _showReconfigureDialog(context),
              icon: Icon(
                Icons.settings_backup_restore,
                size: 18,
                color: isDark ? Colors.white60 : Colors.black45,
              ),
              label: Text(
                'Reconfigurar aplicación',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white60 : Colors.black45,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Footer
            Column(
              children: [
                Text(
                  'versión 10.2.0_8_111125',
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
    );
  }
}