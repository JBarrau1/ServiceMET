// lib/login/screens/login_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/login/auto_login_loading.dart';
import '../widgets/login/login_form.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _passController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  bool _loading = false;
  String? _savedUser;
  String? _savedUserFullName;
  bool _autoLoginEnabled = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimation();
    _loadPrefsAndAutoLogin(context);
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
    super.dispose();
  }

  Future<void> _loadPrefsAndAutoLogin(BuildContext context) async {
    final prefs = await _authService.loadPreferences();

    setState(() {
      _savedUser = prefs['savedUser'];
      _savedUserFullName = prefs['savedUserFullName'];
      _autoLoginEnabled = prefs['autoLoginEnabled'];
    });

    if (_autoLoginEnabled && _savedUser != null && _savedUser!.isNotEmpty) {
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) {
        await _attemptAutoLogin(context);
      }
    }
  }

  Future<void> _attemptAutoLogin(BuildContext context) async {
    setState(() => _loading = true);

    final success = await _authService.attemptAutoLogin(_savedUser);

    if (success && mounted) {
      _showSnackBar(
        context,
        'Inicio de sesión automático exitoso',
        Colors.green,
      );

      await Future.delayed(const Duration(milliseconds: 500));
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      setState(() => _loading = false);
    }
  }

  Future<void> _login(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final result = await _authService.login(
      _savedUser,
      _passController.text.trim(),
    );

    setState(() => _loading = false);

    if (!mounted) return;

    if (result.success) {
      _showSnackBar(context, result.message, Colors.green);
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
      _showSnackBar(
        context,
        'Ingresando en Modo DESCONECTADO',
        Colors.orange,
      );

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
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange[700],
            ),
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

  Future<void> _changeUser(BuildContext context) async {
    await _authService.changeUser();
    setState(() {
      _savedUser = null;
      _savedUserFullName = null;
      _autoLoginEnabled = false;
      _passController.clear();
    });

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
              isDark: isDark,
              loading: _loading,
              savedUser: _savedUser,
              savedUserFullName: _savedUserFullName,
              onLogin: () => _login(context),
              onLoginDemo: () => _loginDemo(context),
              onReconfigure: () => _showReconfigureDialog(context),
              onChangeUser: () => _changeUser(context),
            ),
          ),
        ),
      ),
    );
  }
}