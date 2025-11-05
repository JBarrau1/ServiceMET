import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:archive/archive.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import '../../../../../../database/soporte_tecnico/database_helper_mnt_prv_regular_stil.dart';
import '../models/mnt_prv_regular_stil_model.dart';

class MntPrvRegularStilController {
  final MntPrvRegularStilModel model;
  final Map<String, List<File>> _fieldPhotos = {};


  MntPrvRegularStilController({required this.model});

  void copiarPruebasInicialesAFinales() {
    model.copiarPruebasInicialesAFinales();
  }

  Future<double> getD1FromDatabase() async {
    try {
      // ✅ USAR DatabaseHelperSop en lugar de abrir BD manualmente
      final dbHelper = DatabaseHelperMntPrvRegularStil();
      final db = await dbHelper.database;

      // Consultar d1 desde inf_cliente_balanza usando session_id y cod_metrica
      final results = await db.query(
        'inf_cliente_balanza',
        columns: ['d1'],
        where: 'session_id = ? AND cod_metrica = ?',
        whereArgs: [model.sessionId, model.codMetrica],
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

      // Si no encuentra d1, intentar obtenerlo de la balanza del provider
      try {
        // Esto requiere que el contexto esté disponible, así que lo manejamos con un try/catch separado
        // En la práctica, esta parte se manejará en el widget que llama a esta función
        return 0.1; // Valor por defecto
      } catch (e) {
        return 0.1; // Valor por defecto
      }

    } catch (e) {
      debugPrint('Error al obtener d1: $e');
      return 0.1; // Valor por defecto
    }
  }

  // Método para guardar datos
  Future<void> saveData(BuildContext context) async {
    try {
      // Primero guardar fotos si existen
      await _savePhotos(context);

      // Luego guardar datos en la base de datos
      await _saveToDatabase(context);

      // Mostrar mensaje de éxito
      _showSnackBar(context, 'Datos guardados exitosamente',
          backgroundColor: Colors.green, textColor: Colors.white);

    } catch (e) {
      _showSnackBar(context, 'Error al guardar los datos: ${e.toString()}',
          backgroundColor: Colors.red, textColor: Colors.white);
    }
  }

  // Método privado para guardar fotos
  Future<void> _savePhotos(BuildContext context) async {
    bool hasPhotos = _fieldPhotos.values.any((photos) => photos.isNotEmpty);

    if (hasPhotos) {
      final archive = Archive();
      _fieldPhotos.forEach((label, photos) {
        for (var i = 0; i < photos.length; i++) {
          final file = photos[i];
          final fileName = '${label}_${i + 1}.jpg';
          archive.addFile(ArchiveFile(
              fileName, file.lengthSync(), file.readAsBytesSync()));
        }
      });

      final zipEncoder = ZipEncoder();
      final zipData = zipEncoder.encode(archive);

      final uint8ListData = Uint8List.fromList(zipData!);
      final zipFileName =
          '${model.secaValue}_${model.codMetrica}_relevamiento_de_datos_fotos.zip';

      final params = SaveFileDialogParams(
        data: uint8ListData,
        fileName: zipFileName,
        mimeTypesFilter: ['application/zip'],
      );

      try {
        final filePath = await FlutterFileDialog.saveFile(params: params);
        if (filePath != null) {
          _showSnackBar(context, 'Fotos guardadas en $filePath');
        } else {
          _showSnackBar(context, 'No se seleccionó ninguna carpeta');
        }
      } catch (e) {
        _showSnackBar(context, 'Error al guardar el archivo: $e');
      }
    }
  }

  Map<String, dynamic> _prepareDataForSave() {
    final data = <String, dynamic>{
      // ✅ AGREGAR campos de identificación
      'session_id': model.sessionId,
      'cod_metrica': model.codMetrica,
      'otst': model.secaValue,

      // Campos básicos
      'tipo_servicio': 'mnt prv regular stil',
      'hora_inicio': model.horaInicio,
      'hora_fin': model.horaFin,
      'comentario_general': model.comentarioGeneral,
      'recomendacion': model.recomendacion,
      'estado_fisico': model.estadoFisico,
      'estado_operacional': model.estadoOperacional,
      'estado_metrologico': model.estadoMetrologico,
    };

    // Agregar datos de campos de estado
    _addCamposEstadoData(data);

    // Agregar datos de pruebas metrológicas
    _addPruebasMetrologicasData(data);

    return data;
  }

  // ✅ NUEVO: Agregar datos de campos de estado
  void _addCamposEstadoData(Map<String, dynamic> data) {
    // Función auxiliar para obtener datos de un campo
    void addCampoData(String key, CampoEstado campo) {
      data['${key}_estado'] = campo.initialValue;
      data['${key}_solucion'] = campo.solutionValue;
      data['${key}_comentario'] = campo.comentario;
      data['${key}_foto'] = campo.fotos.map((f) => f.path.split('/').last).join(',');
    }

    // Entorno de instalación
    addCampoData('vibracion', model.camposEstado['Vibración']!);
    addCampoData('polvo', model.camposEstado['Polvo']!);
    addCampoData('temperatura', model.camposEstado['Temperatura']!);
    addCampoData('humedad', model.camposEstado['Humedad']!);
    addCampoData('mesada', model.camposEstado['Mesada']!);
    addCampoData('iluminacion', model.camposEstado['Iluminación']!);
    addCampoData('limpieza_fosa', model.camposEstado['Limpieza de Fosa']!);
    addCampoData('estado_drenaje', model.camposEstado['Estado de Drenaje']!);

    // Terminal de pesaje
    addCampoData('carcasa', model.camposEstado['Carcasa']!);
    addCampoData('teclado_fisico', model.camposEstado['Teclado Fisico']!);
    addCampoData('display_fisico', model.camposEstado['Display Fisico']!);
    addCampoData('fuente_poder', model.camposEstado['Fuente de poder']!);
    addCampoData('bateria_operacional', model.camposEstado['Bateria operacional']!);
    addCampoData('bracket', model.camposEstado['Bracket']!);
    addCampoData('teclado_operativo', model.camposEstado['Teclado Operativo']!);
    addCampoData('display_operativo', model.camposEstado['Display Operativo']!);
    addCampoData('conector_celda', model.camposEstado['Contector de celda']!);
    addCampoData('bateria_memoria', model.camposEstado['Bateria de memoria']!);

    // Estado general de la balanza
    addCampoData('limpieza_general', model.camposEstado['Limpieza general']!);
    addCampoData('golpes_terminal', model.camposEstado['Golpes al terminal']!);
    addCampoData('nivelacion', model.camposEstado['Nivelacion']!);
    addCampoData('limpieza_receptor', model.camposEstado['Limpieza receptor']!);
    addCampoData('golpes_receptor', model.camposEstado['Golpes al receptor de carga']!);
    addCampoData('encendido', model.camposEstado['Encendido']!);

    // Balanza/Plataforma
    addCampoData('limitador_movimiento', model.camposEstado['Limitador de movimiento']!);
    addCampoData('suspension', model.camposEstado['Suspensión']!);
    addCampoData('limitador_carga', model.camposEstado['Limitador de carga']!);
    addCampoData('celda_carga', model.camposEstado['Celda de carga']!);

    // Caja sumadora
    addCampoData('tapa_caja', model.camposEstado['Tapa de caja sumadora']!);
    addCampoData('humedad_interna', model.camposEstado['Humedad Interna']!);
    addCampoData('estado_prensacables', model.camposEstado['Estado de prensacables']!);
    addCampoData('estado_borneas', model.camposEstado['Estado de borneas']!);
  }

  // ✅ NUEVO: Agregar datos de pruebas metrológicas
  void _addPruebasMetrologicasData(Map<String, dynamic> data) {
    // Retorno a cero inicial
    data['retorno_cero_inicial'] = model.pruebasIniciales.retornoCero.estado;
    data['carga_retorno_cero_inicial'] = model.pruebasIniciales.retornoCero.valor;
    data['unidad_retorno_cero_inicial'] = model.pruebasIniciales.retornoCero.unidad;

    // Excentricidad inicial
    if (model.pruebasIniciales.excentricidad?.activo ?? false) {
      final exc = model.pruebasIniciales.excentricidad!;
      data['tipo_plataforma_inicial'] = exc.tipoPlataforma ?? '';
      data['puntos_ind_inicial'] = exc.puntosIndicador ?? '';
      data['carga_exc_inicial'] = exc.carga;

      for (int i = 0; i < exc.posiciones.length; i++) {
        final posicion = exc.posiciones[i];
        final positionNum = i + 1;
        data['posicion_inicial_$positionNum'] = posicion.posicion;
        data['indicacion_inicial_$positionNum'] = posicion.indicacion;
        data['retorno_inicial_$positionNum'] = posicion.retorno;
      }
    }

    // Repetibilidad inicial
    if (model.pruebasIniciales.repetibilidad?.activo ?? false) {
      final rep = model.pruebasIniciales.repetibilidad!;

      for (int i = 0; i < rep.cargas.length; i++) {
        final carga = rep.cargas[i];
        final cargaNum = i + 1;
        data['repetibilidad${cargaNum}_inicial'] = carga.valor;

        for (int j = 0; j < carga.pruebas.length; j++) {
          final prueba = carga.pruebas[j];
          final testNum = j + 1;
          data['indicacion${cargaNum}_inicial_$testNum'] = prueba.indicacion;
          data['retorno${cargaNum}_inicial_$testNum'] = prueba.retorno;
        }
      }
    }

    // Linealidad inicial
    if (model.pruebasIniciales.linealidad?.activo ?? false) {
      final lin = model.pruebasIniciales.linealidad!;
      for (int i = 0; i < lin.puntos.length; i++) {
        final punto = lin.puntos[i];
        final pointNum = i + 1;
        data['lin_inicial_$pointNum'] = punto.lt;
        data['ind_inicial_$pointNum'] = punto.indicacion;
        data['retorno_lin_inicial_$pointNum'] = punto.retorno;
      }
    }

    // Retorno a cero final
    data['retorno_cero_final'] = model.pruebasFinales.retornoCero.estado;
    data['carga_retorno_cero_final'] = model.pruebasFinales.retornoCero.valor;
    data['unidad_retorno_cero_final'] = model.pruebasFinales.retornoCero.unidad;

    // Excentricidad final
    if (model.pruebasFinales.excentricidad?.activo ?? false) {
      final exc = model.pruebasFinales.excentricidad!;
      data['tipo_plataforma_final'] = exc.tipoPlataforma ?? '';
      data['puntos_ind_final'] = exc.puntosIndicador ?? '';
      data['carga_exc_final'] = exc.carga;

      for (int i = 0; i < exc.posiciones.length; i++) {
        final posicion = exc.posiciones[i];
        final positionNum = i + 1;
        data['posicion_final_$positionNum'] = posicion.posicion;
        data['indicacion_final_$positionNum'] = posicion.indicacion;
        data['retorno_final_$positionNum'] = posicion.retorno;
      }
    }

    // Repetibilidad final
    if (model.pruebasFinales.repetibilidad?.activo ?? false) {
      final rep = model.pruebasFinales.repetibilidad!;

      for (int i = 0; i < rep.cargas.length; i++) {
        final carga = rep.cargas[i];
        final cargaNum = i + 1;
        data['repetibilidad${cargaNum}_final'] = carga.valor;

        for (int j = 0; j < carga.pruebas.length; j++) {
          final prueba = carga.pruebas[j];
          final testNum = j + 1;
          data['indicacion${cargaNum}_final_$testNum'] = prueba.indicacion;
          data['retorno${cargaNum}_final_$testNum'] = prueba.retorno;
        }
      }
    }

    // Linealidad final
    if (model.pruebasFinales.linealidad?.activo ?? false) {
      final lin = model.pruebasFinales.linealidad!;
      for (int i = 0; i < lin.puntos.length; i++) {
        final punto = lin.puntos[i];
        final pointNum = i + 1;
        data['lin_final_$pointNum'] = punto.lt;
        data['ind_final_$pointNum'] = punto.indicacion;
        data['retorno_lin_final_$pointNum'] = punto.retorno;
      }
    }
  }

  // Método privado para guardar en base de datos
  Future<void> _saveToDatabase(BuildContext context) async {
    if (model.comentarioGeneral.isEmpty) {
      _showSnackBar(
        context,
        'Por favor complete el campo "Comentario General"',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }

    try {
      // ✅ USAR DatabaseHelperSop
      final dbHelper = DatabaseHelperMntPrvRegularStil();

      // Preparar datos
      final Map<String, dynamic> mntPrvData = _prepareDataForSave();

      // ✅ AGREGAR session_id y cod_metrica del modelo
      mntPrvData['session_id'] = model.sessionId;
      mntPrvData['otst'] = model.secaValue;

      // ✅ USAR upsertRegistro del helper
      await dbHelper.upsertRegistroRelevamiento(mntPrvData);

    } catch (e) {
      debugPrint('Error al guardar en la base de datos: $e');
      throw e;
    }
  }


  // Método para mostrar snackbar
  void _showSnackBar(BuildContext context, String message,
      {Color? backgroundColor, Color? textColor}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: textColor ?? Colors.black),
        ),
        backgroundColor: backgroundColor ?? Colors.grey,
      ),
    );
  }

  // Método para agregar foto a un campo
  void agregarFoto(String campo, File foto) {
    if (!_fieldPhotos.containsKey(campo)) {
      _fieldPhotos[campo] = [];
    }
    _fieldPhotos[campo]!.add(foto);
    model.camposEstado[campo]?.agregarFoto(foto);
  }

  // Método para eliminar foto de un campo
  void eliminarFoto(String campo, int index) {
    if (_fieldPhotos.containsKey(campo) && index < _fieldPhotos[campo]!.length) {
      _fieldPhotos[campo]!.removeAt(index);
      model.camposEstado[campo]?.eliminarFoto(index);
    }
  }

  // Método para limpiar todas las fotos
  void limpiarFotos() {
    _fieldPhotos.clear();
    model.camposEstado.forEach((key, value) {
      value.limpiarFotos();
    });
  }
}