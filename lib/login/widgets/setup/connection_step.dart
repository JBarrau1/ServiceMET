// lib/login/widgets/setup/connection_step.dart

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'config_field.dart';

class ConnectionStep extends StatelessWidget {
  final bool isDark;
  final bool loading;
  final TextEditingController ipController;
  final TextEditingController portController;
  final TextEditingController dbController;
  final TextEditingController dbUserController;
  final TextEditingController dbPassController;
  final VoidCallback onContinue;

  const ConnectionStep({
    super.key,
    required this.isDark,
    required this.loading,
    required this.ipController,
    required this.portController,
    required this.dbController,
    required this.dbUserController,
    required this.dbPassController,
    required this.onContinue,
  });

  bool _isValidIP(String ip) {
    final ipRegex = RegExp(r'^(\d{1,3}\.){3}\d{1,3}$');
    if (!ipRegex.hasMatch(ip)) return false;

    final parts = ip.split('.');
    for (var part in parts) {
      final num = int.tryParse(part);
      if (num == null || num < 0 || num > 255) return false;
    }
    return true;
  }

  bool _isValidPort(String port) {
    final portNum = int.tryParse(port);
    return portNum != null && portNum > 0 && portNum <= 65535;
  }

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
                Icons.storage_outlined,
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
                    'Paso 1: Conexión',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  Text(
                    'Configure la conexión al servidor',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        ConfigField(
          label: 'IP del Servidor',
          controller: ipController,
          icon: Icons.dns_outlined,
          isDark: isDark,
          isNumber: true,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Este campo es requerido';
            }
            if (!_isValidIP(value)) {
              return 'IP inválida';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        ConfigField(
          label: 'Puerto',
          controller: portController,
          icon: Icons.cable_outlined,
          isDark: isDark,
          isNumber: true,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Este campo es requerido';
            }
            if (!_isValidPort(value)) {
              return 'Puerto inválido (1-65535)';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        ConfigField(
          label: 'Base de Datos',
          controller: dbController,
          icon: Icons.storage_outlined,
          isDark: isDark,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Este campo es requerido';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        ConfigField(
          label: 'Usuario BD',
          controller: dbUserController,
          icon: Icons.admin_panel_settings_outlined,
          isDark: isDark,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Este campo es requerido';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        ConfigField(
          label: 'Contraseña BD',
          controller: dbPassController,
          icon: Icons.vpn_key_outlined,
          isDark: isDark,
          isPassword: true,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Este campo es requerido';
            }
            return null;
          },
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0E8833),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: loading ? null : onContinue,
            icon: const Icon(Icons.arrow_forward),
            label: Text(
              'Validar Conexión y Continuar',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
