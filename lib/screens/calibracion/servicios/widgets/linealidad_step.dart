import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../provider/balanza_provider.dart';
import '../servicio_controller.dart';

class LinealidadStep extends StatefulWidget {
  final String dbName;
  final String secaValue;
  final String codMetrica;

  const LinealidadStep({
    Key? key,
    required this.dbName,
    required this.secaValue,
    required this.codMetrica,
  }) : super(key: key);

  @override
  State<LinealidadStep> createState() => _LinealidadStepState();
}

class _LinealidadStepState extends State<LinealidadStep> {
  final List<TextEditingController> _ltControllers = [];
  final List<TextEditingController> _indicacionControllers = [];
  final List<TextEditingController> _retornoControllers = [];
  final List<TextEditingController> _diferenciaControllers = [];

  final TextEditingController _iLsubnController = TextEditingController();
  final TextEditingController _lsubnController = TextEditingController();
  final TextEditingController _ioController = TextEditingController(text: '0');
  final TextEditingController _ltnController = TextEditingController();
  final TextEditingController _iLtnController = TextEditingController();
  final TextEditingController _cpController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeControllers();
    });
  }

  void _initializeControllers() {
    final controller = Provider.of<ServicioController>(context, listen: false);

    for (int i = 0; i < controller.linealidadRows.length; i++) {
      _ltControllers.add(TextEditingController(
          text: controller.linealidadRows[i]['lt'] ?? ''
      ));
      _indicacionControllers.add(TextEditingController(
          text: controller.linealidadRows[i]['indicacion'] ?? ''
      ));
      _retornoControllers.add(TextEditingController(
          text: controller.linealidadRows[i]['retorno'] ?? '0'
      ));
      _diferenciaControllers.add(TextEditingController(
          text: controller.linealidadRows[i]['difference'] ?? ''
      ));
    }
  }

  @override
  void dispose() {
    _ltControllers.forEach((c) => c.dispose());
    _indicacionControllers.forEach((c) => c.dispose());
    _retornoControllers.forEach((c) => c.dispose());
    _diferenciaControllers.forEach((c) => c.dispose());
    _iLsubnController.dispose();
    _lsubnController.dispose();
    _ioController.dispose();
    _ltnController.dispose();
    _iLtnController.dispose();
    _cpController.dispose();
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
                      text: 'LINEALIDAD',
                      style: TextStyle(color: Colors.blue),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 600.ms),

              const SizedBox(height: 30),

              // Selección de método
              _buildMetodoSection(controller),

              const SizedBox(height: 30),

              // Método de carga seleccionado
              if (controller.selectedMetodoCarga != null)
                _buildMetodoCargaSection(controller),

              const SizedBox(height: 30),

              // Tabla de linealidad
              _buildLinealidadTable(controller),

              const SizedBox(height: 20),

              // Controles de tabla
              _buildTableControls(controller),

              const SizedBox(height: 30),

              // Botón para guardar
              _buildSaveButton(controller),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetodoSection(ServicioController controller) {
    return Column(
      children: [
        Text(
          '1. SELECCIÓN DEL MÉTODO',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ).animate(delay: 200.ms).fadeIn().slideX(begin: -0.3),

        const SizedBox(height: 20),

        DropdownButtonFormField<String>(
          value: controller.selectedMetodoLinealidad,
          decoration: _buildInputDecoration('Método de Linealidad'),
          items: controller.metodosLinealidad.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (String? newValue) {
            controller.setSelectedMetodoLinealidad(newValue!);
          },
        ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.3),

        const SizedBox(height: 20),

        DropdownButtonFormField<String>(
          value: controller.selectedMetodoCarga,
          decoration: _buildInputDecoration('Método de Carga'),
          items: controller.metodoCargaOptions.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (String? newValue) {
            controller.setSelectedMetodoCarga(newValue!);
          },
        ).animate(delay: 400.ms).fadeIn().slideX(begin: 0.3),
      ],
    );
  }

  Widget _buildMetodoCargaSection(ServicioController controller) {
    if (controller.selectedMetodoCarga == 'Método 1') {
      return _buildMetodo1Section(controller);
    } else if (controller.selectedMetodoCarga == 'Método 2') {
      return _buildMetodo2Section(controller);
    }
    return const SizedBox();
  }

  Widget _buildMetodo1Section(ServicioController controller) {
    return Column(
      children: [
        Text(
          'MÉTODO 1 - CÁLCULOS',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ).animate(delay: 500.ms).fadeIn().slideX(begin: -0.3),

        const SizedBox(height: 20),

        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _ltnController,
                decoration: _buildInputDecoration('LTn'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                onChanged: (value) {
                  _calculateLsubn();
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: _iLtnController,
                decoration: _buildInputDecoration('I(LTn)'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                onChanged: (value) {
                  _calculateLsubn();
                },
              ),
            ),
          ],
        ).animate(delay: 600.ms).fadeIn().slideY(begin: 0.3),

        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _iLsubnController,
                decoration: _buildInputDecoration('I(Lsubn)'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                onChanged: (value) {
                  _calculateLsubn();
                },
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
        ).animate(delay: 700.ms).fadeIn().slideX(begin: 0.3),

        const SizedBox(height: 10),

        ElevatedButton(
          onPressed: _saveLtnToRow,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          child: const Text('Agregar LTn a la tabla'),
        ).animate(delay: 800.ms).fadeIn().scale(),
      ],
    );
  }

  Widget _buildMetodo2Section(ServicioController controller) {
    return Column(
      children: [
        Text(
          'MÉTODO 2 - CÁLCULOS',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ).animate(delay: 500.ms).fadeIn().slideX(begin: -0.3),

        const SizedBox(height: 20),

        TextFormField(
          controller: _iLsubnController,
          decoration: _buildInputDecoration('I(Lsubn)'),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
          ],
          onChanged: (value) {
            _calculateMetodo2();
          },
        ).animate(delay: 600.ms).fadeIn().slideY(begin: 0.3),

        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _lsubnController,
                decoration: _buildInputDecoration('Lsubn'),
                readOnly: true,
                style: const TextStyle(color: Colors.lightGreen),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: _ioController,
                decoration: _buildInputDecoration('Io'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                onChanged: (value) {
                  _calculateMetodo2();
                },
              ),
            ),
          ],
        ).animate(delay: 700.ms).fadeIn().slideX(begin: 0.3),

        const SizedBox(height: 10),

        TextFormField(
          controller: _ltnController,
          decoration: _buildInputDecoration('LTn'),
          readOnly: true,
          style: const TextStyle(color: Colors.orange),
        ).animate(delay: 800.ms).fadeIn().slideY(begin: 0.3),

        const SizedBox(height: 10),

        ElevatedButton(
          onPressed: _saveLtnToRow,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
          child: const Text('Guardar LTn en tabla'),
        ).animate(delay: 900.ms).fadeIn().scale(),
      ],
    );
  }

  void _calculateLsubn() {
    final ltn = double.tryParse(_ltnController.text) ?? 0.0;
    final iLtn = double.tryParse(_iLtnController.text) ?? 0.0;
    final iLsubn = double.tryParse(_iLsubnController.text) ?? 0.0;

    final difference = ltn - iLtn;
    final lsubn = iLsubn + difference;

    _lsubnController.text = lsubn.toStringAsFixed(2);
  }

  void _calculateMetodo2() {
    final iLsubn = double.tryParse(_iLsubnController.text) ?? 0.0;
    final io = double.tryParse(_ioController.text) ?? 0.0;

    // Encontrar el LT más cercano en la tabla
    double closestLt = double.infinity;
    double closestDifference = 0.0;

    for (int i = 0; i < _ltControllers.length; i++) {
      final lt = double.tryParse(_ltControllers[i].text) ?? 0.0;
      final indicacion = double.tryParse(_indicacionControllers[i].text) ?? 0.0;
      final difference = indicacion - lt;

      if ((iLsubn - lt).abs() < (iLsubn - closestLt).abs()) {
        closestLt = lt;
        closestDifference = difference;
      }
    }

    final lsubn = iLsubn - closestDifference;
    _lsubnController.text = lsubn.toStringAsFixed(2);

    final cp = double.tryParse(_cpController.text) ?? 0.0;
    final ltn = (cp + lsubn) - io;
    _ltnController.text = ltn.toStringAsFixed(2);
  }

  void _saveLtnToRow() {
    if (_ltnController.text.isNotEmpty) {
      final controller = Provider.of<ServicioController>(context, listen: false);
      controller.addLinealidadRow();
      final newIndex = controller.linealidadRows.length - 1;

      _ltControllers.add(TextEditingController(text: _ltnController.text));
      _indicacionControllers.add(TextEditingController());
      _retornoControllers.add(TextEditingController(text: '0'));
      _diferenciaControllers.add(TextEditingController());

      controller.updateLinealidadRow(newIndex, 'lt', _ltnController.text);

      // Limpiar campos después de guardar
      _iLsubnController.clear();
      _lsubnController.clear();
      _ioController.clear();
      _ltnController.clear();
      _iLtnController.clear();

      setState(() {});
    }
  }

  Widget _buildLinealidadTable(ServicioController controller) {
    return Column(
      children: [
        Text(
          'REGISTRO DE LINEALIDAD',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ).animate(delay: 1000.ms).fadeIn().slideX(begin: -0.3),

        const SizedBox(height: 20),

        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: controller.linealidadRows.length,
          itemBuilder: (context, index) {
            return _buildLinealidadRow(controller, index);
          },
        ),
      ],
    );
  }

  Widget _buildLinealidadRow(ServicioController controller, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _ltControllers[index],
                  decoration: _buildInputDecoration('LT ${index + 1}'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  onChanged: (value) {
                    controller.updateLinealidadRow(index, 'lt', value);
                    // Auto-sincronizar con indicación
                    if (_indicacionControllers[index].text.isEmpty) {
                      _indicacionControllers[index].text = value;
                      controller.updateLinealidadRow(index, 'indicacion', value);
                    }
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Ingrese valor';
                    if (double.tryParse(value) == null) return 'Número inválido';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: _diferenciaControllers[index],
                  decoration: _buildInputDecoration('Diferencia'),
                  readOnly: true,
                  style: const TextStyle(color: Colors.orange),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
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
                      controller: _indicacionControllers[index],
                      decoration: _buildInputDecoration(
                        'Indicación ${index + 1}',
                        suffixIcon: PopupMenuButton<String>(
                          icon: const Icon(Icons.arrow_drop_down),
                          onSelected: (String newValue) {
                            setState(() {
                              _indicacionControllers[index].text = newValue;
                            });
                            controller.updateLinealidadRow(index, 'indicacion', newValue);
                            _calculateDifference(index);
                          },
                          itemBuilder: (BuildContext context) {
                            final baseValue = double.tryParse(_indicacionControllers[index].text) ?? 0.0;

                            return List.generate(11, (i) {
                              final multiplier = i - 5;
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
                        controller.updateLinealidadRow(index, 'indicacion', value);
                        _calculateDifference(index);
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Ingrese valor';
                        if (double.tryParse(value) == null) return 'Número inválido';
                        return null;
                      },
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: _retornoControllers[index],
                  decoration: _buildInputDecoration('Retorno ${index + 1}'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  onChanged: (value) {
                    controller.updateLinealidadRow(index, 'retorno', value);
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Ingrese valor';
                    if (double.tryParse(value) == null) return 'Número inválido';
                    return null;
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate(delay: (1100 + index * 100).ms)
        .fadeIn()
        .slideX(begin: index % 2 == 0 ? -0.3 : 0.3);
  }

  void _calculateDifference(int index) {
    final lt = double.tryParse(_ltControllers[index].text) ?? 0.0;
    final indicacion = double.tryParse(_indicacionControllers[index].text) ?? 0.0;
    final difference = indicacion - lt;
    _diferenciaControllers[index].text = difference.toStringAsFixed(2);
    Provider.of<ServicioController>(context, listen: false)
        .updateLinealidadRow(index, 'difference', difference.toStringAsFixed(2));
  }

  Widget _buildTableControls(ServicioController controller) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton.icon(
          onPressed: () {
            controller.addLinealidadRow();
            _ltControllers.add(TextEditingController());
            _indicacionControllers.add(TextEditingController());
            _retornoControllers.add(TextEditingController(text: '0'));
            _diferenciaControllers.add(TextEditingController());
            setState(() {});
          },
          icon: const Icon(Icons.add),
          label: const Text('Agregar Fila'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
        ),
        const SizedBox(width: 10),
        ElevatedButton.icon(
          onPressed: () {
            if (controller.linealidadRows.length > 6) {
              final lastIndex = controller.linealidadRows.length - 1;
              controller.removeLinealidadRow(lastIndex);
              _ltControllers.removeLast().dispose();
              _indicacionControllers.removeLast().dispose();
              _retornoControllers.removeLast().dispose();
              _diferenciaControllers.removeLast().dispose();
              setState(() {});
            }
          },
          icon: const Icon(Icons.remove),
          label: const Text('Eliminar Fila'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    ).animate(delay: 1200.ms).fadeIn().slideY(begin: 0.3);
  }

  Widget _buildSaveButton(ServicioController controller) {
    return Container(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () async {
          try {
            // Calcular todas las diferencias antes de guardar
            for (int i = 0; i < controller.linealidadRows.length; i++) {
              _calculateDifference(i);
            }

            await controller.saveCurrentStepData();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Datos de linealidad guardados correctamente'),
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
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'GUARDAR LINEALIDAD',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ).animate(delay: 1300.ms).fadeIn().slideY(begin: 0.3);
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