import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../provider/balanza_provider.dart';
import '../servicio_controller.dart';

class RepetibilidadStep extends StatefulWidget {
  final String dbName;
  final String secaValue;
  final String codMetrica;

  const RepetibilidadStep({
    Key? key,
    required this.dbName,
    required this.secaValue,
    required this.codMetrica,
  }) : super(key: key);

  @override
  State<RepetibilidadStep> createState() => _RepetibilidadStepState();
}

class _RepetibilidadStepState extends State<RepetibilidadStep> {
  final List<TextEditingController> _cargaControllers = [];
  final List<List<TextEditingController>> _indicacionControllers = [];
  final List<List<TextEditingController>> _retornoControllers = [];

  final TextEditingController _pmax1Controller = TextEditingController();
  final TextEditingController _pmaxCalculoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeControllers();
      _fetchPmax1Data();
    });
  }

  void _initializeControllers() {
    final controller = Provider.of<ServicioController>(context, listen: false);

    // Inicializar controladores de carga
    for (int i = 0; i < controller.selectedRepetibilityCount; i++) {
      _cargaControllers.add(TextEditingController());
    }

    // Inicializar controladores de indicación y retorno
    for (int carga = 0; carga < controller.selectedRepetibilityCount; carga++) {
      List<TextEditingController> cargaIndicaciones = [];
      List<TextEditingController> cargaRetornos = [];

      for (int fila = 0; fila < controller.selectedRowCount; fila++) {
        cargaIndicaciones.add(TextEditingController(
            text: controller.repetibilidadData[carga][fila]['indicacion'] ?? ''
        ));
        cargaRetornos.add(TextEditingController(
            text: controller.repetibilidadData[carga][fila]['retorno'] ?? '0'
        ));
      }

      _indicacionControllers.add(cargaIndicaciones);
      _retornoControllers.add(cargaRetornos);
    }
  }

  Future<void> _fetchPmax1Data() async {
    final balanza = Provider.of<BalanzaProvider>(context, listen: false).selectedBalanza;
    if (balanza != null) {
      final pmax1 = double.tryParse(balanza.cap_max1) ?? 0.0;
      final fiftyPercentPmax1 = pmax1 * 0.5;
      setState(() {
        _pmax1Controller.text = pmax1.toStringAsFixed(2);
        _pmaxCalculoController.text = fiftyPercentPmax1.toStringAsFixed(2);
      });
    }
  }

  @override
  void dispose() {
    _cargaControllers.forEach((c) => c.dispose());
    _indicacionControllers.forEach((lista) => lista.forEach((c) => c.dispose()));
    _retornoControllers.forEach((lista) => lista.forEach((c) => c.dispose()));
    _pmax1Controller.dispose();
    _pmaxCalculoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ServicioController>(
      builder: (context, controller, child) {
        return SingleChildScrollView(
          child: Column(
            children: [
              // Título
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
                      text: 'REPETIBILIDAD',
                      style: TextStyle(color: Colors.green),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 600.ms),

              const SizedBox(height: 30),

              // Selectores de configuración
              _buildConfigurationSection(controller),

              const SizedBox(height: 30),

              // Datos de pmax1
              _buildPmaxSection(controller),

              const SizedBox(height: 30),

              // Sección de cargas y pruebas
              _buildCargasSection(controller),

              const SizedBox(height: 30),

              // Botón para guardar
              _buildSaveButton(controller),
            ],
          ),
        );
      },
    );
  }

  Widget _buildConfigurationSection(ServicioController controller) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<int>(
                value: controller.selectedRepetibilityCount,
                decoration: _buildInputDecoration('Cantidad de Cargas'),
                items: [1, 2, 3].map((int value) {
                  return DropdownMenuItem<int>(
                    value: value,
                    child: Text(value.toString()),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    _updateControllersForNewConfig(controller, value, controller.selectedRowCount);
                    controller.setSelectedRepetibilityCount(value);
                  }
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DropdownButtonFormField<int>(
                value: controller.selectedRowCount,
                decoration: _buildInputDecoration('Cantidad de Pruebas'),
                items: [3, 5, 10].map((int value) {
                  return DropdownMenuItem<int>(
                    value: value,
                    child: Text(value.toString()),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    _updateControllersForNewConfig(controller, controller.selectedRepetibilityCount, value);
                    controller.setSelectedRowCount(value);
                  }
                },
              ),
            ),
          ],
        ),
      ],
    ).animate(delay: 200.ms).fadeIn().slideY(begin: -0.3);
  }

  void _updateControllersForNewConfig(ServicioController controller, int cargas, int pruebas) {
    // Actualizar controladores de carga
    while (_cargaControllers.length < cargas) {
      _cargaControllers.add(TextEditingController());
    }
    while (_cargaControllers.length > cargas) {
      _cargaControllers.removeLast().dispose();
    }

    // Actualizar controladores de indicación y retorno
    while (_indicacionControllers.length < cargas) {
      _indicacionControllers.add([]);
    }
    while (_indicacionControllers.length > cargas) {
      _indicacionControllers.removeLast().forEach((c) => c.dispose());
    }

    for (int carga = 0; carga < cargas; carga++) {
      while (_indicacionControllers[carga].length < pruebas) {
        _indicacionControllers[carga].add(TextEditingController());
      }
      while (_indicacionControllers[carga].length > pruebas) {
        _indicacionControllers[carga].removeLast().dispose();
      }

      if (_retornoControllers.length <= carga) {
        _retornoControllers.add([]);
      }
      while (_retornoControllers[carga].length < pruebas) {
        _retornoControllers[carga].add(TextEditingController(text: '0'));
      }
      while (_retornoControllers[carga].length > pruebas) {
        _retornoControllers[carga].removeLast().dispose();
      }
    }
  }

  Widget _buildPmaxSection(ServicioController controller) {
    return Row(
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
    ).animate(delay: 300.ms).fadeIn().slideX(begin: -0.3);
  }

  Widget _buildCargasSection(ServicioController controller) {
    return Column(
      children: List.generate(controller.selectedRepetibilityCount, (cargaIndex) {
        return Column(
          children: [
            Text(
              'CARGA ${cargaIndex + 1}',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ).animate(delay: (400 + cargaIndex * 100).ms).fadeIn().slideX(begin: -0.3),

            const SizedBox(height: 10),

            TextFormField(
              controller: _cargaControllers[cargaIndex],
              decoration: _buildInputDecoration('Valor de Carga ${cargaIndex + 1}'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              onChanged: (value) {
                // Auto-rellenar todas las indicaciones de esta carga
                for (int fila = 0; fila < controller.selectedRowCount; fila++) {
                  if (_indicacionControllers[cargaIndex][fila].text.isEmpty) {
                    _indicacionControllers[cargaIndex][fila].text = value;
                    controller.updateRepetibilidadData(cargaIndex, fila, 'indicacion', value);
                  }
                }
              },
            ).animate(delay: (500 + cargaIndex * 100).ms).fadeIn().slideX(begin: 0.3),

            const SizedBox(height: 20),

            // Lista de pruebas para esta carga
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: controller.selectedRowCount,
              itemBuilder: (context, filaIndex) {
                return _buildPruebaRow(controller, cargaIndex, filaIndex);
              },
            ),

            const SizedBox(height: 30),
          ],
        );
      }),
    );
  }

  Widget _buildPruebaRow(ServicioController controller, int cargaIndex, int filaIndex) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: FutureBuilder<double>(
                  future: controller.getD1FromDatabase(),
                  builder: (context, snapshot) {
                    final balanza = Provider.of<BalanzaProvider>(context, listen: false).selectedBalanza;
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
                      controller: _indicacionControllers[cargaIndex][filaIndex],
                      decoration: _buildInputDecoration(
                        'Indicación ${filaIndex + 1}',
                        suffixIcon: PopupMenuButton<String>(
                          icon: const Icon(Icons.arrow_drop_down),
                          onSelected: (String newValue) {
                            setState(() {
                              _indicacionControllers[cargaIndex][filaIndex].text = newValue;
                            });
                            controller.updateRepetibilidadData(cargaIndex, filaIndex, 'indicacion', newValue);
                          },
                          itemBuilder: (BuildContext context) {
                            final baseValue = double.tryParse(
                                _indicacionControllers[cargaIndex][filaIndex].text) ??
                                0.0;

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
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                      ],
                      onChanged: (value) {
                        controller.updateRepetibilidadData(cargaIndex, filaIndex, 'indicacion', value);
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Ingrese un valor';
                        if (double.tryParse(value) == null) return 'Valor numérico inválido';
                        return null;
                      },
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: _retornoControllers[cargaIndex][filaIndex],
                  decoration: _buildInputDecoration('Retorno ${filaIndex + 1}'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  onChanged: (value) {
                    controller.updateRepetibilidadData(cargaIndex, filaIndex, 'retorno', value);
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Ingrese un valor';
                    if (double.tryParse(value) == null) return 'Valor numérico inválido';
                    return null;
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate(delay: (600 + cargaIndex * 100 + filaIndex * 50).ms)
        .fadeIn()
        .slideX(begin: filaIndex % 2 == 0 ? -0.3 : 0.3);
  }

  Widget _buildSaveButton(ServicioController controller) {
    return Container(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () async {
          try {
            await controller.saveCurrentStepData();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Datos de repetibilidad guardados correctamente'),
                backgroundColor: Colors.green,
              ),
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error al guardar: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'GUARDAR REPETIBILIDAD',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ).animate(delay: 800.ms).fadeIn().slideY(begin: 0.3);
  }

  InputDecoration _buildInputDecoration(String labelText, {Widget? suffixIcon}) {
    return InputDecoration(
      labelText: labelText,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      suffixIcon: suffixIcon,
    );
  }
}