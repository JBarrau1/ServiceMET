import 'package:flutter/material.dart';
import 'eccentricity_test.dart';
import 'repeatability_test.dart';
import 'linearity_test.dart';

class MetrologicalTestsContainer extends StatefulWidget {
  final String testType; // 'initial' o 'final'
  final Map<String, dynamic> initialData;
  final ValueChanged<Map<String, dynamic>> onTestsDataChanged;
  final String? selectedUnit;
  final ValueChanged<String>? onUnitChanged;

  const MetrologicalTestsContainer({
    super.key,
    required this.testType,
    required this.initialData,
    required this.onTestsDataChanged,
    this.selectedUnit,
    this.onUnitChanged,
  });

  @override
  State<MetrologicalTestsContainer> createState() =>
      _MetrologicalTestsContainerState();
}

class _MetrologicalTestsContainerState
    extends State<MetrologicalTestsContainer> {
  final Map<String, dynamic> _testsData = <String, dynamic>{};
  late String _selectedUnit;

  @override
  void initState() {
    super.initState();
    _selectedUnit = widget.selectedUnit ?? 'kg';
    // Asegurar conversión de tipos
    _testsData.addAll(Map<String, dynamic>.from(widget.initialData));
  }

  // Función auxiliar para manejar cambios en las pruebas
  void _handleTestChange(String testKey, bool value) {
    setState(() {
      if (value) {
        final initialData = widget.initialData[testKey] ?? {};
        _testsData[testKey] = Map<String, dynamic>.from(initialData);
      } else {
        _testsData.remove(testKey);
      }
      widget.onTestsDataChanged(Map<String, dynamic>.from(_testsData));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 20),
        Text(
          'PRUEBAS METROLÓGICAS ${widget.testType.toUpperCase()}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Icon(Icons.info, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Para aplicar alguna de las pruebas metrológicas debe activar el switch de la prueba que desea aplicar.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Prueba de Excentricidad
        SwitchListTile(
          title: Text(
            'PRUEBAS DE EXCENTRICIDAD ${widget.testType.toUpperCase()}',
            style: const TextStyle(
              fontSize: 14, // Tamaño de fuente 16 px
              fontWeight: FontWeight.w500,
            ),
          ),
          value: _testsData['eccentricity'] != null,
          onChanged: (value) => _handleTestChange('eccentricity', value),
        ),
        if (_testsData['eccentricity'] != null)
          EccentricityTest(
            testType: widget.testType,
            initialData: Map<String, dynamic>.from(_testsData['eccentricity']!),
            onDataChanged: (data) {
              setState(() {
                _testsData['eccentricity'] = Map<String, dynamic>.from(data);
                widget
                    .onTestsDataChanged(Map<String, dynamic>.from(_testsData));
              });
            },
            selectedUnit: _selectedUnit,
          ),
        const SizedBox(height: 20),
        // Prueba de Repetibilidad
        SwitchListTile(
          title: Text(
            'PRUEBAS DE REPETIBILIDAD ${widget.testType.toUpperCase()}',
            style: const TextStyle(
              fontSize: 14, // Tamaño de fuente 16 px
              fontWeight: FontWeight.w500,
            ),
          ),
          value: _testsData['repeatability'] != null,
          onChanged: (value) => _handleTestChange('repeatability', value),
        ),
        if (_testsData['repeatability'] != null)
          RepeatabilityTest(
            testType: widget.testType,
            initialData:
                Map<String, dynamic>.from(_testsData['repeatability']!),
            onDataChanged: (data) {
              setState(() {
                _testsData['repeatability'] = Map<String, dynamic>.from(data);
                widget
                    .onTestsDataChanged(Map<String, dynamic>.from(_testsData));
              });
            },
            selectedUnit: _selectedUnit,
          ),
        const SizedBox(height: 20),

        // Prueba de Linealidad
        SwitchListTile(
          title: Text(
            'PRUEBAS DE LINEALIDAD ${widget.testType.toUpperCase()}', // <--- Coma añadida aquí
            style: const TextStyle(
              fontSize: 14, // Tamaño de fuente 16 px
              fontWeight: FontWeight.w500,
            ),
          ),
          value: _testsData['linearity'] != null,
          onChanged: (value) => _handleTestChange('linearity', value),
        ),
        if (_testsData['linearity'] != null)
          LinearityTest(
            testType: widget.testType,
            initialData: Map<String, dynamic>.from(_testsData['linearity']!),
            onDataChanged: (data) {
              setState(() {
                _testsData['linearity'] = Map<String, dynamic>.from(data);
                widget
                    .onTestsDataChanged(Map<String, dynamic>.from(_testsData));
              });
            },
            selectedUnit: _selectedUnit,
          ),
      ],
    );
  }
}
