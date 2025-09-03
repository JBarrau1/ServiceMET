import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:archive/archive.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
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
      final path = join(model.dbPath, '${model.dbName}.db');
      final db = await openDatabase(path);

      // Consultar d1 desde inf_cliente_balanza
      final results = await db.query(
        'inf_cliente_balanza',
        columns: ['d1'],
        where: 'cod_metrica = ?', // Asumiendo que hay relación por código métrica
        whereArgs: [model.codMetrica],
      );

      await db.close();

      if (results.isNotEmpty && results.first['d1'] != null) {
        return double.parse(results.first['d1'].toString());
      }

      return 0.1;

    } catch (e) {
      debugPrint('Error al obtener d1: $e');
      return 0.1;
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
          '${model.otValue}_${model.codMetrica}_relevamiento_de_datos_fotos.zip';

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
      final path = join(model.dbPath, '${model.dbName}.db');
      final db = await openDatabase(path);

      // Función para convertir listas de fotos a strings
      String getFotosString(String label) {
        final campo = model.camposEstado[label];
        return campo?.fotos.map((f) => basename(f.path)).join(',') ?? '';
      }

      // Preparar datos para insertar/actualizar
      final Map<String, dynamic> relevamientoData = {
        'tipo_servicio': 'mnt prv regular stil',
        'cod_metrica': model.codMetrica,
        'hora_inicio': model.horaInicio,
        'hora_fin': model.horaFin,
        'comentario_general': model.comentarioGeneral,
        'recomendacion': model.recomendacion,
        'estado_fisico': model.estadoFisico,
        'estado_operacional': model.estadoOperacional,
        'estado_metrologico': model.estadoMetrologico,

        // Entorno de instalación
        'vibracion_estado': model.camposEstado['Vibración']?.initialValue ?? '',
        'vibracion_solucion': model.camposEstado['Vibración']?.solutionValue ??
            '',
        'vibracion_comentario': model.camposEstado['Vibración']?.comentario ??
            '',
        'vibracion_foto': getFotosString('Vibración'),

        'polvo_estado': model.camposEstado['Polvo']?.initialValue ?? '',
        'polvo_solucion': model.camposEstado['Polvo']?.solutionValue ?? '',
        'polvo_comentario': model.camposEstado['Polvo']?.comentario ?? '',
        'polvo_foto': getFotosString('Polvo'),

        'temperatura_estado': model.camposEstado['Temperatura']?.initialValue ??
            '',
        'temperatura_solucion': model.camposEstado['Temperatura']
            ?.solutionValue ?? '',
        'temperatura_comentario': model.camposEstado['Temperatura']
            ?.comentario ?? '',
        'temperatura_foto': getFotosString('Temperatura'),

        'humedad_estado': model.camposEstado['Humedad']?.initialValue ?? '',
        'humedad_solucion': model.camposEstado['Humedad']?.solutionValue ?? '',
        'humedad_comentario': model.camposEstado['Humedad']?.comentario ?? '',
        'humedad_foto': getFotosString('Humedad'),

        'mesada_estado': model.camposEstado['Mesada']?.initialValue ?? '',
        'mesada_solucion': model.camposEstado['Mesada']?.solutionValue ?? '',
        'mesada_comentario': model.camposEstado['Mesada']?.comentario ?? '',
        'mesada_foto': getFotosString('Mesada'),

        'iluminacion_estado': model.camposEstado['Iluminación']?.initialValue ??
            '',
        'iluminacion_solucion': model.camposEstado['Iluminación']
            ?.solutionValue ?? '',
        'iluminacion_comentario': model.camposEstado['Iluminación']
            ?.comentario ?? '',
        'iluminacion_foto': getFotosString('Iluminación'),

        'limpieza_fosa_estado': model.camposEstado['Limpieza de Fosa']
            ?.initialValue ?? '',
        'limpieza_fosa_solucion': model.camposEstado['Limpieza de Fosa']
            ?.solutionValue ?? '',
        'limpieza_fosa_comentario': model.camposEstado['Limpieza de Fosa']
            ?.comentario ?? '',
        'limpieza_fosa_foto': getFotosString('Limpieza de Fosa'),

        'estado_drenaje_estado': model.camposEstado['Estado de Drenaje']
            ?.initialValue ?? '',
        'estado_drenaje_solucion': model.camposEstado['Estado de Drenaje']
            ?.solutionValue ?? '',
        'estado_drenaje_comentario': model.camposEstado['Estado de Drenaje']
            ?.comentario ?? '',
        'estado_drenaje_foto': getFotosString('Estado de Drenaje'),

        // Terminal de pesaje
        'carcasa_estado': model.camposEstado['Carcasa']?.initialValue ?? '',
        'carcasa_solucion': model.camposEstado['Carcasa']?.solutionValue ?? '',
        'carcasa_comentario': model.camposEstado['Carcasa']?.comentario ?? '',
        'carcasa_foto': getFotosString('Carcasa'),

        'teclado_fisico_estado': model.camposEstado['Teclado Fisico']
            ?.initialValue ?? '',
        'teclado_fisico_solucion': model.camposEstado['Teclado Fisico']
            ?.solutionValue ?? '',
        'teclado_fisico_comentario': model.camposEstado['Teclado Fisico']
            ?.comentario ?? '',
        'teclado_fisico_foto': getFotosString('Teclado Fisico'),

        'display_fisico_estado': model.camposEstado['Display Fisico']
            ?.initialValue ?? '',
        'display_fisico_solucion': model.camposEstado['Display Fisico']
            ?.solutionValue ?? '',
        'display_fisico_comentario': model.camposEstado['Display Fisico']
            ?.comentario ?? '',
        'display_fisico_foto': getFotosString('Display Fisico'),

        'fuente_poder_estado': model.camposEstado['Fuente de poder']
            ?.initialValue ?? '',
        'fuente_poder_solucion': model.camposEstado['Fuente de poder']
            ?.solutionValue ?? '',
        'fuente_poder_comentario': model.camposEstado['Fuente de poder']
            ?.comentario ?? '',
        'fuente_poder_foto': getFotosString('Fuente de poder'),

        'bateria_operacional_estado': model.camposEstado['Bateria operacional']
            ?.initialValue ?? '',
        'bateria_operacional_solucion': model
            .camposEstado['Bateria operacional']?.solutionValue ?? '',
        'bateria_operacional_comentario': model
            .camposEstado['Bateria operacional']?.comentario ?? '',
        'bateria_operacional_foto': getFotosString('Bateria operacional'),

        'bracket_estado': model.camposEstado['Bracket']?.initialValue ?? '',
        'bracket_solucion': model.camposEstado['Bracket']?.solutionValue ?? '',
        'bracket_comentario': model.camposEstado['Bracket']?.comentario ?? '',
        'bracket_foto': getFotosString('Bracket'),

        'teclado_operativo_estado': model.camposEstado['Teclado Operativo']
            ?.initialValue ?? '',
        'teclado_operativo_solucion': model.camposEstado['Teclado Operativo']
            ?.solutionValue ?? '',
        'teclado_operativo_comentario': model.camposEstado['Teclado Operativo']
            ?.comentario ?? '',
        'teclado_operativo_foto': getFotosString('Teclado Operativo'),

        'display_operativo_estado': model.camposEstado['Display Operativo']
            ?.initialValue ?? '',
        'display_operativo_solucion': model.camposEstado['Display Operativo']
            ?.solutionValue ?? '',
        'display_operativo_comentario': model.camposEstado['Display Operativo']
            ?.comentario ?? '',
        'display_operativo_foto': getFotosString('Display Operativo'),

        'conector_celda_estado': model.camposEstado['Contector de celda']
            ?.initialValue ?? '',
        'conector_celda_solucion': model.camposEstado['Contector de celda']
            ?.solutionValue ?? '',
        'conector_celda_comentario': model.camposEstado['Contector de celda']
            ?.comentario ?? '',
        'conector_celda_foto': getFotosString('Contector de celda'),

        'bateria_memoria_estado': model.camposEstado['Bateria de memoria']
            ?.initialValue ?? '',
        'bateria_memoria_solucion': model.camposEstado['Bateria de memoria']
            ?.solutionValue ?? '',
        'bateria_memoria_comentario': model.camposEstado['Bateria de memoria']
            ?.comentario ?? '',
        'bateria_memoria_foto': getFotosString('Bateria de memoria'),

        // Estado general de la balanza
        'limpieza_general_estado': model.camposEstado['Limpieza general']
            ?.initialValue ?? '',
        'limpieza_general_solucion': model.camposEstado['Limpieza general']
            ?.solutionValue ?? '',
        'limpieza_general_comentario': model.camposEstado['Limpieza general']
            ?.comentario ?? '',
        'limpieza_general_foto': getFotosString('Limpieza general'),

        'golpes_terminal_estado': model.camposEstado['Golpes al terminal']
            ?.initialValue ?? '',
        'golpes_terminal_solucion': model.camposEstado['Golpes al terminal']
            ?.solutionValue ?? '',
        'golpes_terminal_comentario': model.camposEstado['Golpes al terminal']
            ?.comentario ?? '',
        'golpes_terminal_foto': getFotosString('Golpes al terminal'),

        'nivelacion_estado': model.camposEstado['Nivelacion']?.initialValue ??
            '',
        'nivelacion_solucion': model.camposEstado['Nivelacion']
            ?.solutionValue ?? '',
        'nivelacion_comentario': model.camposEstado['Nivelacion']?.comentario ??
            '',
        'nivelacion_foto': getFotosString('Nivelacion'),

        'limpieza_receptor_estado': model.camposEstado['Limpieza receptor']
            ?.initialValue ?? '',
        'limpieza_receptor_solucion': model.camposEstado['Limpieza receptor']
            ?.solutionValue ?? '',
        'limpieza_receptor_comentario': model.camposEstado['Limpieza receptor']
            ?.comentario ?? '',
        'limpieza_receptor_foto': getFotosString('Limpieza receptor'),

        'golpes_receptor_estado': model
            .camposEstado['Golpes al receptor de carga']?.initialValue ?? '',
        'golpes_receptor_solucion': model
            .camposEstado['Golpes al receptor de carga']?.solutionValue ?? '',
        'golpes_receptor_comentario': model
            .camposEstado['Golpes al receptor de carga']?.comentario ?? '',
        'golpes_receptor_foto': getFotosString('Golpes al receptor de carga'),

        'encendido_estado': model.camposEstado['Encendido']?.initialValue ?? '',
        'encendido_solucion': model.camposEstado['Encendido']?.solutionValue ??
            '',
        'encendido_comentario': model.camposEstado['Encendido']?.comentario ??
            '',
        'encendido_foto': getFotosString('Encendido'),

        // Balanza/Plataforma
        'limitador_movimiento_estado': model
            .camposEstado['Limitador de movimiento']?.initialValue ?? '',
        'limitador_movimiento_solucion': model
            .camposEstado['Limitador de movimiento']?.solutionValue ?? '',
        'limitador_movimiento_comentario': model
            .camposEstado['Limitador de movimiento']?.comentario ?? '',
        'limitador_movimiento_foto': getFotosString('Limitador de movimiento'),

        'suspension_estado': model.camposEstado['Suspensión']?.initialValue ??
            '',
        'suspension_solucion': model.camposEstado['Suspensión']
            ?.solutionValue ?? '',
        'suspension_comentario': model.camposEstado['Suspensión']?.comentario ??
            '',
        'suspension_foto': getFotosString('Suspensión'),

        'limitador_carga_estado': model.camposEstado['Limitador de carga']
            ?.initialValue ?? '',
        'limitador_carga_solucion': model.camposEstado['Limitador de carga']
            ?.solutionValue ?? '',
        'limitador_carga_comentario': model.camposEstado['Limitador de carga']
            ?.comentario ?? '',
        'limitador_carga_foto': getFotosString('Limitador de carga'),

        'celda_carga_estado': model.camposEstado['Celda de carga']
            ?.initialValue ?? '',
        'celda_carga_solucion': model.camposEstado['Celda de carga']
            ?.solutionValue ?? '',
        'celda_carga_comentario': model.camposEstado['Celda de carga']
            ?.comentario ?? '',
        'celda_carga_foto': getFotosString('Celda de carga'),

        // Caja sumadora
        'tapa_caja_estado': model.camposEstado['Tapa de caja sumadora']
            ?.initialValue ?? '',
        'tapa_caja_solucion': model.camposEstado['Tapa de caja sumadora']
            ?.solutionValue ?? '',
        'tapa_caja_comentario': model.camposEstado['Tapa de caja sumadora']
            ?.comentario ?? '',
        'tapa_caja_foto': getFotosString('Tapa de caja sumadora'),

        'humedad_interna_estado': model.camposEstado['Humedad Interna']
            ?.initialValue ?? '',
        'humedad_interna_solucion': model.camposEstado['Humedad Interna']
            ?.solutionValue ?? '',
        'humedad_interna_comentario': model.camposEstado['Humedad Interna']
            ?.comentario ?? '',
        'humedad_interna_foto': getFotosString('Humedad Interna'),

        'estado_prensacables_estado': model
            .camposEstado['Estado de prensacables']?.initialValue ?? '',
        'estado_prensacables_solucion': model
            .camposEstado['Estado de prensacables']?.solutionValue ?? '',
        'estado_prensacables_comentario': model
            .camposEstado['Estado de prensacables']?.comentario ?? '',
        'estado_prensacables_foto': getFotosString('Estado de prensacables'),

        'estado_borneas_estado': model.camposEstado['Estado de borneas']
            ?.initialValue ?? '',
        'estado_borneas_solucion': model.camposEstado['Estado de borneas']
            ?.solutionValue ?? '',
        'estado_borneas_comentario': model.camposEstado['Estado de borneas']
            ?.comentario ?? '',
        'estado_borneas_foto': getFotosString('Estado de borneas'),

        // PRUEBAS METROLÓGICAS INICIALES
        'retorno_cero_inicial': model.pruebasIniciales.retornoCero.estado,
        'carga_retorno_cero_inicial': model.pruebasIniciales.retornoCero.valor,
        'unidad_retorno_cero_inicial': model.pruebasIniciales.retornoCero
            .unidad,
      };

      // Agregar datos de pruebas metrológicas iniciales si están activas
      if (model.pruebasIniciales.excentricidad?.activo ?? false) {
        final exc = model.pruebasIniciales.excentricidad!;
        relevamientoData.addAll({
          'tipo_plataforma_inicial': exc.tipoPlataforma ?? '',
          'puntos_ind_inicial': exc.puntosIndicador ?? '',
          'carga_exc_inicial': exc.carga,
        });

        // Posiciones de excentricidad inicial
        for (int i = 0; i < exc.posiciones.length; i++) {
          final posicion = exc.posiciones[i];
          final positionNum = i + 1;
          relevamientoData.addAll({
            'posicion_inicial_$positionNum': posicion.posicion,
            'indicacion_inicial_$positionNum': posicion.indicacion,
            'retorno_inicial_$positionNum': posicion.retorno,
          });
        }
      }

      if (model.pruebasIniciales.repetibilidad?.activo ?? false) {
        final rep = model.pruebasIniciales.repetibilidad!;

        // Carga 1 inicial
        if (rep.cargas.isNotEmpty) {
          final carga1 = rep.cargas[0];
          relevamientoData['repetibilidad1_inicial'] = carga1.valor;

          for (int i = 0; i < carga1.pruebas.length; i++) {
            final prueba = carga1.pruebas[i];
            final testNum = i + 1;
            relevamientoData.addAll({
              'indicacion1_inicial_$testNum': prueba.indicacion,
              'retorno1_inicial_$testNum': prueba.retorno,
            });
          }
        }

        // Carga 2 inicial (si aplica)
        if (rep.cargas.length >= 2) {
          final carga2 = rep.cargas[1];
          relevamientoData['repetibilidad2_inicial'] = carga2.valor;

          for (int i = 0; i < carga2.pruebas.length; i++) {
            final prueba = carga2.pruebas[i];
            final testNum = i + 1;
            relevamientoData.addAll({
              'indicacion2_inicial_$testNum': prueba.indicacion,
              'retorno2_inicial_$testNum': prueba.retorno,
            });
          }
        }

        // Carga 3 inicial (si aplica)
        if (rep.cargas.length >= 3) {
          final carga3 = rep.cargas[2];
          relevamientoData['repetibilidad3_inicial'] = carga3.valor;

          for (int i = 0; i < carga3.pruebas.length; i++) {
            final prueba = carga3.pruebas[i];
            final testNum = i + 1;
            relevamientoData.addAll({
              'indicacion3_inicial_$testNum': prueba.indicacion,
              'retorno3_inicial_$testNum': prueba.retorno,
            });
          }
        }
      }

      if (model.pruebasIniciales.linealidad?.activo ?? false) {
        final lin = model.pruebasIniciales.linealidad!;
        for (int i = 0; i < lin.puntos.length; i++) {
          final punto = lin.puntos[i];
          final pointNum = i + 1;
          relevamientoData.addAll({
            'lin_inicial_$pointNum': punto.lt,
            'ind_inicial_$pointNum': punto.indicacion,
            'retorno_lin_inicial_$pointNum': punto.retorno,
          });
        }
      }

      // PRUEBAS METROLÓGICAS FINALES
      relevamientoData.addAll({
        'retorno_cero_final': model.pruebasFinales.retornoCero.estado,
        'carga_retorno_cero_final': model.pruebasFinales.retornoCero.valor,
        'unidad_retorno_cero_final': model.pruebasFinales.retornoCero.unidad,
      });

      // Agregar datos de pruebas metrológicas finales si están activas
      if (model.pruebasFinales.excentricidad?.activo ?? false) {
        final exc = model.pruebasFinales.excentricidad!;
        relevamientoData.addAll({
          'tipo_plataforma_final': exc.tipoPlataforma ?? '',
          'puntos_ind_final': exc.puntosIndicador ?? '',
          'carga_exc_final': exc.carga,
        });

        // Posiciones de excentricidad final
        for (int i = 0; i < exc.posiciones.length; i++) {
          final posicion = exc.posiciones[i];
          final positionNum = i + 1;
          relevamientoData.addAll({
            'posicion_final_$positionNum': posicion.posicion,
            'indicacion_final_$positionNum': posicion.indicacion,
            'retorno_final_$positionNum': posicion.retorno,
          });
        }
      }

      if (model.pruebasFinales.repetibilidad?.activo ?? false) {
        final rep = model.pruebasFinales.repetibilidad!;
        relevamientoData['repetibilidad_count_final'] = rep.cantidadCargas;
        relevamientoData['repetibilidad_rows_final'] = rep.cantidadPruebas;

        // Carga 1 final
        if (rep.cargas.isNotEmpty) {
          final carga1 = rep.cargas[0];
          relevamientoData['repetibilidad1_final'] = carga1.valor;

          for (int i = 0; i < carga1.pruebas.length; i++) {
            final prueba = carga1.pruebas[i];
            final testNum = i + 1;
            relevamientoData.addAll({
              'indicacion1_final_$testNum': prueba.indicacion,
              'retorno1_final_$testNum': prueba.retorno,
            });
          }
        }

        // Carga 2 final (si aplica)
        if (rep.cargas.length >= 2) {
          final carga2 = rep.cargas[1];
          relevamientoData['repetibilidad2_final'] = carga2.valor;

          for (int i = 0; i < carga2.pruebas.length; i++) {
            final prueba = carga2.pruebas[i];
            final testNum = i + 1;
            relevamientoData.addAll({
              'indicacion2_final_$testNum': prueba.indicacion,
              'retorno2_final_$testNum': prueba.retorno,
            });
          }
        }

        // Carga 3 final (si aplica)
        if (rep.cargas.length >= 3) {
          final carga3 = rep.cargas[2];
          relevamientoData['repetibilidad3_final'] = carga3.valor;

          for (int i = 0; i < carga3.pruebas.length; i++) {
            final prueba = carga3.pruebas[i];
            final testNum = i + 1;
            relevamientoData.addAll({
              'indicacion3_final_$testNum': prueba.indicacion,
              'retorno3_final_$testNum': prueba.retorno,
            });
          }
        }
      }

      if (model.pruebasFinales.linealidad?.activo ?? false) {
        final lin = model.pruebasFinales.linealidad!;
        for (int i = 0; i < lin.puntos.length; i++) {
          final punto = lin.puntos[i];
          final pointNum = i + 1;
          relevamientoData.addAll({
            'lin_final_$pointNum': punto.lt,
            'ind_final_$pointNum': punto.indicacion,
            'retorno_lin_final_$pointNum': punto.retorno,
          });
        }
      }

      // Verificar si ya existe un registro
      final existingRecords = await db.query('mnt_prv_regular_stil');

      if (existingRecords.isNotEmpty) {
        await db.update('mnt_prv_regular_stil', relevamientoData);
      } else {
        await db.insert('mnt_prv_regular_stil', relevamientoData,
            conflictAlgorithm: ConflictAlgorithm.replace);
      }

      await db.close();
    } catch (e) {
      // Manejo del error
      debugPrint('Error al guardar en la base de datos: $e');
      throw e; // Opcional: re-lanzar el error si quieres manejarlo en otro lugar
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