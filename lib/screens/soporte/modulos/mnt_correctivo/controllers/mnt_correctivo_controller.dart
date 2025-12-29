// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/mnt_correctivo_model.dart';
import '../../../../../database/soporte_tecnico/database_helper_diagnostico_correctivo.dart';
import '../../../../../database/soporte_tecnico/database_helper_ajustes.dart'; // Para d1
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';

class MntCorrectivoController {
  final MntCorrectivoModel model;
  double? _cachedD1;

  MntCorrectivoController({required this.model});

  Future<void> init() async {
    await getD1FromDatabase();
  }

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
      debugPrint('Error getting d1: $e');
    }
    return 0.0;
  }

  List<String> getIndicationSuggestions(double carga, double d) {
    if (d == 0) return [];
    int decimals = getDecimalPlaces(d);
    return [
      carga.toString(),
      (carga + d).toStringAsFixed(decimals),
      (carga - d).toStringAsFixed(decimals),
    ];
  }

  int getDecimalPlaces(double value) {
    String text = value.toString();
    if (text.contains('.')) return text.split('.')[1].length;
    return 0;
  }

  // --- IMPORTACIÓN CSV ---

  Future<void> importDiagnosticoCsv(
      BuildContext context, VoidCallback onUpdate) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null) {
        File file = File(result.files.single.path!);
        final input = file.openRead();
        final fields = await input
            .transform(utf8.decoder)
            .transform(const CsvToListConverter(
                fieldDelimiter: ';', textDelimiter: '"'))
            .toList();

        if (fields.isNotEmpty && fields.length > 1) {
          final headers = fields[0].map((e) => e.toString().trim()).toList();

          // Buscar índice de la columna cod_metrica
          final codMetricaIndex = headers.indexOf('cod_metrica');

          if (codMetricaIndex == -1) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      'El archivo CSV no contiene la columna "cod_metrica"'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
            return;
          }

          // Buscar la fila que coincida con el cod_metrica actual
          Map<String, dynamic>? matchingRow;

          for (int rowIndex = 1; rowIndex < fields.length; rowIndex++) {
            final row = fields[rowIndex];

            if (codMetricaIndex < row.length) {
              final csvCodMetrica =
                  row[codMetricaIndex]?.toString().trim() ?? '';
              final modelCodMetrica = model.codMetrica.trim();

              if (csvCodMetrica == modelCodMetrica) {
                // Encontramos una coincidencia, crear el mapa
                matchingRow = {};
                for (int i = 0; i < headers.length; i++) {
                  if (i < row.length) {
                    matchingRow[headers[i]] = row[i];
                  }
                }
                break; // Tomar la primera coincidencia
              }
            }
          }

          if (matchingRow != null) {
            _populateModelFromCsv(matchingRow);
            onUpdate(); // Actualizar UI

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Datos importados correctamente para balanza: ${model.codMetrica}'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } else {
            // No se encontró coincidencia
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'La balanza seleccionada (${model.codMetrica}) no coincide con ninguna del CSV importado'),
                  backgroundColor: Colors.orange,
                  duration: const Duration(seconds: 4),
                ),
              );
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error importing CSV: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error al importar: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  // Mapa estático de etiquetas a claves de BD (compartido para import/export)
  static const Map<String, String> labelToDbKey = {
    'Vibración': 'vibracion',
    'Polvo': 'polvo',
    'Temperatura': 'temperatura',
    'Humedad': 'humedad',
    'Mesada': 'mesada',
    'Iluminación': 'iluminacion',
    'Limpieza de Fosa': 'limpieza_fosa',
    'Estado de Drenaje': 'estado_drenaje',
    'Carcasa': 'carcasa',
    'Teclado Fisico': 'teclado_fisico',
    'Display Fisico': 'display_fisico',
    'Fuente de poder': 'fuente_poder',
    'Bateria operacional': 'bateria_operacional',
    'Bracket': 'bracket',
    'Teclado Operativo': 'teclado_operativo',
    'Display Operativo': 'display_operativo',
    'Contector de celda': 'conector_celda',
    'Bateria de memoria': 'bateria_memoria',
    'Limpieza general': 'limpieza_general',
    'Golpes al terminal': 'golpes_terminal',
    'Nivelacion': 'nivelacion',
    'Limpieza receptor': 'limpieza_receptor',
    'Golpes al receptor de carga': 'golpes_receptor',
    'Encendido': 'encendido',
    'Limitador de movimiento': 'limitador_movimiento',
    'Suspensión': 'suspension',
    'Limitador de carga': 'limitador_carga',
    'Celda de carga': 'celda_carga',
    'Tapa de caja sumadora': 'tapa_caja',
    'Humedad Interna': 'humedad_interna',
    'Estado de prensacables': 'estado_prensacables',
    'Estado de borneas': 'estado_borneas'
  };

  void _populateModelFromCsv(Map<String, dynamic> data) {
    debugPrint("--- IMPORTING CSV DATA ---");
    // Helper para obtener string seguro y trim
    String getVal(String key) => data[key]?.toString().trim() ?? '';

    // 1. General
    if (data.containsKey('reporte')) {
      model.reporteFalla = getVal('reporte');
    }
    if (data.containsKey('evaluacion')) {
      model.evaluacion = getVal('evaluacion');
    }

    // 2. Inspección Visual
    model.inspeccionItems.forEach((label, item) {
      final key = labelToDbKey[label];
      if (key != null) {
        // Estado
        if (data.containsKey('${key}_estado')) {
          // Solo sobreescribir si el valor no está vacío en el CSV, o si queremos forzar lo del CSV
          // Asumimos que queremos lo del CSV
          final val = getVal('${key}_estado');
          if (val.isNotEmpty) item.estado = val;
        }
        // Solución
        if (data.containsKey('${key}_solucion')) {
          final val = getVal('${key}_solucion');
          if (val.isNotEmpty) item.solucion = val;
        }
        // Comentario
        if (data.containsKey('${key}_comentario')) {
          final val = getVal('${key}_comentario');
          if (val.isNotEmpty) item.comentario = val;
        }
      }
    });

    // 3. Pruebas Iniciales
    // Retorno Cero
    if (data.containsKey('retorno_cero_inicial_valoracion') &&
        getVal('retorno_cero_inicial_valoracion').isNotEmpty) {
      model.pruebasIniciales.retornoCero.estado =
          getVal('retorno_cero_inicial_valoracion');
      model.pruebasIniciales.retornoCero.valor =
          getVal('retorno_cero_inicial_carga');
      // Si el CSV de diagnóstico exporta 'carga' como estabilidad, lo ponemos en estabilidad también
      model.pruebasIniciales.retornoCero.estabilidad =
          getVal('retorno_cero_inicial_carga');
      model.pruebasIniciales.retornoCero.unidad =
          getVal('retorno_cero_inicial_unidad');
    }

    // Excentricidad Inicial
    // Lógica para detectar si es estándar (posiciones definidas) o rieles (ida/vuelta)
    bool hasExcentricidadStandard =
        data.containsKey('excentricidad_inicial_cantidad_posiciones') &&
            getVal('excentricidad_inicial_cantidad_posiciones') != '0' &&
            getVal('excentricidad_inicial_cantidad_posiciones').isNotEmpty;

    bool hasExcentricidadRieles =
        data.containsKey('excentricidad_inicial_punto1_ida_indicacion');

    if (hasExcentricidadStandard || hasExcentricidadRieles) {
      model.pruebasIniciales.excentricidad = Excentricidad(activo: true);
      var exc = model.pruebasIniciales.excentricidad!;
      exc.tipoPlataforma = getVal('excentricidad_inicial_tipo_plataforma');
      exc.puntosIndicador = getVal('excentricidad_inicial_opcion_prueba');
      exc.carga = getVal('excentricidad_inicial_carga'); // Corrección carga

      exc.posiciones.clear();

      if (hasExcentricidadStandard) {
        // Lógica Estándar
        int count =
            int.tryParse(getVal('excentricidad_inicial_cantidad_posiciones')) ??
                0;
        for (int i = 1; i <= count; i++) {
          exc.posiciones.add(PosicionExcentricidad(
            posicion: getVal('excentricidad_inicial_pos${i}_numero'),
            indicacion: getVal('excentricidad_inicial_pos${i}_indicacion'),
            retorno: getVal('excentricidad_inicial_pos${i}_retorno'),
          ));
        }
      } else if (hasExcentricidadRieles) {
        // Lógica Rieles (Ida/Vuelta) -> Mapear a posiciones lineales 1-12
        // Ida (Puntos 1-6)
        for (int i = 1; i <= 6; i++) {
          if (data.containsKey('excentricidad_inicial_punto${i}_ida_numero')) {
            exc.posiciones.add(PosicionExcentricidad(
              posicion: getVal('excentricidad_inicial_punto${i}_ida_numero'),
              indicacion:
                  getVal('excentricidad_inicial_punto${i}_ida_indicacion'),
              retorno: getVal('excentricidad_inicial_punto${i}_ida_retorno'),
            ));
          }
        }
        // Vuelta (Puntos 7-12)
        for (int i = 7; i <= 12; i++) {
          if (data
              .containsKey('excentricidad_inicial_punto${i}_vuelta_numero')) {
            exc.posiciones.add(PosicionExcentricidad(
              posicion: getVal('excentricidad_inicial_punto${i}_vuelta_numero'),
              indicacion:
                  getVal('excentricidad_inicial_punto${i}_vuelta_indicacion'),
              retorno: getVal('excentricidad_inicial_punto${i}_vuelta_retorno'),
            ));
          }
        }
      }
    }

    // Repetibilidad Inicial
    String repCantCargas = getVal('repetibilidad_inicial_cantidad_cargas');
    if (repCantCargas.isNotEmpty && repCantCargas != '0') {
      model.pruebasIniciales.repetibilidad = Repetibilidad(activo: true);
      var rep = model.pruebasIniciales.repetibilidad!;
      rep.cantidadCargas = int.tryParse(repCantCargas) ?? 1;
      rep.cantidadPruebas =
          int.tryParse(getVal('repetibilidad_inicial_cantidad_pruebas')) ?? 3;

      rep.cargas.clear();
      for (int i = 1; i <= rep.cantidadCargas; i++) {
        var carga = CargaRepetibilidad();
        carga.valor = getVal('repetibilidad_inicial_carga${i}_valor');
        for (int j = 1; j <= rep.cantidadPruebas; j++) {
          carga.pruebas.add(PruebaRepetibilidad(
              indicacion: getVal(
                  'repetibilidad_inicial_carga${i}_prueba${j}_indicacion'),
              retorno: getVal(
                  'repetibilidad_inicial_carga${i}_prueba${j}_retorno')));
        }
        rep.cargas.add(carga);
      }
    } else {
      debugPrint("Repetibilidad: No se encontró cantidad de cargas o es 0.");
    }

    // Linealidad Inicial
    String linCantPuntos = getVal('linealidad_inicial_cantidad_puntos');
    if (linCantPuntos.isNotEmpty && linCantPuntos != '0') {
      model.pruebasIniciales.linealidad = Linealidad(activo: true);
      var lin = model.pruebasIniciales.linealidad!;
      int cantidadPuntos = int.tryParse(linCantPuntos) ?? 0;
      lin.puntos.clear();

      for (int i = 1; i <= cantidadPuntos; i++) {
        // Obtenemos los valores
        String lt = getVal('linealidad_inicial_punto${i}_lt');
        String ind = getVal('linealidad_inicial_punto${i}_indicacion');
        String ret = getVal('linealidad_inicial_punto${i}_retorno');

        // Solo agregamos si hay al menos un LT definidio o indicación, para evitar puntos vacíos fantasma
        if (lt.isNotEmpty || ind.isNotEmpty) {
          lin.puntos.add(PuntoLinealidad(
            lt: lt,
            indicacion: ind,
            retorno: ret,
          ));
        }
      }
    } else {
      debugPrint("Linealidad: No se encontró cantidad de puntos o es 0.");
    }

    // 4. Comentarios
    for (int i = 1; i <= 10; i++) {
      if (data.containsKey('comentario_$i')) {
        if (i - 1 < model.comentarios.length) {
          model.comentarios[i - 1] = getVal('comentario_$i');
        }
      }
    }
  }

  // --- SAVE ---
  Future<void> saveData(BuildContext context) async {
    try {
      final DatabaseHelperDiagnosticoCorrectivo dbHelper =
          DatabaseHelperDiagnosticoCorrectivo();
      final data = _prepareDataForSave();
      await dbHelper
          .upsertRegistroRelevamiento(data); // Método existente en el helper

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Datos guardados exitosamente'),
            backgroundColor: Colors.green),
      );
    } catch (e) {
      debugPrint('Error saving: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error guardando: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Map<String, dynamic> _prepareDataForSave() {
    // Lógica similar a Diagnostico pero con Pruebas Finales e Inspección
    final data = <String, dynamic>{
      'session_id': model.sessionId,
      'cod_metrica': model.codMetrica,
      'otst': model.secaValue,
      'estado_servicio': 'Completo',
      'tipo_servicio': 'correctivo',
      'hora_inicio': model.horaInicio,
      'hora_fin': model.horaFin,
      'reporte': model.reporteFalla,
      'evaluacion': model.evaluacion,
    };

    // Comentarios
    for (int i = 0; i < model.comentarios.length; i++) {
      if (model.comentarios[i] != null) {
        data['comentario_${i + 1}'] = model.comentarios[i];
      }
    }

    // Pruebas
    _addPruebasData(data, model.pruebasIniciales, 'inicial');
    _addPruebasData(data, model.pruebasFinales, 'final');

    // Inspección
    model.inspeccionItems.forEach((label, item) {
      final key = labelToDbKey[label];
      if (key != null) {
        data['${key}_estado'] = item.estado;
        data['${key}_solucion'] = item.solucion ?? '';
        data['${key}_comentario'] = item.comentario ?? '';
        // Fotos?
      }
    });

    return data;
  }

  void _addPruebasData(
      Map<String, dynamic> data, PruebasMetrologicas pruebas, String tipo) {
    data['retorno_cero_${tipo}_valoracion'] = pruebas.retornoCero.estado;
    // Guardar carga (estabilidad)
    data['retorno_cero_${tipo}_carga'] = pruebas.retornoCero.estabilidad;
    data['retorno_cero_${tipo}_unidad'] = pruebas.retornoCero.unidad;

    if (pruebas.excentricidad?.activo == true) {
      final exc = pruebas.excentricidad!;
      data['excentricidad_${tipo}_tipo_plataforma'] = exc.tipoPlataforma ?? '';
      data['excentricidad_${tipo}_opcion_prueba'] = exc.puntosIndicador ?? '';
      data['excentricidad_${tipo}_carga'] = exc.carga;
      data['excentricidad_${tipo}_ruta_imagen'] = exc.imagenPath ?? '';
      data['excentricidad_${tipo}_cantidad_posiciones'] =
          exc.posiciones.length.toString();
      for (int i = 0; i < exc.posiciones.length; i++) {
        data['excentricidad_${tipo}_pos${i + 1}_numero'] =
            exc.posiciones[i].posicion;
        data['excentricidad_${tipo}_pos${i + 1}_indicacion'] =
            exc.posiciones[i].indicacion;
        data['excentricidad_${tipo}_pos${i + 1}_retorno'] =
            exc.posiciones[i].retorno;
        // Error
        double ind = double.tryParse(exc.posiciones[i].indicacion) ?? 0;
        double pos = double.tryParse(exc.posiciones[i].posicion) ?? 0;
        data['excentricidad_${tipo}_pos${i + 1}_error'] =
            (ind - pos).toStringAsFixed(2);
      }
    }

    if (pruebas.repetibilidad?.activo == true) {
      final rep = pruebas.repetibilidad!;
      data['repetibilidad_${tipo}_cantidad_cargas'] =
          rep.cantidadCargas.toString();
      data['repetibilidad_${tipo}_cantidad_pruebas'] =
          rep.cantidadPruebas.toString();
      for (int i = 0; i < rep.cargas.length; i++) {
        data['repetibilidad_${tipo}_carga${i + 1}_valor'] = rep.cargas[i].valor;
        for (int j = 0; j < rep.cargas[i].pruebas.length; j++) {
          data['repetibilidad_${tipo}_carga${i + 1}_prueba${j + 1}_indicacion'] =
              rep.cargas[i].pruebas[j].indicacion;
          data['repetibilidad_${tipo}_carga${i + 1}_prueba${j + 1}_retorno'] =
              rep.cargas[i].pruebas[j].retorno;
        }
      }
    }

    // Linealidad
    if (pruebas.linealidad?.activo == true) {
      final lin = pruebas.linealidad!;
      data['linealidad_${tipo}_cantidad_puntos'] = lin.puntos.length;

      for (int i = 0; i < lin.puntos.length; i++) {
        // Ajustar índice porque DB espera punto1...punto12
        // Validar que no exceda 12
        if (i >= 12) break;

        data['linealidad_${tipo}_punto${i + 1}_lt'] = lin.puntos[i].lt;
        data['linealidad_${tipo}_punto${i + 1}_indicacion'] =
            lin.puntos[i].indicacion;
        data['linealidad_${tipo}_punto${i + 1}_retorno'] =
            lin.puntos[i].retorno;

        double lt = double.tryParse(lin.puntos[i].lt) ?? 0;
        double ind = double.tryParse(lin.puntos[i].indicacion) ?? 0;
        data['linealidad_${tipo}_punto${i + 1}_error'] =
            (ind - lt).toStringAsFixed(2);
      }
    }
  }
}
