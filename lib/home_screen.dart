import 'dart:ui';
import 'package:service_met/screens/calibracion/precarga.dart';
import 'package:service_met/screens/historial/ult_servicios.dart';
import 'package:service_met/screens/precarga/descarga_de_datos.dart';
import 'package:service_met/screens/respaldo/respaldo.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'extenciones/database_helper.dart';
import 'screens/soporte/soporte_screen.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Para cerrar sesión

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
  final int _totalSections = 3;

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

  // Agregar esta función a tu HomeScreen
  Future<bool> _verificarDatosLocales() async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'usuarios.db');

      // Verificar si existe la BD
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

// Función para mostrar mensaje si no hay datos offline
  void _mostrarMensajeSinDatos(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'SIN DATOS OFFLINE',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: Colors.orange,
            ),
          ),
          content: const Text(
              'No tienes datos almacenados localmente.\n\n'
                  'Para usar el modo offline, primero debes:'
                  '\n• Conectarte a internet'
                  '\n• Iniciar sesión online al menos una vez'
                  '\n• Los datos se guardarán automáticamente'
          ),
          actions: <Widget>[
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
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
        // 🔒 VERIFICAR SI ES MODO OFFLINE SIN DATOS
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
          title: const Text(
            'CERRAR SESIÓN',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
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
              ),
              child: const Text('Cerrar Sesión'),
              onPressed: () async {
                // 🔒 LIMPIAR SOLO DATOS DE SESIÓN, NO CONFIGURACIÓN DE BD
                final prefs = await SharedPreferences.getInstance();

                // Guardar configuración de BD antes de limpiar
                final ip = prefs.getString('ip');
                final port = prefs.getString('port');
                final database = prefs.getString('database');
                final dbuser = prefs.getString('dbuser');
                final dbpass = prefs.getString('dbpass');

                // Limpiar solo datos de sesión de usuario
                await prefs.remove('usuario');
                await prefs.remove('contrasena');
                await prefs.setBool('recordar', false);

                // Restaurar configuración de BD
                if (ip != null) await prefs.setString('ip', ip);
                if (port != null) await prefs.setString('port', port);
                if (database != null) await prefs.setString('database', database);
                if (dbuser != null) await prefs.setString('dbuser', dbuser);
                if (dbpass != null) await prefs.setString('dbpass', dbpass);

                // 🔒 LIMPIAR BASE DE DATOS LOCAL DE USUARIOS
                try {
                  final dbPath = await getDatabasesPath();
                  final path = join(dbPath, 'usuarios.db');
                  final db = await openDatabase(path);
                  await db.delete('usuarios');
                  await db.close();
                } catch (e) {
                  print('Error limpiando BD local: $e');
                }

                // Cerrar todas las pantallas y volver al login
                Navigator.of(context).pushNamedAndRemoveUntil(
                    '/login',
                        (Route<dynamic> route) => false
                );
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
          title: const Text(
            'INFORMACIÓN',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: Text(message),
          actions: <Widget>[
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Aceptar'),
              onPressed: () => Navigator.of(context).pop(),
            )
          ],
        );
      },
    );
  }

  void _handleNavigationTap(int index, BuildContext context) {
    switch (index) {
      case 0: // Inicio
        setState(() {
          _currentIndex = index;
        });
        break;

      case 1: // Respaldo
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => RespaldoScreen()),
        ).then((_) {
          // 🔒 RESETEAR ÍNDICE CUANDO REGRESE DE RESPALDO
          setState(() {
            _currentIndex = 0;
          });
        });
        break;

      case 2: // Cerrar Sesión
        _cerrarSesion(context);
        // No cambiar el índice para cerrar sesión
        break;
    }
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        color: isDarkMode
            ? Colors.black.withOpacity(0.5)
            : Colors.white.withOpacity(0.7),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: NavigationBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            height: 60,
            indicatorColor: isDarkMode
                ? Colors.white.withOpacity(0.2)
                : Colors.black.withOpacity(0.1),
            labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: IconTheme(
                  data: IconThemeData(color: Color(0xFFE8CB0C)),
                  child: Icon(Icons.home_rounded),
                ),
                label: 'Inicio',
              ),
              NavigationDestination(
                icon: Icon(Icons.backup_outlined),
                selectedIcon: IconTheme(
                  data: IconThemeData(color: Color(0xFFE8CB0C)),
                  child: Icon(Icons.backup_rounded),
                ),
                label: 'Respaldo',
              ),
              NavigationDestination(
                icon: Icon(Icons.logout_outlined, color: Colors.red),
                selectedIcon: IconTheme(
                  data: IconThemeData(color: Colors.red),
                  child: Icon(Icons.logout_rounded),
                ),
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
    );
  }

  Widget _buildServiceCard({
    required String imagePath,
    required String title,
    required VoidCallback onTap,
    double width = 230,
    double height = 180,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(imagePath),
              fit: BoxFit.cover,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              Center(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServiceSection(String title, List<Widget> cards) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 26.0),
          child: Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 5.0),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.only(left: 20.0, bottom: 20.0, right: 20.0),
          child: Row(children: cards),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: AppBar(
        toolbarHeight: 70,
        title: Text(
          'INICIO',
          style: GoogleFonts.inter(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black,
            fontWeight: FontWeight.w900,
            fontSize: 16.0,
          ),
        ),
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.transparent
            : Colors.white,
        elevation: 0,
        flexibleSpace: Theme.of(context).brightness == Brightness.dark
            ? ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
            child: Container(
              color: Colors.black.withOpacity(0.4),
            ),
          ),
        )
            : null,
        iconTheme: IconThemeData(color: Theme.of(context).iconTheme.color),
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : Colors.black,
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          top: kToolbarHeight + MediaQuery.of(context).padding.top + 30,
          bottom: 80,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          textAlign: TextAlign.left,
                          text: TextSpan(
                            style: GoogleFonts.openSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color:
                              Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                            children: [
                              const TextSpan(text: '¡Hola! '),
                              TextSpan(
                                text: userName,
                                style: GoogleFonts.openSans(
                                  fontWeight: FontWeight.w900,
                                  color: Theme.of(context).colorScheme.primary,
                                  fontSize: 22.0,
                                ),
                              ),
                            ],
                          ),
                        ).animate().fade(duration: 500.ms).slideY(begin: 0.2),
                        const SizedBox(height: 5),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20.0),
              _buildServiceSection(
                'SERVICIOS DISPONIBLES:',
                [
                  _buildServiceCard(
                    imagePath: 'images/tarjetas/ca_home.png',
                    title: 'SERVICIO DE\nCALIBRACIÓN',
                    onTap: () async {
                      String dbPath = join(
                          await getDatabasesPath(), 'precarga_database.db');
                      bool dbExists = await databaseExists(dbPath);

                      if (dbExists) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PrecargaScreen(
                                userName: userName),
                          ),
                        );
                      } else {
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text(
                                '¡PRECARGA REQUERIDA!',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 17,
                                  color: Colors.red,
                                ),
                              ),
                              content: const Text(
                                'Debes realizar la precarga de datos antes de acceder al módulo de Calibración.\n\n'
                                    'Sin la precarga no podrás:'
                                    '\n- Ver información de Clientes'
                                    '\n- Acceder a Plantas y Balanzas'
                                    '\n- Consultar Últimos Servicios',
                              ),
                              actions: <Widget>[
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                  ),
                                  child: const Text('Salir'),
                                ),
                              ],
                            );
                          },
                        );
                      }
                    },
                  ),
                  const SizedBox(width: 15),
                  _buildServiceCard(
                    imagePath: 'images/tarjetas/st_home.png',
                    title: 'SERVICIO DE\nSOPORTE TÉCNICO',
                    onTap: () async {
                      String dbPath = join(
                          await getDatabasesPath(), 'precarga_database.db');
                      bool dbExists = await databaseExists(dbPath);

                      if (dbExists) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => SoporteScreen(
                                userName: userName,
                              )),
                        );
                      } else {
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text(
                                '¡PRECARGA REQUERIDA!',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 17,
                                  color: Colors.red,
                                ),
                              ),
                              content: const Text(
                                'Debes realizar la precarga de datos antes de acceder al módulo de Soporte Técnico.\n\n'
                                    'Sin la precarga no podrás:'
                                    '\n- Ver información de Clientes'
                                    '\n- Acceder a Plantas y Equipos'
                                    '\n- Consultar Historial de Soporte',
                              ),
                              actions: <Widget>[
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                  ),
                                  child: const Text('Salir'),
                                ),
                              ],
                            );
                          },
                        );
                      }
                    },
                  ),
                  const SizedBox(width: 15),
                  _buildServiceCard(
                    imagePath: 'images/tarjetas/st_home.png',
                    title: 'SERVICIOS\nDISPONIBLES',
                    onTap: () async {
                      String dbPath = join(
                          await getDatabasesPath(), 'precarga_database.db');
                      bool dbExists = await databaseExists(dbPath);

                      if (dbExists) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => SoporteScreen(
                                userName: userName,
                              )),
                        );
                      } else {
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text(
                                '¡PRECARGA REQUERIDA!',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 17,
                                  color: Colors.red,
                                ),
                              ),
                              content: const Text(
                                'Debes realizar la precarga de datos antes de acceder al módulo de Soporte Técnico.\n\n'
                                    'Sin la precarga no podrás:'
                                    '\n- Ver información de Clientes'
                                    '\n- Acceder a Plantas y Equipos'
                                    '\n- Consultar Historial de Soporte',
                              ),
                              actions: <Widget>[
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                  ),
                                  child: const Text('Salir'),
                                ),
                              ],
                            );
                          },
                        );
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildServiceSection(
                'OTROS APARTADOS:',
                [
                  _buildServiceCard(
                    imagePath: 'images/tarjetas/pre_car.png',
                    title: 'PRECARGA DE DATOS',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => DescargaDeDatosScreen(
                              userName: '',
                            )),
                      );
                    },
                  ),
                  const SizedBox(width: 15),
                  _buildServiceCard(
                    imagePath: 'images/tarjetas/ver_ser.png',
                    title: 'ULTIMOS SERVICIOS',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => UltServiciosScreen()),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10.0),
              _buildServiceSection(
                'CASOS DE EMERGENCIA:',
                [
                  _buildServiceCard(
                    imagePath: 'images/tarjetas/b_new.png',
                    title: 'SERVICIO SIN\n PRECARGA',
                    onTap: () {
                      _mostrarEnDesarrollo(context);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }
}