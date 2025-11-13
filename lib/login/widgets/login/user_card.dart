// lib/login/widgets/login/user_card.dart - VERSIÓN SIMPLIFICADA

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class UserCard extends StatelessWidget {
  final bool isDark;
  final String savedUser;
  final String? savedUserFullName;
  final VoidCallback onShowUserSelector;

  const UserCard({
    super.key,
    required this.isDark,
    required this.savedUser,
    this.savedUserFullName,
    required this.onShowUserSelector,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0E8833).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF0E8833).withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
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
                      savedUserFullName ?? savedUser,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    Text(
                      '@$savedUser',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              // ✅ SIMPLIFICADO: Botón directo para cambiar
              IconButton(
                icon: const Icon(Icons.swap_horiz),
                color: const Color(0xFF0E8833),
                tooltip: 'Cambiar usuario',
                onPressed: onShowUserSelector,
              ),
            ],
          ),
        ],
      ),
    );
  }
}