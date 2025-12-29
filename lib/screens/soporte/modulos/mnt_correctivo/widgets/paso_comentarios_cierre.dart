// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import '../models/mnt_correctivo_model.dart';
import '../controllers/mnt_correctivo_controller.dart';
import 'package:intl/intl.dart';
import '../fin_servicio_mntcorrectivo.dart';

class PasoComentariosCierre extends StatefulWidget {
  final MntCorrectivoModel model;
  final MntCorrectivoController controller;

  const PasoComentariosCierre({
    super.key,
    required this.model,
    required this.controller,
  });

  @override
  State<PasoComentariosCierre> createState() => _PasoComentariosCierreState();
}

class _PasoComentariosCierreState extends State<PasoComentariosCierre> {
  @override
  Widget build(BuildContext context) {
    widget.model.horaFin = DateFormat('HH:mm').format(DateTime.now());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 24),

          // Lista de Comentarios Dinámica (Similar a Diagnostico)
          ...List.generate(10, (index) {
            // Caso: Campo actual es null
            if (widget.model.comentarios[index] == null) {
              // Solo mostrar botón si es el primero (0) o si el anterior NO es null
              if (index == 0 || widget.model.comentarios[index - 1] != null) {
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
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 16),
                    ),
                  ),
                );
              } else {
                return const SizedBox.shrink();
              }
            }

            // Caso: Campo tiene valor (String vacía o texto) -> Mostrar TextField
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: TextFormField(
                initialValue: widget.model.comentarios[index],
                maxLines: 3, // Campo más grande
                maxLength: 500, // Máximo 500 caracteres
                buildCounter: (context,
                    {required currentLength, required isFocused, maxLength}) {
                  return Text(
                    '$currentLength / $maxLength',
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          currentLength == maxLength ? Colors.red : Colors.grey,
                    ),
                  );
                },
                decoration: InputDecoration(
                  labelText: 'Comentario ${index + 1}',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        _eliminarComentario(index);
                      });
                    },
                  ),
                ),
                onChanged: (val) => widget.model.comentarios[index] = val,
              ),
            );
          }),

          const SizedBox(height: 20),

          ListTile(
            title: const Text("Hora de Finalización"),
            trailing: Text(
              widget.model.horaFin,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),

          const SizedBox(height: 30),

          Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  onPressed: () => widget.controller.saveData(context),
                  child: const Text('GUARDAR DATOS',
                      style: TextStyle(color: Colors.white)),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  onPressed: () async {
                    await widget.controller.saveData(context);
                    if (mounted) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FinServicioMntcorrectivoScreen(
                            sessionId: widget.model.sessionId,
                            secaValue: widget.model.secaValue,
                            nReca: widget.model.nReca,
                            codMetrica: widget.model.codMetrica,
                            userName: widget.model.userName,
                            clienteId: widget.model.clienteId,
                            plantaCodigo: widget.model.plantaCodigo,
                            tableName: 'diagnostico_correctivo',
                          ),
                        ),
                      );
                    }
                  },
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

  void _eliminarComentario(int index) {
    widget.model.comentarios[index] = null;
    final notNulls = widget.model.comentarios.where((c) => c != null).toList();
    for (int i = 0; i < 10; i++) {
      widget.model.comentarios[i] = null;
    }
    for (int i = 0; i < notNulls.length; i++) {
      widget.model.comentarios[i] = notNulls[i];
    }
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
                  'Conclusión del mantenimiento correctivo',
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
