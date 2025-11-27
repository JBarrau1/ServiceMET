import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../provider/balanza_provider.dart';
import '../services/calibration_service.dart';

class LinearityTest extends StatefulWidget {
  final CalibrationService calibrationService;
  final ValueNotifier<bool> isDataSaved;

  const LinearityTest({
    super.key,
    required this.calibrationService,
    required this.isDataSaved,
  });

  @override
  _LinearityTestState createState() => _LinearityTestState();
}

class _LinearityTestState extends State<LinearityTest> {
  final TextEditingController _ltnController = TextEditingController();
  final TextEditingController _iLtnController = TextEditingController();
  final TextEditingController _iLsubnController = TextEditingController();
  final TextEditingController _lsubnController = TextEditingController();
  final TextEditingController _cpController = TextEditingController();
  final TextEditingController _iCpController = TextEditingController();
  final TextEditingController _differenceController = TextEditingController();
  final TextEditingController _ioController = TextEditingController(text: '0');
  final TextEditingController _notaController = TextEditingController();

  String? _selectedMetodo;
  String? _selectedMetodoCarga;

  final List<String> _metodoOptions = [
    'Ascenso evaluando ceros',
    'Ascenso contínuo por pasos'
  ];

  final List<String> _metodocargaOptions = ['Método 1', 'Método 2'];

  final List<Map<String, TextEditingController>> _rows = List.generate(
    6,
    (index) => {
      'lt': TextEditingController(),
      'indicacion': TextEditingController(),
      'retorno': TextEditingController(text: '0'),
      'difference': TextEditingController(),
    },
  );

  void _calculateLsubn() {
    final ltn = double.tryParse(_ltnController.text) ?? 0.0;
    final iLtn = double.tryParse(_iLtnController.text) ?? 0.0;
    final iLsubn = double.tryParse(_iLsubnController.text) ?? 0.0;

    final difference = ltn - iLtn;
    final lsubn = iLsubn + difference;

    _lsubnController.text = lsubn.toString();
  }

  void _saveLtnToNewRow() {
    final ltnValue = _ltnController.text;
    if (ltnValue.isNotEmpty) {
      setState(() {
        _rows.add({
          'lt': TextEditingController(text: ltnValue),
          'indicacion': TextEditingController(),
          'retorno': TextEditingController(text: '0'),
          'difference': TextEditingController(),
        });
      });
    } else {
      _showSnackBar('LTn está vacío.', isError: true);
    }
  }

  void _saveData() {
    final lsubn = double.tryParse(_lsubnController.text) ?? 0.0;
    final sum = lsubn + 500;

    setState(() {
      _rows.add({
        'lt': TextEditingController(text: sum.toString()),
        'indicacion': TextEditingController(),
        'retorno': TextEditingController(text: '0'),
        'difference': TextEditingController(),
      });
    });
  }

  void _removeRow(int index) {
    if (index >= 6) {
      setState(() {
        _rows.removeAt(index);
      });
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text(
            'ADVERTENCIA',
            style: TextStyle(
                fontSize: 17, fontWeight: FontWeight.w900, color: Colors.red),
          ),
          content: const Text('Las primeras 6 filas no se pueden eliminar.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.green,
              ),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  void _addRow() {
    if (_rows.length >= 12) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text(
            '¡ADVERTENCIA!',
            style: TextStyle(
                fontSize: 17, fontWeight: FontWeight.w900, color: Colors.red),
          ),
          content: const Text('Está excediendo las 12 filas sugeridas.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
    if (_rows.length < 60) {
      setState(() {
        _rows.add({
          'lt': TextEditingController(),
          'indicacion': TextEditingController(),
          'retorno': TextEditingController(text: '0'),
          'difference': TextEditingController(),
        });
      });
    }
  }

  bool _areAllFieldsFilled() {
    for (var row in _rows) {
      if (row['lt']?.text.isEmpty ??
          true || row['indicacion']!.text.isEmpty ??
          true) {
        return false;
      }
    }
    return true;
  }

  void _calculateDifferenceForRow(int index) {
    final balanza =
        Provider.of<BalanzaProvider>(context, listen: false).selectedBalanza;
    final decimals = balanza?.d1.toString().split('.').last.length ?? 5;

    final lt = double.tryParse(_rows[index]['lt']?.text ?? '') ?? 0.0;
    final indicacion =
        double.tryParse(_rows[index]['indicacion']?.text ?? '') ?? 0.0;
    final newDifference = (indicacion - lt).toStringAsFixed(decimals);

    if (_rows[index]['difference']?.text != newDifference) {
      _rows[index]['difference']?.text = newDifference;
    }
  }

  void _calculateAllDifferences() {
    for (int i = 0; i < _rows.length; i++) {
      _calculateDifferenceForRow(i);
    }
    setState(() {});
  }

  Future<void> _saveDataToDatabase() async {
    try {
      // Crear un Map<String, dynamic> explícitamente
      final Map<String, dynamic> registro = {};

      for (int i = 0; i < _rows.length; i++) {
        registro['lin${i + 1}'] = _rows[i]['lt']?.text ?? '';
        registro['lin_ind${i + 1}'] = _rows[i]['indicacion']?.text ?? '';
        registro['lin_ret${i + 1}'] = _rows[i]['retorno']?.text ?? '';
        registro['lin_diff${i + 1}'] = _rows[i]['difference']?.text ?? '';
      }

      registro['metodo_linealidad'] = _selectedMetodo ?? '';
      registro['metodo_carga_linealidad'] = _selectedMetodoCarga ?? '';
      registro['observaciones_linealidad'] = _notaController.text;

      await widget.calibrationService.saveLinearityData(registro);

      widget.isDataSaved.value = true;
      _showSnackBar('Datos de linealidad guardados correctamente');
    } catch (e) {
      _showSnackBar('Error al guardar linealidad: $e', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  InputDecoration _buildInputDecoration(String labelText,
      {Widget? suffixIcon, String? suffixText}) {
    return InputDecoration(
      labelText: labelText,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20.0)),
      suffixIcon: suffixIcon,
      suffixText: suffixText,
    );
  }

  Widget _buildCalibrationForm(BuildContext context) {
    final balanza = Provider.of<BalanzaProvider>(context).selectedBalanza;

    return Column(
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _rows.length,
          itemBuilder: (context, index) {
            final ltController = _rows[index]['lt'];
            final indicacionController = _rows[index]['indicacion'];

            void syncLtToIndicacion() {
              if (ltController != null && indicacionController != null) {
                if (ltController.text.isNotEmpty &&
                    ltController.text != indicacionController.text) {
                  indicacionController.text = ltController.text;
                }
              }
            }

            ltController?.addListener(syncLtToIndicacion);

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d*'))
                          ],
                          controller: ltController,
                          decoration:
                              _buildInputDecoration('LT ${index + 1}').copyWith(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20.0),
                              borderSide: const BorderSide(color: Colors.green),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20.0),
                              borderSide: const BorderSide(color: Colors.green),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20.0),
                              borderSide: const BorderSide(
                                  color: Colors.green, width: 2.0),
                            ),
                          ),
                          onChanged: (value) {
                            syncLtToIndicacion();
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d*'))
                          ],
                          controller: _rows[index]['difference'],
                          decoration: _buildInputDecoration(
                                  'Diferencia en ${_rows[index]['lt']?.text ?? ''}')
                              .copyWith(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20.0),
                              borderSide:
                                  const BorderSide(color: Colors.orange),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20.0),
                              borderSide:
                                  const BorderSide(color: Colors.orange),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20.0),
                              borderSide: const BorderSide(
                                  color: Colors.orange, width: 2.0),
                            ),
                          ),
                          style: const TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.w500),
                          readOnly: true,
                          enabled: false,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10.0),
                  Row(
                    children: [
                      Expanded(
                        child: FutureBuilder<double>(
                          future: widget.calibrationService.getD1Value(),
                          builder: (context, snapshot) {
                            final d1 = balanza?.d1 ?? snapshot.data ?? 0.1;

                            int getSignificantDecimals(double value) {
                              final parts = value.toString().split('.');
                              return parts.length > 1
                                  ? parts[1]
                                      .replaceAll(RegExp(r'0+$'), '')
                                      .length
                                  : 0;
                            }

                            final decimalPlaces = getSignificantDecimals(d1);

                            String formatValue(double value) =>
                                value.toStringAsFixed(decimalPlaces);

                            return TextFormField(
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d*\.?\d*'))
                              ],
                              controller: indicacionController,
                              decoration: _buildInputDecoration(
                                'Indicación ${index + 1}',
                                suffixIcon: PopupMenuButton<String>(
                                  icon: const Icon(Icons.arrow_drop_down),
                                  onSelected: (newValue) {
                                    setState(() {
                                      indicacionController!.text = newValue;
                                    });
                                  },
                                  itemBuilder: (context) {
                                    final baseValue = indicacionController!
                                            .text.isNotEmpty
                                        ? double.tryParse(
                                                indicacionController.text) ??
                                            0.0
                                        : 0.0;

                                    return List.generate(11, (index) {
                                      final multiplier = index - 5;
                                      final value =
                                          baseValue + (multiplier * d1);
                                      return PopupMenuItem<String>(
                                        value: formatValue(value),
                                        child: Text(formatValue(value)),
                                      );
                                    });
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d*'))
                          ],
                          controller: _rows[index]['retorno'],
                          decoration:
                              _buildInputDecoration('Retorno ${index + 1}'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: _areAllFieldsFilled() ? _calculateAllDifferences : null,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          child: const Text('Calcular Diferencias'),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        top: kToolbarHeight + MediaQuery.of(context).padding.top - 25,
        left: 16.0,
        right: 16.0,
        bottom: 16.0,
      ),
      child: Column(
        children: [
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              text: 'PRUEBAS DE ',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
              ),
              children: const <TextSpan>[
                TextSpan(
                  text: 'LINEALIDAD',
                  style: TextStyle(color: Colors.lightBlueAccent),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20.0),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '1. ELIJA EL MÉTODO A APLICAR:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 10.0),
          DropdownButtonFormField<String>(
            decoration: _buildInputDecoration('Método'),
            items: _metodoOptions.map((String metodo) {
              return DropdownMenuItem<String>(
                value: metodo,
                child: Text(metodo),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _selectedMetodo = newValue;
              });
            },
          ),
          const SizedBox(height: 20.0),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '2. SELECCIONE EL MÉTODO DE CARGAS SUSTITUTIVAS:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 10.0),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white70
                    : Colors.black,
                size: 16.0,
              ),
              const SizedBox(width: 8.0),
              Expanded(
                child: Text(
                  'Puede seleccionar el método 1 o 2 según el criterio del Técnico responsable, si no selecciona un método y solo ingresa las cargas, podra guardar los datos con normalidad.',
                  style: TextStyle(
                    fontSize: 12.0,
                    fontWeight: FontWeight.w400,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white70
                        : Colors.black,
                  ),
                ),
              )
            ],
          ),
          const SizedBox(height: 15.0),
          DropdownButtonFormField<String>(
            decoration: _buildInputDecoration('Método de Carga'),
            items: _metodocargaOptions.map((String metodo) {
              return DropdownMenuItem<String>(
                value: metodo,
                child: Text(metodo),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _selectedMetodoCarga = newValue;
              });
            },
          ),
          const SizedBox(height: 10.0),
          Visibility(
            visible: _selectedMetodoCarga == 'Método 2',
            child: Column(
              children: [
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d*'))
                        ],
                        controller: _iLsubnController,
                        decoration: _buildInputDecoration('I(Lsubn)'),
                        onChanged: (value) {
                          final iLsubn = double.tryParse(value) ?? 0.0;
                          double closestLt = double.infinity;
                          double closestDifference = 0.0;

                          for (var row in _rows) {
                            final lt =
                                double.tryParse(row['lt']?.text ?? '') ?? 0.0;
                            final indicacion = double.tryParse(
                                    row['indicacion']?.text ?? '') ??
                                0.0;
                            final difference = indicacion - lt;

                            if ((iLsubn - lt).abs() <
                                (iLsubn - closestLt).abs()) {
                              closestLt = lt;
                              closestDifference = difference;
                            }
                          }

                          final lsubn = iLsubn - closestDifference;
                          _lsubnController.text = lsubn.toString();

                          if (_rows.isNotEmpty &&
                              (_rows[0]['lt']?.text.isEmpty ?? true)) {
                            _ltnController.text = (lsubn + 500).toString();
                          } else {
                            final lastLt =
                                double.tryParse(_rows.last['lt']?.text ?? '') ??
                                    0.0;
                            _ltnController.text = (lsubn + lastLt).toString();
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _lsubnController,
                        keyboardType: TextInputType.number,
                        decoration: _buildInputDecoration('Lsubn'),
                        readOnly: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _ioController,
                        keyboardType: TextInputType.number,
                        decoration: _buildInputDecoration('Io'),
                        onChanged: (value) {
                          final cp = double.tryParse(_cpController.text) ?? 0.0;
                          final lsubn =
                              double.tryParse(_lsubnController.text) ?? 0.0;
                          final io = double.tryParse(value) ?? 0.0;

                          final ltn = (cp + lsubn) - io;
                          _ltnController.text = ltn.toString();
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _ltnController,
                        keyboardType: TextInputType.number,
                        decoration: _buildInputDecoration('LTn'),
                        readOnly: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    _saveLtnToNewRow();
                    _iLsubnController.clear();
                    _lsubnController.clear();
                    _ioController.clear();
                    _ltnController.clear();
                  },
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: const Text('Guardar LTn'),
                )
              ],
            ),
          ),
          const SizedBox(height: 10.0),
          Visibility(
            visible: _selectedMetodoCarga == 'Método 1',
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: _saveData,
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: const Text('Guardar Datos'),
                  ),
                ),
                const SizedBox(height: 10.0),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d*'))
                        ],
                        controller: _ltnController,
                        decoration: _buildInputDecoration('LTn'),
                        onChanged: (value) => _calculateLsubn(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d*'))
                        ],
                        controller: _iLtnController,
                        decoration: _buildInputDecoration('I(LTn)'),
                        onChanged: (value) => _calculateLsubn(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _iLsubnController,
                        decoration: _buildInputDecoration('I(Lsubn)'),
                        keyboardType: TextInputType.number,
                        onChanged: (value) => _calculateLsubn(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _lsubnController,
                        decoration: _buildInputDecoration('Lsubn'),
                        readOnly: true,
                        style: const TextStyle(color: Colors.lightGreen),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20.0),
          const Align(
            alignment: Alignment.center,
            child: Text(
              'CARGA DE PESAS E INDICACIÓN',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 10.0),
          _buildCalibrationForm(context),
          const SizedBox(height: 10.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: _addRow,
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text('Agregar Fila'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              ),
              ElevatedButton.icon(
                onPressed: () => _removeRow(_rows.length - 1),
                icon: const Icon(Icons.remove, color: Colors.white),
                label: const Text('Eliminar Fila'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              ),
            ],
          ),
          const SizedBox(height: 10.0),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info, color: Colors.yellow, size: 16.0),
              const SizedBox(width: 8.0),
              Expanded(
                child: Text(
                  'El técnico responsable puede agregar hasta 60 filas de LT e INDICACIÓN, no puede eliminar las primeras 6 filas.',
                  style: TextStyle(
                    fontSize: 12.0,
                    fontWeight: FontWeight.w400,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white70
                        : Colors.black,
                  ),
                ),
              )
            ],
          ),
          const SizedBox(height: 20.0),
          ElevatedButton(
            onPressed: _saveDataToDatabase,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            child: const Text('GUARDAR DATOS DE LINEALIDAD'),
          ),
          const SizedBox(height: 8.0),
          ValueListenableBuilder<bool>(
            valueListenable: widget.isDataSaved,
            builder: (context, isSaved, child) {
              return Text(
                isSaved
                    ? 'Datos de linealidad guardados correctamente'
                    : 'Guarde los datos antes de continuar',
                style: TextStyle(
                  fontSize: 12.0,
                  color: isSaved ? Colors.green : Colors.grey,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
