// lib/login/screens/login_screen.dart - VERSIÓN SIMPLIFICADA

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../widgets/login/auto_login_loading.dart';
import '../widgets/login/login_form.dart';
import '../widgets/login/user_selector_dialog.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _passController = TextEditingController();
  final TextEditingController _userController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  bool _loading = false;
  bool _showingAutoLogin = false;
  String? _savedUser;
  String? _savedUserFullName;
  bool _autoLoginEnabled = false;
  bool _isFirstLogin = true;

  // ✅ ÚNICO ESTADO: ¿Está ingresando nuevo usuario?
  bool _isAddingNewUser = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimation();
    _loadPrefsAndCheckAutoLogin(context);
  }

  void _initAnimation() {
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
    _passController.dispose();
    _userController.dispose();
    super.dispose();
  }

  // ✅ MEJORADO: Recargar usuarios guardados
  Future<void> _loadPrefsAndCheckAutoLogin(BuildContext context) async {
    final prefs = await _authService.loadPreferences();

    setState(() {
      _savedUser = prefs['savedUser'];
      _savedUserFullName = prefs['savedUserFullName'];
      _autoLoginEnabled = prefs['autoLoginEnabled'];
      _isFirstLogin = prefs['isFirstLogin'];
    });

    // ✅ Validar que el usuario guardado realmente exista en la BD
    if (_savedUser != null) {
      final exists = await _authService.userExists(_savedUser!);
      if (!exists) {
        // Usuario fue eliminado, limpiar preferencias
        await _clearSavedUser();
        setState(() {
          _savedUser = null;
          _savedUserFullName = null;
          _autoLoginEnabled = false;
        });
        return;
      }
    }

    // Auto-login solo si hay usuario válido
    if (_autoLoginEnabled && _isFirstLogin && _savedUser != null) {
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) {
        await _performAutoLogin(context);
      }
    }
  }

  Future<void> _performAutoLogin(BuildContext context) async {
    setState(() {
      _loading = true;
      _showingAutoLogin = true;
    });

    await Future.delayed(const Duration(milliseconds: 1500));

    if (mounted) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_first_login', false);

      _showSnackBar(context, 'Bienvenido de vuelta', Colors.green);
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  // ✅ SIMPLIFICADO: Un solo método de login
  Future<void> _login(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    LoginResult result;

    if (_isAddingNewUser) {
      // Agregar nuevo usuario (valida en servidor)
      result = await _authService.addNewUser(
        usuario: _userController.text.trim(),
        password: _passController.text.trim(),
      );
    } else if (_savedUser != null) {
      // Login con usuario guardado
      result = await _authService.login(
        usuario: _savedUser,
        password: _passController.text.trim(),
        isChangingUser: false,
      );
    } else {
      // No debería llegar aquí
      result = LoginResult(
        success: false,
        message: 'No hay usuario seleccionado',
      );
    }

    setState(() => _loading = false);

    if (!mounted) return;

    if (result.success) {
      _showSnackBar(context, result.message, Colors.green);

      // Recargar preferencias después de agregar usuario
      if (_isAddingNewUser) {
        await _loadPrefsAndCheckAutoLogin(context);
        setState(() => _isAddingNewUser = false);
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_first_login', false);

      Navigator.pushReplacementNamed(context, '/home');
    } else {
      _showSnackBar(context, result.message, Colors.red);
    }
  }

  Future<void> _loginDemo(BuildContext context) async {
    setState(() => _loading = true);

    await Future.delayed(const Duration(milliseconds: 800));
    await _authService.loginDemo();

    if (mounted) {
      _showSnackBar(context, 'Ingresando en Modo DESCONECTADO', Colors.orange);
      setState(() => _loading = false);
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  void _showSnackBar(BuildContext context, String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
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
      await _authService.reconfigure();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/setup');
      }
    }
  }

  // ✅ SIMPLIFICADO: Mostrar lista de usuarios
  Future<void> _showUserSelector(BuildContext context) async {
    final users = await _authService.getSavedUsers();

    if (users.isEmpty) {
      _showSnackBar(
        context,
        'No hay usuarios guardados',
        Colors.orange,
      );
      return;
    }

    if (!mounted) return;

    final selectedUser = await showDialog<UserModel>(
      context: context,
      builder: (dialogContext) => UserSelectorDialog(
        users: users,
        onDelete: (user) async {
          final success = await _authService.deleteUser(user.usuario);

          if (success) {
            Navigator.pop(dialogContext);

            // ✅ Si eliminó el usuario actual, limpiar
            if (user.usuario == _savedUser) {
              await _clearSavedUser();
              setState(() {
                _savedUser = null;
                _savedUserFullName = null;
              });
            }

            _showSnackBar(context, 'Usuario eliminado', Colors.green);

            // ✅ Recargar para verificar si quedan usuarios
            await _loadPrefsAndCheckAutoLogin(context);
          } else {
            _showSnackBar(context, 'Error al eliminar usuario', Colors.red);
          }
        },
      ),
    );

    if (selectedUser != null) {
      // ✅ Seleccionar usuario de la lista
      setState(() {
        _savedUser = selectedUser.usuario;
        _savedUserFullName = selectedUser.fullName;
        _isAddingNewUser = false;
        _passController.clear();
      });

      // Guardar como usuario actual
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('logged_user', selectedUser.usuario);
      await prefs.setString('logged_user_nombre', selectedUser.fullName);
    }
  }

  // ✅ SIMPLIFICADO: Modo agregar nuevo usuario
  void _startAddingNewUser() {
    setState(() {
      _isAddingNewUser = true;
      _userController.clear();
      _passController.clear();
    });
  }

  // ✅ SIMPLIFICADO: Cancelar agregar usuario
  void _cancelAddingUser() {
    setState(() {
      _isAddingNewUser = false;
      _userController.clear();
      _passController.clear();
    });
  }

  // ✅ NUEVO: Limpiar usuario guardado en SharedPreferences
  Future<void> _clearSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('logged_user');
    await prefs.remove('logged_user_nombre');
    await prefs.setBool('auto_login_enabled', false);
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
              ? AutoLoginLoading(
            isDark: isDark,
            savedUserFullName: _savedUserFullName,
            savedUser: _savedUser,
          )
              : FadeTransition(
            opacity: _fadeAnimation,
            child: LoginForm(
              formKey: _formKey,
              passController: _passController,
              userController: _userController,
              isDark: isDark,
              loading: _loading,
              savedUser: _savedUser,
              savedUserFullName: _savedUserFullName,
              isAddingNewUser: _isAddingNewUser,
              onLogin: () => _login(context),
              onLoginDemo: () => _loginDemo(context),
              onReconfigure: () => _showReconfigureDialog(context),
              onShowUserSelector: () => _showUserSelector(context),
              onStartAddingUser: _startAddingNewUser,
              onCancelAddingUser: _cancelAddingUser,
            ),
          ),
        ),
      ),
    );
  }
}