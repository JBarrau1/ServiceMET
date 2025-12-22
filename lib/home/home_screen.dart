import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:google_fonts/google_fonts.dart';

import 'configuracion_screen.dart';
import 'otros_apartados_screen.dart';
import 'servicios_screen.dart';
import 'tabs/home_dashboard_tab.dart';
import 'widgets/home_bottom_bar.dart';

class HomeScreen extends StatefulWidget {
  final String dbName;
  const HomeScreen({super.key, this.dbName = ''});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _modoDemo = false;
  String userName = "Cargando...";

  // Variables para la navegación
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _initializeDateFormatting();
    _checkModoDemo();
    _fetchUserData();
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

  // Lista de pantallas para cada tab
  List<Widget> _screens(BuildContext context) => [
        HomeDashboardTab(
            userName: userName,
            goToServicios: () {
              setState(() {
                _currentIndex = 1;
              });
              _pageController.animateToPage(1,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut);
            }),
        ServiciosScreen(userName: userName),
        OtrosApartadosScreen(userName: userName),
      ];

  Future<void> _fetchUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usuarioLogueado = prefs.getString('logged_user');

      if (usuarioLogueado == null || usuarioLogueado.isEmpty) {
        setState(() {
          userName = "Usuario";
        });
        return;
      }

      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'usuarios.db');

      if (!await databaseExists(path)) {
        setState(() {
          userName = "Usuario";
        });
        return;
      }

      final db = await openDatabase(path);

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

      final userData = results.first;
      final tituloAbr = userData['titulo_abr']?.toString() ?? '';
      final nombre1 = userData['nombre1']?.toString() ?? '';
      final apellido1 = userData['apellido1']?.toString() ?? '';
      final apellido2 = userData['apellido2']?.toString() ?? '';

      String inicialApellido2 = '';
      if (apellido2.isNotEmpty) {
        inicialApellido2 = '${apellido2[0]}.';
      }

      final fullName =
          '$tituloAbr $nombre1 $apellido1 $inicialApellido2'.trim();

      setState(() {
        userName = fullName.isNotEmpty ? fullName : "Usuario";
      });

      debugPrint('✅ Usuario cargado: $userName (ID: $usuarioLogueado)');
    } catch (e) {
      debugPrint('❌ Error obteniendo datos del usuario: $e');
      setState(() {
        userName = "Usuario";
      });
    }
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
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
                              const Icon(
                                Icons.logout,
                                color: Color(0xFFFF9800),
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
                        SharedPreferences prefs =
                            await SharedPreferences.getInstance();
                        await prefs.setBool('modoDemo', false);
                        if (context.mounted) {
                          Navigator.pushReplacementNamed(context, '/login');
                        }
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
      bottomNavigationBar: HomeBottomBar(
        currentIndex: _currentIndex,
        modoDemo: _modoDemo,
        onTap: (index) {
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
