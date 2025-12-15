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
  final List<TextEditingController> _comentarioControllers = [];

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 10; i++) {
      _comentarioControllers
          .add(TextEditingController(text: widget.model.comentarios[i]));
    }
  }

  @override
  void dispose() {
    for (var controller in _comentarioControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    widget.model.horaFin = DateFormat('HH:mm').format(DateTime.now());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const Text(
            'COMENTARIOS FINALES',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          ...List.generate(3, (index) => _buildComentarioField(index)),
          // Solo mostramos 3 por defecto para no saturar, podemos poner boton "Agregar mas"
          // O mostrar todos si tienen texto.

          ExpansionTile(
            title: const Text('Más comentarios'),
            children:
                List.generate(7, (index) => _buildComentarioField(index + 3)),
          ),

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
                    // Navegar a Fin de Servicio
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
                            tableName: 'mnt_correctivo',
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

  Widget _buildComentarioField(int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: TextFormField(
        controller: _comentarioControllers[index],
        decoration: InputDecoration(
          labelText: 'Comentario ${index + 1}',
          border: const OutlineInputBorder(),
        ),
        onChanged: (val) {
          widget.model.comentarios[index] = val;
        },
      ),
    );
  }
}
