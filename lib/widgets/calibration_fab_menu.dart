import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';

class CalibrationFabMenu extends StatelessWidget {
  final VoidCallback onShowData;
  final VoidCallback onAddNote;
  final VoidCallback onFinish;

  const CalibrationFabMenu({
    super.key,
    required this.onShowData,
    required this.onAddNote,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    return SpeedDial(
      icon: Icons.menu,
      activeIcon: Icons.close,
      children: [
        SpeedDialChild(
          child: const Icon(Icons.note_add),
          label: 'Agregar Comentario',
          onTap: onAddNote,
        ),
        SpeedDialChild(
          child: const Icon(Icons.view_list),
          label: 'Ver datos actuales',
          onTap: onShowData,
        ),
        SpeedDialChild(
          child: const Icon(Icons.stop),
          label: 'Cortar Servicio',
          onTap: onFinish,
        ),
      ],
    );
  }
}