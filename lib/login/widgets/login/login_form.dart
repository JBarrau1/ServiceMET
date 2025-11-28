// lib/login/widgets/login/login_form.dart - VERSIÓN SIMPLIFICADA

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'user_card.dart';
import 'password_field.dart';

class LoginForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController passController;
  final TextEditingController userController;
  final bool isDark;
  final bool loading;
  final String? savedUser;
  final String? savedUserFullName;
  final bool isAddingNewUser;
  final VoidCallback onLogin;
  final VoidCallback onLoginDemo;
  final VoidCallback onReconfigure;
  final VoidCallback onShowUserSelector;
  final VoidCallback onStartAddingUser;
  final VoidCallback onCancelAddingUser;

  const LoginForm({
    super.key,
    required this.formKey,
    required this.passController,
    required this.userController,
    required this.isDark,
    required this.loading,
    this.savedUser,
    this.savedUserFullName,
    required this.isAddingNewUser,
    required this.onLogin,
    required this.onLoginDemo,
    required this.onReconfigure,
    required this.onShowUserSelector,
    required this.onStartAddingUser,
    required this.onCancelAddingUser,
  });

  @override
  Widget build(BuildContext context) {
    // ✅ LÓGICA SIMPLIFICADA
    final hasUsers = savedUser != null && savedUser!.isNotEmpty;

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
                    isAddingNewUser
                        ? 'Ingresa credenciales del nuevo usuario'
                        : hasUsers
                        ? 'Ingresa tu contraseña para continuar'
                        : 'Agrega tu primer usuario para comenzar',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: isDark ? Colors.white60 : Colors.black54,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ✅ CAMPO USUARIO (solo si está agregando O no hay usuarios)
                  if (isAddingNewUser || !hasUsers) ...[
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
                      controller: userController,
                      autofocus: true,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Ingresa el usuario',
                        hintStyle: GoogleFonts.inter(
                          color: isDark ? Colors.white30 : Colors.black26,
                        ),
                        filled: true,
                        fillColor: isDark
                            ? const Color(0xFF1a1a1a)
                            : const Color(0xFFF5F7FA),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 18,
                        ),
                        prefixIcon: Icon(
                          Icons.person_add_outlined,
                          color: isDark ? Colors.white70 : Colors.black38,
                          size: 22,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingrese el usuario';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                  ],

                  // ✅ USUARIO GUARDADO (solo si hay usuarios Y no está agregando)
                  if (hasUsers && !isAddingNewUser) ...[
                    UserCard(
                      isDark: isDark,
                      savedUser: savedUser!,
                      savedUserFullName: savedUserFullName,
                      onShowUserSelector: onShowUserSelector,
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Campo Contraseña
                  PasswordField(
                    controller: passController,
                    isDark: isDark,
                    autofocus: hasUsers && !isAddingNewUser,
                  ),
                  const SizedBox(height: 28),

                  // Botón principal
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
                          : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isAddingNewUser || !hasUsers
                                ? Icons.person_add
                                : Icons.login,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isAddingNewUser || !hasUsers
                                ? 'Agregar Usuario'
                                : 'Iniciar sesión',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ✅ Botón cancelar (solo si está agregando Y hay usuarios guardados)
                  if (isAddingNewUser && hasUsers) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: onCancelAddingUser,
                        child: Text(
                          'Cancelar',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ✅ Botón Agregar nuevo usuario (solo si NO está agregando Y hay usuarios)
          if (!isAddingNewUser && hasUsers) ...[
            TextButton.icon(
              onPressed: loading ? null : onStartAddingUser,
              icon: const Icon(Icons.person_add_outlined, size: 18),
              label: Text(
                'Cambiar de Usuario',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],

          TextButton(
            onPressed: loading ? null : onLoginDemo,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              foregroundColor: const Color(0xFFFF9800), // color naranja para texto e ícono
              overlayColor: const Color(0xFFFF9800).withOpacity(0.12),
              // backgroundColor: const Color(0xFFFF9800), // descomenta si quieres fondo naranja
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.science_outlined,
                  size: 16,
                  // color removido para heredar foregroundColor
                ),
                const SizedBox(width: 6),
                Text(
                  'Modo DESCONECTADO',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    // color removido para heredar foregroundColor
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
                'versión 11.4.281125',
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