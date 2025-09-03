import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';

class CalibrationFabMenu extends StatelessWidget {
  final VoidCallback onAddNote;
  final VoidCallback onShowBalanzaInfo;
  final VoidCallback onShowLastService;
  final VoidCallback onFinishService;

  const CalibrationFabMenu({
    super.key,
    required this.onAddNote,
    required this.onShowBalanzaInfo,
    required this.onShowLastService,
    required this.onFinishService,
  });

  @override
  Widget build(BuildContext context) {
    return SpeedDial(
      icon: Icons.menu,
      activeIcon: Icons.close,
      iconTheme: const IconThemeData(color: Colors.black54),
      backgroundColor: const Color(0xFFF9E300),
      foregroundColor: Colors.white,
      children: [
        SpeedDialChild(
          child: const Icon(Icons.note_add),
          backgroundColor: Colors.purpleAccent,
          label: 'Agregar Comentario',
          onTap: onAddNote,
        ),
        SpeedDialChild(
          child: const Icon(Icons.info),
          backgroundColor: Colors.blueAccent,
          label: 'Información de la balanza',
          onTap: onShowBalanzaInfo,
        ),
        SpeedDialChild(
          child: const Icon(Icons.info),
          backgroundColor: Colors.orangeAccent,
          label: 'Datos del Último Servicio',
          onTap: onShowLastService,
        ),
        SpeedDialChild(
          child: const Icon(Icons.stop),
          backgroundColor: Colors.red,
          label: 'Cortar Servicio',
          onTap: onFinishService,
        ),
      ],
    );
  }
}