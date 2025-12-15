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
      widget.model.pruebasFinales.retornoCero.estado =
          widget.model.pruebasIniciales.retornoCero.estado;
      widget.model.pruebasFinales.retornoCero.valor =
          widget.model.pruebasIniciales.retornoCero.valor;
      widget.model.pruebasFinales.retornoCero.estabilidad =
          widget.model.pruebasIniciales.retornoCero.estabilidad;
      // Excentricidad y Repetibilidad requieren copias más estructuradas si se desea clonar todo
    });
  }
}
