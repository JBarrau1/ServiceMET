// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../../database/soporte_tecnico/database_helper_ajustes.dart';
import '../../../../../database/soporte_tecnico/database_helper_diagnostico_correctivo.dart';
import '../models/diagnostico_model.dart';
import 'package:archive/archive.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'dart:typed_data';

class DiagnosticoController {
  final DiagnosticoModel model;

  // Cache para d1
  double? _cachedD1;

  DiagnosticoController({required this.model});

  /// Inicializa datos necesarios
  Future<void> init() async {
    // Cargar hora inicio si está vacía
    if (model.horaInicio.isEmpty) {
      // La hora se setea en el modelo o en la vista al iniciar
    }
    // Cargar d1
    await getD1FromDatabase();
  }

  /// Obtiene d1 de la base de datos (copiado de AjusteVerificacionesController)
  Future<double> getD1FromDatabase() async {
    if (_cachedD1 != null) return _cachedD1!;

    try {
      final dbHelper = DatabaseHelperAjustes();
      final db = await dbHelper.database;
      final List<Map<String, dynamic>> result = await db.query(
        'ajustes_metrologicos',
        columns: ['d1'],
        where: 'cod_metrica = ? AND otst = ?',
        whereArgs: [model.codMetrica, model.secaValue],
        limit: 1,
      );

      if (result.isNotEmpty) {
        final d1 = double.tryParse(result.first['d1'].toString()) ?? 0.0;
        _cachedD1 = d1;
        return d1;
      }
    } catch (e) {
      debugPrint('Error obteniendo d1: $e');
    }
    return 0.0;
  }

  /// Calcula sugerencias de indicación basadas en d
  List<String> getIndicationSuggestions(double carga, double d) {
    if (d == 0) return [];

    // Generar sugerencias: carga, carga + d, carga - d, etc.
    // Lógica simplificada similar a STIL
    return [
      carga.toString(),
      (carga + d).toStringAsFixed(getDecimalPlaces(d)),
      (carga - d).toStringAsFixed(getDecimalPlaces(d)),
    ];
  }

  int getDecimalPlaces(double value) {
    String text = value.toString();
    if (text.contains('.')) {
      return text.split('.')[1].length;
    }
    return 0;
  }

  // --- MÉTODOS DE FOTOS (Similar a STIL/Ajustes) ---

  Future<void> agregarFoto(String campo, File foto) async {
    model.addPhoto(campo, foto);
  }

  void eliminarFoto(String campo, int index) {
    if (model.fieldPhotos.containsKey(campo) &&
        model.fieldPhotos[campo]!.length > index) {
      model.fieldPhotos[campo]!.removeAt(index);
    }
  }

  void limpiarFotos(String campo) {
    model.clearPhotos(campo);
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
        .replaceAll(RegExp(r'[^\w\.-]'), ''); // Eliminar caracteres especiales
  }

  Future<void> _savePhotos(BuildContext context) async {
    bool hasPhotos =
        model.fieldPhotos.values.any((photos) => photos.isNotEmpty);

    if (hasPhotos) {
      try {
        final archive = Archive();
        model.fieldPhotos.forEach((label, photos) {
          for (var i = 0; i < photos.length; i++) {
            final file = photos[i];
            // Usar etiqueta sanitizada
            final safeLabel = _sanitizeFileName(label);
            final fileName = '${safeLabel}_${i + 1}.jpg';

            if (file.existsSync()) {
              final bytes = file.readAsBytesSync();
              archive.addFile(ArchiveFile(fileName, bytes.length, bytes));
            }
          }
        });

        final zipEncoder = ZipEncoder();
        final zipData = zipEncoder.encode(archive);

        final uint8ListData = Uint8List.fromList(zipData);
        final zipFileName =
            '${model.secaValue}_${model.codMetrica}_diagnostico.zip';

        final params = SaveFileDialogParams(
          data: uint8ListData,
          fileName: zipFileName,
          mimeTypesFilter: ['application/zip'],
        );

        final filePath = await FlutterFileDialog.saveFile(params: params);
        if (filePath != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Fotos guardadas en $filePath')),
          );
        }
      } catch (e) {
        debugPrint('Error al guardar fotos: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error al guardar fotos: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  // --- GUARDADO A BASE DE DATOS ---

  Future<void> saveData(BuildContext context) async {
    try {
      // 1. Guardar Fotos
      await _savePhotos(context);

      // 2. Guardar Datos BD
      final DatabaseHelperDiagnosticoCorrectivo dbHelper =
          DatabaseHelperDiagnosticoCorrectivo();
      final data = _prepareDataForSave();

      await dbHelper.upsertRegistroRelevamiento(data);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Datos guardados exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint('Error SAVE DATA: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Map<String, dynamic> _prepareDataForSave() {
    final Map<String, dynamic> data = {
      'session_id': model.sessionId,
      'cod_metrica': model.codMetrica,
      'otst': model.secaValue,
      'estado_servicio': 'Completo',
      'tipo_servicio': 'diagnostico',
      'hora_inicio': model.horaInicio,
      'hora_fin': model.horaFin,
      'reporte': model.reporteFalla,
      'evaluacion': model.evaluacion,
    };

    // Comentarios
    for (int i = 0; i < model.comentarios.length; i++) {
      if (model.comentarios[i] != null && model.comentarios[i]!.isNotEmpty) {
        data['comentario_${i + 1}'] = model.comentarios[i];
      }
    }

    // Pruebas Metrológicas (Iniciales)
    _addPruebasMetrologicasData(data, model.pruebasIniciales, 'inicial');

    return data;
  }

  void _addPruebasMetrologicasData(
      Map<String, dynamic> data, PruebasMetrologicas pruebas, String tipo) {
    // Retorno a Cero
    data['retorno_cero_${tipo}_valoracion'] = pruebas.retornoCero.estado;
    data['retorno_cero_${tipo}_carga'] =
        pruebas.retornoCero.estabilidad; // Priorizar estabilidad
    data['retorno_cero_${tipo}_unidad'] = pruebas.retornoCero.unidad;

    // Excentricidad
    if (pruebas.excentricidad != null && pruebas.excentricidad!.activo) {
      final exc = pruebas.excentricidad!;
      data['excentricidad_${tipo}_tipo_plataforma'] = exc.tipoPlataforma ?? '';
      data['excentricidad_${tipo}_opcion_prueba'] = exc.puntosIndicador ?? '';
      data['excentricidad_${tipo}_carga'] = exc.carga;

      // Fotos se manejan aparte en el ZIP, pero guadamos path si aplica
      data['excentricidad_${tipo}_ruta_imagen'] = exc.imagenPath ?? '';

      data['excentricidad_${tipo}_cantidad_posiciones'] =
          exc.posiciones.length.toString();

      for (int i = 0; i < exc.posiciones.length && i < 6; i++) {
        final pos = exc.posiciones[i];
        final num = i + 1;
        data['excentricidad_${tipo}_pos${num}_numero'] = pos.posicion;
        data['excentricidad_${tipo}_pos${num}_indicacion'] = pos.indicacion;
        data['excentricidad_${tipo}_pos${num}_retorno'] = pos.retorno;
        // Error calculado en DB helper o aqui? En stac_diagnostico se calculaba: indicacion - posicion
        double ind = double.tryParse(pos.indicacion) ?? 0;
        double p = double.tryParse(pos.posicion) ?? 0;
        data['excentricidad_${tipo}_pos${num}_error'] =
            (ind - p).toStringAsFixed(2);
      }
    }

    // Repetibilidad
    if (pruebas.repetibilidad != null && pruebas.repetibilidad!.activo) {
      final rep = pruebas.repetibilidad!;
      data['repetibilidad_${tipo}_cantidad_cargas'] =
          rep.cantidadCargas.toString();
      data['repetibilidad_${tipo}_cantidad_pruebas'] =
          rep.cantidadPruebas.toString();

      for (int i = 0; i < rep.cargas.length; i++) {
        final carga = rep.cargas[i];
        final cNum = i + 1;
        data['repetibilidad_${tipo}_carga${cNum}_valor'] = carga.valor;

        for (int j = 0; j < carga.pruebas.length; j++) {
          final prueba = carga.pruebas[j];
          final pNum = j + 1;
          data['repetibilidad_${tipo}_carga${cNum}_prueba${pNum}_indicacion'] =
              prueba.indicacion;
          data['repetibilidad_${tipo}_carga${cNum}_prueba${pNum}_retorno'] =
              prueba.retorno;
        }
      }
    }

    // Linealidad
    if (pruebas.linealidad != null && pruebas.linealidad!.activo) {
      final lin = pruebas.linealidad!;
      data['linealidad_${tipo}_cantidad_puntos'] = lin.puntos.length.toString();

      for (int i = 0; i < lin.puntos.length; i++) {
        final pNum = i + 1;
        // Db espera puntos 1..12
        if (pNum > 12) break;

        final punto = lin.puntos[i];
        data['linealidad_${tipo}_punto${pNum}_lt'] = punto.lt;
        data['linealidad_${tipo}_punto${pNum}_indicacion'] = punto.indicacion;
        data['linealidad_${tipo}_punto${pNum}_retorno'] = punto.retorno;

        // Error
        double l = double.tryParse(punto.lt) ?? 0;
        double ind = double.tryParse(punto.indicacion) ?? 0;
        data['linealidad_${tipo}_punto${pNum}_error'] =
            (ind - l).toStringAsFixed(2);
      }
    }
  }
}
