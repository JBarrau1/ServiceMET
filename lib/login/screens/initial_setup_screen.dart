// lib/login/screens/initial_setup_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import '../services/setup_service.dart';
import '../widgets/setup/setup_loading.dart';
import '../widgets/setup/step_indicator.dart';
import '../widgets/setup/connection_step.dart';
import '../widgets/setup/user_credentials_step.dart';
import '../widgets/setup/info_card.dart';

class InitialSetupScreen extends StatefulWidget {
  const InitialSetupScreen({super.key});

  @override
  State<InitialSetupScreen> createState() => _InitialSetupScreenState();
}

class _InitialSetupScreenState extends State<InitialSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final SetupService _setupService = SetupService();

  // Controladores de campos - Conexión BD
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _portController = TextEditingController(text: '1433');
  final TextEditingController _dbController = TextEditingController();
  final TextEditingController _dbUserController = TextEditingController();
  final TextEditingController _dbPassController = TextEditingController();

  // Controladores de campos - Usuario App
  final TextEditingController _appUserController = TextEditingController();
  final TextEditingController _appPassController = TextEditingController();

  int _currentStep = 0;
  bool _loading = false;

  String _statusMessage = '';
  double _progressValue = 0.0;

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    _dbController.dispose();
    _dbUserController.dispose();
    _dbPassController.dispose();
    _appUserController.dispose();
    _appPassController.dispose();
    _setupService.disconnect();
    super.dispose();
  }

  Future<void> _executeSetup(BuildContext context) async {
    // ========== PASO 1: CONFIGURACIÓN DE BD ==========
    if (_currentStep == 0) {
      if (!_formKey.currentState!.validate()) return;

      setState(() => _loading = true);

      final result = await _setupService.validateConnection(
        ip: _ipController.text.trim(),
        port: _portController.text.trim(),
        database: _dbController.text.trim(),
        username: _dbUserController.text.trim(),
        password: _dbPassController.text.trim(),
      );

      if (!result.success) {
        _showError(context, result.message);
        setState(() => _loading = false);
        return;
      }

      setState(() {
        _currentStep = 1;
        _loading = false;
      });

      return;
    }

    // ========== PASO 2: CREDENCIALES DE USUARIO ==========
    if (_currentStep == 1) {
      if (!_formKey.currentState!.validate()) return;

      setState(() => _loading = true);

      try {
        // 1. Validar usuario en SQL Server
        final userResult = await _setupService.validateUserInServer(
          _appUserController.text.trim(),
          _appPassController.text.trim(),
        );

        if (!userResult.success || userResult.userData == null) {
          _showError(context, userResult.message);
          setState(() => _loading = false);
          return;
        }

        // 2. Guardar usuario autenticado en SQLite
        final saveResult =
        await _setupService.saveAuthenticatedUser(userResult.userData!);

        if (!saveResult.success) {
          _showError(context, saveResult.message);
          setState(() => _loading = false);
          return;
        }

        // 3. Descargar datos de precarga
        final downloadResult = await _setupService.downloadPrecargaData(
              (message, progress) {
            setState(() {
              _statusMessage = message;
              _progressValue = progress;
            });
          },
        );

        if (!downloadResult.success) {
          _showError(context, downloadResult.message);
          setState(() => _loading = false);
          return;
        }

        // 4. Guardar configuración de conexión
        await _setupService.saveConfiguration(
          ip: _ipController.text.trim(),
          port: _portController.text.trim(),
          database: _dbController.text.trim(),
          dbUser: _dbUserController.text.trim(),
          dbPass: _dbPassController.text.trim(),
        );

        // 5. Navegar al login
        setState(() {
          _statusMessage = 'Configuración completada exitosamente';
          _progressValue = 1.0;
        });

        await Future.delayed(const Duration(seconds: 1));

        if (mounted) {
          await _setupService.disconnect();
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
          child: _loading
              ? SetupLoading(
            isDark: isDark,
            statusMessage: _statusMessage,
            progressValue: _progressValue,
          )
              : _buildSetupForm(context, isDark),
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
              height: 80,
            ),
          ),
          const SizedBox(height: 32),

          // Indicador de pasos
          StepIndicator(
            currentStep: _currentStep,
            isDark: isDark,
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
                  ? ConnectionStep(
                isDark: isDark,
                loading: _loading,
                ipController: _ipController,
                portController: _portController,
                dbController: _dbController,
                dbUserController: _dbUserController,
                dbPassController: _dbPassController,
                onContinue: () => _executeSetup(context),
              )
                  : UserCredentialsStep(
                isDark: isDark,
                loading: _loading,
                appUserController: _appUserController,
                appPassController: _appPassController,
                onBack: () => setState(() => _currentStep = 0),
                onFinish: () => _executeSetup(context),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Información
          InfoCard(
            isDark: isDark,
            currentStep: _currentStep,
          ),
        ],
      ),
    );
  }
}