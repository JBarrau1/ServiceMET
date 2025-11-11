// lib/login/widgets/login/auto_login_loading.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AutoLoginLoading extends StatelessWidget {
  final bool isDark;
  final String? savedUserFullName;
  final String? savedUser;

  const AutoLoginLoading({
    super.key,
    required this.isDark,
    this.savedUserFullName,
    this.savedUser,
  });

  @override
  Widget build(BuildContext context) {
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
            savedUserFullName ?? '@$savedUser',
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
}