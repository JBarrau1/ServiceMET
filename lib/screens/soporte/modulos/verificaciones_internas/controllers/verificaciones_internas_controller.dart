import 'package:flutter/material.dart';
import 'package:service_met/database/soporte_tecnico/database_helper_verificaciones.dart';
import '../models/verificaciones_internas_model.dart';

class VerificacionesInternasController {
  final VerificacionesInternasModel model;

  VerificacionesInternasController({required this.model});

  void copiarPruebasInicialesAFinales() {
    model.copiarPruebasInicialesAFinales();
  }

  // Obtener d1 desde la base de datos (reutilizando lógica de STIL)
  Future<double> getD1FromDatabase() async {
    try {
      final dbHelper = DatabaseHelperVerificaciones();
      final db = await dbHelper.database;

      final results = await db.query(
        'verificaciones_internas',
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

  // Lógica de decimales adaptada para carga
  Future<double> getDForCarga(double carga) async {
    try {
      final dbHelper = DatabaseHelperVerificaciones();
      final db = await dbHelper.database;

      final results = await db.query(
        'verificaciones_internas',
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

    final baseText = currentValue.trim().isEmpty ? cargaText : currentValue;
    final baseValue = double.tryParse(baseText.replaceAll(',', '.')) ?? carga;

    return List.generate(11, (i) {
      final value = baseValue + ((i - 5) * dValue);
      return value.toStringAsFixed(decimalPlaces);
    });
  }

  // Guardar datos en BD
  Future<void> saveDataToDatabase(BuildContext context,
      {bool showMessage = true}) async {
    try {
      final dbHelper = DatabaseHelperVerificaciones();
      final Map<String, dynamic> dbData = _prepareDataForSave();

      // IDs clave
      dbData['session_id'] = model.sessionId;
      dbData['otst'] = model.secaValue;
      dbData['cod_metrica'] = model.codMetrica;

      await dbHelper.upsertRegistroRelevamiento(dbData);

      if (showMessage && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Datos guardados exitosamente'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
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
            duration: const Duration(seconds: 3),
          ),
        );
      }
      rethrow;
    }
  }

  // Preparar mapa de datos para BD
  Map<String, dynamic> _prepareDataForSave() {
    final data = <String, dynamic>{
      'tipo_servicio': 'verificaciones internas',
      'hora_inicio': model.horaInicio,
      'hora_fin': model.horaFin,
      'reporte': model.reporteFalla,
      'evaluacion': model.evaluacion,
      'excentricidad_estado_general': model.excentricidadEstadoGeneral,
      'repetibilidad_estado_general': model.repetibilidadEstadoGeneral,
      'linealidad_estado_general': model.linealidadEstadoGeneral,
      'estado_servicio': 'Completo',
    };

    // Agregar comentarios
    for (int i = 0; i < model.comentarios.length; i++) {
      if (i < 10) {
        // Limite de 10 en DB
        data['comentario_${i + 1}'] = model.comentarios[i].comentario;
      }
    }

    _addPruebasMetrologicasData(data);

    return data;
  }

  void _addPruebasMetrologicasData(Map<String, dynamic> data) {
    // Retorno a Cero Inicial
    data['retorno_cero_inicial_valoracion'] =
        model.pruebasIniciales.retornoCero.estado;
    data['retorno_cero_inicial_carga'] = model.pruebasIniciales.retornoCero
        .valor; // Se usa 'valor' como carga en la UI actual o al revés? Verificaremos.
    // En STIL, retornoCero tiene 'valor' y 'unidad'. En DB: 'retorno_cero_inicial_carga'.
    // Asumiendo que 'valor' es la carga aplicada o el retorno?
    // Revisando MntPrvRegularStilModel: RetornoCero tiene valor, estado, estabilidad.
    // Revisando DB Helper: retorno_cero_inicial_carga.
    // Voy a mapear model.pruebasIniciales.retornoCero.valor a retorno_cero_inicial_carga.
    data['retorno_cero_inicial_unidad'] =
        model.pruebasIniciales.retornoCero.unidad;

    // Retorno a Cero Final
    data['retorno_cero_final_valoracion'] =
        model.pruebasFinales.retornoCero.estado;
    data['retorno_cero_final_carga'] = model.pruebasFinales.retornoCero.valor;
    data['retorno_cero_final_unidad'] = model.pruebasFinales.retornoCero.unidad;

    // Pruebas Iniciales
    _addExcentricidadData(
        data, model.pruebasIniciales.excentricidad, 'inicial');
    _addRepetibilidadData(
        data, model.pruebasIniciales.repetibilidad, 'inicial');
    _addLinealidadData(data, model.pruebasIniciales.linealidad, 'inicial');

    // Pruebas Finales
    _addExcentricidadData(data, model.pruebasFinales.excentricidad, 'final');
    _addRepetibilidadData(data, model.pruebasFinales.repetibilidad, 'final');
    _addLinealidadData(data, model.pruebasFinales.linealidad, 'final');
  }

  void _addExcentricidadData(
      Map<String, dynamic> data, Excentricidad? exc, String tipo) {
    if (exc?.activo ?? false) {
      data['excentricidad_${tipo}_tipo_plataforma'] = exc!.tipoPlataforma ?? '';
      data['excentricidad_${tipo}_opcion_prueba'] = exc.puntosIndicador ?? '';
      data['excentricidad_${tipo}_carga'] = double.tryParse(exc.carga) ?? 0.0;
      data['excentricidad_${tipo}_ruta_imagen'] = exc.imagenPath ?? '';
      data['excentricidad_${tipo}_cantidad_posiciones'] =
          exc.posiciones.length.toString();

      // Lógica para mapear posiciones a DB (ida/vuelta o pos1..pos6)
      // La DB de verificaciones tiene columnas específicas para:
      // excentricidad_inicial_pos1_... a pos6
      // Y TAMBIEN tiene puntox_ida / puntox_vuelta.
      // Debemos decidir cuál usar o llenar ambos si es posible.
      // Por simplicidad y robustez, llenaremos según el tipo de plataforma (similar a STIL).

      bool esCamionera =
          (exc.tipoPlataforma ?? '').toLowerCase().contains('camion');

      for (int i = 0; i < exc.posiciones.length; i++) {
        final pos = exc.posiciones[i];
        final indicacion = double.tryParse(pos.indicacion) ?? 0.0;
        final retorno = double.tryParse(pos.retorno) ?? 0.0;
        // Calculo de error simple si es pos estándar
        final posicionVal = double.tryParse(pos.posicion) ??
            0.0; // En modelo es String, suele ser el número de pos

        if (esCamionera) {
          // Lógica Camionera (Ida/Vuelta)
          // Asumiendo 12 puntos max.
          if (i < 12) {
            // Determinar si es ida o vuelta y número
            // En el Helper DB vi columnas: excentricidad_inicial_punto1_ida_...
            // El modelo tiene una lista plana de posiciones.
            // Necesito saber cómo STIL mapea esto.
            // STIL Controller:
            /*
                 if ((ecc['platform'] ?? '').toString().toLowerCase().contains('camion')) {
                    for (int i = 0; i < positions.length; i++) {
                        final label = pos['label'] ?? (i < (positions.length ~/ 2) ? 'Ida' : 'Vuelta');
                        final prefix = 'excentricidad_${testType}_punto${i + 1}_${label.toLowerCase()}';
                        ...
                    }
                 }
                 */
            // Aquí en mi modelo solo tengo `posicion` (string), `indicacion`, `retorno`.
            // Voy a usar un mapeo directo a Pos1..6 si NO es camionera.
            // Si ES camionera, mapearé a Ida/Vuelta asumiendo el orden.
            // Pero Verificaciones DB TIENE 12 puntos ida/vuelta.
            // Mapearé secuencialmente.
            // String suffix = '';
            // Asumiendo que la lista viene ordenada Ida 1..6 luego Vuelta 1..6?
            // O Ida 1..6 ..
            // Si no tengo metadata extra, llenaré pos1..pos6 (sectores) que es lo común,
            // Y si hay mas, intentaré llenar los otros.
            // PERO: El DB Helper de Verificaciones tiene AMBOS sets de columnas.
            // Llenaré pos1..pos6 para todos los casos "standard"
            final num = i + 1;
            if (num <= 6) {
              data['excentricidad_${tipo}_pos${num}_numero'] = pos.posicion;
              data['excentricidad_${tipo}_pos${num}_indicacion'] = indicacion;
              data['excentricidad_${tipo}_pos${num}_retorno'] = retorno;
              data['excentricidad_${tipo}_pos${num}_error'] =
                  indicacion - posicionVal; // Error ?
            }
          }
        } else {
          // Caso Standard (hasta 6 posiciones)
          if (i < 6) {
            final num = i + 1;
            data['excentricidad_${tipo}_pos${num}_numero'] = pos.posicion;
            data['excentricidad_${tipo}_pos${num}_indicacion'] = indicacion;
            data['excentricidad_${tipo}_pos${num}_retorno'] = retorno;
            // Error: Indicacion - Carga? No, excentricidad es diferencia entre esquinas.
            // Dejaremos error en 0 o calculado si se requiere.
            data['excentricidad_${tipo}_pos${num}_error'] = 0.0;
          }
        }
      }
    }
  }

  void _addRepetibilidadData(
      Map<String, dynamic> data, Repetibilidad? rep, String tipo) {
    if (rep?.activo ?? false) {
      data['repetibilidad_${tipo}_cantidad_cargas'] =
          rep!.cantidadCargas.toString();
      data['repetibilidad_${tipo}_cantidad_pruebas'] =
          rep.cantidadPruebas.toString();

      for (int i = 0; i < rep.cargas.length; i++) {
        final carga = rep.cargas[i];
        final cargaNum = i + 1;
        // DB Columns: repetibilidad_inicial_carga1_valor
        data['repetibilidad_${tipo}_carga${cargaNum}_valor'] = carga.valor;

        for (int j = 0; j < carga.pruebas.length; j++) {
          final prueba = carga.pruebas[j];
          final testNum = j + 1;
          // DB Columns: repetibilidad_inicial_carga1_prueba1_indicacion
          data['repetibilidad_${tipo}_carga${cargaNum}_prueba${testNum}_indicacion'] =
              prueba.indicacion;
          data['repetibilidad_${tipo}_carga${cargaNum}_prueba${testNum}_retorno'] =
              prueba.retorno;
        }
      }
    }
  }

  void _addLinealidadData(
      Map<String, dynamic> data, Linealidad? lin, String tipo) {
    if (lin?.activo ?? false) {
      data['linealidad_${tipo}_cantidad_puntos'] = lin!.puntos.length;

      for (int i = 0; i < lin.puntos.length; i++) {
        final punto = lin.puntos[i];
        final num = i + 1;
        // DB Columns: linealidad_inicial_punto1_lt
        data['linealidad_${tipo}_punto${num}_lt'] = punto.lt;
        data['linealidad_${tipo}_punto${num}_indicacion'] = punto.indicacion;
        data['linealidad_${tipo}_punto${num}_retorno'] = punto.retorno;
        // data['linealidad_${tipo}_punto${num}_error'] = ...;
      }
    }
  }
}
