import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'extenciones/database_helper.dart';
import 'detalles_seca_screen.dart';

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

class HomeScreen extends StatefulWidget {
  final String dbName;
  const HomeScreen({super.key, this.dbName = ''});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String userName = "Cargando...";
  String? photoUrl;
  int totalServiciosCal = 0;
  int totalServiciosSop = 0;
  String fechaUltimaPrecarga = "Sin datos";

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _loadDashboardData();
  }

  // Cargar datos del dashboard
  Future<void> _loadDashboardData() async {
    await _getTotalServiciosCal();
    await _getFechaUltimaPrecarga();
    await _getTotalServiciosSop();
  }

  Future<void> _getTotalServiciosSop() async {
    try {
      String dbPath = join(await getDatabasesPath(), 'servcios_soporte_tecnico.db');

      if (await databaseExists(dbPath)) {
        final db = await openDatabase(dbPath);

        // Consulta para contar los registros en la tabla inf_cliente_balanza
        final result = await db.rawQuery('SELECT COUNT(*) as total FROM inf_cliente_balanza');

        await db.close();

        // Extraer el resultado del conteo
        int count = result.isNotEmpty ? result.first['total'] as int : 0;

        setState(() {
          totalServiciosSop = count;
        });
      } else {
        print('La base de datos servcios_soporte_tecnico.db no existe');
        setState(() {
          totalServiciosSop = 0;
        });
      }
    } catch (e) {
      print('Error obteniendo total de servicios de soporte: $e');
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

        // Consulta para contar los registros en la tabla registros_calibracion
        final result = await db.rawQuery('SELECT COUNT(*) as total FROM registros_calibracion');

        await db.close();

        // Extraer el resultado del conteo
        int count = result.isNotEmpty ? result.first['total'] as int : 0;

        setState(() {
          totalServiciosCal = count;
        });
      } else {
        print('La base de datos calibracion.db no existe');
        setState(() {
          totalServiciosCal = 0;
        });
      }
    } catch (e) {
      print('Error obteniendo total de servicios: $e');
      setState(() {
        totalServiciosCal = 0;
      });
    }
  }

  Future<void> _getFechaUltimaPrecarga() async {
    try {
      String dbPath = join(await getDatabasesPath(), 'precarga_database.db');

      if (await databaseExists(dbPath)) {
        // Obtener información del archivo de la base de datos
        final file = File(dbPath);
        final lastModified = await file.lastModified();

        // Formatear la fecha
        final formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(lastModified);

        setState(() {
          fechaUltimaPrecarga = formattedDate;
        });
      } else {
        setState(() {
          fechaUltimaPrecarga = "Base de datos no existe";
        });
      }
    } catch (e) {
      print('Error obteniendo fecha de precarga: $e');
      setState(() {
        fechaUltimaPrecarga = "Error al obtener fecha";
      });
    }
  }

  Future<List<ServicioSeca>> _getServiciosAgrupadosPorSeca() async {
    final List<ServicioSeca> servicios = [];

    try {
      String dbPath = join(await getDatabasesPath(), 'calibracion.db');

      if (await databaseExists(dbPath)) {
        final db = await openDatabase(dbPath);

        // Obtener todos los registros de calibración
        final List<Map<String, dynamic>> registros = await db.query('registros_calibracion');

        // Agrupar por SECA
        final Map<String, List<Map<String, dynamic>>> agrupados = {};

        for (var registro in registros) {
          final String seca = registro['seca']?.toString() ?? 'Sin SECA';

          if (!agrupados.containsKey(seca)) {
            agrupados[seca] = [];
          }

          agrupados[seca]!.add(registro);
        }

        // Convertir a lista de ServicioSeca
        agrupados.forEach((seca, balanzas) {
          servicios.add(ServicioSeca(
            seca: seca,
            cantidadBalanzas: balanzas.length,
            balanzas: balanzas,
          ));
        });

        await db.close();
      }

      // Ordenar por SECA
      servicios.sort((a, b) => a.seca.compareTo(b.seca));

      return servicios;
    } catch (e) {
      print('Error obteniendo servicios agrupados: $e');
      return [];
    }
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
          title: const Text(
            'SIN DATOS OFFLINE',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: Colors.orange,
            ),
          ),
          content: const Text('No tienes datos almacenados localmente.\n\n'
              'Para usar el modo offline, primero debes:'
              '\n• Conectarte a internet'
              '\n• Iniciar sesión online al menos una vez'
              '\n• Los datos se guardarán automáticamente'),
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
          photoUrl = null;
        });
      } else {
        final hayDatosLocales = await _verificarDatosLocales();
        if (!hayDatosLocales) {
          setState(() {
            userName = "Usuario sin datos";
          });
          return;
        }

        setState(() {
          userName = "Usuario no identificado";
        });
      }
    } catch (e) {
      print("Error al obtener datos del usuario: $e");
      setState(() {
        userName = "Error al cargar datos";
      });
    }
  }

  Future<void> _exportarSecaDirectamente(BuildContext context, ServicioSeca servicio) async {
    try {
      final List<List<dynamic>> csvData = [];

      // Encabezados
      if (servicio.balanzas.isNotEmpty) {
        csvData.add(servicio.balanzas.first.keys.toList());
      }

      // Datos
      for (var balanza in servicio.balanzas) {
        csvData.add(balanza.values.toList());
      }

      // Convertir a CSV
      String csv = const ListToCsvConverter().convert(csvData);

      // Obtener directorio de descargas
      final directory = await getDownloadsDirectory();
      final path = directory?.path;

      if (path == null) {
        throw Exception('No se pudo acceder al directorio de descargas');
      }

      // Crear nombre de archivo
      final fileName = 'SECA_${servicio.seca}_${DateTime.now().millisecondsSinceEpoch}.csv';
      final filePath = '$path/$fileName';

      // Guardar archivo
      final File file = File(filePath);
      await file.writeAsString(csv);

      // Abrir el archivo
      OpenFilex.open(filePath);

      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Archivo exportado: $fileName'))
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al exportar: $e'))
      );
    }
  }

  void _mostrarEnDesarrollo(BuildContext context,
      {String message = 'Este apartado se encuentra actualmente en desarrollo.'}) {
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

  Widget _buildSummaryCard(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String value,
        required Color color,
      }) {
    return Expanded(
      child: Card(
        color: color, // 🔹 Fondo de la tarjeta
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(
                icon,
                size: 25,
                color: Colors.black, // 🔹 Contraste sobre el fondo
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black, // 🔹 Texto en blanco para contraste
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black, // 🔹 También en blanco
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ).animate().scale(delay: 200.ms),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          top: 20,
          bottom: 20,
          left: 24,
          right: 24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            // Saludo personalizado
            RichText(
              textAlign: TextAlign.left,
              text: TextSpan(
                style: GoogleFonts.openSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
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
            const SizedBox(height: 30),

            // Resumen visual
            Text(
              'RESUMEN',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 15),

            Row(
              children: [
                _buildSummaryCard(
                  context,
                  icon: FontAwesomeIcons.wrench,
                  title: 'Total\nBalanzas Arregladas',
                  value: totalServiciosSop.toString(),
                  color: Color(0xFFF9E300),
                ),
                const SizedBox(width: 10),
                _buildSummaryCard(
                  context,
                  icon: FontAwesomeIcons.scaleBalanced,
                  title: 'Total\nBalanzas Calibradas',
                  value: totalServiciosCal.toString(),
                  color: const Color(0xFFFFF15C),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildSummaryCard(
                  context,
                  icon: FontAwesomeIcons.cloudDownloadAlt,
                  title: 'Última\nPrecarga Realizada',
                  value: fechaUltimaPrecarga.split(' ')[0],
                  color: Color(0xFFFFEE2E),
                ),
              ],
            ),
            const SizedBox(height: 40),

            // NUEVA SECCIÓN: Lista de Servicios
            Text(
              'LISTA DE SERVICIOS',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 15),

            FutureBuilder<List<ServicioSeca>>(
              future: _getServiciosAgrupadosPorSeca(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                  return Text(
                    'No hay servicios de calibración registrados',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                  );
                }

                final servicios = snapshot.data!;

                return Column(
                  children: servicios.map((servicio) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'SECA: ${servicio.seca}',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${servicio.cantidadBalanzas} balanza(s)',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => DetallesSecaScreen(servicioSeca: servicio),
                                      ),
                                    );
                                  },
                                  child: Text('Abrir'),
                                ),
                                const SizedBox(width: 8),
                                OutlinedButton(
                                  onPressed: () => _exportarSecaDirectamente(context, servicio),
                                  child: Text('Exportar'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}