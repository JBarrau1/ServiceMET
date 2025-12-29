// ignore_for_file: unused_element

import 'package:flutter/material.dart';
import 'linealidad_controller.dart';
import 'linearity_row.dart';
import 'method_selector.dart';

class LinealidadForm extends StatefulWidget {
  final LinealidadController controller;

  const LinealidadForm({
    super.key,
    required this.controller,
  });

  @override
  State<LinealidadForm> createState() => _LinealidadFormState();
}

class _LinealidadFormState extends State<LinealidadForm> {
  final _formKey = GlobalKey<FormState>();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _rowsSectionKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    widget.controller.updateNotifier.addListener(_onControllerUpdate);
  }

  @override
  void dispose() {
    widget.controller.updateNotifier.removeListener(_onControllerUpdate);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Forzar actualización cuando el controlador cambie
    widget.controller.onUpdate = () {
      if (mounted) {
        setState(() {});
      }
    };
  }

  void _onControllerUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  void _scrollToNewRow() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _calculateLsubn(LinealidadController controller) {
    final lt = double.tryParse(controller.ltnController.text) ?? 0.0;
    final iLt = double.tryParse(controller.cpController.text) ?? 0.0;
    final iLsubn = double.tryParse(controller.iLsubnController.text) ?? 0.0;

    final difference = iLt - lt;
    final lsubn = iLsubn - difference;
    controller.lsubnController.text = lsubn.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;

    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          children: [
            const Text(
              'PRUEBAS DE LINEALIDAD',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            MethodSelector(controller: controller),
            const SizedBox(height: 20),

            // SOLO MOSTRAR CAMPOS DE MÉTODO SI NO ES "Sin método de carga"
            if (controller.selectedMetodoCarga == 'Método 1') ...[
              _buildMethod1Fields(controller),
              const SizedBox(height: 20),
            ],

            if (controller.selectedMetodoCarga == 'Método 2') ...[
              _buildMethod2Fields(controller),
              const SizedBox(height: 20),
            ],

            // Si es "Sin método de carga", no mostrar campos adicionales
            if (controller.selectedMetodoCarga == 'Sin método de carga') ...[
              const SizedBox(height: 10),
              Text(
                'Modo sin método de carga - Solo ingrese cargas e indicaciones',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
            ],

            _buildRowsSection(controller),
            _buildActionButtons(controller, context),
          ],
        ),
      ),
    );
  }

  Future<void> _saveDataToDatabase(
      BuildContext context, LinealidadController controller) async {
    try {
      await controller.saveDataToDatabase();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Datos guardados correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _saveLsubnAsLt(LinealidadController controller) {
    final lsubn = controller.lsubnController.text;
    if (lsubn.isNotEmpty) {
      bool inserted = false;

      for (var row in controller.rows) {
        if (row['lt']?.text.isEmpty ?? true) {
          row['lt']?.text = lsubn;
          inserted = true;
          break;
        }
      }

      if (!inserted && controller.rows.length < 60) {
        controller.addRow();
        controller.rows.last['lt']?.text = lsubn;
        _scrollToNewRow(); // ← Auto-scroll aquí
      }

      controller.iLsubnController.clear();
      controller.lsubnController.clear();
      controller.cpController.clear();
      controller.ltnController.clear();
      controller.iCpController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lsubn guardado como LT')),
      );
    }
  }

  Widget _buildMethod1Fields(LinealidadController controller) {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton(
            onPressed: () => _saveLsubnAsLt(controller),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Guardar Lsubn como LT'),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                controller: controller.ltnController,
                decoration: buildInputDecoration('LTn'),
                onChanged: (_) => _calculateLsubn(controller),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                controller: controller.cpController,
                decoration: buildInputDecoration('I(LTn)'),
                onChanged: (_) => _calculateLsubn(controller),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: controller.iLsubnController,
                decoration: buildInputDecoration('I(Lsubn)'),
                keyboardType: TextInputType.number,
                onChanged: (_) => _calculateLsubn(controller),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: controller.lsubnController,
                readOnly: true,
                decoration: buildInputDecoration('Lsubn'),
                style: const TextStyle(color: Colors.lightGreen),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMethod2Fields(LinealidadController controller) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                controller: controller.iLsubnController,
                decoration: buildInputDecoration(
                  'I(Lsubn)',
                ),
                onChanged: (value) {
                  final iLsubn = double.tryParse(value) ?? 0.0;
                  double closestLt = double.infinity;
                  double closestDifference = 0.0;

                  for (var row in controller.rows) {
                    final lt = double.tryParse(row['lt']?.text ?? '') ?? 0.0;
                    final indicacion =
                        double.tryParse(row['indicacion']?.text ?? '') ?? 0.0;
                    final difference = indicacion - lt;

                    if ((iLsubn - lt).abs() < (iLsubn - closestLt).abs()) {
                      closestLt = lt;
                      closestDifference = difference;
                    }
                  }

                  final lsubn = iLsubn - closestDifference;
                  controller.lsubnController.text = lsubn.toStringAsFixed(2);

                  if (controller.rows.isNotEmpty &&
                      (controller.rows[0]['lt']?.text.isEmpty ?? true)) {
                    controller.ltnController.text =
                        (lsubn + 500).toStringAsFixed(2);
                  } else {
                    final lastLt = double.tryParse(
                            controller.rows.last['lt']?.text ?? '') ??
                        0.0;
                    controller.ltnController.text =
                        (lsubn + lastLt).toStringAsFixed(2);
                  }
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: controller.lsubnController,
                readOnly: true,
                decoration: buildInputDecoration(
                  'Lsubn',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: controller.ioController,
                keyboardType: TextInputType.number,
                decoration: buildInputDecoration(
                  'Io',
                ),
                onChanged: (value) {
                  final cp =
                      double.tryParse(controller.cpController.text) ?? 0.0;
                  final lsubn =
                      double.tryParse(controller.lsubnController.text) ?? 0.0;
                  final io = double.tryParse(value) ?? 0.0;
                  final ltn = (cp + lsubn) - io;
                  controller.ltnController.text = ltn.toStringAsFixed(2);
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: controller.ltnController,
                readOnly: true,
                decoration: buildInputDecoration(
                  'LTn',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: controller.saveLtnToNewRow,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          child: const Text('Guardar LTn'),
        ),
      ],
    );
  }

  Widget _buildRowsSection(LinealidadController controller) {
    return Column(
      key: _rowsSectionKey, // ← Key para la sección de filas
      children: [
        const SizedBox(height: 10),
        const Text(
          'CARGA DE PESAS E INDICACIÓN',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 3.0),
        Text('Total de cargas: ${controller.rows.length} / 60'),
        const SizedBox(height: 20.0),
        if (controller.rows.length > 12)
          Text(
            '⚠️ Está ingresando más de 12 cargas, lo cual supera lo recomendado.',
            style: TextStyle(
              color: Colors.orange.shade800,
              fontWeight: FontWeight.bold,
            ),
          ),
        const SizedBox(height: 10),
        ...List.generate(
          controller.rows.length,
          (index) => LinearityRow(
            index: index,
            controller: controller,
            onRemove: () => setState(() {
              controller.removeRow(index);
            }),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF287a94),
              ),
              onPressed: controller.rows.length < 60
                  ? () {
                      setState(() {
                        controller.addRow();
                        _scrollToNewRow(); // ← Auto-scroll al agregar fila
                      });
                    }
                  : null,
              icon: const Icon(Icons.add),
              label: const Text('Agregar Carga'),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFc11515),
              ),
              onPressed: controller.rows.length > 6
                  ? () => setState(() {
                        controller.removeRow(controller.rows.length - 1);
                      })
                  : null,
              icon: const Icon(Icons.remove),
              label: const Text('Eliminar Carga'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons(
      LinealidadController controller, BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 20),
        IntrinsicHeight(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0E8833),
                      ),
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          await _saveDataToDatabase(context, controller);
                        }
                      },
                      child: const Text('GUARDAR DATOS DE LINEALIDAD'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showSnackBar(BuildContext context, String message,
      {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white), // color del texto
        ),
        // Usa `SnackBarTheme` o personaliza aquí:
        backgroundColor: isError
            ? Colors.red
            : Colors.green, // esto aún funciona en versiones actuales
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  InputDecoration buildInputDecoration(
    String labelText, {
    Widget? suffixIcon,
    String? suffixText,
  }) {
    return InputDecoration(
      labelText: labelText,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      suffixIcon: suffixIcon,
      suffixText: suffixText,
    );
  }
}
