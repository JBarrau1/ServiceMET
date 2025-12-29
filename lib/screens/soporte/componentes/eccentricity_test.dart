// ignore_for_file: unused_field

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:service_met/provider/balanza_provider.dart';

class EccentricityTest extends StatefulWidget {
  final String testType;
  final Map<String, dynamic> initialData;
  final ValueChanged<Map<String, dynamic>> onDataChanged;
  final String? selectedUnit;
  final ValueChanged<String>? onUnitChanged;

  const EccentricityTest({
    super.key,
    required this.testType,
    required this.initialData,
    required this.onDataChanged,
    this.selectedUnit,
    this.onUnitChanged,
  });

  @override
  State<EccentricityTest> createState() => _EccentricityTestState();
}

class _EccentricityTestState extends State<EccentricityTest> {
  final List<int> _basculaCellCounts = [6, 8, 10, 12];
  int? _selectedBasculaCellCount;

  late String? _selectedPlatform;
  late String? _selectedOption;
  late String? _selectedImagePath;
  late TextEditingController _loadController;
  late List<TextEditingController> _positionControllers;
  late List<TextEditingController> _indicationControllers;
  late List<TextEditingController> _returnControllers;
  int? _truckPoints;
  final TextEditingController _truckPointsController = TextEditingController();

  final Map<String, List<String>> _platformOptions = {
    'Rectangular': [
      'Rectangular 3 pts - Ind Derecha',
      'Rectangular 3 pts - Ind Izquierda',
      'Rectangular 3 pts - Ind Frontal',
      'Rectangular 3 pts - Ind Atras',
      'Rectangular 5 pts - Ind Derecha',
      'Rectangular 5 pts - Ind Izquierda',
      'Rectangular 5 pts - Ind Frontal',
      'Rectangular 5 pts - Ind Atras'
    ],
    'Circular': [
      'Circular 5 pts - Ind Derecha',
      'Circular 5 pts - Ind Izquierda',
      'Circular 5 pts - Ind Frontal',
      'Circular 5 pts - Ind Atras',
      'Circular 4 pts - Ind Derecha',
      'Circular 4 pts - Ind Izquierda',
      'Circular 4 pts - Ind Frontal',
      'Circular 4 pts - Ind Atras'
    ],
    'Cuadrada': [
      'Cuadrada - Ind Derecha',
      'Cuadrada - Ind Izquierda',
      'Cuadrada - Ind Frontal',
      'Cuadrada - Ind Atras'
    ],
    'Triangular': [
      'Triangular - Ind Izquierda',
      'Triangular - Ind Frontal',
      'Triangular - Ind Atras',
      'Triangular - Ind Derecha'
    ],
    'Báscula de camión': [],
  };

  final Map<String, String> _optionImages = {
    'Rectangular 3 pts - Ind Derecha': 'images/Rectangular_3D.png',
    'Rectangular 3 pts - Ind Izquierda': 'images/Rectangular_3I.png',
    'Rectangular 3 pts - Ind Frontal': 'images/Rectangular_3F.png',
    'Rectangular 3 pts - Ind Atras': 'images/Rectangular_3A.png',
    'Rectangular 5 pts - Ind Derecha': 'images/Rectangular_5D.png',
    'Rectangular 5 pts - Ind Izquierda': 'images/Rectangular_5I.png',
    'Rectangular 5 pts - Ind Frontal': 'images/Rectangular_5F.png',
    'Rectangular 5 pts - Ind Atras': 'images/Rectangular_5A.png',
    'Circular 5 pts - Ind Derecha': 'images/Circular_5D.png',
    'Circular 5 pts - Ind Izquierda': 'images/Circular_5I.png',
    'Circular 5 pts - Ind Frontal': 'images/Circular_5F.png',
    'Circular 5 pts - Ind Atras': 'images/Circular_5A.png',
    'Circular 4 pts - Ind Derecha': 'images/Circular_4D.png',
    'Circular 4 pts - Ind Izquierda': 'images/Circular_4I.png',
    'Circular 4 pts - Ind Frontal': 'images/Circular_4F.png',
    'Circular 4 pts - Ind Atras': 'images/Circular_4A.png',
    'Cuadrada - Ind Derecha': 'images/Cuadrada_D.png',
    'Cuadrada - Ind Izquierda': 'images/Cuadrada_I.png',
    'Cuadrada - Ind Frontal': 'images/Cuadrada_F.png',
    'Cuadrada - Ind Atras': 'images/Cuadrada_A.png',
    'Triangular - Ind Izquierda': 'images/Triangular_I.png',
    'Triangular - Ind Frontal': 'images/Triangular_F.png',
    'Triangular - Ind Atras': 'images/Triangular_A.png',
    'Triangular - Ind Derecha': 'images/Triangular_D.png',
  };

  @override
  void initState() {
    super.initState();
    _loadController =
        TextEditingController(text: widget.initialData['load'] ?? '');
    _selectedPlatform = widget.initialData['platform'];
    _selectedOption = widget.initialData['option'];
    _selectedImagePath = widget.initialData['imagePath'];

    _positionControllers = [];
    _indicationControllers = [];
    _returnControllers = [];

    _initializeControllers();
  }

  void _initializeControllers() {
    final positions = widget.initialData['positions'] ?? [];

    for (int i = 0; i < positions.length; i++) {
      _positionControllers
          .add(TextEditingController(text: positions[i]['position']));
      _indicationControllers
          .add(TextEditingController(text: positions[i]['indication']));
      _returnControllers
          .add(TextEditingController(text: positions[i]['return'] ?? '0'));
    }
  }

  void _updatePositions() {
    if (_selectedOption == null) return;

    int numberOfPositions = _getNumberOfPositions(_selectedOption!);

    _positionControllers = [];
    _indicationControllers = [];
    _returnControllers = [];

    for (int i = 0; i < numberOfPositions; i++) {
      _positionControllers.add(TextEditingController(text: (i + 1).toString()));
      _indicationControllers
          .add(TextEditingController(text: _loadController.text));
      _returnControllers.add(TextEditingController(text: '0'));
    }

    _updateData();
  }

  int _getNumberOfPositions(String platform) {
    if (platform == 'Báscula de camión') return 6;
    if (platform.contains('3')) return 3;
    if (platform.contains('4')) return 4;
    if (platform.contains('5')) return 5;
    if (platform.startsWith('Cuadrada')) return 5;
    if (platform.startsWith('Triangular')) return 4;
    return 0;
  }

  void _updateData() {
    final positions = [];
    for (int i = 0; i < _positionControllers.length; i++) {
      positions.add({
        'position': _positionControllers[i].text,
        'indication': _indicationControllers[i].text,
        'return': _returnControllers[i].text,
        'label': _selectedPlatform == 'Báscula de camión'
            ? (i < (_truckPoints! ~/ 2) ? 'Ida' : 'Vuelta')
            : null,
      });
    }
    widget.onDataChanged({
      'type': 'eccentricity',
      'testType': widget.testType,
      'platform': _selectedPlatform,
      'option': _selectedOption,
      'imagePath': _selectedImagePath,
      'load': _loadController.text,
      'positions': positions,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 20),
        const Text(
          'INFORMACIÓN DE PLATAFORMA',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        DropdownButtonFormField<String>(
          initialValue: _selectedPlatform,
          decoration: _buildInputDecoration('Tipo de Plataforma'),
          items: _platformOptions.keys.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              _selectedPlatform = newValue;
              _selectedOption = null;
              _selectedImagePath = null;
              _updatePositions();
            });
          },
        ),
        const SizedBox(height: 20),

        // SOLO mostrar estos campos si NO es báscula de camión
        if (_selectedPlatform != 'Báscula de camión') ...[
          if (_selectedPlatform != null)
            DropdownButtonFormField<String>(
              initialValue: _selectedOption,
              decoration: _buildInputDecoration('Puntos e Indicador'),
              items: _platformOptions[_selectedPlatform]!.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedOption = newValue;
                  _selectedImagePath = _optionImages[newValue!];
                  _updatePositions();
                });
              },
            ),
          const SizedBox(height: 20),
          if (_selectedImagePath != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: 130,
                child: Image.asset(
                  _selectedImagePath!,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _loadController,
            decoration: _buildInputDecoration('Carga'),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              final doubleValue = double.tryParse(value);
              if (doubleValue != null) {
                for (int i = 0; i < _indicationControllers.length; i++) {
                  _indicationControllers[i].text = value;
                }
                _updateData();
              }
            },
          ),
          const SizedBox(height: 20),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _positionControllers.length,
            itemBuilder: (context, index) {
              return _buildPositionRow(index);
            },
          ),
        ],

        // SOLO mostrar estos campos si ES báscula de camión
        if (_selectedPlatform == 'Báscula de camión') ...[
          const SizedBox(height: 20),
          TextFormField(
            controller: _truckPointsController,
            decoration: _buildInputDecoration('Cantidad de puntos (par, 6-12)'),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              final parsed = int.tryParse(value);
              if (parsed != null &&
                  parsed >= 6 &&
                  parsed <= 12 &&
                  parsed % 2 == 0) {
                setState(() {
                  _truckPoints = parsed;
                  // Actualiza los controladores para los puntos
                  _positionControllers = List.generate(_truckPoints!,
                      (i) => TextEditingController(text: (i + 1).toString()));
                  _indicationControllers = List.generate(
                      _truckPoints!, (i) => TextEditingController());
                  _returnControllers = List.generate(
                      _truckPoints!, (i) => TextEditingController(text: '0'));
                });
              }
            },
          ),
          const SizedBox(height: 20),
          if (_truckPoints != null)
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _truckPoints!,
              itemBuilder: (context, index) {
                final label = index < (_truckPoints! ~/ 2) ? 'Ida' : 'Vuelta';
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text('Punto ${index + 1} ($label)'),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _indicationControllers[index],
                          decoration: _buildInputDecoration('Indicación'),
                          keyboardType: TextInputType.number,
                          onChanged: (_) => _updateData(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _returnControllers[index],
                          decoration: _buildInputDecoration('Retorno'),
                          keyboardType: TextInputType.number,
                          onChanged: (_) => _updateData(),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ],
    );
  }

  Widget _buildPositionRow(int index) {
    final balanza =
        Provider.of<BalanzaProvider>(context, listen: false).selectedBalanza;
    final d1 = balanza?.d1 ?? 0.1;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: _positionControllers[index],
              decoration: _buildInputDecoration('Posición ${index + 1}'),
              enabled: false,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              children: [
                TextFormField(
                  controller: _indicationControllers[index],
                  decoration: _buildInputDecoration(
                    'Indicación',
                    suffixIcon: PopupMenuButton<String>(
                      icon: const Icon(Icons.arrow_drop_down),
                      onSelected: (String newValue) {
                        setState(() {
                          _indicationControllers[index].text = newValue;
                          _updateData();
                        });
                      },
                      itemBuilder: (BuildContext context) {
                        final baseValue = double.tryParse(
                                _indicationControllers[index].text) ??
                            0.0;
                        final decimalPlaces = _getSignificantDecimals(d1);

                        return List.generate(11, (i) {
                          final multiplier = i - 5;
                          final value = baseValue + (multiplier * d1);
                          final formattedValue =
                              value.toStringAsFixed(decimalPlaces);
                          return PopupMenuItem<String>(
                            value: formattedValue,
                            child: Text(formattedValue),
                          );
                        });
                      },
                    ),
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _returnControllers[index],
                  decoration: _buildInputDecoration('Retorno'),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    if (value.isEmpty) {
                      _returnControllers[index].text = '0';
                    }
                    _updateData();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _getSignificantDecimals(double value) {
    final parts = value.toString().split('.');
    if (parts.length == 2) {
      return parts[1].replaceAll(RegExp(r'0+$'), '').length;
    }
    return 0;
  }

  InputDecoration _buildInputDecoration(String labelText,
      {Widget? suffixIcon}) {
    return InputDecoration(
      labelText: labelText,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20.0)),
      suffixIcon: suffixIcon,
    );
  }

  @override
  void dispose() {
    _truckPointsController.dispose();
    _loadController.dispose();
    for (var controller in _positionControllers) {
      controller.dispose();
    }
    for (var controller in _indicationControllers) {
      controller.dispose();
    }
    for (var controller in _returnControllers) {
      controller.dispose();
    }
    super.dispose();
  }
}
