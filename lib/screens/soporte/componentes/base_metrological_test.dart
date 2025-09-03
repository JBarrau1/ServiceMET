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
