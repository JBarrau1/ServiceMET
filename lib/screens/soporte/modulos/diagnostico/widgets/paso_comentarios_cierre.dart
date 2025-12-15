import 'package:flutter/material.dart';
import '../models/diagnostico_model.dart';
import '../controllers/diagnostico_controller.dart';
import 'package:intl/intl.dart';
import '../fin_servicio_diagnostico.dart'; // Importar pantalla de fin de servicio

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
  bool _isSaving = false;
  bool _isSaved = false;

  void _actualizarHoraFin() {
    final ahora = DateTime.now();
    final horaFormateada = DateFormat('HH:mm:ss').format(ahora);
    setState(() {
      widget.model.horaFin = horaFormateada;
    });
  }

  Future<void> _guardarDatos() async {
    setState(() {
      _isSaving = true;
    });
    await widget.controller.saveData(context);
    setState(() {
      _isSaving = false;
      _isSaved = true; // Habilitar 'Siguiente' / 'Finalizar'
    });
  }

  void _irAFinServicio() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FinServicioDiagnosticoScreen(
          nReca: widget.model.nReca,
          secaValue: widget.model.secaValue,
          sessionId: widget.model.sessionId,
          codMetrica: widget.model.codMetrica,
          userName: widget.model.userName,
          clienteId: widget.model.clienteId,
          plantaCodigo: widget.model.plantaCodigo,
          tableName: 'diagnostico',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Usamos una lógica similar a la de AjusteVerificaciones para los comentarios
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'COMENTARIOS Y CIERRE',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 20),

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
                          for (int i = 0; i < notNulls.length; i++)
                            widget.model.comentarios[i] = notNulls[i];
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

          const SizedBox(height: 30),

          // Botones
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF195375),
                      padding: const EdgeInsets.symmetric(vertical: 16)),
                  onPressed: _isSaving ? null : _guardarDatos,
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('GUARDAR DATOS',
                          style: TextStyle(color: Colors.white)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _isSaved ? const Color(0xFF167D1D) : Colors.grey,
                      padding: const EdgeInsets.symmetric(vertical: 16)),
                  onPressed: _isSaved ? _irAFinServicio : null,
                  child: const Text('FINALIZAR',
                      style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
