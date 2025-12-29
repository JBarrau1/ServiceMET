// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../login/services/setup_service.dart';
import '../../login/widgets/setup/setup_loading.dart';

class DescargaDeDatosScreen extends StatefulWidget {
  final String userName;
  const DescargaDeDatosScreen({
    super.key,
    required this.userName,
  });

  @override
  State<DescargaDeDatosScreen> createState() => _DescargaDeDatosScreenState();
}

class _DescargaDeDatosScreenState extends State<DescargaDeDatosScreen> {
  final SetupService _setupService = SetupService();
  bool _loading = false;
  String _statusMessage = '';
  double _progressValue = 0.0;
  String? _lastUpdate;

  @override
  void initState() {
    super.initState();
    _loadLastUpdate();
  }

  @override
  void dispose() {
    _setupService.disconnect();
    super.dispose();
  }

  Future<void> _loadLastUpdate() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _lastUpdate = prefs.getString('lastUpdate');
    });
  }

  Future<void> _updateData() async {
    // Confirmación
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Actualizar Datos',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: const Text(
            '¿Está seguro de actualizar los datos? Esto reemplazará la información actual con la del servidor.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0E8833)),
            child:
                const Text('Actualizar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _loading = true;
      _statusMessage = 'Conectando al servidor...';
      _progressValue = 0.0;
    });

    try {
      // 1. Conectar usando configuración guardada
      final connectionResult =
          await _setupService.connectFromSavedConfiguration();

      if (!connectionResult.success) {
        _showError(connectionResult.message);
        setState(() => _loading = false);
        return;
      }

      // 2. Descargar datos
      final downloadResult = await _setupService.downloadPrecargaData(
        (message, progress) {
          setState(() {
            _statusMessage = message;
            _progressValue = progress;
          });
        },
      );

      if (!downloadResult.success) {
        _showError(downloadResult.message);
        setState(() => _loading = false);
        return;
      }

      // 3. Finalizar
      await _setupService.disconnect();

      // Actualizar fecha de última actualización
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now().toIso8601String();
      await prefs.setString('lastUpdate', now);

      setState(() {
        _loading = false;
        _lastUpdate = now;
        _statusMessage = '';
        _progressValue = 0.0;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Datos actualizados exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _showError('Error inesperado: $e');
      setState(() => _loading = false);
    }
  }

  void _showError(String message) {
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
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
            child: AppBar(
              toolbarHeight: 70,
              title: Text(
                'PRECARGA DE DATOS',
                style: GoogleFonts.poppins(
                  color: isDark ? Colors.white : Colors.black,
                  fontWeight: FontWeight.w700,
                  fontSize: 16.0,
                ),
              ),
              backgroundColor: isDark
                  ? Colors.black.withOpacity(0.4)
                  : Colors.white.withOpacity(0.7),
              elevation: 0,
              centerTitle: true,
            ),
          ),
        ),
      ),
      body: _loading
          ? SetupLoading(
              isDark: isDark,
              statusMessage: _statusMessage,
              progressValue: _progressValue,
            )
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2d2d2d) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.cloud_sync_outlined,
                          size: 48,
                          color: Color(0xFF0E8833),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Sincronización de Datos',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Actualice la base de datos local con la información más reciente del servidor.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Last Update Info
                  if (_lastUpdate != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0E8833).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF0E8833).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.history, color: Color(0xFF0E8833)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Última actualización:',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.black87,
                                  ),
                                ),
                                Text(
                                  _formatDate(_lastUpdate!),
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color:
                                        isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  const Spacer(),

                  // Update Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _updateData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0E8833),
                        foregroundColor: Colors.white,
                        elevation: 4,
                      ),
                      icon: const Icon(Icons.refresh),
                      label: Text(
                        'ACTUALIZAR DATOS',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return isoDate;
    }
  }
}
