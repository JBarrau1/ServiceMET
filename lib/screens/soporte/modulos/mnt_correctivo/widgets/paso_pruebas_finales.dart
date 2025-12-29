// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../models/mnt_correctivo_model.dart';
import '../controllers/mnt_correctivo_controller.dart';
import 'pruebas_metrologicas_widget.dart';

class PasoPruebasFinales extends StatefulWidget {
  final MntCorrectivoModel model;
  final MntCorrectivoController controller;

  const PasoPruebasFinales({
    super.key,
    required this.model,
    required this.controller,
  });

  @override
  State<PasoPruebasFinales> createState() => _PasoPruebasFinalesState();
}

class _PasoPruebasFinalesState extends State<PasoPruebasFinales> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildHeader(context),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(8.0),
            color: Colors.green.shade100,
            child: const Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.green),
                SizedBox(width: 8),
                Expanded(
                    child: Text(
                        'Estas pruebas se realizan DESPUÉS de los ajustes.')),
              ],
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: _copiarDeIniciales,
            icon: const Icon(Icons.copy),
            label: const Text('COPIAR DE INICIALES'),
          ),
          const SizedBox(height: 20),
          PruebasMetrologicasWidget(
            pruebas: widget.model.pruebasFinales,
            tipoPrueba: 'Final',
            onChanged: () => setState(() {}),
            getIndicationSuggestions:
                (String cargaStr, String currentIndication) async {
              double carga = double.tryParse(cargaStr) ?? 0;
              double d = await widget.controller.getD1FromDatabase();
              return widget.controller.getIndicationSuggestions(carga, d);
            },
            getD1FromDatabase: widget.controller.getD1FromDatabase,
          ),
        ],
      ),
    );
  }

  void _copiarDeIniciales() {
    // Lógica simplificada de copia
    setState(() {
      // Copia profunda idealmente, pero por ahora asignación manual de valores clave
      widget.model.pruebasFinales =
          PruebasMetrologicas.fromOther(widget.model.pruebasIniciales);
    });
  }

  Widget _buildHeader(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.teal.withOpacity(0.1)
            : Colors.teal.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.teal.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.task_alt_outlined,
            color: Colors.teal,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PRUEBAS FINALES',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Verificación final del equipo',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
