import 'dart:ui';
import 'package:service_met/screens/soporte/modulos/ajuste_verificaciones/stac_ajuste_verificaciones.dart';
import 'package:service_met/screens/soporte/modulos/diagnostico/stac_diagnostico.dart';
import 'package:service_met/screens/soporte/modulos/instalacion/stac_instalacion.dart';
import 'package:service_met/screens/soporte/modulos/mnt_correctivo/stac_mnt_correctivo.dart';
import 'package:service_met/screens/soporte/modulos/mnt_prv_avanzado/stac_mnt_prv_avanzado.dart';
import 'package:service_met/screens/soporte/modulos/mnt_prv_avanzado/stil_mnt_prv_avanzado.dart';
import 'package:service_met/screens/soporte/modulos/mnt_prv_regular/stac_mnt_prv_regular.dart';
import 'package:service_met/screens/soporte/modulos/mnt_prv_regular/mnt_prv_regular_stil/stil_mnt_prv_regular.dart';
import 'package:service_met/screens/soporte/modulos/relevamiento_de_datos/relevamiento_de_datos.dart';
import 'package:service_met/screens/soporte/modulos/verificaciones_internas/stac_verificaciones_internas.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class HomeStacScreen extends StatefulWidget {
  final String dbName;
  final String dbPath;
  final String otValue;
  final String selectedCliente;
  final String selectedPlantaNombre;
  final String codMetrica;

  const HomeStacScreen({
    super.key,
    required this.dbName,
    required this.dbPath,
    required this.otValue,
    required this.selectedCliente,
    required this.selectedPlantaNombre,
    required this.codMetrica,
  });

  @override
  State<HomeStacScreen> createState() => _HomeStacScreenState();
}

class _HomeStacScreenState extends State<HomeStacScreen> {
  DateTime? _lastPressedTime;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  List<String>? qrDataList;
  bool isDialogShown = false;
  String? _clienteNombre;
  String? _codMetrica;

  @override
  void initState() {
    super.initState();
    _loadClienteData();
  }

  Future<void> _loadClienteData() async {
    final path = join(widget.dbPath, '${widget.dbName}.db');
    final db = await openDatabase(path);

    try {
      final List<Map<String, dynamic>> result = await db.query(
        'inf_cliente_balanza',
        columns: ['cliente', 'cod_metrica'],
        where: 'id = ?',
        whereArgs: [1],
        limit: 1,
      );

      if (result.isNotEmpty) {
        setState(() {
          _clienteNombre = result.first['cliente'] as String?;
          _codMetrica = result.first['cod_metrica'] as String?;
        });
      }
    } catch (e) {
      debugPrint('Error al cargar datos del cliente: $e');
    } finally {
      await db.close();
    }
  }

  Future<bool> _onWillPop(BuildContext context) async {
    final now = DateTime.now();
    if (_lastPressedTime == null ||
        now.difference(_lastPressedTime!) > const Duration(seconds: 2)) {
      _lastPressedTime = now;
      _showSnackBar(context,
          'Presione nuevamente para retroceder. Los datos registrados se perderán.');
      return false;
    }
    return true;
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: message.contains('Error') ? Colors.red : Colors.green,
      ),
    );
  }

  void _showServiceTypeDialogAva(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'SELECCIONE LA CATEGORIA DE LA BALANZA',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: const Text(
              'Verifique la categoria de la balanza si es STAC o STIL antes de continuar, los datos por categoria son distintos.'),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Cierra el diálogo
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StacMntPrvAvanzadoStacScreen(
                      dbName: widget.dbName,
                      dbPath: widget.dbPath,
                      otValue: widget.otValue,
                      selectedCliente: widget.selectedCliente,
                      selectedPlantaNombre: widget.selectedPlantaNombre,
                      codMetrica: widget.codMetrica,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 12.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: const Text(
                'STAC',
                style: TextStyle(color: Colors.white),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Cierra el diálogo
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StilMntPrvAvanzadoStacScreen(
                      dbName: widget.dbName,
                      dbPath: widget.dbPath,
                      otValue: widget.otValue,
                      selectedCliente: widget.selectedCliente,
                      selectedPlantaNombre: widget.selectedPlantaNombre,
                      codMetrica: widget.codMetrica,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 12.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: const Text(
                'STIL',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showServiceTypeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'SELECCIONE LA CATEGORIA DE LA BALANZA',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: const Text(
              'Verifique la categoria de la balanza si es STAC o STIL antes de continuar, los datos por categoria son distintos.'),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Cierra el diálogo
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StacMntPrvRegularStacScreen(
                      dbName: widget.dbName,
                      dbPath: widget.dbPath,
                      otValue: widget.otValue,
                      selectedCliente: widget.selectedCliente,
                      selectedPlantaNombre: widget.selectedPlantaNombre,
                      codMetrica: widget.codMetrica,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 12.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: const Text(
                'STAC',
                style: TextStyle(color: Colors.white),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Cierra el diálogo
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StilMntPrvRegularStacScreen(
                      dbName: widget.dbName,
                      dbPath: widget.dbPath,
                      otValue: widget.otValue,
                      selectedCliente: widget.selectedCliente,
                      selectedPlantaNombre: widget.selectedPlantaNombre,
                      codMetrica: widget.codMetrica,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 12.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: const Text(
                'STIL',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return WillPopScope(
      onWillPop: () => _onWillPop(context),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          toolbarHeight: 80,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'SOPORTE TÉCNICO',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 5.0),
              Text(
                'CLIENTE: ${_clienteNombre ?? 'No especificado'}\nCÓDIGO: ${_codMetrica ?? 'No especificado'}',
                style: TextStyle(
                  fontSize: 10,
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          backgroundColor: isDarkMode ? Colors.transparent : Colors.white,
          elevation: 0,
          flexibleSpace: isDarkMode
              ? ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                    child: Container(color: Colors.black.withOpacity(0.4)),
                  ),
                )
              : null,
          iconTheme: IconThemeData(color: Theme.of(context).iconTheme.color),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.only(
            top: kToolbarHeight + MediaQuery.of(context).padding.top + 40, // Altura del AppBar + Altura de la barra de estado + un poco de espacio extra
            left: 16.0, // Tu padding horizontal original
            right: 16.0, // Tu padding horizontal original
            bottom: 16.0, // Tu padding inferior original
          ),
          child: Column(
            children: [
              const SizedBox(height: 15.0),
              const Text(
                'TIPO DE SERVICIO',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10.0),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Seleccione el tipo de servicio a realizar:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                    textAlign: TextAlign.left,
                  ),
                ),
              ),
              const SizedBox(height: 8.0),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.info,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white70
                          : Colors.black54,
                      size: 16.0,
                    ),
                    const SizedBox(width: 8.0),
                    Expanded(
                      child: Text(
                        'Solo podra seleccionar un tipo de servicio por balanzar, a menos que el procedimiento indique que puede realizar 2 o mas servicios en la misma balanza.',
                        style: TextStyle(
                          fontSize: 12.0,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white70
                              : Colors.black54,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RelevamientoDeDatosScreen(
                            dbName: widget.dbName,
                            dbPath: widget.dbPath,
                            otValue: widget.otValue,
                            selectedCliente: widget.selectedCliente,
                            selectedPlantaNombre: widget.selectedPlantaNombre,
                            codMetrica: widget.codMetrica,
                          ),
                        ),
                      );
                    },
                    child: _buildCard(
                      Icons.assignment,
                      'RELEVAMIENTO DE DATOS',
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => StacAjusteVerificacionesScreen(
                            dbName: widget.dbName,
                            dbPath: widget.dbPath,
                            otValue: widget.otValue,
                            selectedCliente: widget.selectedCliente,
                            selectedPlantaNombre: widget.selectedPlantaNombre,
                            codMetrica: widget.codMetrica,
                          ),
                        ),
                      );
                    },
                    child: _buildCard(
                      Icons.settings,
                      'AJUSTES METROLÓGICOS y/o VERIFICACIONES IBMETRO',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => StacDiagnosticoScreen(
                            dbName: widget.dbName,
                            dbPath: widget.dbPath,
                            otValue: widget.otValue,
                            selectedCliente: widget.selectedCliente,
                            selectedPlantaNombre: widget.selectedPlantaNombre,
                            codMetrica: widget.codMetrica,
                          ),
                        ),
                      );
                    },
                    child: _buildCard(
                      Icons.medical_services,
                      'DIAGNÓSTICO',
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      _showServiceTypeDialog(context);
                    },
                    child: _buildCard(
                      Icons.construction,
                      'MNT PRV REGULAR',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () {
                      _showServiceTypeDialogAva(context);
                    },
                    child: _buildCard(
                      Icons.engineering,
                      'MNT PRV AVANZADO',
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => StacMntCorrectivoScreen(
                            dbName: widget.dbName,
                            dbPath: widget.dbPath,
                            otValue: widget.otValue,
                            selectedCliente: widget.selectedCliente,
                            selectedPlantaNombre: widget.selectedPlantaNombre,
                            codMetrica: widget.codMetrica,
                          ),
                        ),
                      );
                    },
                    child: _buildCard(
                      Icons.build_circle,
                      'MNT CORRECTIVO',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => StacInstalacionScreen(
                            dbName: widget.dbName,
                            dbPath: widget.dbPath,
                            otValue: widget.otValue,
                            selectedCliente: widget.selectedCliente,
                            selectedPlantaNombre: widget.selectedPlantaNombre,
                            codMetrica: widget.codMetrica,
                          ),
                        ),
                      );
                    },
                    child: _buildCard(
                      Icons.install_desktop,
                      'INSTALACIÓN',
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              StacVerificacionesInternasScreen(
                            dbName: widget.dbName,
                            dbPath: widget.dbPath,
                            otValue: widget.otValue,
                            selectedCliente: widget.selectedCliente,
                            selectedPlantaNombre: widget.selectedPlantaNombre,
                            codMetrica: widget.codMetrica,
                          ),
                        ),
                      );
                    },
                    child: _buildCard(
                      Icons.verified,
                      'VERIFICACIONES INTERNAS',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(IconData icon, String title,
      [String? subtitle, double textSize = 14]) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        color: Colors.grey[850],
        child: Container(
          width: 150,
          height: 150,
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 35,
                color: Color(0xFFFEFFF0),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: textSize - 2,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
