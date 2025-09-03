import 'dart:io';
import 'dart:ui';
import 'package:service_met/screens/offline/pe_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';

class PcScreen extends StatefulWidget {
  final String dbName;
  final String userName;
  final String dbPath;

  const PcScreen({
    super.key,
    required this.dbName,
    required this.userName,
    required this.dbPath,
  });

  @override
  _PcScreenState createState() => _PcScreenState();
}

class _PcScreenState extends State<PcScreen> {
  final List<TextEditingController> _precargasControllers = [];
  final List<TextEditingController> _indicacionesControllers = [];
  int _rowCount = 5;
  String? _horaInicio;

  final _formKey = GlobalKey<FormState>();
  final Map<String, Map<String, dynamic>> _fieldData = {};
  final Map<String, List<File>> _fieldPhotos = {};
  bool _isAjusteRealizado = false;
  bool _isAjusteExterno = false;
  final TextEditingController _tipoAjusteController = TextEditingController();
  final TextEditingController _cargasPesasController = TextEditingController();
  final TextEditingController _horaController = TextEditingController();
  final TextEditingController _tiController = TextEditingController();
  final TextEditingController _hriController = TextEditingController();
  final TextEditingController _patmiController = TextEditingController();

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _horaInicio =
        DateFormat('HH:mm:ss').format(DateTime.now()); // Obtener la hora actual
    _horaController.text = _horaInicio!; // Asignar la hora al controlador

    for (int i = 0; i < 5; i++) {
      _precargasControllers.add(TextEditingController());
      _indicacionesControllers.add(TextEditingController());
    }
  }

  //guardado en la base de datos interna
  Future<void> _saveDataToDatabase(BuildContext context) async {
    final db = await openDatabase(widget.dbPath);

    // Crear el mapa de registro
    final registro = <String, dynamic>{};

    // Agregar las precargas e indicaciones dinámicamente
    for (int i = 0; i < _precargasControllers.length; i++) {
      registro['precarga${i + 1}'] = _precargasControllers[i].text;
      registro['p_indicador${i + 1}'] = _indicacionesControllers[i].text;
    }

    // Llenar los campos restantes con valores vacíos si hay menos de 6 filas
    for (int i = _precargasControllers.length; i < 6; i++) {
      registro['precarga${i + 1}'] = '';
      registro['p_indicador${i + 1}'] = '';
    }

    // Agregar los demás campos
    registro['ajuste'] = _tipoAjusteController.text; // Ajuste realizado (Sí/No)
    registro['tipo'] =
        _isAjusteExterno ? 'EXTERNO' : 'INTERNO'; // Tipo de ajuste
    registro['cargas_pesas'] =
        _cargasPesasController.text; // Cargas/Pesas de ajuste
    registro['hora'] = _horaController.text; // Hora
    registro['hri'] = _hriController.text; // HRi (%)
    registro['ti'] = _tiController.text; // ti (°C)
    registro['patmi'] = _patmiController.text; // Patmi (hPa)

    // Verificar si ya existe un registro con id = 1
    final existingRecord = await db.query(
      'registros_calibracion_bn',
      where: 'id = ?',
      whereArgs: [1],
    );

    if (existingRecord.isEmpty) {
      // Insertar el nuevo registro
      await db.insert(
        'registros_calibracion_bn',
        registro,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } else {
      // Actualizar el registro existente
      await db.update(
        'registros_calibracion_bn',
        registro,
        where: 'id = ?',
        whereArgs: [1],
      );
    }

    // Mostrar un mensaje de éxito
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Datos guardados exitosamente.')),
    );
  }

  void _addRow(BuildContext context) {
    // Acepta BuildContext como parámetro
    if (_rowCount >= 6) {
      // Mostrar un mensaje al usuario indicando que no se pueden agregar más filas
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pueden agregar más de 6 precargas.'),
          duration: Duration(seconds: 2), // Duración del mensaje
        ),
      );
      return;
    }

    setState(() {
      _rowCount++;
      _precargasControllers.add(TextEditingController());
      _indicacionesControllers.add(TextEditingController());
    });
  }

  void _removeRow() {
    if (_rowCount > 5) {
      setState(() {
        _rowCount--;
        _precargasControllers.removeLast();
        _indicacionesControllers.removeLast();
      });
    }
  }

  void _onAjusteRealizadoChanged(String? value) {
    setState(() {
      _isAjusteRealizado = value == 'Sí';
      if (!_isAjusteRealizado) {
        _tipoAjusteController.text = 'NO APLICA';
        _cargasPesasController.text = 'NO APLICA';
      } else {
        _tipoAjusteController.clear();
        _cargasPesasController.clear();
      }
    });
  }

  void _onTipoAjusteChanged(String? value) {
    setState(() {
      _isAjusteExterno = value == 'EXTERNO';
      if (!_isAjusteExterno) {
        _cargasPesasController.text = 'NO APLICA';
      } else {
        _cargasPesasController.clear();
      }
    });
  }

  void _navigateToNextScreen(BuildContext context) async {
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
                Navigator.of(context).pop(false);
              },
              child: const Text('No'),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.green,
              ),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text('Sí'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await _saveDataToDatabase(context);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PeScreen(
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
    final dividerColor = isDarkMode ? Colors.white : Colors.black;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 70,
        title: Text(
          'CALIBRACION PC',
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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'INICIO DE PRUEBAS DE PRECARGAS DE AJUSTE',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Precargas:',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () =>
                              _addRow(context), // Pasa el contexto aquí
                        ),
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: _removeRow,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _rowCount,
                  itemBuilder: (context, index) {
                    if (index >= _precargasControllers.length ||
                        index >= _indicacionesControllers.length) {
                      return Container(); // Retorna un contenedor vacío si el índice está fuera de los límites
                    }
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _precargasControllers[index],
                              decoration: InputDecoration(
                                labelText:
                                    'Precarga ${index + 1}', // Enumerar las precargas
                                border: const OutlineInputBorder(),
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _indicacionesControllers[index].text = value;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _indicacionesControllers[index],
                              decoration: InputDecoration(
                                labelText:
                                    'Indicación ${index + 1}', // Enumerar las indicaciones
                                border: const OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                const Center(
                  child: Text(
                    'REGISTRO DE AJUSTES',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  items: ['Sí', 'No']
                      .map((item) => DropdownMenuItem<String>(
                            value: item,
                            child: Text(item),
                          ))
                      .toList(),
                  onChanged: _onAjusteRealizadoChanged,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: '¿Se Realizo el Ajuste?',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor seleccione una opción';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  items: ['INTERNO', 'EXTERNO']
                      .map((item) => DropdownMenuItem<String>(
                            value: item,
                            child: Text(item),
                          ))
                      .toList(),
                  onChanged: _isAjusteRealizado ? _onTipoAjusteChanged : null,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Tipo de Ajuste:',
                  ),
                  validator: (value) {
                    if (_isAjusteRealizado &&
                        (value == null || value.isEmpty)) {
                      return 'Por favor seleccione una opción';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _cargasPesasController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Cargas / Pesas de Ajuste:',
                  ),
                  enabled: _isAjusteExterno,
                  validator: (value) {
                    if (_isAjusteExterno && (value == null || value.isEmpty)) {
                      return 'Por favor ingrese un valor';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                const Center(
                  child: Text(
                    'REGISTRO DE CONDICIONES AMBIENTALES INICIALES',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller:
                      _horaController, // Usar el controlador directamente
                  decoration: InputDecoration(
                    labelText: 'Hora',
                    border: OutlineInputBorder(
                        borderSide: BorderSide(color: dividerColor)),
                  ),
                  readOnly: true, // Hacer el campo de solo lectura
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller:
                      _hriController, // Usar el controlador directamente
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'HRi (%)',
                    border: OutlineInputBorder(),
                    suffixText: '%',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingrese un valor';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Por favor ingrese un número válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _tiController, // Usar el controlador directamente
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'ti (°C)',
                    border: OutlineInputBorder(),
                    suffixText: '°C',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingrese un valor';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Por favor ingrese un número válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _patmiController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Patmi (hPa)',
                    border: OutlineInputBorder(),
                    suffixText: 'hPa',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingrese un valor';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Por favor ingrese un número válido';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
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
              _navigateToNextScreen(context); // Llamar a la nueva función
            },
          ),
        ],
      ),
    );
  }
}
