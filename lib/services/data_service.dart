import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class DataService {
  static final DataService _instance = DataService._internal();

  factory DataService() {
    return _instance;
  }

  DataService._internal();

  Future<void> saveData(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  Future<String?> getData(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  Future<void> clearData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  Future<void> exportCsv() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    final data = keys.map((key) => '$key,${prefs.getString(key)}').join('\n');

    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/datos_servicio.csv';
    final file = File(path);
    await file.writeAsString(data);

    print('Datos exportados a $path');
  }
}
