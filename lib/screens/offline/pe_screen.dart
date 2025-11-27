import 'dart:ui';
import 'package:service_met/provider/balanza_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';

class PeScreen extends StatefulWidget {
  final String dbName;
  final String userName;
  final String dbPath;

  const PeScreen({
    super.key,
    required this.dbName,
    required this.userName,
    required this.dbPath,
  });

  @override
  _PeScreenState createState() => _PeScreenState();
}

class _PeScreenState extends State<PeScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedPlatform;
  String? _selectedOption;
  String? _selectedImagePath;
  final TextEditingController _cargaController = TextEditingController();
  List<TextEditingController> _positionControllers = [];
  List<TextEditingController> _indicationControllers = [];
  final List<TextEditingController> _returnControllers = List.generate(
    10, // Cambia 10 por el número de controladores que necesites
    (index) => TextEditingController(text: '0'),
  );
  List<bool> _isDynamicallyAdded = [];
  List<List<String>> _indicationDropdownItems = [];
  final Map<String, List<String>> _platformOptions = {
    'Rectangular': [
      'Rectangular 3D',
      'Rectangular 3I',
      'Rectangular 3F',
      'Rectangular 3A',
      'Rectangular 5D',
      'Rectangular 5I',
      'Rectangular 5F',
      'Rectangular 5A',
    ],
    'Circular': [
      'Circular 5D',
      'Circular 5I',
      'Circular 5F',
      'Circular 5A',
      'Circular 4D',
      'Circular 4I',
      'Circular 4F',
      'Circular 4A',
    ],
    'Cuadrada': [
      'Cuadrada D',
      'Cuadrada I',
      'Cuadrada F',
      'Cuadrada A',
    ],
    'Triangular': [
      'Triangular I',
      'Triangular F',
      'Triangular A',
      'Triangular D',
    ],
  };

  final Map<String, String> _optionImages = {
    'Rectangular 3D': 'images/Rectangular_3D.png',
    'Rectangular 3I': 'images/Rectangular_3I.png',
    'Rectangular 3F': 'images/Rectangular_3F.png',
    'Rectangular 3A': 'images/Rectangular_3A.png',
    'Rectangular 5D': 'images/Rectangular_5D.png',
    'Rectangular 5I': 'images/Rectangular_5I.png',
    'Rectangular 5F': 'images/Rectangular_5F.png',
    'Rectangular 5A': 'images/Rectangular_5A.png',
    'Circular 5D': 'images/Circular_5D.png',
    'Circular 5I': 'images/Circular_5I.png',
    'Circular 5F': 'images/Circular_5F.png',
    'Circular 5A': 'images/Circular_5A.png',
    'Circular 4D': 'images/Circular_4D.png',
    'Circular 4I': 'images/Circular_4I.png',
    'Circular 4F': 'images/Circular_4F.png',
    'Circular 4A': 'images/Circular_4A.png',
    'Cuadrada D': 'images/Cuadrada_D.png',
    'Cuadrada I': 'images/Cuadrada_I.png',
    'Cuadrada F': 'images/Cuadrada_F.png',
    'Cuadrada A': 'images/Cuadrada_A.png',
    'Triangular I': 'images/Triangular_I.png',
    'Triangular F': 'images/Triangular_F.png',
    'Triangular A': 'images/Triangular_A.png',
    'Triangular D': 'images/Triangular_D.png',
  };

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _positionControllers = [];
    _indicationControllers = [];
    _returnControllers.clear();
    _isDynamicallyAdded = [];
    _indicationDropdownItems = [];
  }

  void _updatePositions() {
    if (_selectedOption == null) return;

    // Obtener el número de posiciones basado en la plataforma seleccionada
    int numberOfPositions = _getNumberOfPositions(_selectedOption!);

    // Limpiar los controladores existentes
    _initializeControllers();

    // Inicializar los controladores con el número de posiciones
    for (int i = 0; i < numberOfPositions; i++) {
      _positionControllers.add(TextEditingController(text: (i + 1).toString()));
      _indicationControllers.add(TextEditingController());
      _returnControllers.add(TextEditingController(text: '0'));
      _isDynamicallyAdded.add(false);
      _indicationDropdownItems.add([]);
    }

    setState(() {});
  }

  int _getNumberOfPositions(String platform) {
    if (platform.contains('3')) {
      return 3;
    } else if (platform.contains('4')) {
      return 4;
    } else if (platform.contains('5')) {
      return 5;
    } else if (platform.startsWith('Cuadrada')) {
      return 5; // Cuadrada siempre tiene 5 posiciones
    } else if (platform.startsWith('Triangular')) {
      return 4; // Triangular siempre tiene 4 posiciones
    }
    return 0; // Por defecto, no mostrar posiciones
  }

  void _updateIndicationDropdownItems(int index, double value) {
    setState(() {
      _indicationDropdownItems[index] = [
        ...List.generate(5, (i) => (value + (i + 1)).toStringAsFixed(0))
            .reversed,
        value.toStringAsFixed(0),
        ...List.generate(5, (i) => (value - (i + 1)).toStringAsFixed(0)),
      ];
    });
  }

  Future<void> _saveDataToDatabase(BuildContext context) async {
    final db = await openDatabase(widget.dbPath);

    final registro = {
      'tipo_plataforma': _selectedPlatform,
      'puntos_ind': _selectedOption,
      'carga': _cargaController.text,
      'posicion1':
          _positionControllers.isNotEmpty ? _positionControllers[0].text : null,
      'indicacion1': _indicationControllers.isNotEmpty
          ? _indicationControllers[0].text
          : null,
      'retorno1':
          _returnControllers.isNotEmpty ? _returnControllers[0].text : null,
      'posicion2':
          _positionControllers.length > 1 ? _positionControllers[1].text : null,
      'indicacion2': _indicationControllers.length > 1
          ? _indicationControllers[1].text
          : null,
      'retorno2':
          _returnControllers.length > 1 ? _returnControllers[1].text : null,
      'posicion3':
          _positionControllers.length > 2 ? _positionControllers[2].text : null,
      'indicacion3': _indicationControllers.length > 2
          ? _indicationControllers[2].text
          : null,
      'retorno3':
          _returnControllers.length > 2 ? _returnControllers[2].text : null,
      'posicion4':
          _positionControllers.length > 3 ? _positionControllers[3].text : null,
      'indicacion4': _indicationControllers.length > 3
          ? _indicationControllers[3].text
          : null,
      'retorno4':
          _returnControllers.length > 3 ? _returnControllers[3].text : null,
      'posicion5':
          _positionControllers.length > 4 ? _positionControllers[4].text : null,
      'indicacion5': _indicationControllers.length > 4
          ? _indicationControllers[4].text
          : null,
      'retorno5':
          _returnControllers.length > 4 ? _returnControllers[4].text : null,
      'posicion6':
          _positionControllers.length > 5 ? _positionControllers[5].text : null,
      'indicacion6': _indicationControllers.length > 5
          ? _indicationControllers[5].text
          : null,
      'retorno6':
          _returnControllers.length > 5 ? _returnControllers[5].text : null,
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
          'CALIBRACION PE',
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
      body: Column(
        children: [
          Expanded(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 5.0),
                      const Text(
                        'PRUEBA DE EXCENTRICIDAD',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w900),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20.0),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'TIPO DE PLATAFORMA',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(height: 15.0),
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Selecciona el tipo de plataforma',
                          border: OutlineInputBorder(),
                        ),
                        items: _platformOptions.keys.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedPlatform = newValue;
                            _selectedOption = null; // Reset the second dropdown
                            _selectedImagePath = null; // Reset the image path
                          });
                        },
                        initialValue: _selectedPlatform,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor seleccione una opción';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10.0),
                      if (_selectedPlatform != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10.0),
                          child: DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'Puntos e Indicador',
                              border: OutlineInputBorder(),
                            ),
                            items: _platformOptions[_selectedPlatform]!
                                .map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedOption = newValue;
                                _selectedImagePath = _optionImages[newValue!];
                                _updatePositions(); // Actualizar las posiciones
                              });
                            },
                            initialValue: _selectedOption,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor seleccione una opción';
                              }
                              return null;
                            },
                          ),
                        ),
                      if (_selectedImagePath != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10.0),
                          child: Image.asset(_selectedImagePath!),
                        ),
                      const SizedBox(height: 20.0),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'REGISTRO DE DATOS DE EXCENTRICIDAD',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(height: 10.0),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10.0),
                        child: TextFormField(
                          controller: _cargaController,
                          decoration: const InputDecoration(
                            labelText: 'Carga',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor ingrese un valor';
                            }
                            final doubleValue = double.tryParse(value);
                            if (doubleValue == null) {
                              return 'Por favor ingrese un número válido';
                            }
                            return null;
                          },
                          onChanged: (value) {
                            final doubleValue = double.tryParse(value);
                            setState(() {
                              _cargaController.text = value;
                              _cargaController.value =
                                  _cargaController.value.copyWith(
                                text: value,
                                selection: TextSelection.collapsed(
                                    offset: value.length),
                                composing: TextRange.empty,
                              );
                              if (doubleValue != null) {
                                for (int i = 0;
                                    i < _indicationControllers.length;
                                    i++) {
                                  _indicationControllers[i].text = value;
                                  _updateIndicationDropdownItems(
                                      i, doubleValue);
                                }
                              }
                            });
                          },
                        ),
                      ),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _positionControllers.length,
                        itemBuilder: (context, index) {
                          return Column(
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _positionControllers[index],
                                        decoration: InputDecoration(
                                          labelText: 'Posición ${index + 1}',
                                          border: const OutlineInputBorder(),
                                        ),
                                        enabled: false,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        children: [
                                          TextFormField(
                                            controller:
                                                _indicationControllers[index],
                                            decoration: InputDecoration(
                                              labelText: 'Indicación',
                                              border:
                                                  const OutlineInputBorder(),
                                              suffixIcon:
                                                  PopupMenuButton<String>(
                                                icon: const Icon(
                                                    Icons.arrow_drop_down),
                                                onSelected: (String newValue) {
                                                  setState(() {
                                                    _indicationControllers[
                                                            index]
                                                        .text = newValue;
                                                  });
                                                },
                                                itemBuilder:
                                                    (BuildContext context) {
                                                  final balanza = Provider.of<
                                                              BalanzaProvider>(
                                                          context,
                                                          listen: false)
                                                      .selectedBalanza;
                                                  final decimals =
                                                      balanza != null
                                                          ? balanza.d1
                                                              .toString()
                                                              .split('.')
                                                              .last
                                                              .length
                                                          : 2;
                                                  final increment = double.parse(
                                                      '0.${'0' * (decimals - 1)}1');
                                                  final baseValue = double.tryParse(
                                                          _indicationControllers[
                                                                  index]
                                                              .text) ??
                                                      0.0;

                                                  return [
                                                    ...List.generate(
                                                        5,
                                                        (i) => (baseValue +
                                                                (i + 1) *
                                                                    increment)
                                                            .toStringAsFixed(
                                                                decimals)),
                                                    baseValue.toStringAsFixed(
                                                        decimals),
                                                    ...List.generate(
                                                        5,
                                                        (i) => (baseValue -
                                                                (i + 1) *
                                                                    increment)
                                                            .toStringAsFixed(
                                                                decimals)),
                                                  ].map((String value) {
                                                    return PopupMenuItem<
                                                        String>(
                                                      value: value,
                                                      child: Text(value),
                                                    );
                                                  }).toList();
                                                },
                                              ),
                                            ),
                                            keyboardType: TextInputType.number,
                                            validator: (value) {
                                              if (value == null ||
                                                  value.isEmpty) {
                                                return 'Por favor ingrese un valor';
                                              }
                                              return null;
                                            },
                                            onChanged: (value) {
                                              final balanza =
                                                  Provider.of<BalanzaProvider>(
                                                          context,
                                                          listen: false)
                                                      .selectedBalanza;
                                              if (balanza != null) {
                                                setState(() {
                                                  _indicationControllers[index]
                                                          .text =
                                                      balanza.exc.toString();
                                                });
                                              }
                                            },
                                          ),
                                          const SizedBox(
                                              height:
                                                  16), // Espaciado entre los campos
                                          TextFormField(
                                            controller: _returnControllers[
                                                index], // Valor por defecto
                                            keyboardType: TextInputType
                                                .number, // Solo números
                                            decoration: const InputDecoration(
                                              labelText: 'Retorno',
                                              border: OutlineInputBorder(),
                                            ),
                                            onChanged: (String value) {
                                              // Lógica adicional si necesitas manejar el valor ingresado
                                              print(
                                                  "Nuevo valor de Retorno: $value");
                                            },
                                            validator: (value) {
                                              if (value == null ||
                                                  value.isEmpty) {
                                                return 'Por favor ingrese un valor para Retorno';
                                              }
                                              return null;
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Divider(color: Colors.grey, thickness: 1),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
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
            },
          ),
        ],
      ),
    );
  }
}
