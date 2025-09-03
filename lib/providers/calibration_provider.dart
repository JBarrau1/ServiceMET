import 'package:flutter/material.dart';
import 'package:service_met/repositories/calibration_repository.dart';
import '../models/calibration_data.dart';

class CalibrationProvider with ChangeNotifier {
  final CalibrationRepository _repository;

  String _currentDbName = '';
  CalibrationData? _currentData;
  bool _isDataSaved = false;
  String? _currentTestType;

  final Map<String, Map<String, dynamic>> _temporaryTestData = {};


  CalibrationProvider(this._repository);
  // Getters
  String get currentDbName => _currentDbName;
  CalibrationData? get currentData => _currentData;
  bool get isDataSaved => _isDataSaved;
  String? get currentTestType => _currentTestType;

  Map<String, dynamic>? getTempDataForTest(String testType) {
    return _temporaryTestData[testType];
  }

  void updateTempDataForTest(String testType, Map<String, dynamic> data) {
    _temporaryTestData[testType] = data;
    notifyListeners();
  }

  void clearTempDataForTest(String testType) {
    _temporaryTestData.remove(testType);
    notifyListeners();
  }

  // Métodos comunes
  Future<void> initializeTest(String dbName, String testType) async {
    _currentDbName = dbName;
    _currentTestType = testType;
    _isDataSaved = false;
    await _loadData();
    notifyListeners();
  }

  Future<void> _loadData() async {
    final data = await _repository.getCalibrationData(_currentDbName, _currentDbName);
    _currentData = CalibrationData(
      codMetrica: data['cod_metrica'] ?? '',
      secaValue: data['seca'] ?? '',
      balanzaData: data,
      lastServiceData: data,
    );
  }

  Future<bool> saveTestData(Map<String, dynamic> testData) async {
    try {
      await _repository.saveCalibrationData(_currentDbName, testData);
      _isDataSaved = true;
      notifyListeners();
      return true;
    } catch (e) {

      return false;
    }
  }

  void resetTest() {
    _currentDbName = '';
    _currentData = null;
    _isDataSaved = false;
    _currentTestType = null;
    notifyListeners();
  }
}