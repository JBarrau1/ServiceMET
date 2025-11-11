// lib/login/widgets/login/login_form.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'user_card.dart';
import 'password_field.dart';

class LoginForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController passController;
  final bool isDark;
  final bool loading;
  final String? savedUser;
  final String? savedUserFullName;
  final VoidCallback onLogin;
  final VoidCallback onLoginDemo;
  final VoidCallback onReconfigure;
  final VoidCallback onChangeUser;

  const LoginForm({
    super.key,
    required this.formKey,
    required this.passController,
    required this.isDark,
    required this.loading,
    this.savedUser,
    this.savedUserFullName,
    required this.onLogin,
    required this.onLoginDemo,
    required this.onReconfigure,
    required this.onChangeUser,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
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
              key: formKey,
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

                  // Usuario guardado
                  if (savedUser != null && savedUser!.isNotEmpty) ...[
                    UserCard(
                      isDark: isDark,
                      savedUser: savedUser!,
                      savedUserFullName: savedUserFullName,
                      onChangeUser: onChangeUser,
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Campo Contraseña
                  PasswordField(
                    controller: passController,
                    isDark: isDark,
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
                      onPressed: loading ? null : onLogin,
                      child: loading
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
            onPressed: loading ? null : onLoginDemo,
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
            onPressed: loading ? null : onReconfigure,
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
                'versión 11.1.1_1_111125',
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
    );
  }
}