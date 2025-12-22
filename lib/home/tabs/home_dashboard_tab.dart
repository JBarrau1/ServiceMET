import 'dart:io';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:intl/intl.dart';

import '../models/servicio_model.dart';
import '../widgets/welcome_header.dart';
import '../widgets/stat_card.dart';
import '../widgets/tipo_servicio_selector.dart';
import '../widgets/service_card_calibracion.dart';
import '../widgets/service_card_soporte.dart';

class HomeDashboardTab extends StatefulWidget {
  final String userName;
  final VoidCallback goToServicios;

  const HomeDashboardTab({
    super.key,
    required this.userName,
    required this.goToServicios,
  });

  @override
  State<HomeDashboardTab> createState() => _HomeDashboardTabState();
}

class _HomeDashboardTabState extends State<HomeDashboardTab> {
  int _tipoServicioSeleccionado = 0; // 0: Calibración, 1: Soporte Técnico
  int totalServiciosCal = 0;
  int totalServiciosSop = 0;
  String fechaUltimaPrecarga = "Sin datos";

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    await _getTotalServiciosCal();
    await _getFechaUltimaPrecarga();
    await _getTotalServiciosSop();
  }

  Future<void> _getTotalServiciosSop() async {
    try {
      int total = 0;
      final Map<String, String> databasesMap = {
        'ajustes.db': 'ajustes_metrologicos',
        'diagnostico.db': 'diagnostico',
        'instalacion.db': 'instalacion',
        'mnt_correctivo.db': 'mnt_correctivo',
        'mnt_prv_avanzado_stac.db': 'mnt_prv_avanzado_stac',
        'mnt_prv_avanzado_stil.db': 'mnt_prv_avanzado_stil',
        'mnt_prv_regular_stac.db': 'mnt_prv_regular_stac',
        'mnt_prv_regular_stil.db': 'mnt_prv_regular_stil',
        'relevamiento_de_datos.db': 'relevamiento_de_datos',
        'verificaciones.db': 'verificaciones_internas',
      };

      for (var entry in databasesMap.entries) {
        String dbName = entry.key;
        String tableName = entry.value;
        String dbPath = p.join(await getDatabasesPath(), dbName);

        if (await databaseExists(dbPath)) {
          try {
            final db = await openDatabase(dbPath);
            final result =
                await db.rawQuery('SELECT COUNT(*) as total FROM $tableName');
            await db.close();
            int count = result.isNotEmpty ? result.first['total'] as int : 0;
            total += count;
          } catch (e) {
            debugPrint('Error contando en $dbName: $e');
            continue;
          }
        }
      }

      if (mounted) {
        setState(() {
          totalServiciosSop = total;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          totalServiciosSop = 0;
        });
      }
    }
  }

  Future<void> _getTotalServiciosCal() async {
    try {
      String dbPath = p.join(await getDatabasesPath(), 'calibracion.db');

      if (await databaseExists(dbPath)) {
        final db = await openDatabase(dbPath);
        final result = await db.rawQuery(
            'SELECT COUNT(*) as total FROM registros_calibracion WHERE estado_servicio_bal = ?',
            ['Balanza Calibrada']);
        await db.close();
        int count = result.isNotEmpty ? result.first['total'] as int : 0;
        if (mounted) {
          setState(() {
            totalServiciosCal = count;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            totalServiciosCal = 0;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          totalServiciosCal = 0;
        });
      }
    }
  }

  Future<void> _getFechaUltimaPrecarga() async {
    try {
      String dbPath = p.join(await getDatabasesPath(), 'precarga_database.db');

      if (await databaseExists(dbPath)) {
        final file = File(dbPath);
        final lastModified = await file.lastModified();
        final formattedDate =
            DateFormat("d MMMM 'de' y", 'es_ES').format(lastModified);

        if (mounted) {
          setState(() {
            fechaUltimaPrecarga = formattedDate;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            fechaUltimaPrecarga = "No existe";
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          fechaUltimaPrecarga = "Error";
        });
      }
    }
  }

  String _obtenerTipoServicio(String dbName) {
    switch (dbName) {
      case 'ajustes.db':
        return 'Ajustes';
      case 'diagnostico.db':
        return 'Diagnóstico';
      case 'instalacion.db':
        return 'Instalación';
      case 'mnt_correctivo.db':
        return 'Mantenimiento Correctivo';
      case 'mnt_prv_avanzado_stac.db':
        return 'Mantenimiento Preventivo Avanzado STAC';
      case 'mnt_prv_avanzado_stil.db':
        return 'Mantenimiento Preventivo Avanzado STIL';
      case 'mnt_prv_regular_stac.db':
        return 'Mantenimiento Preventivo Regular STAC';
      case 'mnt_prv_regular_stil.db':
        return 'Mantenimiento Preventivo Regular STIL';
      case 'relevamiento.db':
        return 'Relevamiento';
      case 'verificaciones.db':
        return 'Verificaciones';
      default:
        return 'Soporte Técnico';
    }
  }

  Future<List<ServicioSeca>> _getServiciosCalibracionPorSeca() async {
    final List<ServicioSeca> servicios = [];

    try {
      String dbPath = p.join(await getDatabasesPath(), 'calibracion.db');

      if (await databaseExists(dbPath)) {
        final db = await openDatabase(dbPath);
        final List<Map<String, dynamic>> registros =
            await db.query('registros_calibracion');
        final Map<String, List<Map<String, dynamic>>> agrupados = {};

        for (var registro in registros) {
          final String seca = registro['seca']?.toString() ?? 'Sin SECA';
          if (!agrupados.containsKey(seca)) {
            agrupados[seca] = [];
          }
          agrupados[seca]!.add(registro);
        }

        agrupados.forEach((seca, balanzas) {
          servicios.add(ServicioSeca(
            seca: seca,
            cantidadBalanzas: balanzas.length,
            balanzas: balanzas,
          ));
        });

        await db.close();
      }

      servicios.sort((a, b) => a.seca.compareTo(b.seca));
      return servicios;
    } catch (e) {
      return [];
    }
  }

  Future<List<ServicioOtst>> _getServiciosSoportePorOtst() async {
    final List<ServicioOtst> servicios = [];

    try {
      final Map<String, String> databasesMap = {
        'ajustes.db': 'ajustes_metrologicos',
        'diagnostico.db': 'diagnostico',
        'instalacion.db': 'instalacion',
        'mnt_correctivo.db': 'mnt_correctivo',
        'mnt_prv_avanzado_stac.db': 'mnt_prv_avanzado_stac',
        'mnt_prv_avanzado_stil.db': 'mnt_prv_avanzado_stil',
        'mnt_prv_regular_stac.db': 'mnt_prv_regular_stac',
        'mnt_prv_regular_stil.db': 'mnt_prv_regular_stil',
        'relevamiento_de_datos.db': 'relevamiento_de_datos',
        'verificaciones.db': 'verificaciones_internas',
      };

      final Map<String, List<Map<String, dynamic>>> agrupados = {};

      for (var entry in databasesMap.entries) {
        String dbName = entry.key;
        String tableName = entry.value;
        String dbPath = p.join(await getDatabasesPath(), dbName);

        if (await databaseExists(dbPath)) {
          try {
            final db = await openDatabase(dbPath);
            final List<Map<String, dynamic>> registros =
                await db.query(tableName);
            await db.close();

            for (var registro in registros) {
              final String otst = registro['otst']?.toString() ?? 'Sin OTST';
              if (!agrupados.containsKey(otst)) {
                agrupados[otst] = [];
              }
              // Agregar información del tipo de servicio.
              // IMPORTANTE: Creamos un nuevo mapa modificable porque el de sqflite es de solo lectura a veces.
              final Map<String, dynamic> registroMod =
                  Map<String, dynamic>.from(registro);
              registroMod['tipo_servicio'] = _obtenerTipoServicio(dbName);
              agrupados[otst]!.add(registroMod);
            }
          } catch (e) {
            continue;
          }
        }
      }

      agrupados.forEach((otst, serviciosList) {
        servicios.add(ServicioOtst(
          otst: otst,
          cantidadServicios: serviciosList.length,
          servicios: serviciosList,
        ));
      });

      servicios.sort((a, b) => a.otst.compareTo(b.otst));
      return servicios;
    } catch (e) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return RefreshIndicator(
      onRefresh: () async {
        await _loadDashboardData();
        setState(() {}); // Forzar reconstrucción para recargar listas
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            WelcomeHeader(userName: widget.userName),
            const SizedBox(height: 30),
            Text(
              'Estadísticas',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : const Color(0xFF2C3E50),
              ),
            ).animate().fadeIn(delay: 300.ms),
            const SizedBox(height: 16),
            Row(
              children: [
                StatCard(
                  icon: FontAwesomeIcons.screwdriverWrench,
                  title: 'Servicios\nSoporte Técnico',
                  value: totalServiciosSop.toString(),
                  color: const Color(0xFF89B2CC),
                  onTap: () {
                    setState(() {
                      _tipoServicioSeleccionado = 1;
                    });
                  },
                ),
                const SizedBox(width: 16),
                StatCard(
                  icon: FontAwesomeIcons.scaleBalanced,
                  title: 'Balanzas\nCalibradas',
                  value: totalServiciosCal.toString(),
                  color: const Color(0xFFBFD6A7),
                  onTap: () {
                    setState(() {
                      _tipoServicioSeleccionado = 0;
                    });
                  },
                ),
              ],
            ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.3),
            const SizedBox(height: 16),
            Row(
              children: [
                StatCard(
                  icon: FontAwesomeIcons.cloudArrowDown,
                  title: 'Última\nPrecarga',
                  value: fechaUltimaPrecarga,
                  color: const Color(0xFFD6D4A7),
                  onTap:
                      () {}, // Puede navegar a pantalla de precarga si se desea
                ),
              ],
            ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.3),
            const SizedBox(height: 40),
            TipoServicioSelector(
              selectedIndex: _tipoServicioSeleccionado,
              onSelected: (index) {
                setState(() {
                  _tipoServicioSeleccionado = index;
                });
              },
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _tipoServicioSeleccionado == 0
                      ? 'Servicios de Calibración\npor SECA'
                      : 'Servicios de Soporte\npor OTST',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : const Color(0xFF2C3E50),
                  ),
                ),
                Icon(
                  _tipoServicioSeleccionado == 0
                      ? FontAwesomeIcons.scaleBalanced
                      : FontAwesomeIcons.screwdriverWrench,
                  color: Colors.grey[600],
                  size: 20,
                ),
              ],
            ).animate().fadeIn(delay: 600.ms),
            const SizedBox(height: 20),
            if (_tipoServicioSeleccionado == 0)
              _buildListaCalibracion(context)
            else
              _buildListaSoporte(context),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildListaCalibracion(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return FutureBuilder<List<ServicioSeca>>(
      future: _getServiciosCalibracionPorSeca(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF2C3E50) : Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              children: [
                Icon(
                  FontAwesomeIcons.scaleBalanced,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No hay servicios de calibración',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Los servicios de calibración aparecerán aquí cuando estén disponibles',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final servicios = snapshot.data!;

        return Column(
          children: servicios.asMap().entries.map((entry) {
            final index = entry.key;
            final servicio = entry.value;

            return ServiceCardCalibracion(servicio: servicio)
                .animate(delay: Duration(milliseconds: 700 + (index * 100)))
                .fadeIn()
                .slideX(begin: 0.3);
          }).toList(),
        );
      },
    );
  }

  Widget _buildListaSoporte(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return FutureBuilder<List<ServicioOtst>>(
      future: _getServiciosSoportePorOtst(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF2C3E50) : Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              children: [
                Icon(
                  FontAwesomeIcons.screwdriverWrench,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No hay servicios de soporte técnico',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Los servicios de soporte técnico aparecerán aquí cuando estén disponibles',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final servicios = snapshot.data!;

        return Column(
          children: servicios.asMap().entries.map((entry) {
            final index = entry.key;
            final servicio = entry.value;

            return ServiceCardSoporte(servicio: servicio)
                .animate(delay: Duration(milliseconds: 700 + (index * 100)))
                .fadeIn()
                .slideX(begin: 0.3);
          }).toList(),
        );
      },
    );
  }
}
