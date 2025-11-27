import 'package:flutter/material.dart';

abstract class BaseMetrologicalTest extends StatefulWidget {
  final String testType; // 'initial' o 'final'
  final ValueChanged<Map<String, dynamic>> onDataChanged;
  final Map<String, dynamic> initialData;
  final String? selectedUnit;
  final ValueChanged<String>? onUnitChanged;

  const BaseMetrologicalTest({
    super.key,
    required this.testType,
    required this.onDataChanged,
    required this.initialData,
    this.selectedUnit,
    this.onUnitChanged,
  });
}

// Mixin para funcionalidades comunes
mixin MetrologicalTestMixin<T extends BaseMetrologicalTest> on State<T> {
  /// Construye un InputDecoration estándar
  InputDecoration buildInputDecoration(String labelText, {Widget? suffixIcon}) {
    return InputDecoration(
      labelText: labelText,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20.0)),
      suffixIcon: suffixIcon,
    );
  }

  /// Calcula decimales significativos (ignora ceros a la derecha)
  int getSignificantDecimals(double value) {
    final parts = value.toString().split('.');
    if (parts.length == 2) {
      return parts[1].replaceAll(RegExp(r'0+$'), '').length;
    }
    return 0;
  }

  /// Actualiza datos y notifica al padre
  void updateData(Map<String, dynamic> data) {
    widget.onDataChanged(data);
  }

  /// Muestra un snackbar con mensaje
  void showSnackBar(BuildContext context, String message,
      {Color? backgroundColor}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor ?? Colors.orange,
      ),
    );
  }

  /// Dispone una lista de controladores de forma segura
  void disposeControllers(List<TextEditingController> controllers) {
    for (var controller in controllers) {
      controller.dispose();
    }
  }

  /// Dispone un mapa de controladores de forma segura
  void disposeControllerMaps(List<Map<String, TextEditingController>> maps) {
    for (var map in maps) {
      for (var controller in map.values) {
        controller.dispose();
      }
    }
  }
}
