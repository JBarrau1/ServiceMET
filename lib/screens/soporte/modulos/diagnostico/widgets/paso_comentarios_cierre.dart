import 'package:flutter/material.dart';
import '../models/diagnostico_model.dart';
import '../controllers/diagnostico_controller.dart';
import 'package:intl/intl.dart';

class PasoComentariosCierre extends StatefulWidget {
  final DiagnosticoModel model;
  final DiagnosticoController controller;

  const PasoComentariosCierre({
    super.key,
    required this.model,
    required this.controller,
  });

  @override
  State<PasoComentariosCierre> createState() => _PasoComentariosCierreState();
}

class _PasoComentariosCierreState extends State<PasoComentariosCierre> {
  void _actualizarHoraFin() {
    final ahora = DateTime.now();
    final horaFormateada = DateFormat('HH:mm:ss').format(ahora);
    setState(() {
      widget.model.horaFin = horaFormateada;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Usamos una lógica similar a la de AjusteVerificaciones para los comentarios
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 24),

          // Lista de Comentarios
          ...List.generate(10, (index) {
            bool show = index == 0 ||
                (widget.model.comentarios[index - 1] != null &&
                    widget.model.comentarios[index - 1]!.isNotEmpty);

            if (widget.model.comentarios[index] == null &&
                (index > 0 && widget.model.comentarios[index - 1] == null)) {
              return const SizedBox.shrink();
            }

            if (widget.model.comentarios[index] == null) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      widget.model.comentarios[index] = "";
                    });
                  },
                  icon: const Icon(Icons.add),
                  label: Text('Agregar Comentario ${index + 1}'),
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: TextFormField(
                initialValue: widget.model.comentarios[index],
                decoration: InputDecoration(
                    labelText: 'Comentario ${index + 1}',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          widget.model.comentarios[index] = null;
                          // Reordenar
                          final notNulls = widget.model.comentarios
                              .where((c) => c != null)
                              .toList();
                          widget.model.comentarios = List.filled(10, null);
                          for (int i = 0; i < notNulls.length; i++) {
                            widget.model.comentarios[i] = notNulls[i];
                          }
                        });
                      },
                    )),
                onChanged: (val) => widget.model.comentarios[index] = val,
              ),
            );
          }),

          const SizedBox(height: 20),

          // Hora Fin
          TextField(
            readOnly: true,
            decoration: InputDecoration(
              labelText: 'Hora Final del Servicio *',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              suffixIcon: IconButton(
                icon: const Icon(Icons.update),
                onPressed: _actualizarHoraFin,
              ),
            ),
            controller: TextEditingController(text: widget.model.horaFin),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.green.withOpacity(0.1)
            : Colors.green.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.green.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.assignment_turned_in_outlined,
            color: Colors.green,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'COMENTARIOS Y CIERRE',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Conclusión del servicio de diagnóstico',
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
