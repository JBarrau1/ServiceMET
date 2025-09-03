import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';

class DataStorage {
  Future<String> _getFilePath() async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/calibracion_data.csv';
  }

  Future<void> saveToCsv(List<List<dynamic>> data, String fileName) async {
    String csvData = const ListToCsvConverter(fieldDelimiter: ';').convert(data);
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/$fileName.csv';
    final file = File(path);
    await file.writeAsString(csvData);
  }

  Future<void> saveData(List<List<dynamic>> data) async {
    String csvData = const ListToCsvConverter(fieldDelimiter: ';').convert(data);
    final path = await _getFilePath();
    final file = File(path);
    await file.writeAsString(csvData);
  }

  Future<String> readData() async {
    try {
      final path = await _getFilePath();
      final file = File(path);
      return await file.readAsString();
    } catch (e) {
      return 'Error reading file: $e';
    }
  }
}