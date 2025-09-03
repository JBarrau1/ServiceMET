import 'dart:ui';
import 'package:service_met/screens/offline/eb_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:sqflite/sqflite.dart';

class BalScreen extends StatefulWidget {
  final String dbName;
  final String userName;
  final String dbPath;

  const BalScreen({
    super.key,
    required this.dbName,
    required this.userName,
    required this.dbPath,
  });

  @override
  _BalScreenState createState() => _BalScreenState();
}

class _BalScreenState extends State<BalScreen> {
  final TextEditingController _stickerController = TextEditingController();
  final TextEditingController _codMetricaController = TextEditingController();
  final TextEditingController _codInternoController = TextEditingController();
  final TextEditingController _tipoEquipoController = TextEditingController();
  final TextEditingController _marcaController = TextEditingController();
  final TextEditingController _modeloController = TextEditingController();
  final TextEditingController _serieController = TextEditingController();
  final TextEditingController _unidadController = TextEditingController();
  final TextEditingController _ubicacionController = TextEditingController();
  final TextEditingController _pmax1Controller = TextEditingController();
  final TextEditingController _d1Controller = TextEditingController();
  final TextEditingController _e1Controller = TextEditingController();
  final TextEditingController _dec1Controller = TextEditingController();
  final TextEditingController _pmax2Controller = TextEditingController();
  final TextEditingController _d2Controller = TextEditingController();
  final TextEditingController _e2Controller = TextEditingController();
  final TextEditingController _dec2Controller = TextEditingController();
  final TextEditingController _pmax3Controller = TextEditingController();
  final TextEditingController _d3Controller = TextEditingController();
  final TextEditingController _e3Controller = TextEditingController();
  final TextEditingController _dec3Controller = TextEditingController();

  Map<String, dynamic>? selectedBalanza;
  List<Map<String, dynamic>> selectedEquipos = [];
  final PageController _pageController = PageController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _stickerController.dispose();
    _codMetricaController.dispose();
    _codInternoController.dispose();
    _tipoEquipoController.dispose();
    _marcaController.dispose();
    _modeloController.dispose();
    _serieController.dispose();
    _unidadController.dispose();
    _ubicacionController.dispose();
    _pmax1Controller.dispose();
    _d1Controller.dispose();
    _e1Controller.dispose();
    _dec1Controller.dispose();
    _pmax2Controller.dispose();
    _d2Controller.dispose();
    _e2Controller.dispose();
    _dec2Controller.dispose();
    _pmax3Controller.dispose();
    _d3Controller.dispose();
    _e3Controller.dispose();
    _dec3Controller.dispose();
    super.dispose();
  }

  Future<void> _saveDataToDatabase(BuildContext context) async {
    // Validar que el campo de sticker no esté vacío
    if (_stickerController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingrese el N° de Sticker.')),
      );
      return;
    }

    final db = await openDatabase(widget.dbPath);

    final registro = {
      'sticker': _stickerController.text,
      'cod_int': _codInternoController.text,
      'tipo_equipo': _tipoEquipoController.text,
      'marca': _marcaController.text,
      'modelo': _modeloController.text,
      'serie': _serieController.text,
      'unidades': _unidadController.text,
      'ubicacion': _ubicacionController.text,
      'pmax1': _pmax1Controller.text,
      'd1': _d1Controller.text,
      'e1': _e1Controller.text,
      'dec1': _dec1Controller.text,
      'pmax2': _pmax2Controller.text,
      'd2': _d2Controller.text,
      'e2': _e2Controller.text,
      'dec2': _dec2Controller.text,
      'pmax3': _pmax3Controller.text,
      'd3': _d3Controller.text,
      'e3': _e3Controller.text,
      'dec3': _dec3Controller.text,
    };

    // Verificar si el registro con id = 1 existe
    final existingRecord = await db.query(
      'registros_calibracion_bn',
      where: 'id = ?',
      whereArgs: [1],
    );

    if (existingRecord.isEmpty) {
      // Insertar un nuevo registro si no existe
      await db.insert(
        'registros_calibracion_bn',
        registro,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } else {
      // Actualizar el registro si ya existe
      await db.update(
        'registros_calibracion_bn',
        registro,
        where: 'id = ?',
        whereArgs: [1],
      );
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Datos guardados exitosamente.')),
    );
  }

  Widget buildEquipoCard(BuildContext context, Map<String, dynamic> equipo) {
    // Lógica para construir la tarjeta de equipo
    return Card(
      child: ListTile(
        title: Text(equipo['nombre'] ?? 'Sin nombre'),
        subtitle: Text(equipo['descripcion'] ?? 'Sin descripción'),
      ),
    );
  }

  void _navigateToEbScreen(BuildContext context) async {
    // Validar que todos los campos estén llenos
    if (_stickerController.text.isEmpty ||
        _codInternoController.text.isEmpty ||
        _marcaController.text.isEmpty ||
        _modeloController.text.isEmpty ||
        _serieController.text.isEmpty ||
        _unidadController.text.isEmpty ||
        _ubicacionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor registre todos los datos.')),
      );
      return;
    }

    // Mostrar diálogo de confirmación
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'CONFIRMACIÓN',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: const Text('¿Está seguro de los datos registrados?'),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
              ),
              onPressed: () {
                Navigator.of(context).pop(false); // No confirmado
              },
              child: const Text('No'),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.green,
              ),
              onPressed: () {
                Navigator.of(context).pop(true); // Confirmado
              },
              child: const Text('Sí'),
            ),
          ],
        );
      },
    );

    // Si el usuario confirma, guardar datos y navegar a BalScreen
    if (confirm == true) {
      // Guardar los datos en la base de datos
      await _saveDataToDatabase(context);

      // Navegar a BalScreen y pasar los parámetros necesarios
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EbScreen(
            dbName: widget.dbName,
            userName: widget.userName,
            dbPath: widget.dbPath,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 70,
        title: Text(
          'CALIBRACION BALANZA NUEVA',
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        backgroundColor: isDarkMode ? Colors.transparent : Colors.white,
        elevation: 0,
        flexibleSpace: isDarkMode
            ? ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                  child: Container(
                    color: Colors.black.withOpacity(0.5),
                  ),
                ),
              )
            : null,
        iconTheme: IconThemeData(color: Theme.of(context).iconTheme.color),
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: isDarkMode ? Colors.white : Colors.black,
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'REGITRO DE DATOS DE LA BALANZA',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8.0),
            TextFormField(
              controller: _stickerController,
              decoration: const InputDecoration(
                labelText: 'Sticker',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 5.0),
            SizedBox(
              height: MediaQuery.of(context).size.height *
                  0.6, // Altura fija para el PageView
              child: PageView(
                controller: _pageController,
                children: [
                  // Primera página: Información de la balanza
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Column(
                          children: [
                            const Text(
                              'INFORMACION DE LA BALANZA',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8.0),
                            Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  TextFormField(
                                    controller: _codInternoController,
                                    decoration: const InputDecoration(
                                      labelText: 'Codigo Interno de la Balanza',
                                      border: OutlineInputBorder(),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Por favor ingrese el Codigo Interno de la Balanza';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 8.0),
                                  TextFormField(
                                    controller: _serieController,
                                    decoration: const InputDecoration(
                                      labelText: 'Serie',
                                      border: OutlineInputBorder(),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Por favor ingrese la Serie';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 8.0),
                                  TextFormField(
                                    controller: _marcaController,
                                    decoration: const InputDecoration(
                                      labelText: 'Marca',
                                      border: OutlineInputBorder(),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Por favor ingrese la Marca';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 8.0),
                                  TextFormField(
                                    controller: _modeloController,
                                    decoration: const InputDecoration(
                                      labelText: 'Modelo',
                                      border: OutlineInputBorder(),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Por favor ingrese el Modelo';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 8.0),
                                  TextFormField(
                                    controller: _unidadController,
                                    decoration: const InputDecoration(
                                      labelText: 'Unidades de Pesaje',
                                      border: OutlineInputBorder(),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Por favor ingrese las Unidades de Pesaje';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 8.0),
                                  TextFormField(
                                    controller: _ubicacionController,
                                    decoration: const InputDecoration(
                                      labelText: 'Ubicación de la Balanza',
                                      border: OutlineInputBorder(),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Por favor ingrese la Ubicación de la Balanza';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20.0),
                            TextFormField(
                              controller: _pmax1Controller,
                              decoration: const InputDecoration(
                                labelText: 'Pmax1',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 8.0),
                            TextFormField(
                              controller: _d1Controller,
                              decoration: const InputDecoration(
                                labelText: 'd1',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 8.0),
                            TextFormField(
                              controller: _e1Controller,
                              decoration: const InputDecoration(
                                labelText: 'e1',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 8.0),
                            TextFormField(
                              controller: _dec1Controller,
                              decoration: const InputDecoration(
                                labelText: 'dec1',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 20.0),
                            TextFormField(
                              controller: _pmax2Controller,
                              decoration: const InputDecoration(
                                labelText: 'Pmax2',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 8.0),
                            TextFormField(
                              controller: _d2Controller,
                              decoration: const InputDecoration(
                                labelText: 'd2',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 8.0),
                            TextFormField(
                              controller: _e2Controller,
                              decoration: const InputDecoration(
                                labelText: 'e2',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 8.0),
                            TextFormField(
                              controller: _dec2Controller,
                              decoration: const InputDecoration(
                                labelText: 'dec2',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 20.0),
                            TextFormField(
                              controller: _pmax3Controller,
                              decoration: const InputDecoration(
                                labelText: 'Pmax3',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 8.0),
                            TextFormField(
                              controller: _d3Controller,
                              decoration: const InputDecoration(
                                labelText: 'd3',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 8.0),
                            TextFormField(
                              controller: _e3Controller,
                              decoration: const InputDecoration(
                                labelText: 'e3',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 8.0),
                            TextFormField(
                              controller: _dec3Controller,
                              decoration: const InputDecoration(
                                labelText: 'dec3',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10.0),
                      ],
                    ),
                  ),
                  const SingleChildScrollView(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Row(),
                        SizedBox(height: 20.0),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20.0),
            // Indicador de puntos
            SmoothPageIndicator(
              controller: _pageController,
              count: 2, // Número de páginas
              effect: const WormEffect(
                activeDotColor: Colors.deepOrange,
                dotColor: Colors.grey,
                dotHeight: 10,
                dotWidth: 10,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: SpeedDial(
        icon: Icons.menu,
        activeIcon: Icons.close,
        iconTheme: const IconThemeData(color: Colors.black54),
        backgroundColor: const Color(0xFFF9E300),
        foregroundColor: Colors.white,
        children: [
          SpeedDialChild(
            child: const Icon(Icons.arrow_forward),
            backgroundColor: Colors.green,
            label: 'Guardar Datos y Siguiente',
            onTap: () {
              _saveDataToDatabase(context);
              _navigateToEbScreen(context);
            },
          ),
        ],
      ),
    );
  }
}
