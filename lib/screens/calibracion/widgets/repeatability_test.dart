import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../provider/balanza_provider.dart';
import '../services/calibration_service.dart';

class RepeatabilityTest extends StatefulWidget {
  final CalibrationService calibrationService;
  final ValueNotifier<bool> isDataSaved;

  const RepeatabilityTest({
    super.key,
    required this.calibrationService,
    required this.isDataSaved,
  });

  @override
  _RepeatabilityTestState createState() => _RepeatabilityTestState();
}

class _RepeatabilityTestState extends State<RepeatabilityTest> {
  final TextEditingController _pmax1Controller = TextEditingController();
  final TextEditingController _pmaxCalculoController = TextEditingController();

  final TextEditingController repetibilidadController1 = TextEditingController();
  final TextEditingController repetibilidadController2 = TextEditingController();
  final TextEditingController repetibilidadController3 = TextEditingController();

  final List<TextEditingController> indicacionControllers1 =
  List.generate(10, (index) => TextEditingController());
  final List<TextEditingController> retornoControllers1 =
  List.generate(10, (index) => TextEditingController(text: '0'));
  final List<TextEditingController> indicacionControllers2 =
  List.generate(10, (index) => TextEditingController());
  final List<TextEditingController> retornoControllers2 =
  List.generate(10, (index) => TextEditingController(text: '0'));
  final List<TextEditingController> indicacionControllers3 =
  List.generate(10, (index) => TextEditingController());
  final List<TextEditingController> retornoControllers3 =
  List.generate(10, (index) => TextEditingController(text: '0'));

  int _selectedRepetibilityCount = 3;
  int _selectedRowCount = 3;

  @override
  void initState() {
    super.initState();
    _loadPmax1Data();
  }

  Future<void> _loadPmax1Data() async {
    final pmax1 = await widget.calibrationService.getPmax1Value();
    final pmaxCalculo = pmax1 * 0.5;

    setState(() {
      _pmax1Controller.text = pmax1.toStringAsFixed(2);
      _pmaxCalculoController.text = pmaxCalculo.toStringAsFixed(2);
    });
  }

  void _updateIndicacionValues(String value) {
    if (value.isEmpty) return;
    setState(() {
      for (var controller in indicacionControllers1) {
        controller.text = value;
      }
    });
  }

  void _updateIndicacionValues2(String value) {
    if (value.isEmpty) return;
    setState(() {
      for (var controller in indicacionControllers2) {
        controller.text = value;
      }
    });
  }

  void _updateIndicacionValues3(String value) {
    if (value.isEmpty) return;
    setState(() {
      for (var controller in indicacionControllers3) {
        controller.text = value;
      }
    });
  }

  Future<void> _saveDataToDatabase() async {
    // Validar campos de repetibilidad
    for (int i = 0; i < _selectedRowCount; i++) {
      if (indicacionControllers1[i].text.isEmpty) {
        _showSnackBar('Ingrese la medición ${i + 1}', isError: true);
        return;
      }
      if (retornoControllers1[i].text.isEmpty) {
        _showSnackBar('Ingrese el retorno ${i + 1}', isError: true);
        return;
      }
    }

    try {
      final registro = {
        'rep1': indicacionControllers1[0].text,
        'rep_ret1': retornoControllers1[0].text,
        'rep2': indicacionControllers1[1].text,
        'rep_ret2': retornoControllers1[1].text,
        'rep3': indicacionControllers1[2].text,
        'rep_ret3': retornoControllers1[2].text,
        'rep4': _selectedRowCount > 3 ? indicacionControllers1[3].text : '',
        'rep_ret4': _selectedRowCount > 3 ? retornoControllers1[3].text : '',
        'rep5': _selectedRowCount > 4 ? indicacionControllers1[4].text : '',
        'rep_ret5': _selectedRowCount > 4 ? retornoControllers1[4].text : '',
      };

      await widget.calibrationService.saveRepeatabilityData(registro);

      widget.isDataSaved.value = true;
      _showSnackBar('Datos de repetibilidad guardados correctamente');
    } catch (e) {
      _showSnackBar('Error al guardar repetibilidad: $e', isError: true);
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

  InputDecoration _buildInputDecoration(String labelText, {Widget? suffixIcon, String? suffixText}) {
    return InputDecoration(
      labelText: labelText,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20.0)),
      suffixIcon: suffixIcon,
      suffixText: suffixText,
    );
  }

  @override
  Widget build(BuildContext context) {
    final balanza = Provider.of<BalanzaProvider>(context).selectedBalanza;

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        top: kToolbarHeight + MediaQuery.of(context).padding.top -25,
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
                    ? Colors.white : Colors.black,
              ),
              children: const <TextSpan>[
                TextSpan(
                  text: 'REPETIBILIDAD',
                  style: TextStyle(color: Colors.greenAccent),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<int>(
            value: _selectedRepetibilityCount,
            items: [1, 2, 3].map((int value) => DropdownMenuItem<int>(
              value: value,
              child: Text(value.toString()),
            )).toList(),
            onChanged: (value) {
              setState(() {
                _selectedRepetibilityCount = value ?? 1;
              });
            },
            decoration: _buildInputDecoration('Seleccione la cantidad de Cargas'),
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<int>(
            value: _selectedRowCount,
            items: [3, 5, 10].map((int value) => DropdownMenuItem<int>(
              value: value,
              child: Text(value.toString()),
            )).toList(),
            onChanged: (value) {
              setState(() {
                _selectedRowCount = value ?? 3;
              });
            },
            decoration: _buildInputDecoration('Seleccione la cantidad de Pruebas'),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _pmax1Controller,
                  decoration: _buildInputDecoration('pmax1'),
                  readOnly: true,
                  style: const TextStyle(color: Colors.yellow),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: _pmaxCalculoController,
                  decoration: _buildInputDecoration('50% de pmax1'),
                  readOnly: true,
                  style: const TextStyle(color: Colors.lightGreen),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_selectedRepetibilityCount >= 1) ...[
            const Text(
              'CARGA 1',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            TextFormField(
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
              controller: repetibilidadController1,
              decoration: _buildInputDecoration('CARGA 1'),
              onChanged: _updateIndicacionValues,
            ),
            const SizedBox(height: 20),
            for (int i = 0; i < _selectedRowCount; i++)
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: FutureBuilder<double>(
                          future: widget.calibrationService.getD1Value(),
                          builder: (context, snapshot) {
                            final d1 = balanza?.d1 ?? snapshot.data ?? 0.1;

                            int getSignificantDecimals(double value) {
                              final text = value.toString();
                              if (text.contains('.')) {
                                return text.split('.')[1].replaceAll(RegExp(r'0+$'), '').length;
                              }
                              return 0;
                            }

                            final decimalPlaces = getSignificantDecimals(d1);

                            return TextFormField(
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                              controller: indicacionControllers1[i],
                              decoration: _buildInputDecoration(
                                'Indicación ${i + 1}',
                                suffixIcon: PopupMenuButton<String>(
                                  icon: const Icon(Icons.arrow_drop_down),
                                  onSelected: (String newValue) {
                                    setState(() => indicacionControllers1[i].text = newValue);
                                  },
                                  itemBuilder: (BuildContext context) {
                                    final baseValue = double.tryParse(indicacionControllers1[i].text) ?? 0.0;

                                    return List.generate(11, (index) {
                                      final multiplier = index - 5;
                                      final value = baseValue + (multiplier * d1);
                                      final formattedValue = value.toStringAsFixed(decimalPlaces);

                                      return PopupMenuItem<String>(
                                        value: formattedValue,
                                        child: Text(formattedValue),
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
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                          controller: retornoControllers1[i],
                          decoration: _buildInputDecoration('Retorno ${i + 1}'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            const SizedBox(height: 10),
          ],
          if (_selectedRepetibilityCount >= 2) ...[
            const Text(
              'CARGA 2',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            TextFormField(
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
              controller: repetibilidadController2,
              decoration: _buildInputDecoration('CARGA 2'),
              onChanged: _updateIndicacionValues2,
            ),
            const SizedBox(height: 20),
            for (int i = 0; i < _selectedRowCount; i++)
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: FutureBuilder<double>(
                          future: widget.calibrationService.getD1Value(),
                          builder: (context, snapshot) {
                            final d1 = balanza?.d1 ?? snapshot.data ?? 0.1;

                            int getSignificantDecimals(double value) {
                              final text = value.toString();
                              if (text.contains('.')) {
                                return text.split('.')[1].replaceAll(RegExp(r'0+$'), '').length;
                              }
                              return 0;
                            }

                            final decimalPlaces = getSignificantDecimals(d1);

                            return TextFormField(
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                              controller: indicacionControllers2[i],
                              decoration: _buildInputDecoration(
                                'Indicación ${i + 1}',
                                suffixIcon: PopupMenuButton<String>(
                                  icon: const Icon(Icons.arrow_drop_down),
                                  onSelected: (String newValue) {
                                    setState(() => indicacionControllers2[i].text = newValue);
                                  },
                                  itemBuilder: (BuildContext context) {
                                    final baseValue = double.tryParse(indicacionControllers2[i].text) ?? 0.0;

                                    return List.generate(11, (index) {
                                      final multiplier = index - 5;
                                      final value = baseValue + (multiplier * d1);
                                      final formattedValue = value.toStringAsFixed(decimalPlaces);

                                      return PopupMenuItem<String>(
                                        value: formattedValue,
                                        child: Text(formattedValue),
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
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                          controller: retornoControllers2[i],
                          decoration: _buildInputDecoration('Retorno ${i + 1}'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            const SizedBox(height: 10),
          ],
          if (_selectedRepetibilityCount == 3) ...[
            const Text(
              'CARGA 3',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            TextFormField(
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
              controller: repetibilidadController3,
              decoration: _buildInputDecoration('CARGA 3'),
              onChanged: _updateIndicacionValues3,
            ),
            const SizedBox(height: 20),
            for (int i = 0; i < _selectedRowCount; i++)
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: FutureBuilder<double>(
                          future: widget.calibrationService.getD1Value(),
                          builder: (context, snapshot) {
                            final d1 = balanza?.d1 ?? snapshot.data ?? 0.1;

                            int getSignificantDecimals(double value) {
                              final text = value.toString();
                              if (text.contains('.')) {
                                return text.split('.')[1].replaceAll(RegExp(r'0+$'), '').length;
                              }
                              return 0;
                            }

                            final decimalPlaces = getSignificantDecimals(d1);

                            return TextFormField(
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                              controller: indicacionControllers3[i],
                              decoration: _buildInputDecoration(
                                'Indicación ${i + 1}',
                                suffixIcon: PopupMenuButton<String>(
                                  icon: const Icon(Icons.arrow_drop_down),
                                  onSelected: (String newValue) {
                                    setState(() => indicacionControllers3[i].text = newValue);
                                  },
                                  itemBuilder: (BuildContext context) {
                                    final baseValue = double.tryParse(indicacionControllers3[i].text) ?? 0.0;

                                    return List.generate(11, (index) {
                                      final multiplier = index - 5;
                                      final value = baseValue + (multiplier * d1);
                                      final formattedValue = value.toStringAsFixed(decimalPlaces);

                                      return PopupMenuItem<String>(
                                        value: formattedValue,
                                        child: Text(formattedValue),
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
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                          controller: retornoControllers3[i],
                          decoration: _buildInputDecoration('Retorno ${i + 1}'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              ),
          ],
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: _saveDataToDatabase,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            child: const Text('GUARDAR DATOS DE REPETIBILIDAD'),
          ),
          const SizedBox(height: 8.0),
          ValueListenableBuilder<bool>(
            valueListenable: widget.isDataSaved,
            builder: (context, isSaved, child) {
              return Text(
                isSaved
                    ? 'Datos de repetibilidad guardados correctamente'
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