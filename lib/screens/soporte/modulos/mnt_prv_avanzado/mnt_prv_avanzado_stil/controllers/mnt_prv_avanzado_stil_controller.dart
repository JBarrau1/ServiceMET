// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:archive/archive.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import '../../../../../../database/soporte_tecnico/database_helper_mnt_prv_avanzado_stil.dart';
import '../models/mnt_prv_avanzado_stil_model.dart';

class MntPrvAvanzadoStilController {
  final MntPrvAvanzadoStilModel model;
  final Map<String, List<File>> _fieldPhotos = {};

  MntPrvAvanzadoStilController({required this.model});

  void copiarPruebasInicialesAFinales() {
    model.copiarPruebasInicialesAFinales();
  }

  // OPTIMIZADO: Obtener d1 sin múltiples consultas
  Future<double> getD1FromDatabase() async {
    try {
      final dbHelper = DatabaseHelperMntPrvAvanzadoStil();
      final db = await dbHelper.database;

      final results = await db.query(
        'mnt_prv_avanzado_stil',
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

  // NUEVO: Método para guardar solo en BD (sin fotos)
  Future<void> saveDataToDatabase(BuildContext context,
      {bool showMessage = true}) async {
    try {
      final dbHelper = DatabaseHelperMntPrvAvanzadoStil();
      final Map<String, dynamic> mntPrvData = _prepareDataForSave();

      mntPrvData['session_id'] = model.sessionId;
      mntPrvData['otst'] = model.secaValue;

      await dbHelper.upsertRegistroRelevamiento(mntPrvData);

      if (showMessage && context.mounted) {
        _showSnackBar(
          context,
          'Datos guardados exitosamente',
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
      }
    } catch (e) {
      debugPrint('Error al guardar en BD: $e');
      if (showMessage && context.mounted) {
        _showSnackBar(
          context,
          'Error al guardar: ${e.toString()}',
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
      rethrow;
    }
  }

  // ✅ Método completo: guardar datos + fotos
  Future<void> saveData(BuildContext context) async {
    try {
      // Primero guardar fotos si existen
      await _savePhotos(context);

      // Luego guardar datos en la base de datos
      await saveDataToDatabase(context, showMessage: true);
    } catch (e) {
      if (context.mounted) {
        _showSnackBar(
          context,
          'Error al guardar los datos: ${e.toString()}',
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    }
  }

  // ✅ MEJORADO: Guardar fotos con compresión
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
          _showSnackBar(context, 'Fotos guardadas en $filePath');
        } else if (context.mounted) {
          _showSnackBar(context, 'No se seleccionó ninguna carpeta');
        }
      } catch (e) {
        if (context.mounted) {
          _showSnackBar(context, 'Error al guardar el archivo: $e');
        }
      }
    }
  }

  // ✅ Sanitizar nombres de archivo
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

  // ✅ MEJORADO: Preparar datos con validación
  Map<String, dynamic> _prepareDataForSave() {
    final data = <String, dynamic>{
      'estado_servicio': 'Completo',
      'session_id': model.sessionId,
      'cod_metrica': model.codMetrica,
      'otst': model.secaValue,
      'tipo_servicio': 'mnt prv regular stil',
      'hora_inicio': model.horaInicio,
      'hora_fin': model.horaFin,
      'comentario_general': model.comentarioGeneral,
      'recomendacion': model.recomendacion,
      'estado_fisico': model.estadoFisico,
      'estado_operacional': model.estadoOperacional,
      'estado_metrologico': model.estadoMetrologico,
      'fecha_prox_servicio': model.fechaProxServicio,
    };

    _addCamposEstadoData(data);
    _addPruebasMetrologicasData(data);

    return data;
  }

  // ✅ REFACTORIZADO: Agregar datos de campos de estado
  void _addCamposEstadoData(Map<String, dynamic> data) {
    // Función auxiliar simplificada
    void addCampo(String dbKey, String modelKey) {
      final campo = model.camposEstado[modelKey];
      if (campo != null) {
        data['${dbKey}_estado'] = campo.initialValue;
        data['${dbKey}_solucion'] = campo.solutionValue;
        data['${dbKey}_comentario'] = campo.comentario;
        data['${dbKey}_foto'] = campo.fotos.isNotEmpty
            ? campo.fotos.map((f) => f.path.split('/').last).join(',')
            : '';
      }
    }

    // Mapeo de campos (DB key -> Model key)
    final camposMap = {
      // Entorno
      'vibracion': 'Vibración',
      'polvo': 'Polvo',
      'temperatura': 'Temperatura',
      'humedad': 'Humedad',
      'mesada': 'Mesada',
      'iluminacion': 'Iluminación',
      'limpieza_fosa': 'Limpieza de Fosa',
      'estado_drenaje': 'Estado de Drenaje',

      // Terminal
      'carcasa': 'Carcasa',
      'teclado_fisico': 'Teclado Fisico',
      'display_fisico': 'Display Fisico',
      'fuente_poder': 'Fuente de poder',
      'bateria_operacional': 'Bateria operacional',
      'bracket': 'Bracket',
      'teclado_operativo': 'Teclado Operativo',
      'display_operativo': 'Display Operativo',
      'conector_celda': 'Contector de celda',
      'bateria_memoria': 'Bateria de memoria',

      // Balanza
      'limpieza_general': 'Limpieza general',
      'golpes_terminal': 'Golpes al terminal',
      'nivelacion': 'Nivelacion',
      'limpieza_receptor': 'Limpieza receptor',
      'golpes_receptor': 'Golpes al receptor de carga',
      'encendido': 'Encendido',

      // Plataforma
      'limitador_movimiento': 'Limitador de movimiento',
      'suspension': 'Suspensión',
      'limitador_carga': 'Limitador de carga',
      'celda_carga': 'Celda de carga',

      // Caja sumadora
      'tapa_caja': 'Tapa de caja sumadora',
      'humedad_interna': 'Humedad Interna',
      'estado_prensacables': 'Estado de prensacables',
      'estado_borneas': 'Estado de borneas',
      'trabajo_especial': 'Trabajo especial'
    };

    camposMap.forEach((dbKey, modelKey) => addCampo(dbKey, modelKey));
  }

  // ✅ MEJORADO: Agregar pruebas metrológicas con null-safety
  void _addPruebasMetrologicasData(Map<String, dynamic> data) {
    // Retorno a Cero y Estabilidad - Inicial
    data['retorno_cero_inicial_valoracion'] =
        model.pruebasIniciales.retornoCero.estado;
    data['estabilizacion_inicial'] =
        model.pruebasIniciales.retornoCero.estabilidad;
    data['unidad_retorno_cero_inicial'] =
        model.pruebasIniciales.retornoCero.unidad;

    // Retorno a Cero y Estabilidad - Final
    data['retorno_cero_final_valoracion'] =
        model.pruebasFinales.retornoCero.estado;
    data['estabilizacion_final'] = model.pruebasFinales.retornoCero.estabilidad;
    data['unidad_retorno_cero_final'] = model.pruebasFinales.retornoCero.unidad;

    // Excentricidad inicial
    _addExcentricidadData(
        data, model.pruebasIniciales.excentricidad, 'inicial');

    // Repetibilidad inicial
    _addRepetibilidadData(
        data, model.pruebasIniciales.repetibilidad, 'inicial');

    // Linealidad inicial
    _addLinealidadData(data, model.pruebasIniciales.linealidad, 'inicial');

    // Excentricidad final
    _addExcentricidadData(data, model.pruebasFinales.excentricidad, 'final');

    // Repetibilidad final
    _addRepetibilidadData(data, model.pruebasFinales.repetibilidad, 'final');

    // Linealidad final
    _addLinealidadData(data, model.pruebasFinales.linealidad, 'final');
  }

  void _addExcentricidadData(
      Map<String, dynamic> data, Excentricidad? exc, String tipo) {
    if (exc?.activo ?? false) {
      data['tipo_plataforma_$tipo'] = exc!.tipoPlataforma ?? '';
      data['puntos_ind_$tipo'] = exc.puntosIndicador ?? '';
      data['carga_exc_$tipo'] = exc.carga;

      for (int i = 0; i < exc.posiciones.length; i++) {
        final pos = exc.posiciones[i];
        final num = i + 1;
        data['posicion_${tipo}_$num'] = pos.posicion;
        data['indicacion_${tipo}_$num'] = pos.indicacion;
        data['retorno_${tipo}_$num'] = pos.retorno;
      }
    }
  }

  void _addRepetibilidadData(
      Map<String, dynamic> data, Repetibilidad? rep, String tipo) {
    if (rep?.activo ?? false) {
      for (int i = 0; i < rep!.cargas.length; i++) {
        final carga = rep.cargas[i];
        final cargaNum = i + 1;
        data['repetibilidad${cargaNum}_$tipo'] = carga.valor;

        for (int j = 0; j < carga.pruebas.length; j++) {
          final prueba = carga.pruebas[j];
          final testNum = j + 1;
          data['indicacion${cargaNum}_${tipo}_$testNum'] = prueba.indicacion;
          data['retorno${cargaNum}_${tipo}_$testNum'] = prueba.retorno;
        }
      }
    }
  }

  void _addLinealidadData(
      Map<String, dynamic> data, Linealidad? lin, String tipo) {
    if (lin?.activo ?? false) {
      for (int i = 0; i < lin!.puntos.length; i++) {
        final punto = lin.puntos[i];
        final num = i + 1;
        data['lin_${tipo}_$num'] = punto.lt;
        data['ind_${tipo}_$num'] = punto.indicacion;
        data['retorno_lin_${tipo}_$num'] = punto.retorno;
      }
    }
  }

  void _showSnackBar(BuildContext context, String message,
      {Color? backgroundColor, Color? textColor}) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: textColor ?? Colors.white),
        ),
        backgroundColor: backgroundColor ?? Colors.grey[700],
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Métodos de gestión de fotos
  void agregarFoto(String campo, File foto) {
    if (!_fieldPhotos.containsKey(campo)) {
      _fieldPhotos[campo] = [];
    }

    // ✅ Limitar a 5 fotos por campo
    if (_fieldPhotos[campo]!.length >= 5) {
      debugPrint('⚠️ Límite de 5 fotos alcanzado para: $campo');
      return;
    }

    _fieldPhotos[campo]!.add(foto);
    model.camposEstado[campo]?.agregarFoto(foto);
  }

  void eliminarFoto(String campo, int index) {
    if (_fieldPhotos.containsKey(campo) &&
        index < _fieldPhotos[campo]!.length) {
      _fieldPhotos[campo]!.removeAt(index);
      model.camposEstado[campo]?.eliminarFoto(index);
    }
  }

  void limpiarFotos() {
    _fieldPhotos.clear();
    model.camposEstado.forEach((key, value) {
      value.limpiarFotos();
    });
  }
}
