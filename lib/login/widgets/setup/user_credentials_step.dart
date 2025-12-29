// lib/login/widgets/setup/user_credentials_step.dart

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class UserCredentialsStep extends StatefulWidget {
  final bool isDark;
  final bool loading;
  final TextEditingController appUserController;
  final TextEditingController appPassController;
  final VoidCallback onBack;
  final VoidCallback onFinish;

  const UserCredentialsStep({
    super.key,
    required this.isDark,
    required this.loading,
    required this.appUserController,
    required this.appPassController,
    required this.onBack,
    required this.onFinish,
  });

  @override
  State<UserCredentialsStep> createState() => _UserCredentialsStepState();
}

class _UserCredentialsStepState extends State<UserCredentialsStep> {
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
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
                      color: widget.isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  Text(
                    'Ingrese sus credenciales de acceso',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: widget.isDark ? Colors.white60 : Colors.black54,
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
            color: widget.isDark ? Colors.white70 : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: widget.appUserController,
          style: GoogleFonts.inter(
            fontSize: 15,
            color: widget.isDark ? Colors.white : Colors.black87,
          ),
          decoration: InputDecoration(
            hintText: 'Ingresa tu usuario',
            hintStyle: GoogleFonts.inter(
              color: widget.isDark ? Colors.white30 : Colors.black26,
            ),
            filled: true,
            fillColor: widget.isDark
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
              Icons.person_outline_rounded,
              color: widget.isDark ? Colors.white70 : Colors.black38,
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
            color: widget.isDark ? Colors.white70 : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: widget.appPassController,
          obscureText: _obscurePassword,
          keyboardType: TextInputType.number,
          style: GoogleFonts.inter(
            fontSize: 15,
            color: widget.isDark ? Colors.white : Colors.black87,
          ),
          decoration: InputDecoration(
            hintText: 'Ingresa tu contraseña',
            hintStyle: GoogleFonts.inter(
              color: widget.isDark ? Colors.white30 : Colors.black26,
            ),
            filled: true,
            fillColor: widget.isDark
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
              Icons.lock_outline_rounded,
              color: widget.isDark ? Colors.white70 : Colors.black38,
              size: 22,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: widget.isDark ? Colors.white70 : Colors.black38,
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
                  foregroundColor:
                      widget.isDark ? Colors.white70 : Colors.black54,
                  side: BorderSide(
                    color: widget.isDark ? Colors.white24 : Colors.black12,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: widget.loading ? null : widget.onBack,
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
                onPressed: widget.loading ? null : widget.onFinish,
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
}
