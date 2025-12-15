import 'package:flutter/material.dart';
import '../models/diagnostico_model.dart';
import 'pruebas_metrologicas_widget.dart';
import '../controllers/diagnostico_controller.dart';

class PasoPruebasIniciales extends StatelessWidget {
  final DiagnosticoModel model;
  final DiagnosticoController controller;

  const PasoPruebasIniciales({
    super.key,
    required this.model,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PRUEBAS METROLÓGICAS INICIALES',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          PruebasMetrologicasWidget(
            pruebas: model.pruebasIniciales,
            tipoPrueba: 'Inicial',
            controller:
                controller, // Pasamos el controller para fotos y sugerencias
            onChanged:
                () {}, // El estado se actualiza por referencia en el modelo
            // Pasamos funciones helper del controlador adaptadas a la firma requerida (Future<List<String>> Function(String, String))
            getIndicationSuggestions:
                (String cargaStr, String currentIndication) async {
              double carga = double.tryParse(cargaStr) ?? 0;
              // Obtenemos d1 asumiendo que ya está cacheado o lo pedimos
              double d = await controller.getD1FromDatabase();
              // El método del controlador es sincrono, lo envolvemos en Future
              return controller.getIndicationSuggestions(carga, d);
            },
            getD1FromDatabase:
                controller.getD1FromDatabase, // Ya devuelve Future<double>
          ),
        ],
      ),
    );
  }
}
