import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/ajuste_verificaciones_model.dart';

class PasoComentariosFinal extends StatelessWidget {
  final AjusteVerificacionesModel model;
  final VoidCallback onChanged;

  const PasoComentariosFinal({
    super.key,
    required this.model,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, isDarkMode),
          const SizedBox(height: 24),

          // Lista de 10 comentarios
          const Text(
            'COMENTARIOS (Máx 10)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          ...List.generate(10, (index) {
            bool show = index == 0 ||
                (model.comentarios[index - 1] != null &&
                    model.comentarios[index - 1]!.isNotEmpty);

            if (model.comentarios[index] == null &&
                (index > 0 && model.comentarios[index - 1] == null)) {
              return const SizedBox
                  .shrink(); // Ocultar si el anterior también es nulo
            }

            // Si es nulo pero es el siguiente disponible (o el primero), mostrar como botón o campo.
            if (model.comentarios[index] == null) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: OutlinedButton.icon(
                  onPressed: () {
                    model.comentarios[index] = "";
                    onChanged();
                  },
                  icon: const Icon(Icons.add),
                  label: Text('Agregar Comentario ${index + 1}'),
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: model.comentarios[index],
                      decoration: InputDecoration(
                          labelText: 'Comentario ${index + 1}',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              // Eliminar: desplazar los siguientes hacia atrás o poner null
                              model.comentarios[index] = null;
                              // Reordenar lista para no dejar huecos
                              final notNulls = model.comentarios
                                  .where((c) => c != null)
                                  .toList();
                              model.comentarios = List.filled(10, null);
                              for (int i = 0; i < notNulls.length; i++) {
                                model.comentarios[i] = notNulls[i];
                              }
                              onChanged();
                            },
                          )),
                      maxLines: 2,
                      onChanged: (value) {
                        model.comentarios[index] = value;
                        // No llamamos onChanged a cada caracter para evitar rebuilds masivos,
                        // pero si es necesario guardar estado, sí.
                      },
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 24),

          // Hora Final
          TextField(
            readOnly: true,
            decoration: InputDecoration(
              labelText: 'Hora Final del Servicio *',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.access_time),
              suffixIcon: IconButton(
                icon: const Icon(Icons.update),
                onPressed: () {
                  final ahora = DateTime.now();
                  final horaFormateada = DateFormat('HH:mm:ss').format(ahora);
                  model.horaFin = horaFormateada;
                  onChanged();
                },
                tooltip: 'Registrar hora actual',
              ),
            ),
            controller: TextEditingController(text: model.horaFin),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.orange.withOpacity(0.1)
            : Colors.orange.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.orange.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: const Row(
        children: [
          Icon(Icons.comment, color: Colors.orange, size: 32),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'COMENTARIOS Y CIERRE',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text('Agregue comentarios y finalice el servicio'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
