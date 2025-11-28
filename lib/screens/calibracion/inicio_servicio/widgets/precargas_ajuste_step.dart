import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../pruebas_metrologicas/decimal_helper.dart';
import '../inicio_servicio_controller.dart';

class PrecargasAjusteStep extends StatelessWidget {
  const PrecargasAjusteStep({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<InicioServicioController>(context);

    return FutureBuilder<Map<String, double>>(
      future: controller.getAllDValues(),
      builder: (context, snapshot) {
        final dValues = snapshot.data ?? {};

        return Column(
          children: [
            const Text(
              'INICIO DE PRUEBAS DE PRECARGAS DE AJUSTE',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: Colors.orange),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20.0),

            // Precargas
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Precargas:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline,
                          color: Colors.orange),
                      onPressed: controller.addPreloadRow,
                    ),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline,
                          color: Colors.orange),
                      onPressed: controller.removePreloadRow,
                    ),
                  ],
                ),
              ],
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: controller.rowCount,
              itemBuilder: (context, index) {
                return _buildPreloadRow(context, controller, index, dValues);
              },
            ),
            const SizedBox(height: 20.0),

            // Ajuste
            const Text(
              'Ajuste:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10.0),
            SwitchListTile(
              title: const Text('¿Se realizó Ajuste?'),
              value: controller.isAjusteRealizado,
              onChanged: controller.setIsAjusteRealizado,
              activeColor: Colors.orange,
            ),
            if (controller.isAjusteRealizado) ...[
              const SizedBox(height: 10.0),
              DropdownButtonFormField<String>(
                value: controller.tipoAjusteController.text.isEmpty
                    ? null
                    : controller.tipoAjusteController.text,
                decoration: _buildInputDecoration('Tipo de Ajuste'),
                items: const [
                  DropdownMenuItem(value: 'Interno', child: Text('Interno')),
                  DropdownMenuItem(value: 'Externo', child: Text('Externo')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    controller.tipoAjusteController.text = value;
                    controller.setIsAjusteExterno(value == 'Externo');
                  }
                },
              ),
              if (controller.isAjusteExterno) ...[
                const SizedBox(height: 10.0),
                TextFormField(
                  controller: controller.cargasPesasController,
                  decoration: _buildInputDecoration(
                      'Cargas de Pesas Patrón Utilizadas'),
                  keyboardType: TextInputType.number,
                ),
              ],
            ],
            const SizedBox(height: 20.0),

            // Condiciones Ambientales
            const Text(
              'Condiciones Ambientales:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10.0),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: controller.horaPruebasController,
                  readOnly: true,
                  decoration: _buildInputDecoration(
                    'Hora',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.access_time),
                      onPressed: controller.updatePruebasTime,
                    ),
                  ),
                ),
                const SizedBox(height: 8.0),
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16.0,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white70
                          : Colors.black87,
                    ),
                    const SizedBox(width: 8.0),
                    Expanded(
                      child: Text(
                        'Haga clic en el icono del reloj para ingresar la hora. La hora se obtiene automáticamente del sistema.',
                        style: TextStyle(
                          fontSize: 12.0,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white70
                              : Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10.0),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: controller.tiController,
                    decoration: _buildInputDecoration('Ti (°C)'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 10.0),
                Expanded(
                  child: TextFormField(
                    controller: controller.hriController,
                    decoration: _buildInputDecoration('HRi (%)'),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10.0),
            TextFormField(
              controller: controller.patmiController,
              decoration: _buildInputDecoration('Patmi (hPa)'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20.0),
          ],
        );
      },
    );
  }

  Widget _buildPreloadRow(
      BuildContext context,
      InicioServicioController controller,
      int index,
      Map<String, double> dValues) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Text('${index + 1}.',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 10.0),
          Expanded(
            child: TextFormField(
              controller: controller.precargasControllers[index],
              decoration: _buildInputDecoration('Precarga'),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              onChanged: (value) {
                // Update indication controller to match preload value
                controller.indicacionesControllers[index].text = value;
                // Force rebuild to update suggestions if needed, though controller handles text
                // Since it's stateless, we rely on controller listeners or parent rebuild
              },
            ),
          ),
          const SizedBox(width: 10.0),
          Expanded(
            child: TextFormField(
              controller: controller.indicacionesControllers[index],
              decoration: _buildInputDecoration(
                'Indicación',
                suffixIcon: PopupMenuButton<String>(
                  icon: const Icon(Icons.arrow_drop_down),
                  onSelected: (String newValue) {
                    controller.indicacionesControllers[index].text = newValue;
                  },
                  itemBuilder: (BuildContext context) {
                    final currentText =
                        controller.indicacionesControllers[index].text;
                    final baseValue =
                        double.tryParse(currentText.replaceAll(',', '.')) ??
                            0.0;

                    // Get dynamic decimal step based on the value
                    final dValue =
                        DecimalHelper.getDecimalForValue(baseValue, dValues);
                    final decimalPlaces =
                        DecimalHelper.getDecimalPlaces(dValue);

                    return List.generate(11, (i) {
                      final value = baseValue + ((i - 5) * dValue);
                      final txt = value.toStringAsFixed(decimalPlaces);
                      return PopupMenuItem<String>(
                          value: txt, child: Text(txt));
                    });
                  },
                ),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration(String labelText,
      {Widget? suffixIcon}) {
    return InputDecoration(
      labelText: labelText,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      suffixIcon: suffixIcon,
    );
  }
}
