import 'package:flutter/material.dart';

class MetrologicalTestsProvider extends ChangeNotifier {
  final Map<String, Map<String, dynamic>> _testsData = {
    'initial': {},
    'final': {},
  };

  /// Obtiene todos los datos de un tipo de prueba (initial o final)
  Map<String, dynamic> getTests(String type) {
    return _testsData[type] ?? {};
  }

  /// Guarda datos de una prueba
  void setTest(String type, String key, Map<String, dynamic> data) {
    _testsData[type]![key] = Map<String, dynamic>.from(data);

    // Si es initial, replicar automáticamente en final
    if (type == 'initial') {
      _testsData['final']![key] = Map<String, dynamic>.from(data);
    }

    notifyListeners();
  }

  /// Activa o desactiva una prueba
  void toggleTest(String type, String key, bool active) {
    if (active) {
      _testsData[type]![key] = {};
      if (type == 'initial') {
        _testsData['final']![key] = {};
      }
    } else {
      _testsData[type]!.remove(key);
      if (type == 'initial') {
        _testsData['final']!.remove(key);
      }
    }
    notifyListeners();
  }
}
