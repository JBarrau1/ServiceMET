import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'extenciones/database_helper.dart';
import 'detalles_seca_screen.dart';
import 'home/configuracion_screen.dart';
import 'home/otros_apartados_screen.dart';
import 'home/servicios_screen.dart';

class ServicioSeca {
  final String seca;
  final int cantidadBalanzas;
  final List<Map<String, dynamic>> balanzas;
  final String tipoServicio;

  ServicioSeca({
    required this.seca,
    required this.cantidadBalanzas,
    required this.balanzas,
    required this.tipoServicio,
  });
}

class HomeScreen extends StatefulWidget {
  final String dbName;
  const HomeScreen({super.key, this.dbName = ''});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Variables para el Home
  String userName = "Cargando...";
  String? photoUrl;
  int totalServiciosCal = 0;
  int totalServiciosSop = 0;
  String fechaUltimaPrecarga = "Sin datos";

  // Variables para la navegación
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _initializeDateFormatting();
    _fetchUserData();
    _loadDashboardData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _initializeDateFormatting() async {
    await initializeDateFormatting('es_ES', null);
  }

  // Lista de pantallas para cada tab
  List<Widget> _screens(BuildContext context) => [
    _buildHomeContent(context), // Contenido del home
    ServiciosScreen(userName: userName),
    OtrosApartadosScreen(userName: userName),
    ConfiguracionScreen(),
  ];

  // Cargar datos del dashboard
  Future<void> _loadDashboardData() async {
    await _getTotalServiciosCal();
    await _getFechaUltimaPrecarga();
    await _getTotalServiciosSop();
  }

  Future<void> _getTotalServiciosSop() async {
    try {
      String dbPath = join(await getDatabasesPath(), 'servicios_soporte_tecnico.db');

      if (await databaseExists(dbPath)) {
        Database? db;
        try {
          db = await openDatabase(dbPath, readOnly: false);

          // Verificar si la tabla existe
          final tableExists = await _tableExists(db, 'inf_cliente_balanza');
          if (!tableExists) {
            setState(() {
              totalServiciosSop = 0;
            });
            return;
          }

          final result = await db.rawQuery('SELECT COUNT(*) as total FROM inf_cliente_balanza');
          int count = result.isNotEmpty ? result.first['total'] as int : 0;

          if (mounted) {
            setState(() {
              totalServiciosSop = count;
            });
          }
        } catch (e) {
          print('Error consultando total servicios soporte: $e');
          if (mounted) {
            setState(() {
              totalServiciosSop = 0;
            });
          }
        } finally {
          await db?.close();
        }
      } else {
        if (mounted) {
          setState(() {
            totalServiciosSop = 0;
          });
        }
      }
    } catch (e) {
      print('Error en _getTotalServiciosSop: $e');
      if (mounted) {
        setState(() {
          totalServiciosSop = 0;
        });
      }
    }
  }

  Future<void> _getTotalServiciosCal() async {
    try {
      String dbPath = join(await getDatabasesPath(), 'calibracion.db');

      if (await databaseExists(dbPath)) {
        final db = await openDatabase(dbPath);
        final result = await db.rawQuery('SELECT COUNT(*) as total FROM registros_calibracion');
        await db.close();
        int count = result.isNotEmpty ? result.first['total'] as int : 0;
        setState(() {
          totalServiciosCal = count;
        });
      } else {
        setState(() {
          totalServiciosCal = 0;
        });
      }
    } catch (e) {
      setState(() {
        totalServiciosCal = 0;
      });
    }
  }

  Future<void> _getFechaUltimaPrecarga() async {
    try {
      String dbPath = join(await getDatabasesPath(), 'precarga_database.db');

      if (await databaseExists(dbPath)) {
        final file = File(dbPath);
        final lastModified = await file.lastModified();
        final formattedDate = DateFormat("d MMMM 'de' y", 'es_ES').format(lastModified);

        setState(() {
          fechaUltimaPrecarga = formattedDate;
        });
      } else {
        setState(() {
          fechaUltimaPrecarga = "No existe";
        });
      }
    } catch (e) {
      setState(() {
        fechaUltimaPrecarga = "Error";
      });
    }
  }


  Future<List<ServicioSeca>> _getServiciosAgrupadosPorSeca() async {
    final List<ServicioSeca> servicios = [];

    try {
      // === 1. CONSULTAR BASE DE DATOS DE CALIBRACIÓN ===
      String dbPathCalibracion = join(await getDatabasesPath(), 'calibracion.db');

      if (await databaseExists(dbPathCalibracion)) {
        Database? dbCalibracion;
        try {
          dbCalibracion = await openDatabase(
            dbPathCalibracion,
            readOnly: false, // Asegurar que no sea solo lectura
          );

          final List<Map<String, dynamic>> registrosCalibracion =
          await dbCalibracion.query('registros_calibracion');

          final Map<String, List<Map<String, dynamic>>> agrupadosCalibracion = {};

          for (var registro in registrosCalibracion) {
            final String seca = registro['seca']?.toString() ?? 'Sin SECA';

            if (!agrupadosCalibracion.containsKey(seca)) {
              agrupadosCalibracion[seca] = [];
            }

            agrupadosCalibracion[seca]!.add(registro);
          }

          // Crear ServicioSeca para calibración
          agrupadosCalibracion.forEach((seca, balanzas) {
            servicios.add(ServicioSeca(
              seca: 'SECA $seca',
              cantidadBalanzas: balanzas.length,
              balanzas: balanzas,
              tipoServicio: 'calibracion',
            ));
          });

        } catch (e) {
          print('Error consultando calibración: $e');
        } finally {
          await dbCalibracion?.close();
        }
      }

      // === 2. CONSULTAR BASE DE DATOS DE SOPORTE TÉCNICO ===
      String dbPathSoporte = join(await getDatabasesPath(), 'servicios_soporte_tecnico.db');

      if (await databaseExists(dbPathSoporte)) {
        Database? dbSoporte;
        try {
          dbSoporte = await openDatabase(
            dbPathSoporte,
            readOnly: false, // Asegurar que no sea solo lectura
          );

          // Lista de todas las tablas de soporte técnico
          final List<String> tablasSoporte = [
            'inf_cliente_balanza',
            'relevamiento_de_datos',
            'ajustes_metrológicos',
            'diagnostico',
            'mnt_prv_regular_stac',
            'mnt_prv_regular_stil',
            'mnt_prv_avanzado_stac',
            'mnt_prv_avanzado_stil',
            'mnt_correctivo',
            'instalacion',
            'verificaciones_internas'
          ];

          final Map<String, Map<String, List<Map<String, dynamic>>>> agrupadosSoporte = {};

          // Consultar cada tabla individualmente y verificar existencia
          for (String tabla in tablasSoporte) {
            try {
              // Verificar si la tabla existe antes de consultarla
              final tableExists = await _tableExists(dbSoporte, tabla);
              if (!tableExists) {
                print('Tabla $tabla no existe, saltando...');
                continue;
              }

              final List<Map<String, dynamic>> registrosTabla = await dbSoporte.query(tabla);

              for (var registro in registrosTabla) {
                // Obtener OTST y tipo de servicio
                String otst = '';
                String tipoServicio = '';

                // Diferentes campos según la tabla
                if (tabla == 'inf_cliente_balanza') {
                  otst = registro['otst']?.toString() ?? 'Sin OTST';
                  tipoServicio = 'Información Cliente'; // Valor por defecto
                } else {
                  otst = registro['cod_metrica']?.toString() ?? 'Sin OTST';
                  tipoServicio = registro['tipo_servicio']?.toString() ?? 'Sin Tipo';
                }

                // Solo procesar si tenemos datos válidos
                if (otst.isNotEmpty && otst != 'Sin OTST') {
                  // Crear clave única: OTST + Tipo de Servicio
                  final String claveGrupo = '$otst - $tipoServicio';

                  if (!agrupadosSoporte.containsKey(claveGrupo)) {
                    agrupadosSoporte[claveGrupo] = {};
                  }

                  if (!agrupadosSoporte[claveGrupo]!.containsKey(tabla)) {
                    agrupadosSoporte[claveGrupo]![tabla] = [];
                  }

                  // Agregar información de la tabla al registro
                  registro['tabla_origen'] = tabla;
                  agrupadosSoporte[claveGrupo]![tabla]!.add(registro);
                }
              }
            } catch (e) {
              print('Error consultando tabla $tabla: $e');
              // Continuar con la siguiente tabla en caso de error
              continue;
            }
          }

          // Crear ServicioSeca para soporte técnico
          agrupadosSoporte.forEach((claveGrupo, tablas) {
            // Contar total de registros en todas las tablas para este grupo
            int totalRegistros = 0;
            List<Map<String, dynamic>> todosLosRegistros = [];

            tablas.forEach((tabla, registros) {
              totalRegistros += registros.length;
              todosLosRegistros.addAll(registros);
            });

            if (totalRegistros > 0) { // Solo agregar si hay registros
              servicios.add(ServicioSeca(
                seca: 'OTST $claveGrupo',
                cantidadBalanzas: totalRegistros,
                balanzas: todosLosRegistros,
                tipoServicio: 'soporte',
              ));
            }
          });

        } catch (e) {
          print('Error general en soporte técnico: $e');
        } finally {
          await dbSoporte?.close();
        }
      }

      // Ordenar por nombre
      servicios.sort((a, b) => a.seca.compareTo(b.seca));
      return servicios;

    } catch (e) {
      print('Error en _getServiciosAgrupadosPorSeca: $e');
      return [];
    }
  }

  // Método auxiliar para verificar si una tabla existe
  Future<bool> _tableExists(Database db, String tableName) async {
    try {
      final result = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
        [tableName],
      );
      return result.isNotEmpty;
    } catch (e) {
      print('Error verificando existencia de tabla $tableName: $e');
      return false;
    }
  }

  Future<void> _fetchUserData() async {
    try {
      final dbHelper = DatabaseHelper();
      final userData = await dbHelper.getUserData();

      if (userData != null) {
        final tituloAbr = userData['titulo_abr'] ?? '';
        final nombre1 = userData['nombre1'] ?? '';
        final apellido1 = userData['apellido1'] ?? '';

        final userName = '$tituloAbr $nombre1 $apellido1'.trim();

        setState(() {
          this.userName = userName.isNotEmpty ? userName : "Usuario";
          photoUrl = null;
        });
      } else {
        setState(() {
          userName = "Usuario";
        });
      }
    } catch (e) {
      setState(() {
        userName = "Usuario";
      });
    }
  }

  Future<void> _exportarSecaDirectamente(BuildContext context, ServicioSeca servicio) async {
    try {
      final List<List<dynamic>> csvData = [];

      if (servicio.balanzas.isNotEmpty) {
        csvData.add(servicio.balanzas.first.keys.toList());
      }

      for (var balanza in servicio.balanzas) {
        csvData.add(balanza.values.toList());
      }

      String csv = const ListToCsvConverter().convert(csvData);
      final directory = await getDownloadsDirectory();
      final path = directory?.path;

      if (path == null) {
        throw Exception('No se pudo acceder al directorio de descargas');
      }

      final fileName = 'SECA_${servicio.seca}_${DateTime.now().millisecondsSinceEpoch}.csv';
      final filePath = '$path/$fileName';
      final File file = File(filePath);
      await file.writeAsString(csv);

      OpenFilex.open(filePath);

      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Archivo exportado: $fileName'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          )
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al exportar: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          )
      );
    }
  }

  Widget _buildWelcomeHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF2C3E50), const Color(0xFF34495E)]
              : [const Color(0xFF667EEA), const Color(0xFF764BA2)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: Colors.white.withOpacity(0.2),
                child: Icon(
                  FontAwesomeIcons.user,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '¡Bienvenido/a!',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      userName,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  FontAwesomeIcons.calendarAlt,
                  color: Colors.white,
                  size: 14,
                ),
                const SizedBox(width: 8),
                FutureBuilder(
                  future: initializeDateFormatting('es_ES', null),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done) {
                      return Text(
                        DateFormat('EEEE, dd MMMM yyyy', 'es_ES').format(DateTime.now()),
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      );
                    } else {
                      return Text(
                        DateFormat('dd/MM/yyyy').format(DateTime.now()),
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.2);
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback? onTap,
    required Color color,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color.withOpacity(0.8), color],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: Color(0xFF212121),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF212121),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServiceCard(BuildContext context, ServicioSeca servicio) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C3E50) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DetallesSecaScreen(servicioSeca: servicio),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: servicio.tipoServicio == 'calibracion'
                                ? [const Color(0xFF667EEA), const Color(0xFF764BA2)]
                                : [const Color(0xFF11998E), const Color(0xFF38EF7D)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          servicio.tipoServicio == 'calibracion'
                              ? FontAwesomeIcons.scaleBalanced
                              : FontAwesomeIcons.screwdriverWrench,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              servicio.seca,
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF2C3E50),
                              ),
                            ),
                            Text(
                              '${servicio.cantidadBalanzas} ${servicio.tipoServicio == 'calibracion' ? 'balanza' : 'registro'}${servicio.cantidadBalanzas != 1 ? 's' : ''}',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            // Mostrar tipo de servicio
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: servicio.tipoServicio == 'calibracion'
                                    ? Colors.blue.withOpacity(0.1)
                                    : Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                servicio.tipoServicio == 'calibracion' ? 'Calibración' : 'Soporte Técnico',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: servicio.tipoServicio == 'calibracion'
                                      ? Colors.blue[700]
                                      : Colors.green[700],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: servicio.tipoServicio == 'calibracion'
                              ? const Color(0xFF667EEA).withOpacity(0.1)
                              : const Color(0xFF11998E).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          servicio.cantidadBalanzas.toString(),
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: servicio.tipoServicio == 'calibracion'
                                ? const Color(0xFF667EEA)
                                : const Color(0xFF11998E),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DetallesSecaScreen(servicioSeca: servicio),
                              ),
                            );
                          },
                          icon: const Icon(FontAwesomeIcons.eye, size: 16),
                          label: const Text('Ver detalles'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: servicio.tipoServicio == 'calibracion'
                                ? const Color(0xFF667EEA)
                                : const Color(0xFF11998E),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _exportarSecaDirectamente(context, servicio),
                          icon: const Icon(FontAwesomeIcons.download, size: 16),
                          label: const Text('Exportar'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: servicio.tipoServicio == 'calibracion'
                                ? const Color(0xFF667EEA)
                                : const Color(0xFF11998E),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            side: BorderSide(
                              color: servicio.tipoServicio == 'calibracion'
                                  ? const Color(0xFF667EEA)
                                  : const Color(0xFF11998E),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Contenido original del Home
  Widget _buildHomeContent(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return RefreshIndicator(
      onRefresh: () async {
        await _loadDashboardData();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header de bienvenida
            _buildWelcomeHeader(context),

            const SizedBox(height: 30),

            // Estadísticas
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
                _buildStatCard(
                  icon: FontAwesomeIcons.screwdriverWrench,
                  title: 'Balanzas\nArregladas',
                  value: totalServiciosSop.toString(),
                  color: Color(0xFF89B2CC),
                  onTap: () {},
                ),
                const SizedBox(width: 16),
                _buildStatCard(
                  icon: FontAwesomeIcons.scaleBalanced,
                  title: 'Balanzas\nCalibradas',
                  value: totalServiciosCal.toString(),
                  color: Color(0xFFBFD6A7),
                  onTap: () {},
                ),
              ],
            ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.3),

            const SizedBox(height: 16),

            Row(
              children: [
                _buildStatCard(
                  icon: FontAwesomeIcons.cloudArrowDown,
                  title: 'Última\nPrecarga',
                  value: fechaUltimaPrecarga,
                  color: Color(0xFFD6D4A7),
                  onTap: () {},
                ),
              ],
            ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.3),

            const SizedBox(height: 40),

            // Lista de servicios
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Servicios por SECA u OTST',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : const Color(0xFF2C3E50),
                  ),
                ),
                Icon(
                  FontAwesomeIcons.listUl,
                  color: Colors.grey[600],
                  size: 20,
                ),
              ],
            ).animate().fadeIn(delay: 600.ms),

            const SizedBox(height: 20),

            FutureBuilder<List<ServicioSeca>>(
              future: _getServiciosAgrupadosPorSeca(),
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
                          FontAwesomeIcons.exclamationTriangle,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No hay servicios registrados',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Los servicios de calibración o soporte técnico aparecerán aquí cuando estén disponibles',
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

                    return _buildServiceCard(context, servicio)
                        .animate(delay: Duration(milliseconds: 700 + (index * 100)))
                        .fadeIn()
                        .slideX(begin: 0.3);
                  }).toList(),
                );
              },
            ),

            const SizedBox(height: 80), // Espacio para el bottom navigation
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              color: isDarkMode
                  ? Colors.black.withOpacity(0.4)
                  : Colors.white.withOpacity(0.7),
              border: Border.all(
                color: isDarkMode
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.1),
                width: 0.5,
              ),
            ),
            child: NavigationBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              height: 70,
              indicatorColor: const Color(0xFFE8CB0C).withOpacity(0.15),
              labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
              destinations: [
                NavigationDestination(
                  icon: Icon(
                    FontAwesomeIcons.home,
                    color: _currentIndex == 0
                        ? const Color(0xFFE8CB0C)
                        : (isDarkMode ? Colors.white70 : Colors.black54),
                    size: 20,
                  ),
                  label: 'Inicio',
                ),
                NavigationDestination(
                  icon: Icon(
                    FontAwesomeIcons.wrench,
                    color: _currentIndex == 1
                        ? const Color(0xFFE8CB0C)
                        : (isDarkMode ? Colors.white70 : Colors.black54),
                    size: 20,
                  ),
                  label: 'Servicios',
                ),
                NavigationDestination(
                  icon: Icon(
                    FontAwesomeIcons.solidFolder,
                    color: _currentIndex == 2
                        ? const Color(0xFFE8CB0C)
                        : (isDarkMode ? Colors.white70 : Colors.black54),
                    size: 20,
                  ),
                  label: 'Otros',
                ),
                NavigationDestination(
                  icon: Icon(
                    FontAwesomeIcons.cog,
                    color: _currentIndex == 3
                        ? const Color(0xFFE8CB0C)
                        : (isDarkMode ? Colors.white70 : Colors.black54),
                    size: 20,
                  ),
                  label: 'Configuración',
                ),
              ],
              selectedIndex: _currentIndex,
              onDestinationSelected: (index) {
                setState(() {
                  _currentIndex = index;
                });
                _pageController.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
            child: AppBar(
              toolbarHeight: 70,
              title: Text(
                _getAppBarTitle(),
                style: GoogleFonts.poppins(
                  color: isDarkMode ? Colors.white : Colors.black,
                  fontWeight: FontWeight.w700,
                  fontSize: 16.0,
                ),
              ),
              backgroundColor: isDarkMode
                  ? Colors.black.withOpacity(0.1)
                  : Colors.white.withOpacity(0.7),
              elevation: 0,
              centerTitle: true,
              // Agregar borde sutil como en NavigationBar
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(0.5),
                child: Container(
                  height: 0.5,
                  color: isDarkMode
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.1),
                ),
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: _screens(context),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  String _getAppBarTitle() {
    switch (_currentIndex) {
      case 0:
        return 'INICIO';
      case 1:
        return 'SERVICIOS';
      case 2:
        return 'OTROS';
      case 3:
        return 'CONFIGURACIÓN';
      default:
        return 'INICIO';
    }
  }
}