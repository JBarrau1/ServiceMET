import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:archive/archive.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import '../../../../../../database/soporte_tecnico/database_helper_mnt_prv_avanzado_stac.dart';
import '../models/mnt_prv_avanzado_stac_model.dart';

class MntPrvAvanzadoStacController {
  final MntPrvAvanzadoStacModel model;
  final Map<String, List<File>> _fieldPhotos = {};

  MntPrvAvanzadoStacController({required this.model});

  void copiarPruebasInicialesAFinales() {
    model.copiarPruebasInicialesAFinales();
  }

  // ✅ OPTIMIZADO: Obtener d1 sin múltiples consultas
  Future<double> getD1FromDatabase() async {
    try {
      final dbHelper = DatabaseHelperMntPrvAvanzadoStac();
      final db = await dbHelper.database;

      final results = await db.query(
        'mnt_prv_regular_stac',
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

  // ✅ NUEVO: Método para guardar solo en BD (sin fotos)
  Future<void> saveDataToDatabase(BuildContext context,
      {bool showMessage = true}) async {
    try {
      final dbHelper = DatabaseHelperMntPrvAvanzadoStac();
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
      'tipo_servicio': 'mnt prv avanzado stac',
      'hora_inicio': model.horaInicio,
      'hora_fin': model.horaFin,
      'comentario_general': model.comentarioGeneral,
      'recomendacion': model.recomendacion,
      'fisico': model.estadoFisico,
      'operacional': model.estadoOperacional,
      'metrologico': model.estadoMetrologico,
      'fecha_prox_servicio': model.fechaProxServicio,
    };

    _addCamposEstadoData(data);
    _addPruebasMetrologicasData(data);

    return data;
  }

  // REFACTORIZADO: Agregar datos de campos de estado
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

    // MAPEO ACTUALIZADO CON NOMBRES DE BD CORRECTOS
    final camposMap = {
      // Lozas y Fundaciones
      'losas_aproximacion': 'Losas de aproximación (daños o grietas)',
      'fundaciones': 'Fundaciones (daños o grietas)',

      // Limpieza y Drenaje
      'limpieza_perimetro': 'Limpieza de perímetro de balanza',
      'fosa_humedad': 'Fosa libre de humedad',
      'drenaje_libre': 'Drenaje libre',
      'bomba_sumidero': 'Bomba de sumidero funcional',

      // Chequeo
      'corrosion': 'Corrosión',
      'grietas': 'Grietas',
      'tapas_pernos': 'Tapas superiores y pernos',
      'desgaste_estres': 'Desgaste y estrés',
      'acumulacion_escombros': 'Acumulación de escombros o materiales externos',
      'verificacion_rieles': 'Verificación de rieles laterales',
      'paragolpes_longitudinales': 'Verificación de paragolpes longitudinales',
      'paragolpes_transversales': 'Verificación de paragolpes transversales',

      // Verificaciones Eléctricas (CORREGIDO)
      'cable_homerun': 'Condición de cable de Home Run',
      'cable_celda_celda': 'Condición de cable de célula a célula',
      'conexion_celdas': 'Conexión segura a celdas de carga',
      'funda_conector': 'Funda de goma y conector ajustados',
      'conector_terminacion': 'Conector de terminación ajustado',
      'cables_conectados': 'Cables conectados correctamente',

      // Protección contra Rayos
      'sistema_tierra': 'Sistema de protección contra rayos conectado a tierra',
      'conexion_strike_shield':
          'Conexión de la correa de tierra del Strike shield',
      'tension_neutro_tierra': 'Tensión entre neutro y tierra adecuada',
      'impresora_strike_shield': 'Impresora conectada al mismo Strike Shield',

      //Verificaciones de Células de Carga (nombres exactos de BD)
      'elevado_puente':
          'Elevado del puente de pesaje y retirado de las celdas de carga',
      'limpieza_estructura':
          'Limpieza e inspección de superficies de acoplamiento de la estructura',
      'bearing_cups': 'Limpieza e inspección de bearing cups',
      'celdas_carga': 'Limpieza e inspección de celdas de carga',
      'lubricacion_cabezas': 'Lubricación de cabezas de celdas de carga',
      'engrasado_bearing': 'Engrasado de bearing cups',
      'lainas_botas': 'Lainas, botas de goma colocadas',

      // Terminal
      'carcasa_lente_teclado':
          'Carcasa, lente y el teclado estan limpios, sin daños y sellados',
      'voltaje_bateria': 'Voltaje de la batería es adecuado',
      'teclado_operativo': 'Teclado operativo correctamente',
      'brillo_pantalla': 'Brillo de pantalla adecuado',
      'registros_pdx': 'Registros de rendimiento de cambio PDX OK',
      'pantallas_servicio':
          'Pantallas de servicio de MT indican operación normal',
      'archivos_respaldados':
          'Archivos de configuración respaldados con InSite',
      'terminal_disponibilidad':
          'Terminal devuelto a la disponibilidad operativo',

      // Calibración
      'calibracion_balanza':
          'Calibración de balanza realiza y dentro de tolerancia',
    };

    camposMap.forEach((dbKey, modelKey) => addCampo(dbKey, modelKey));
  }

  //MEJORADO: Agregar pruebas metrológicas con null-safety
  void _addPruebasMetrologicasData(Map<String, dynamic> data) {
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
