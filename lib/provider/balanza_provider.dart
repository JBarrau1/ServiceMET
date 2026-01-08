import 'package:flutter/material.dart';
import '../models/balanza_model.dart';

class BalanzaProvider with ChangeNotifier {
  Balanza? _selectedBalanza;
  Map<String, dynamic>? _lastServiceData;
  bool _isNewBalanza = false;

  Balanza? get selectedBalanza => _selectedBalanza;
  Map<String, dynamic>? get lastServiceData => _lastServiceData;
  bool get isNewBalanza => _isNewBalanza;

  void setSelectedBalanza(Balanza balanza, {bool isNew = false}) {
    _selectedBalanza = balanza;
    _isNewBalanza = isNew;
    if (isNew) {
      _lastServiceData = null; // Limpiar datos anteriores si es nueva
    }
    notifyListeners();
  }

  void setLastServiceData(Map<String, dynamic> serviceData) {
    _lastServiceData = serviceData;
    _isNewBalanza = false; // Si hay datos, no es nueva
    notifyListeners();
  }

  void clearLastServiceData() {
    _lastServiceData = null;
    notifyListeners();
  }

  void markAsNewBalanza(bool isNew) {
    _isNewBalanza = isNew;
    if (isNew) {
      _lastServiceData = null;
    }
    notifyListeners();
  }

  void clearSelectedBalanza() {
    _selectedBalanza = null;
    _isNewBalanza = false;
    _lastServiceData = null;
    notifyListeners();
  }
}
