import 'dart:ui';
import 'package:service_met/screens/calibracion/precarga.dart';
import 'package:service_met/screens/historial/ult_servicios.dart';
import 'package:service_met/screens/precarga/descarga_de_datos.dart';
import 'package:service_met/screens/respaldo/respaldo.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:service_met/screens_new/area_selection/area_seleccion.dart';
import 'package:sqflite/sqflite.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'extenciones/database_helper.dart';
import 'screens/soporte/soporte_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  final String dbName;
  const HomeScreen({super.key, this.dbName = ''});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String userName = "Cargando...";
  String? photoUrl;
  String userArea = "Cargando...";
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<bool> _verificarDatosLocales() async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'usuarios.db');

      if (!await databaseExists(path)) {
        return false;
      }

      final db = await openDatabase(path);
      final result = await db.query('usuarios');
      await db.close();

      return result.isNotEmpty;
    } catch (e) {
      print('Error verificando datos locales: $e');
      return false;
    }
  }

  void _mostrarMensajeSinDatos(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 24),
              const SizedBox(width: 8),
              const Text(
                'SIN DATOS OFFLINE',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          content: const Text(
            'No tienes datos almacenados localmente.\n\n'
                'Para usar el modo offline, primero debes:\n'
                '• Conectarte a internet\n'
                '• Iniciar sesión online al menos una vez\n'
                '• Los datos se guardarán automáticamente',
            style: TextStyle(height: 1.4),
          ),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Colors.orange.withOpacity(0.1),
                foregroundColor: Colors.orange,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Entendido'),
              onPressed: () => Navigator.of(context).pop(),
            )
          ],
        );
      },
    );
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
          userArea = userData['area'] ?? "Área no especificada";
          photoUrl = null;
        });
      } else {
        final hayDatosLocales = await _verificarDatosLocales();
        if (!hayDatosLocales) {
          setState(() {
            userName = "Usuario sin datos";
            userArea = "Requiere conexión";
          });
          return;
        }

        setState(() {
          userName = "Usuario no identificado";
          userArea = "Área no especificada";
        });
      }
    } catch (e) {
      print("Error al obtener datos del usuario: $e");
      setState(() {
        userName = "Error al cargar datos";
        userArea = "Área no disponible";
      });
    }
  }

  Future<void> _cerrarSesion(BuildContext context) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.logout_rounded, color: Colors.red, size: 24),
              const SizedBox(width: 8),
              const Text(
                'CERRAR SESIÓN',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Cerrar Sesión'),
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();

                final ip = prefs.getString('ip');
                final port = prefs.getString('port');
                final database = prefs.getString('database');
                final dbuser = prefs.getString('dbuser');
                final dbpass = prefs.getString('dbpass');

                await prefs.remove('usuario');
                await prefs.remove('contrasena');
                await prefs.setBool('recordar', false);

                if (ip != null) await prefs.setString('ip', ip);
                if (port != null) await prefs.setString('port', port);
                if (database != null) await prefs.setString('database', database);
                if (dbuser != null) await prefs.setString('dbuser', dbuser);
                if (dbpass != null) await prefs.setString('dbpass', dbpass);

                try {
                  final dbPath = await getDatabasesPath();
                  final path = join(dbPath, 'usuarios.db');
                  final db = await openDatabase(path);
                  await db.delete('usuarios');
                  await db.close();
                } catch (e) {
                  print('Error limpiando BD local: $e');
                }

                Navigator.of(context).pushNamedAndRemoveUntil(
                    '/login', (Route<dynamic> route) => false);
              },
            )
          ],
        );
      },
    );
  }

  void _mostrarEnDesarrollo(BuildContext context, {String message = 'Este apartado se encuentra actualmente en desarrollo.'}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.construction_rounded, color: Colors.amber, size: 24),
              const SizedBox(width: 8),
              const Text(
                'EN DESARROLLO',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Colors.amber.withOpacity(0.1),
                foregroundColor: Colors.amber.shade800,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Entendido'),
              onPressed: () => Navigator.of(context).pop(),
            )
          ],
        );
      },
    );
  }

  void _handleNavigationTap(int index, BuildContext context) {
    switch (index) {
      case 0:
        setState(() {
          _currentIndex = index;
        });
        break;

      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => RespaldoScreen()),
        ).then((_) {
          setState(() {
            _currentIndex = 0;
          });
        });
        break;

      case 2:
        _cerrarSesion(context);
        break;
    }
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: isDarkMode ? Colors.black26 : Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
          child: Container(
            decoration: BoxDecoration(
              color: isDarkMode
                  ? Colors.black.withOpacity(0.7)
                  : Colors.white.withOpacity(0.9),
              border: Border.all(
                color: isDarkMode
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.05),
              ),
              borderRadius: BorderRadius.circular(28),
            ),
            child: NavigationBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              height: 65,
              indicatorColor: const Color(0xFFE8CB0C).withOpacity(0.2),
              labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined, size: 26),
                  selectedIcon: Icon(Icons.home_rounded, color: Color(0xFFE8CB0C), size: 26),
                  label: 'Inicio',
                ),
                NavigationDestination(
                  icon: Icon(Icons.backup_outlined, size: 26),
                  selectedIcon: Icon(Icons.backup_rounded, color: Color(0xFFE8CB0C), size: 26),
                  label: 'Respaldo',
                ),
                NavigationDestination(
                  icon: Icon(Icons.logout_outlined, color: Colors.red, size: 26),
                  selectedIcon: Icon(Icons.logout_rounded, color: Colors.red, size: 26),
                  label: 'Cerrar Sesión',
                )
              ],
              selectedIndex: _currentIndex,
              onDestinationSelected: (index) {
                _handleNavigationTap(index, context);
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildServiceCard(BuildContext context,{
    required String imagePath,
    required String title,
    required VoidCallback onTap,
    required IconData icon,
    double width = 280,
    double height = 160,
    Color? accentColor,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: width,
      height: height,
      margin: const EdgeInsets.only(right: 16),
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(20),
        shadowColor: Colors.black.withOpacity(0.3),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: accentColor != null
                    ? [
                  accentColor.withOpacity(0.9),
                  accentColor.withOpacity(0.7),
                ]
                    : isDarkMode
                    ? [
                  const Color(0xFF2A2A2A),
                  const Color(0xFF1A1A1A),
                ]
                    : [
                  const Color(0xFF6C63FF),
                  const Color(0xFF5A52E5),
                ],
              ),
            ),
            child: Stack(
              children: [
                // Patrón de fondo sutil
                Positioned(
                  top: -20,
                  right: -20,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -30,
                  left: -30,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.05),
                    ),
                  ),
                ),
                // Contenido principal
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          icon,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: Colors.white,
                          size: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ).animate().fadeIn(duration: 600.ms).slideX(begin: 0.3),
    );
  }

  Widget _buildQuickActionCard({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Expanded(
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withOpacity(0.1),
                  color.withOpacity(0.05),
                ],
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDarkMode
              ? [
            const Color(0xFF2D2D2D),
            const Color(0xFF1A1A1A),
          ]
              : [
            const Color(0xFFF8F9FF),
            const Color(0xFFE8EAFF),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode ? Colors.black26 : Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFE8CB0C),
                      const Color(0xFFE8CB0C).withOpacity(0.7),
                    ],
                  ),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '¡Hola!',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    Text(
                      userName,
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFE8CB0C).withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.business_rounded,
                  size: 16,
                  color: const Color(0xFFE8CB0C),
                ),
                const SizedBox(width: 6),
                Text(
                  userArea,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFE8CB0C),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 800.ms).slideY(begin: -0.2);
  }

  Widget _buildSectionTitle(String title) {
    return Builder(
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).textTheme.titleLarge?.color,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      backgroundColor: isDarkMode ? const Color(0xFF0F0F0F) : const Color(0xFFF8F9FF),
      appBar: AppBar(
        toolbarHeight: 70,
        title: Text(
          'INICIO',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
            child: Container(
              color: isDarkMode
                  ? Colors.black.withOpacity(0.3)
                  : Colors.white.withOpacity(0.8),
            ),
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          top: kToolbarHeight + MediaQuery.of(context).padding.top + 20,
          bottom: 100,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header de bienvenida
            _buildWelcomeHeader(context),

            // Servicios principales
            _buildSectionTitle('SERVICIOS PRINCIPALES'),
            SizedBox(
              height: 180,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(left: 24),
                children: [
                  _buildServiceCard(
                    context,
                    imagePath: 'images/tarjetas/ca_home.png',
                    title: 'SERVICIO DE\nCALIBRACIÓN',
                    icon: Icons.tune_rounded,
                    accentColor: const Color(0xFF6C63FF),
                    onTap: () async {
                      String dbPath = join(await getDatabasesPath(), 'precarga_database.db');
                      bool dbExists = await databaseExists(dbPath);

                      if (dbExists) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PrecargaScreen(userName: userName),
                          ),
                        );
                      } else {
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              title: Row(
                                children: [
                                  Icon(Icons.warning_rounded, color: Colors.red, size: 24),
                                  const SizedBox(width: 8),
                                  const Text(
                                    '¡PRECARGA REQUERIDA!',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                      color: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                              content: const Text(
                                'Debes realizar la precarga de datos antes de acceder al módulo de Calibración.\n\n'
                                    'Sin la precarga no podrás:\n'
                                    '• Ver información de Clientes\n'
                                    '• Acceder a Plantas y Balanzas\n'
                                    '• Consultar Últimos Servicios',
                                style: TextStyle(height: 1.4),
                              ),
                              actions: <Widget>[
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  style: TextButton.styleFrom(
                                    backgroundColor: Colors.red.withOpacity(0.1),
                                    foregroundColor: Colors.red,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  child: const Text('Entendido'),
                                ),
                              ],
                            );
                          },
                        );
                      }
                    },
                  ),
                  _buildServiceCard(
                    context,
                    imagePath: 'images/tarjetas/st_home.png',
                    title: 'SERVICIO DE\nSOPORTE TÉCNICO',
                    icon: Icons.support_agent_rounded,
                    accentColor: const Color(0xFF00BCD4),
                    onTap: () async {
                      String dbPath = join(await getDatabasesPath(), 'precarga_database.db');
                      bool dbExists = await databaseExists(dbPath);

                      if (dbExists) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SoporteScreen(userName: userName),
                          ),
                        );
                      } else {
                        // Similar dialog logic
                      }
                    },
                  ),
                  _buildServiceCard(
                    context,
                    imagePath: 'images/tarjetas/st_home.png',
                    title: 'SELECCIÓN DE\nSERVICIOS',
                    icon: Icons.apps_rounded,
                    accentColor: const Color(0xFF4CAF50),
                    onTap: () async {
                      String dbPath = join(await getDatabasesPath(), 'precarga_database.db');
                      bool dbExists = await databaseExists(dbPath);

                      if (dbExists) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AreaSeleccionScreen(userName: userName),
                          ),
                        );
                      } else {
                        // Similar dialog logic
                      }
                    },
                  ),
                ],
              ),
            ),

            // Acciones rápidas
            _buildSectionTitle('ACCIONES RÁPIDAS'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  _buildQuickActionCard(
                    title: 'PRECARGA\nDE DATOS',
                    icon: Icons.download_rounded,
                    color: const Color(0xFF9C27B0),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DescargaDeDatosScreen(userName: ''),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  _buildQuickActionCard(
                    title: 'ÚLTIMOS\nSERVICIOS',
                    icon: Icons.history_rounded,
                    color: const Color(0xFFFF9800),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UltServiciosScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  _buildQuickActionCard(
                    title: 'SERVICIO\nEMERGENCIA',
                    icon: Icons.emergency_rounded,
                    color: const Color(0xFFF44336),
                    onTap: () {
                      _mostrarEnDesarrollo(context);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }
}
