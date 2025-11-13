import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'detalles_seca_screen.dart';
import 'detalles_otst_screen.dart';
import 'home/configuracion_screen.dart';
import 'home/otros_apartados_screen.dart';
import 'home/servicios_screen.dart';

class ServicioSeca {
  final String seca;
  final int cantidadBalanzas;
  final List<Map<String, dynamic>> balanzas;

  ServicioSeca({
    required this.seca,
    required this.cantidadBalanzas,
    required this.balanzas,
  });
}

class ServicioOtst {
  final String otst;
  final int cantidadServicios;
  final List<Map<String, dynamic>> servicios;

  ServicioOtst({
    required this.otst,
    required this.cantidadServicios,
    required this.servicios,
  });
}

class HomeScreen extends StatefulWidget {
  final String dbName;
  const HomeScreen({super.key, this.dbName = ''});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _modoDemo = false;
  // Variables para el Home
  String userName = "Cargando...";
  String? photoUrl;
  int totalServiciosCal = 0;
  int totalServiciosSop = 0;
  String fechaUltimaPrecarga = "Sin datos";

  // Variables para controlar qué tipo de servicios mostrar
  int _tipoServicioSeleccionado = 0; // 0: Calibración, 1: Soporte Técnico

  // Variables para la navegación (ahora solo 3 tabs)
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _initializeDateFormatting();
    _checkModoDemo();
    _fetchUserData();
    _loadDashboardData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _checkModoDemo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _modoDemo = prefs.getBool('modoDemo') ?? false;
    });
  }

  Future<void> _initializeDateFormatting() async {
    await initializeDateFormatting('es_ES', null);
  }

  // Lista de pantallas para cada tab (sin Configuración)
  List<Widget> _screens(BuildContext context) => [
    _buildHomeContent(context),
    ServiciosScreen(userName: userName),
    OtrosApartadosScreen(userName: userName),
  ];

  // Cargar datos del dashboard
  Future<void> _loadDashboardData() async {
    await _getTotalServiciosCal();
    await _getFechaUltimaPrecarga();
    await _getTotalServiciosSop();
  }

  Future<void> _getTotalServiciosSop() async {
    try {
      int total = 0;

      // Mapa de bases de datos con sus nombres de tabla correctos
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
        String dbPath = join(await getDatabasesPath(), dbName);

        if (await databaseExists(dbPath)) {
          try {
            final db = await openDatabase(dbPath);
            final result = await db.rawQuery('SELECT COUNT(*) as total FROM $tableName');
            await db.close();
            int count = result.isNotEmpty ? result.first['total'] as int : 0;
            total += count;
          } catch (e) {
            debugPrint('Error contando en $dbName: $e');
            continue;
          }
        }
      }

      setState(() {
        totalServiciosSop = total;
      });
    } catch (e) {
      debugPrint('Error en _getTotalServiciosSop: $e');
      setState(() {
        totalServiciosSop = 0;
      });
    }
  }

  Future<void> _getTotalServiciosCal() async {
    try {
      String dbPath = join(await getDatabasesPath(), 'calibracion.db');

      if (await databaseExists(dbPath)) {
        final db = await openDatabase(dbPath);
        final result = await db.rawQuery(
            'SELECT COUNT(*) as total FROM registros_calibracion WHERE estado_servicio_bal = ?',
            ['Balanza Calibrada']
        );
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

  // Obtener servicios de calibración agrupados por SECA
  Future<List<ServicioSeca>> _getServiciosCalibracionPorSeca() async {
    final List<ServicioSeca> servicios = [];

    try {
      String dbPath = join(await getDatabasesPath(), 'calibracion.db');

      if (await databaseExists(dbPath)) {
        final db = await openDatabase(dbPath);
        final List<Map<String, dynamic>> registros = await db.query('registros_calibracion');
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

  // Obtener servicios de soporte técnico agrupados por OTST
  Future<List<ServicioOtst>> _getServiciosSoportePorOtst() async {
    final List<ServicioOtst> servicios = [];

    try {
      // Mapa de bases de datos con sus nombres de tabla correctos
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
        String dbPath = join(await getDatabasesPath(), dbName);

        if (await databaseExists(dbPath)) {
          try {
            final db = await openDatabase(dbPath);
            final List<Map<String, dynamic>> registros = await db.query(tableName);
            await db.close();

            for (var registro in registros) {
              final String otst = registro['otst']?.toString() ?? 'Sin OTST';

              if (!agrupados.containsKey(otst)) {
                agrupados[otst] = [];
              }

              // Agregar información del tipo de servicio
              registro['tipo_servicio'] = _obtenerTipoServicio(dbName);
              agrupados[otst]!.add(registro);
            }
          } catch (e) {
            debugPrint('Error leyendo $dbName: $e');
            // Continuar con la siguiente base de datos si hay error
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
      debugPrint('Error general en _getServiciosSoportePorOtst: $e');
      return [];
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

  Future<void> _fetchUserData() async {
    try {
      // ✅ PASO 1: Obtener el usuario logueado desde SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final usuarioLogueado = prefs.getString('logged_user');

      if (usuarioLogueado == null || usuarioLogueado.isEmpty) {
        setState(() {
          userName = "Usuario";
        });
        return;
      }

      // ✅ PASO 2: Buscar los datos del usuario específico en la BD
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'usuarios.db');

      if (!await databaseExists(path)) {
        setState(() {
          userName = "Usuario";
        });
        return;
      }

      final db = await openDatabase(path);

      // ✅ PASO 3: Query filtrado por usuario actual
      final results = await db.query(
        'usuarios',
        where: 'usuario = ?',
        whereArgs: [usuarioLogueado],
        limit: 1,
      );

      await db.close();

      if (results.isEmpty) {
        setState(() {
          userName = "Usuario";
        });
        return;
      }

      // ✅ PASO 4: Construir el nombre completo
      final userData = results.first;
      final tituloAbr = userData['titulo_abr']?.toString() ?? '';
      final nombre1 = userData['nombre1']?.toString() ?? '';
      final apellido1 = userData['apellido1']?.toString() ?? '';
      final apellido2 = userData['apellido2']?.toString() ?? '';

      String inicialApellido2 = '';
      if (apellido2.isNotEmpty) {
        inicialApellido2 = '${apellido2[0]}.';
      }

      final fullName = '$tituloAbr $nombre1 $apellido1 $inicialApellido2'.trim();

      setState(() {
        userName = fullName.isNotEmpty ? fullName : "Usuario";
        photoUrl = null;
      });

      debugPrint('✅ Usuario cargado: $userName (ID: $usuarioLogueado)');

    } catch (e) {
      debugPrint('❌ Error obteniendo datos del usuario: $e');
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

  Future<void> _exportarOtstDirectamente(BuildContext context, ServicioOtst servicio) async {
    try {
      final List<List<dynamic>> csvData = [];

      if (servicio.servicios.isNotEmpty) {
        csvData.add(servicio.servicios.first.keys.toList());
      }

      for (var serv in servicio.servicios) {
        csvData.add(serv.values.toList());
      }

      String csv = const ListToCsvConverter().convert(csvData);
      final directory = await getDownloadsDirectory();
      final path = directory?.path;

      if (path == null) {
        throw Exception('No se pudo acceder al directorio de descargas');
      }

      final fileName = 'OTST_${servicio.otst}_${DateTime.now().millisecondsSinceEpoch}.csv';
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

  Widget _buildServiceCardCalibracion(BuildContext context, ServicioSeca servicio) {
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
                          gradient: const LinearGradient(
                            colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          FontAwesomeIcons.scaleBalanced,
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
                              'SECA ${servicio.seca}',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF2C3E50),
                              ),
                            ),
                            Text(
                              '${servicio.cantidadBalanzas} balanza${servicio.cantidadBalanzas != 1 ? 's' : ''} calibrada${servicio.cantidadBalanzas != 1 ? 's' : ''}',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF667EEA).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          servicio.cantidadBalanzas.toString(),
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF667EEA),
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
                            backgroundColor: const Color(0xFF667EEA),
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
                            foregroundColor: const Color(0xFF667EEA),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            side: const BorderSide(color: Color(0xFF667EEA)),
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

  Widget _buildServiceCardSoporte(BuildContext context, ServicioOtst servicio) {
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
                  builder: (context) => DetallesOtstScreen(servicioOtst: servicio),
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
                          gradient: const LinearGradient(
                            colors: [Color(0xFF4CAF50), Color(0xFF45a049)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          FontAwesomeIcons.screwdriverWrench,
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
                              'OTST ${servicio.otst}',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF2C3E50),
                              ),
                            ),
                            Text(
                              '${servicio.cantidadServicios} servicio${servicio.cantidadServicios != 1 ? 's' : ''} técnico${servicio.cantidadServicios != 1 ? 's' : ''}',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          servicio.cantidadServicios.toString(),
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF4CAF50),
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
                                builder: (context) => DetallesOtstScreen(servicioOtst: servicio),
                              ),
                            );
                          },
                          icon: const Icon(FontAwesomeIcons.eye, size: 16),
                          label: const Text('Ver detalles'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4CAF50),
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
                          onPressed: () => _exportarOtstDirectamente(context, servicio),
                          icon: const Icon(FontAwesomeIcons.download, size: 16),
                          label: const Text('Exportar'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF4CAF50),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            side: const BorderSide(color: Color(0xFF4CAF50)),
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

  Widget _buildTipoServicioSelector(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildTipoServicioButton(
            index: 0,
            icon: FontAwesomeIcons.scaleBalanced,
            label: 'Calibración',
            isSelected: _tipoServicioSeleccionado == 0,
          ),
          _buildTipoServicioButton(
            index: 1,
            icon: FontAwesomeIcons.screwdriverWrench,
            label: 'Soporte Técnico',
            isSelected: _tipoServicioSeleccionado == 1,
          ),
        ],
      ),
    );
  }

  Widget _buildTipoServicioButton({
    required int index,
    required IconData icon,
    required String label,
    required bool isSelected,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _tipoServicioSeleccionado = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF667EEA) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : Colors.grey,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.white : Colors.grey,
                ),
              ),
            ],
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
                  title: 'Servicios\nSoporte Técnico',
                  value: totalServiciosSop.toString(),
                  color: Color(0xFF89B2CC),
                  onTap: () {
                    setState(() {
                      _tipoServicioSeleccionado = 1;
                    });
                  },
                ),
                const SizedBox(width: 16),
                _buildStatCard(
                  icon: FontAwesomeIcons.scaleBalanced,
                  title: 'Balanzas\nCalibradas',
                  value: totalServiciosCal.toString(),
                  color: Color(0xFFBFD6A7),
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

            // Selector de tipo de servicio
            _buildTipoServicioSelector(context),

            const SizedBox(height: 20),

            // Lista de servicios según el tipo seleccionado
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

            const SizedBox(height: 80), // Espacio para el bottom navigation
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

            return _buildServiceCardCalibracion(context, servicio)
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

            return _buildServiceCardSoporte(context, servicio)
                .animate(delay: Duration(milliseconds: 700 + (index * 100)))
                .fadeIn()
                .slideX(begin: 0.3);
          }).toList(),
        );
      },
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
              height: 80,
              indicatorColor: const Color(0xFFE8CB0C).withOpacity(0.15),
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              destinations: [
                NavigationDestination(
                  icon: Icon(
                    FontAwesomeIcons.home,
                    color: _modoDemo
                        ? (isDarkMode ? Colors.white24 : Colors.black26)
                        : _currentIndex == 0
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
                    FontAwesomeIcons.download,
                    color: _modoDemo
                        ? (isDarkMode ? Colors.white24 : Colors.black26)
                        : _currentIndex == 2
                        ? const Color(0xFFE8CB0C)
                        : (isDarkMode ? Colors.white70 : Colors.black54),
                    size: 20,
                  ),
                  label: 'Precarga',
                ),
              ],
              selectedIndex: _currentIndex,
              onDestinationSelected: (index) {
                // En modo DEMO solo permitir acceso a Servicios (index 1)
                if (_modoDemo && index != 1) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.lock_outline, color: Colors.white, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'En modo DESCONECTADO solo puedes acceder a Servicios',
                              style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: const Color(0xFFFF9800),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                    ),
                  );
                  return;
                }

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
            filter: ImageFilter.blur(sigmaX: 40.0, sigmaY: 40.0),
            child: AppBar(
              toolbarHeight: 70,
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _getAppBarTitle(),
                    style: GoogleFonts.poppins(
                      color: isDarkMode ? Colors.white : Colors.black,
                      fontWeight: FontWeight.w700,
                      fontSize: 16.0,
                    ),
                  ),
                  if (_modoDemo) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF9800).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFFF9800),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.science,
                            size: 12,
                            color: const Color(0xFFFF9800),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'DEMO',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFFF9800),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              backgroundColor: isDarkMode
                  ? Colors.black.withOpacity(0.1)
                  : Colors.white.withOpacity(0.7),
              elevation: 0,
              centerTitle: true,
              actions: [
                // Botón de Configuración en el AppBar
                if (!_modoDemo)
                  IconButton(
                    icon: Icon(
                      FontAwesomeIcons.cog,
                      size: 20,
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ConfiguracionScreen(),
                        ),
                      );
                    },
                    tooltip: 'Configuración',
                  ),

                // Botón para salir del modo DEMO
                if (_modoDemo)
                  IconButton(
                    icon: Icon(
                      Icons.exit_to_app,
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          title: Row(
                            children: [
                              Icon(
                                Icons.logout,
                                color: const Color(0xFFFF9800),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Salir del modo DESCONECTADO',
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          content: Text(
                            '¿Deseas salir del modo DESCONECTADO y volver al login?',
                            style: GoogleFonts.inter(),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: Text(
                                'Cancelar',
                                style: GoogleFonts.inter(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF9800),
                              ),
                              child: Text(
                                'Salir',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        SharedPreferences prefs = await SharedPreferences.getInstance();
                        await prefs.setBool('modoDemo', false);
                        Navigator.pushReplacementNamed(context, '/login');
                      }
                    },
                    tooltip: 'Salir del modo DESCONECTADO',
                  ),
              ],
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
        return 'PRECARGA';
      default:
        return 'INICIO';
    }
  }
}