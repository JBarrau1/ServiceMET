// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:archive/archive.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:service_met/database/soporte_tecnico/database_helper_ajustes.dart';

import '../models/ajuste_verificaciones_model.dart';

class AjusteVerificacionesController {
  final AjusteVerificacionesModel model;
  final Map<String, List<File>> _fieldPhotos = {};

  AjusteVerificacionesController({required this.model});

  void copiarPruebasInicialesAFinales() {
    model.pruebasFinales =
        PruebasMetrologicas.fromOther(model.pruebasIniciales);
  }

  Future<double> getD1FromDatabase() async {
    try {
      final dbHelper = DatabaseHelperAjustes();
      final db = await dbHelper.database;

      final results = await db.query(
        'ajustes_metrologicos',
        columns: ['d1'],
        where: 'session_id = ? AND cod_metrica = ?',
        whereArgs: [model.sessionId, model.codMetrica],
        limit: 1,
      );

      if (results.isNotEmpty && results.first['d1'] != null) {
        final d1Value = results.first['d1'];
        if (d1Value is double) {
          return d1Value;
        } else if (d1Value is int) {
          return d1Value.toDouble();
        } else if (d1Value is String) {
          return double.tryParse(d1Value) ?? 0.1;
        }
      }

      return 0.1;
    } catch (e) {
      debugPrint('Error al obtener d1: $e');
      return 0.1;
    }
  }

  Future<double> getDForCarga(double carga) async {
    try {
      final dbHelper = DatabaseHelperAjustes();
      final db = await dbHelper.database;

      final results = await db.query(
        'ajustes_metrologicos',
        columns: ['d1', 'd2', 'd3', 'cap_max1', 'cap_max2', 'cap_max3'],
        where: 'session_id = ? AND cod_metrica = ?',
        whereArgs: [model.sessionId, model.codMetrica],
        limit: 1,
      );

      if (results.isNotEmpty) {
        final data = results.first;
        final d1 = double.tryParse(data['d1']?.toString() ?? '') ?? 0.1;
        final d2 = double.tryParse(data['d2']?.toString() ?? '') ?? 0.1;
        final d3 = double.tryParse(data['d3']?.toString() ?? '') ?? 0.1;

        final capMax1 =
            double.tryParse(data['cap_max1']?.toString() ?? '') ?? 0.0;
        final capMax2 =
            double.tryParse(data['cap_max2']?.toString() ?? '') ?? 0.0;
        final capMax3 =
            double.tryParse(data['cap_max3']?.toString() ?? '') ?? 0.0;

        if (carga <= capMax1 && capMax1 > 0) return d1;
        if (carga <= capMax2 && capMax2 > 0) return d2;
        if (carga <= capMax3 && capMax3 > 0) return d3;
        return d1;
      }
      return 0.1;
    } catch (e) {
      debugPrint('Error al obtener D: $e');
      return 0.1;
    }
  }

  int getDecimalPlaces(double dValue) {
    if (dValue >= 1) return 0;
    if (dValue >= 0.1) return 1;
    if (dValue >= 0.01) return 2;
    if (dValue >= 0.001) return 3;
    return 1;
  }

  Future<List<String>> getIndicationSuggestions(
      String cargaText, String currentValue) async {
    final carga = double.tryParse(cargaText.replaceAll(',', '.')) ?? 0.0;
    final dValue = await getDForCarga(carga);
    final decimalPlaces = getDecimalPlaces(dValue);

    // Si el valor actual está vacío, usa la carga como base
    final baseText = currentValue.trim().isEmpty ? cargaText : currentValue;
    final baseValue = double.tryParse(baseText.replaceAll(',', '.')) ?? carga;

    return List.generate(11, (i) {
      final value = baseValue + ((i - 5) * dValue);
      return value.toStringAsFixed(decimalPlaces);
    });
  }

  Future<void> saveDataToDatabase(BuildContext context,
      {bool showMessage = true}) async {
    try {
      final dbHelper = DatabaseHelperAjustes();
      final Map<String, dynamic> data = _prepareDataForSave();

      await dbHelper.upsertRegistroRelevamiento(data);

      if (showMessage && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Datos guardados exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error al guardar en BD: $e');
      if (showMessage && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      rethrow;
    }
  }

  Future<void> saveData(BuildContext context) async {
    try {
      await _savePhotos(context);

      // Luego guardar datos en la base de datos
      await saveDataToDatabase(context, showMessage: true);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar los datos: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _savePhotos(BuildContext context) async {
    bool hasPhotos = _fieldPhotos.values.any((photos) => photos.isNotEmpty);

    if (hasPhotos) {
      final archive = Archive();
      int totalSize = 0;

      _fieldPhotos.forEach((label, photos) {
        for (var i = 0; i < photos.length; i++) {
          final file = photos[i];
          final fileSize = file.lengthSync();
          totalSize += fileSize;

          // ⚠️ Advertir si el archivo es muy grande (> 5MB)
          if (fileSize > 5 * 1024 * 1024) {
            debugPrint(
                '⚠️ Foto grande detectada: ${label}_${i + 1} - ${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB');
          }

          final fileName = '${_sanitizeFileName(label)}_${i + 1}.jpg';
          archive.addFile(ArchiveFile(
            fileName,
            file.lengthSync(),
            file.readAsBytesSync(),
          ));
        }
      });

      debugPrint(
          '📦 Tamaño total de fotos: ${(totalSize / 1024 / 1024).toStringAsFixed(2)} MB');

      final zipEncoder = ZipEncoder();
      final zipData = zipEncoder.encode(archive);

      final uint8ListData = Uint8List.fromList(zipData);
      final zipFileName =
          '${model.secaValue}_${model.codMetrica}_fotos_${DateTime.now().millisecondsSinceEpoch}.zip';

      final params = SaveFileDialogParams(
        data: uint8ListData,
        fileName: zipFileName,
        mimeTypesFilter: ['application/zip'],
      );

      try {
        final filePath = await FlutterFileDialog.saveFile(params: params);
        if (filePath != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Fotos guardadas en $filePath')),
          );
        } else if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se seleccionó ninguna carpeta')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al guardar el archivo: $e')),
          );
        }
      }
    }
  }

  String _sanitizeFileName(String name) {
    return name
        .replaceAll(' ', '_')
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ñ', 'n')
        .replaceAll(RegExp(r'[^\w\-]'), '');
  }

  // Métodos de gestión de fotos
  void agregarFoto(String campo, File foto) {
    if (!_fieldPhotos.containsKey(campo)) {
      _fieldPhotos[campo] = [];
    }

    if (_fieldPhotos[campo]!.length >= 5) {
      debugPrint('⚠️ Límite de 5 fotos alcanzado para: $campo');
      return;
    }

    _fieldPhotos[campo]!.add(foto);
    // Nota: El modelo de Ajustes no tiene camposEstado, así que solo guardamos en el controller
    // Si se necesitara impactar el modelo para Excentricidad, se haría aquí.
  }

  void eliminarFoto(String campo, int index) {
    if (_fieldPhotos.containsKey(campo) &&
        index < _fieldPhotos[campo]!.length) {
      _fieldPhotos[campo]!.removeAt(index);
    }
  }

  void limpiarFotos() {
    _fieldPhotos.clear();
  }

  Map<String, dynamic> _prepareDataForSave() {
    final data = <String, dynamic>{
      'tipo_servicio': 'ajustes y verificaciones',
      'estado_servicio': 'Completo',
      'session_id': model.sessionId,
      'cod_metrica': model.codMetrica,
      'otst': model.secaValue,
      'hora_inicio': model.horaInicio,
      'hora_fin': model.horaFin,
    };

    // Comentarios
    for (int i = 0; i < model.comentarios.length; i++) {
      if (model.comentarios[i] != null && model.comentarios[i]!.isNotEmpty) {
        data['comentario_${i + 1}'] = model.comentarios[i];
      }
    }

    _addPruebasMetrologicasData(data, model.pruebasIniciales, 'inicial');
    _addPruebasMetrologicasData(data, model.pruebasFinales, 'final');

    return data;
  }

  void _addPruebasMetrologicasData(
      Map<String, dynamic> data, PruebasMetrologicas pruebas, String tipo) {
    // Retorno a Cero
    data['retorno_cero_${tipo}_valoracion'] = pruebas.retornoCero.estado;
    // Mapeo solicitado: Estabilidad se guarda en la columna de carga
    data['retorno_cero_${tipo}_carga'] = pruebas.retornoCero.estabilidad;
    data['retorno_cero_${tipo}_unidad'] = pruebas.retornoCero.unidad;

    // Excentricidad
    _addExcentricidadData(data, pruebas.excentricidad, tipo);

    // Repetibilidad
    _addRepetibilidadData(data, pruebas.repetibilidad, tipo);

    // Linealidad
    _addLinealidadData(data, pruebas.linealidad, tipo);
  }

  void _addExcentricidadData(
      Map<String, dynamic> data, Excentricidad? exc, String tipo) {
    if (exc?.activo ?? false) {
      data['excentricidad_${tipo}_tipo_plataforma'] = exc!.tipoPlataforma ?? '';
      data['excentricidad_${tipo}_opcion_prueba'] = exc.puntosIndicador ?? '';
      data['excentricidad_${tipo}_carga'] = exc.carga;

      for (int i = 0; i < exc.posiciones.length && i < 6; i++) {
        final pos = exc.posiciones[i];
        final num = i + 1;

        data['excentricidad_${tipo}_pos${num}_numero'] = pos.posicion;
        data['excentricidad_${tipo}_pos${num}_indicacion'] = pos.indicacion;
        data['excentricidad_${tipo}_pos${num}_retorno'] = pos.retorno;
      }
    }
  }

  void _addRepetibilidadData(
      Map<String, dynamic> data, Repetibilidad? rep, String tipo) {
    if (rep?.activo ?? false) {
      // Campos adicionales de conteo
      data['repetibilidad_${tipo}_cantidad_cargas'] =
          rep!.cantidadCargas.toString();
      data['repetibilidad_${tipo}_cantidad_pruebas'] =
          rep.cantidadPruebas.toString();

      for (int i = 0; i < rep.cargas.length; i++) {
        final carga = rep.cargas[i];
        final cNum = i + 1;
        data['repetibilidad_${tipo}_carga${cNum}_valor'] = carga.valor;

        for (int j = 0; j < carga.pruebas.length; j++) {
          final pNum = j + 1;
          data['repetibilidad_${tipo}_carga${cNum}_prueba${pNum}_indicacion'] =
              carga.pruebas[j].indicacion;
          data['repetibilidad_${tipo}_carga${cNum}_prueba${pNum}_retorno'] =
              carga.pruebas[j].retorno;
        }
      }
    }
  }

  void _addLinealidadData(
      Map<String, dynamic> data, Linealidad? lin, String tipo) {
    if (lin?.activo ?? false) {
      data['linealidad_${tipo}_cantidad_puntos'] =
          lin!.puntos.length.toString();

      for (int i = 0; i < lin.puntos.length; i++) {
        final punto = lin.puntos[i];
        final pNum = i + 1;
        data['linealidad_${tipo}_punto${pNum}_lt'] = punto.lt;
        data['linealidad_${tipo}_punto${pNum}_indicacion'] = punto.indicacion;
        data['linealidad_${tipo}_punto${pNum}_retorno'] = punto.retorno;

        try {
          final ind = double.tryParse(punto.indicacion) ?? 0;
          final lt = double.tryParse(punto.lt) ?? 0;
          data['linealidad_${tipo}_punto${pNum}_error'] =
              (ind - lt).toStringAsFixed(2);
        } catch (_) {}
      }
    }
  }
}
