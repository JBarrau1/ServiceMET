import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../inicio_servicio_controller.dart';
import 'inspeccion_visual_field.dart';

class InspeccionVisualStep extends StatelessWidget {
  const InspeccionVisualStep({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<InicioServicioController>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        const Text(
          'REGISTRO DE DATOS DE CONDICIONES \n DEL EQUIPO A CALIBRAR',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20.0),

        // Hora Inicio
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              initialValue: controller.horaInicio,
              decoration:
                  _buildInputDecoration('Hora de inicio de la Calibración:'),
              readOnly: true,
            ),
            const SizedBox(height: 8.0),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info,
                  color: isDarkMode ? Colors.white70 : Colors.black87,
                  size: 16.0,
                ),
                const SizedBox(width: 5.0),
                Expanded(
                  child: Text(
                    'Hora obtenida automáticamente del sistema',
                    style: TextStyle(
                      fontSize: 12.0,
                      color: isDarkMode ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
        const SizedBox(height: 20.0),

        // Tiempos
        DropdownButtonFormField<String>(
          value: controller.tiempoMin,
          decoration: _buildInputDecoration(
              'Tiempo de estabilización de Pesas (en Minutos):'),
          items: const [
            DropdownMenuItem(
                value: 'Mayor a 15 minutos', child: Text('Mayor a 15 minutos')),
            DropdownMenuItem(
                value: 'Mayor a 30 minutos', child: Text('Mayor a 30 minutos')),
          ],
          onChanged: controller.setTiempoMin,
        ),
        const SizedBox(height: 20.0),
        DropdownButtonFormField<String>(
          value: controller.tiempoBalanza,
          decoration:
              _buildInputDecoration('Tiempo previo a operacion de Balanza:'),
          items: const [
            DropdownMenuItem(
                value: 'Mayor a 15 minutos', child: Text('Mayor a 15 minutos')),
            DropdownMenuItem(
                value: 'Mayor a 30 minutos', child: Text('Mayor a 30 minutos')),
          ],
          onChanged: controller.setTiempoBalanza,
        ),
        const SizedBox(height: 20.0),

        // Switch "Buen Estado"
        const Text(
          'ENTORNO DE INSTALACIÓN',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20.0),
        SwitchListTile(
          title: const Text('Establecer todo en Buen Estado'),
          value: controller.setAllToGood,
          onChanged: controller.setSetAllToGood,
          activeThumbColor: Colors.green,
          secondary: Icon(
            controller.setAllToGood
                ? Icons.check_circle
                : Icons.circle_outlined,
            color: controller.setAllToGood ? Colors.green : Colors.grey,
          ),
        ),
        const SizedBox(height: 20.0),

        // Campos Dinámicos usando el nuevo widget
        InspeccionVisualField(label: 'Vibración', controller: controller),
        InspeccionVisualField(label: 'Polvo', controller: controller),
        InspeccionVisualField(label: 'Temperatura', controller: controller),
        InspeccionVisualField(label: 'Humedad', controller: controller),
        InspeccionVisualField(label: 'Mesada', controller: controller),
        InspeccionVisualField(label: 'Iluminación', controller: controller),
        InspeccionVisualField(
            label: 'Limpieza de Fosa', controller: controller),
        InspeccionVisualField(
            label: 'Estado de Drenaje', controller: controller),

        const SizedBox(height: 20.0),
        const Text(
          'ESTADO GENERAL DE LA BALANZA',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20.0),

        InspeccionVisualField(
            label: 'Limpieza General', controller: controller),
        InspeccionVisualField(
            label: 'Golpes al Terminal', controller: controller),
        InspeccionVisualField(label: 'Nivelación', controller: controller),
        InspeccionVisualField(
            label: 'Limpieza Receptor', controller: controller),
        InspeccionVisualField(
            label: 'Golpes al receptor de Carga', controller: controller),
        InspeccionVisualField(label: 'Encendido', controller: controller),

        const SizedBox(height: 20.0),
      ],
    );
  }

  InputDecoration _buildInputDecoration(String labelText) {
    return InputDecoration(
      labelText: labelText,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
    );
  }
}
