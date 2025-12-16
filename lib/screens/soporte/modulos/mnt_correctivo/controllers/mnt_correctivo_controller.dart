import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../../mnt_prv_regular/mnt_prv_regular_stil/models/mnt_prv_regular_stil_model.dart';
import '../models/mnt_correctivo_model.dart';
import '../../../../../database/soporte_tecnico/database_helper_mnt_correctivo.dart';
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
          final headers = fields[0].map((e) => e.toString()).toList();

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

  void _populateModelFromCsv(Map<String, dynamic> data) {
    // 1. General
    if (data.containsKey('reporte')) {
      model.reporteFalla = data['reporte'].toString();
    }
    if (data.containsKey('evaluacion')) {
      model.evaluacion = data['evaluacion'].toString();
    }

    // 2. Pruebas Iniciales
    // Retorno Cero
    if (data.containsKey('retorno_cero_inicial_valoracion')) {
      model.pruebasIniciales.retornoCero.estado =
          data['retorno_cero_inicial_valoracion'].toString();
      model.pruebasIniciales.retornoCero.valor =
          data['retorno_cero_inicial_carga'].toString();
      // Si el CSV de diagnóstico exporta 'carga' como estabilidad, lo ponemos en estabilidad también
      model.pruebasIniciales.retornoCero.estabilidad =
          data['retorno_cero_inicial_carga'].toString();
      model.pruebasIniciales.retornoCero.unidad =
          data['retorno_cero_inicial_unidad'].toString();
    }

    // Excentricidad Inicial
    if (data.containsKey('excentricidad_inicial_cantidad_posiciones')) {
      model.pruebasIniciales.excentricidad = Excentricidad(activo: true);
      var exc = model.pruebasIniciales.excentricidad!;
      exc.tipoPlataforma = data['excentricidad_inicial_tipo_plataforma'];
      exc.puntosIndicador = data['excentricidad_inicial_opcion_prueba'];
      exc.carga = data['excentricidad_inicial_carga'].toString();
      // Imagen path no servirá de mucho si es local del otro dispositivo, pero lo intentamos
      exc.imagenPath = data['excentricidad_inicial_ruta_imagen'];

      int count = int.tryParse(
              data['excentricidad_inicial_cantidad_posiciones'].toString()) ??
          0;
      exc.posiciones.clear();
      for (int i = 1; i <= count; i++) {
        exc.posiciones.add(PosicionExcentricidad(
          posicion: data['excentricidad_inicial_pos${i}_numero'].toString(),
          indicacion:
              data['excentricidad_inicial_pos${i}_indicacion'].toString(),
          retorno: data['excentricidad_inicial_pos${i}_retorno'].toString(),
        ));
      }
    }

    // Repetibilidad Inicial
    if (data.containsKey('repetibilidad_inicial_cantidad_cargas')) {
      model.pruebasIniciales.repetibilidad = Repetibilidad(activo: true);
      var rep = model.pruebasIniciales.repetibilidad!;
      rep.cantidadCargas = int.tryParse(
              data['repetibilidad_inicial_cantidad_cargas'].toString()) ??
          1;
      rep.cantidadPruebas = int.tryParse(
              data['repetibilidad_inicial_cantidad_pruebas'].toString()) ??
          3;

      rep.cargas.clear();
      for (int i = 1; i <= rep.cantidadCargas; i++) {
        var carga = CargaRepetibilidad();
        carga.valor = data['repetibilidad_inicial_carga${i}_valor'].toString();
        for (int j = 1; j <= rep.cantidadPruebas; j++) {
          carga.pruebas.add(PruebaRepetibilidad(
              indicacion:
                  data['repetibilidad_inicial_carga${i}_prueba${j}_indicacion']
                      .toString(),
              retorno:
                  data['repetibilidad_inicial_carga${i}_prueba${j}_retorno']
                      .toString()));
        }
        rep.cargas.add(carga);
      }
    }

    // 3. Inspección Visual
    // Mapear claves de BD a Labels
    final Map<String, String> dbKeyToLabel = {
      'vibracion': 'Vibración',
      'polvo': 'Polvo',
      'temperatura': 'Temperatura',
      'humedad': 'Humedad',
      'mesada': 'Mesada',
      'iluminacion': 'Iluminación',
      'limpieza_fosa': 'Limpieza de Fosa',
      'estado_drenaje': 'Estado de Drenaje',
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
      'limpieza_general': 'Limpieza general',
      'golpes_terminal': 'Golpes al terminal',
      'nivelacion': 'Nivelacion',
      'limpieza_receptor': 'Limpieza receptor',
      'golpes_receptor': 'Golpes al receptor de carga',
      'encendido': 'Encendido',
      'limitador_movimiento': 'Limitador de movimiento',
      'suspension': 'Suspensión',
      'limitador_carga': 'Limitador de carga',
      'celda_carga': 'Celda de carga',
      'tapa_caja': 'Tapa de caja sumadora',
      'humedad_interna': 'Humedad Interna',
      'estado_prensacables': 'Estado de prensacables',
      'estado_borneas': 'Estado de borneas'
    };

    dbKeyToLabel.forEach((dbKey, label) {
      if (model.inspeccionItems.containsKey(label)) {
        if (data.containsKey('${dbKey}_estado')) {
          model.inspeccionItems[label]!.estado =
              data['${dbKey}_estado'].toString();
        }
        if (data.containsKey('${dbKey}_comentario')) {
          model.inspeccionItems[label]!.comentario =
              data['${dbKey}_comentario'].toString();
        }
        // Solución generalmente no se importa del diagnóstico (es lo que se hace ahora en el correctivo), pero si se quisiera:
        // if (data.containsKey('${dbKey}_solucion')) ...
      }
    });
  }

  // --- SAVE ---
  Future<void> saveData(BuildContext context) async {
    try {
      final dbHelper = DatabaseHelperMntCorrectivo();
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
    final Map<String, String> labelToDbKey = {
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
    data['retorno_cero_${tipo}_carga'] =
        pruebas.retornoCero.estabilidad ?? pruebas.retornoCero.valor;
    data['retorno_cero_${tipo}_unidad'] = pruebas.retornoCero.unidad;

    if (pruebas.excentricidad?.activo == true) {
      final exc = pruebas.excentricidad!;
      data['excentricidad_${tipo}_tipo_plataforma'] = exc.tipoPlataforma ?? '';
      data['excentricidad_${tipo}_opcion_prueba'] = exc.puntosIndicador ?? '';
      data['excentricidad_${tipo}_carga'] = exc.carga;
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
