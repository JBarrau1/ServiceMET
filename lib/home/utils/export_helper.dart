import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import '../models/servicio_model.dart';

class ExportHelper {
  static Future<void> exportarSecaDirectamente(
      BuildContext context, ServicioSeca servicio) async {
    try {
      final List<List<dynamic>> csvData = [];

      if (servicio.balanzas.isNotEmpty) {
        csvData.add(servicio.balanzas.first.keys.toList());
      }

      for (var balanza in servicio.balanzas) {
        csvData.add(balanza.values.toList());
      }

      String csv = const ListToCsvConverter().convert(csvData);
      final directory = await getDownloadsDirectory();
      final path = directory?.path;

      if (path == null) {
        throw Exception('No se pudo acceder al directorio de descargas');
      }

      final fileName =
          'SECA_${servicio.seca}_${DateTime.now().millisecondsSinceEpoch}.csv';
      final filePath = '$path/$fileName';
      final File file = File(filePath);
      await file.writeAsString(csv);

      OpenFilex.open(filePath);

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Archivo exportado: $fileName'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error al exportar: $e'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  static Future<void> exportarOtstDirectamente(
      BuildContext context, ServicioOtst servicio) async {
    try {
      final List<List<dynamic>> csvData = [];

      if (servicio.servicios.isNotEmpty) {
        csvData.add(servicio.servicios.first.keys.toList());
      }

      for (var serv in servicio.servicios) {
        csvData.add(serv.values.toList());
      }

      String csv = const ListToCsvConverter().convert(csvData);
      final directory = await getDownloadsDirectory();
      final path = directory?.path;

      if (path == null) {
        throw Exception('No se pudo acceder al directorio de descargas');
      }

      final fileName =
          'OTST_${servicio.otst}_${DateTime.now().millisecondsSinceEpoch}.csv';
      final filePath = '$path/$fileName';
      final File file = File(filePath);
      await file.writeAsString(csv);

      OpenFilex.open(filePath);

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Archivo exportado: $fileName'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error al exportar: $e'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }
}
