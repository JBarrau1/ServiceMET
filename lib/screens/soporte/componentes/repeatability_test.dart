import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:service_met/provider/balanza_provider.dart';

class RepeatabilityTest extends StatefulWidget {
  final String testType;
  final Map<String, dynamic> initialData;
  final ValueChanged<Map<String, dynamic>> onDataChanged;
  final String? selectedUnit;
  final ValueChanged<String>? onUnitChanged;

  const RepeatabilityTest({
    super.key,
    required this.testType,
    required this.initialData,
    required this.onDataChanged,
    this.selectedUnit,
    this.onUnitChanged,
  });

  @override
  State<RepeatabilityTest> createState() => _RepeatabilityTestState();
}

class _RepeatabilityTestState extends State<RepeatabilityTest> {
  late int _selectedRepetibilityCount;
  late int _selectedRowCount;
  late List<TextEditingController> _loadControllers;
  late List<List<TextEditingController>> _indicationControllers;
  late List<List<TextEditingController>> _returnControllers;

  @override
  void initState() {
    super.initState();
    _selectedRepetibilityCount = widget.initialData['repetibilityCount'] ?? 1;
    _selectedRowCount = widget.initialData['rowCount'] ?? 3;

    _loadControllers = [];
    _indicationControllers = [];
    _returnControllers = [];

    _initializeControllers();
  }

  void _initializeControllers() {
    // Limpiar controladores existentes
    _disposeControllers();

    // Inicializar nuevos controladores con datos existentes o valores por defecto
    final loads = widget.initialData['loads'] ?? [];

    for (int i = 0; i < _selectedRepetibilityCount; i++) {
      _loadControllers.add(
        TextEditingController(
          text: i < loads.length ? loads[i]['value']?.toString() ?? '' : '',
        ),
      );

      List<TextEditingController> currentIndications = [];
      List<TextEditingController> currentReturns = [];

      final indications = (i < loads.length && loads[i]['indications'] != null)
          ? loads[i]['indications']
          : [];

      for (int j = 0; j < _selectedRowCount; j++) {
        currentIndications.add(
          TextEditingController(
            text: j < indications.length
                ? indications[j]['value']?.toString() ?? ''
                : '',
          ),
        );
        currentReturns.add(
          TextEditingController(
            text: j < indications.length
                ? indications[j]['return']?.toString() ?? '0'
                : '0',
          ),
        );
      }

      _indicationControllers.add(currentIndications);
      _returnControllers.add(currentReturns);
    }
  }

  void _disposeControllers() {
    for (var controller in _loadControllers) {
      controller.dispose();
    }
    for (var list in _indicationControllers) {
      for (var controller in list) {
        controller.dispose();
      }
    }
    for (var list in _returnControllers) {
      for (var controller in list) {
        controller.dispose();
      }
    }
    _loadControllers.clear();
    _indicationControllers.clear();
    _returnControllers.clear();
  }

  void _updateData() {
    final loads = [];

    for (int i = 0; i < _loadControllers.length; i++) {
      final indications = [];

      for (int j = 0; j < _indicationControllers[i].length; j++) {
        indications.add({
          'value': _indicationControllers[i][j].text,
          'return': _returnControllers[i][j].text,
        });
      }

      loads.add({
        'value': _loadControllers[i].text,
        'indications': indications,
      });
    }

    widget.onDataChanged({
      'type': 'repeatability',
      'testType': widget.testType,
      'repetibilityCount': _selectedRepetibilityCount,
      'rowCount': _selectedRowCount,
      'loads': loads,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 30),
        const Text(
          'PRUEBAS DE REPETIBILIDAD',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        DropdownButtonFormField<int>(
          initialValue: _selectedRepetibilityCount,
          items: [1, 2, 3]
              .map((int value) => DropdownMenuItem<int>(
                    value: value,
                    child: Text(value.toString()),
                  ))
              .toList(),
          onChanged: (value) {
            setState(() {
              _selectedRepetibilityCount = value ?? 1;
              _initializeControllers();
              _updateData();
            });
          },
          decoration: _buildInputDecoration('Cantidad de Cargas'),
        ),
        const SizedBox(height: 20),
        DropdownButtonFormField<int>(
          initialValue: _selectedRowCount,
          items: [3, 5, 10]
              .map((int value) => DropdownMenuItem<int>(
                    value: value,
                    child: Text(value.toString()),
                  ))
              .toList(),
          onChanged: (value) {
            setState(() {
              _selectedRowCount = value ?? 3;
              _initializeControllers();
              _updateData();
            });
          },
          decoration: _buildInputDecoration('Cantidad de Pruebas'),
        ),
        const SizedBox(height: 20),
        ..._buildLoadSections(),
      ],
    );
  }

  List<Widget> _buildLoadSections() {
    final sections = <Widget>[];

    for (int i = 0; i < _selectedRepetibilityCount; i++) {
      // Verificar que tenemos controladores para esta carga
      if (i >= _loadControllers.length) break;

      sections.addAll([
        Text(
          'CARGA ${i + 1}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _loadControllers[i],
          decoration: _buildInputDecoration('Carga ${i + 1}'),
          keyboardType: TextInputType.number,
          onChanged: (value) {
            _updateIndicationValues(i, value);
            _updateData();
          },
        ),
        const SizedBox(height: 10),
        ..._buildTestRows(i),
      ]);
    }

    return sections;
  }

  List<Widget> _buildTestRows(int loadIndex) {
    final rows = <Widget>[];
    final balanza =
        Provider.of<BalanzaProvider>(context, listen: false).selectedBalanza;
    final d1 = balanza?.d1 ?? 0.1;

    // Verificar que tenemos controladores para este índice de carga
    if (loadIndex >= _indicationControllers.length ||
        loadIndex >= _returnControllers.length) {
      return rows;
    }

    for (int i = 0; i < _selectedRowCount; i++) {
      // Verificar que tenemos controladores para esta fila
      if (i >= _indicationControllers[loadIndex].length ||
          i >= _returnControllers[loadIndex].length) {
        continue;
      }

      rows.add(Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _indicationControllers[loadIndex][i],
                  decoration: _buildInputDecoration(
                    'Indicación ${i + 1}',
                    suffixIcon: PopupMenuButton<String>(
                      icon: const Icon(Icons.arrow_drop_down),
                      onSelected: (String newValue) {
                        setState(() {
                          _indicationControllers[loadIndex][i].text = newValue;
                          _updateData();
                        });
                      },
                      itemBuilder: (BuildContext context) {
                        final baseValue = double.tryParse(
                                _indicationControllers[loadIndex][i].text) ??
                            0.0;
                        final decimalPlaces = _getSignificantDecimals(d1);

                        return List.generate(11, (index) {
                          final multiplier = index - 5;
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
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: _returnControllers[loadIndex][i],
                  decoration: _buildInputDecoration('Retorno ${i + 1}'),
                  keyboardType: TextInputType.number,
                  onChanged: (_) => _updateData(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
      ));
    }

    return rows;
  }

  void _updateIndicationValues(int loadIndex, String value) {
    if (value.isEmpty) return;

    // Verificar que tenemos controladores para este índice de carga
    if (loadIndex >= _indicationControllers.length) return;

    for (var controller in _indicationControllers[loadIndex]) {
      controller.text = value;
    }
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
    _disposeControllers();
    super.dispose();
  }
}
