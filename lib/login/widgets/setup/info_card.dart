// lib/login/widgets/setup/info_card.dart

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class InfoCard extends StatelessWidget {
  final bool isDark;
  final int currentStep;

  const InfoCard({
    super.key,
    required this.isDark,
    required this.currentStep,
  });

  @override
  Widget build(BuildContext context) {
    final message = currentStep == 0
        ? 'Paso 1 de 2: Se conectará al servidor y descargará los datos necesarios.'
        : 'Paso 2 de 2: Ingrese sus credenciales para configurar el acceso automático.';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0E8833).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF0E8833).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline,
            color: Color(0xFF0E8833),
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: isDark ? Colors.white70 : Colors.black87,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
