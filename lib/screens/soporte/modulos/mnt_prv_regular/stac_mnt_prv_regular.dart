import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:service_met/screens/soporte/componentes/test_container.dart';
import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:provider/provider.dart';
import 'package:service_met/provider/balanza_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'fin_servicio_stac.dart';

class StacMntPrvRegularStacScreen extends StatefulWidget {
  final String nReca;
  final String secaValue;
  final String sessionId;
  final String codMetrica;

  const StacMntPrvRegularStacScreen({
    super.key,
    required this.nReca,
    required this.secaValue,
    required this.sessionId,
    required this.codMetrica,
  });

  @override
  State<StacMntPrvRegularStacScreen> createState() =>
      _StacMntPrvRegularStacScreenState();
}

class _StacMntPrvRegularStacScreenState
    extends State<StacMntPrvRegularStacScreen> {
  final TextEditingController _horaController = TextEditingController();
  final TextEditingController _horaFinController = TextEditingController();
  final TextEditingController _comentarioGeneralController =
      TextEditingController();

  String? _selectedRecommendation;
  String? _selectedFisico;
  String? _selectedOperacional;
  String? _selectedMetrologico;

  late Map<String, dynamic> _initialTestsData;
  late Map<String, dynamic> _finalTestsData;
  late String _selectedUnitInicial;
  late String _selectedUnitFinal;

  final ImagePicker _imagePicker = ImagePicker();
  final Map<String, Map<String, dynamic>> _fieldData = {};
  final Map<String, List<File>> _fieldPhotos = {};
  final ValueNotifier<bool> _isSaveButtonPressed = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _isDataSaved = ValueNotifier<bool>(false);
  DateTime? _lastPressedTime;

  //controladores de comentarios de los campos
  final TextEditingController _lazasAproximacionComentarioController =
      TextEditingController();
  final TextEditingController _fundacionesComentarioController =
      TextEditingController();

// Sección de limpieza y drenaje
  final TextEditingController _limpiezaPerimetroComentarioController =
      TextEditingController();
  final TextEditingController _fosaHumedadComentarioController =
      TextEditingController();
  final TextEditingController _drenajeComentarioController =
      TextEditingController();
  final TextEditingController _bombaSumideroComentarioController =
      TextEditingController();

// Sección de Chequeo
  final TextEditingController _corrosionComentarioController =
      TextEditingController();
  final TextEditingController _grietasComentarioController =
      TextEditingController();
  final TextEditingController _tapasPernosComentarioController =
      TextEditingController();
  final TextEditingController _desgasteEstresComentarioController =
      TextEditingController();
  final TextEditingController _escombrosComentarioController =
      TextEditingController();
  final TextEditingController _rielesLateralesComentarioController =
      TextEditingController();
  final TextEditingController _paragolpesLongitudinalesComentarioController =
      TextEditingController();
  final TextEditingController _paragolpesTransversalesComentarioController =
      TextEditingController();

// Sección de Verificaciones eléctricas
  final TextEditingController _cableHomeRunComentarioController =
      TextEditingController();
  final TextEditingController _cableCeldaCeldaComentarioController =
      TextEditingController();
  final TextEditingController _cablesConectadosComentarioController =
      TextEditingController();
  final TextEditingController _conexionCeldasComentarioController =
      TextEditingController();
  final TextEditingController _fundaConectorComentarioController =
      TextEditingController();
  final TextEditingController _conectorTerminacionComentarioController =
      TextEditingController();

// Sección de protección contra rayos
  final TextEditingController _proteccionRayosComentarioController =
      TextEditingController();
  final TextEditingController _correaTierraComentarioController =
      TextEditingController();
  final TextEditingController _tensionNeutroTierraComentarioController =
      TextEditingController();
  final TextEditingController _impresoraShieldComentarioController =
      TextEditingController();

// Sección de Terminal
  final TextEditingController _terminalCarcasaComentarioController =
      TextEditingController();
  final TextEditingController _terminalBateriaComentarioController =
      TextEditingController();
  final TextEditingController _terminalTecladoComentarioController =
      TextEditingController();
  final TextEditingController _terminalPantallaComentarioController =
      TextEditingController();
  final TextEditingController _terminalRegistrosComentarioController =
      TextEditingController();
  final TextEditingController _terminalServicioComentarioController =
      TextEditingController();
  final TextEditingController _terminalBackupComentarioController =
      TextEditingController();
  final TextEditingController _terminalOperativoComentarioController =
      TextEditingController();

// Sección de Calibración
  final TextEditingController _calibracionComentarioController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _actualizarHora();

    // Inicialización de unidades y datos de pruebas
    _selectedUnitInicial = 'kg';
    _selectedUnitFinal = 'kg';
    _initialTestsData = <String, dynamic>{};
    _finalTestsData = <String, dynamic>{};

    // Lista de todos los campos del estado general del instrumento
    final List<String> camposEstadoGeneral = [
      // Sección de Lazas de aproximación y fundaciones
      'Losas de aproximación (daños o grietas)',
      'Fundaciones (daños o grietas)',

      // Sección de limpieza y drenaje
      'Limpieza de perímetro de balanza',
      'Fosa libre de humedad',
      'Drenaje libre',
      'Bomba de sumidero funcional',

      // Sección de Chequeo
      'Corrosión',
      'Grietas',
      'Tapas superiores y pernos',
      'Desgaste y estrés',
      'Acumulación de escombros o materiales externos',
      'Verificación de rieles laterales',
      'Verificación de paragolpes longitudinales',
      'Verificación de paragolpes transversales',

      // Sección de Verificaciones eléctricas
      'Condición de cable de Home Run',
      'Condición de cable de célula a célula',
      'Conexión segura a celdas de carga',
      'Funda de goma y conector ajustados',
      'Conector de terminación ajustado',
      'Los cables están conectados de forma segura a todas las celdas de carga',
      'La funda de goma y el conector del cable están apretados contra la celda de carga',
      'Conector de terminación ajustado y capuchón en su lugar',

      // Sección de protección contra rayos
      'Sistema de protección contra rayos conectado a tierra',
      'Conexión de la correa de tierra del Strike shield',
      'Tensión entre neutro y tierra adecuada',
      'Impresora conectada al mismo Strike Shield',

      // Sección de Terminal
      'Carcasa, lente y el teclado estan limpios, sin daños y sellados',
      'Voltaje de la batería es adecuado',
      'Teclado operativo correctamente',
      'Brillo de pantalla adecuado',
      'Registros de rendimiento de cambio PDX OK',
      'Pantallas de servicio de MT indican operación normal',
      'Archivos de configuración respaldados con InSite',
      'Terminal devuelto a la disponibilidad operativo',

      // Sección de Calibración
      'Calibración de balanza realiza y dentro de tolerancia'
    ];

    // Inicializar TODOS los campos con "4 No aplica" y "No aplica"
    for (final campo in camposEstadoGeneral) {
      _fieldData[campo] = {
        'initial_value': '4 No aplica', // Estado inicial
        'solution_value':
            'No aplica' // Solución (asegurar que coincida exactamente con las opciones)
      };
    }

    // Inicialización de controladores de comentarios
    _lazasAproximacionComentarioController.text = "Sin comentario";
    _fundacionesComentarioController.text = "Sin comentario";
    _limpiezaPerimetroComentarioController.text = "Sin comentario";
    _fosaHumedadComentarioController.text = "Sin comentario";
    _drenajeComentarioController.text = "Sin comentario";
    _bombaSumideroComentarioController.text = "Sin comentario";
    _corrosionComentarioController.text = "Sin comentario";
    _grietasComentarioController.text = "Sin comentario";
    _tapasPernosComentarioController.text = "Sin comentario";
    _desgasteEstresComentarioController.text = "Sin comentario";
    _escombrosComentarioController.text = "Sin comentario";
    _rielesLateralesComentarioController.text = "Sin comentario";
    _paragolpesLongitudinalesComentarioController.text = "Sin comentario";
    _paragolpesTransversalesComentarioController.text = "Sin comentario";
    _cableHomeRunComentarioController.text = "Sin comentario";
    _cableCeldaCeldaComentarioController.text = "Sin comentario";
    _conexionCeldasComentarioController.text = "Sin comentario";
    _fundaConectorComentarioController.text = "Sin comentario";
    _conectorTerminacionComentarioController.text = "Sin comentario";
    _proteccionRayosComentarioController.text = "Sin comentario";
    _correaTierraComentarioController.text = "Sin comentario";
    _tensionNeutroTierraComentarioController.text = "Sin comentario";
    _impresoraShieldComentarioController.text = "Sin comentario";
    _terminalCarcasaComentarioController.text = "Sin comentario";
    _terminalBateriaComentarioController.text = "Sin comentario";
    _terminalTecladoComentarioController.text = "Sin comentario";
    _terminalPantallaComentarioController.text = "Sin comentario";
    _terminalRegistrosComentarioController.text = "Sin comentario";
    _terminalServicioComentarioController.text = "Sin comentario";
    _terminalBackupComentarioController.text = "Sin comentario";
    _terminalOperativoComentarioController.text = "Sin comentario";
    _calibracionComentarioController.text = "Sin comentario";

    // Forzar actualización de la UI después de la inicialización
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  void _showSnackBar(BuildContext context, String message,
      {Color? backgroundColor, Color? textColor}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
              color: textColor ?? Colors.black), // Texto blanco por defecto
        ),
        backgroundColor:
            backgroundColor ?? Colors.grey, // Fondo naranja por defecto
      ),
    );
  }

  void _actualizarHora() {
    final ahora = DateTime.now();
    final horaFormateada = DateFormat('HH:mm:ss').format(ahora);
    _horaController.text = horaFormateada;
  }

  Future<bool> _onWillPop(BuildContext context) async {
    final now = DateTime.now();
    if (_lastPressedTime == null ||
        now.difference(_lastPressedTime!) > const Duration(seconds: 2)) {
      _lastPressedTime = now;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Presione nuevamente para retroceder. Los datos registrados se perderán.'),
          backgroundColor: Colors.orange,
        ),
      );
      return false;
    }
    return true;
  }

  Future<void> _saveAllDataAndPhotos(BuildContext context) async {
    // Verificar si el widget está montado antes de continuar
    if (!mounted) return;

    _isSaveButtonPressed.value = true; // Mostrar indicador de carga

    try {
      // Verificar si hay fotos en alguno de los campos
      bool hasPhotos = _fieldPhotos.values.any((photos) => photos.isNotEmpty);

      if (hasPhotos) {
        // Guardar las fotos en un archivo ZIP
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

        final uint8ListData = Uint8List.fromList(zipData);
        final zipFileName =
            '${widget.otValue}_${widget.codMetrica}_relevamiento_de_datos_fotos.zip';

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
      } else {
        _showSnackBar(
          context,
          'No se tomaron fotografías. Solo se guardarán los datos.',
          backgroundColor: Colors.orange,
        );
      }

      // Validar campos requeridos
      if (_horaController.text.isEmpty) {
        _showSnackBar(context, 'Por favor ingrese la hora de inicio',
            backgroundColor: Colors.red);
        return;
      }

      if (_horaFinController.text.isEmpty) {
        _showSnackBar(context, 'Por favor ingrese la hora final',
            backgroundColor: Colors.red);
        return;
      }

      // Guardar los datos en la base de datos
      await _saveAllMetrologicalTests(context);
    } catch (e) {
      _showSnackBar(context, 'Error al guardar: ${e.toString()}');
      debugPrint('Error al guardar: $e');
    } finally {
      if (mounted) {
        _isSaveButtonPressed.value =
            false; // Asegurarse de ocultar el indicador de carga
      }
    }
  }

  Future<void> _saveAllMetrologicalTests(BuildContext context) async {
    try {
      final path = join(widget.dbPath, '${widget.dbName}.db');
      final db = await openDatabase(path);

      String getFotosString(String label) {
        return _fieldPhotos[label]?.map((f) => basename(f.path)).join(',') ??
            '';
      }

      // Convertir todos los datos a un mapa para la base de datos
      final Map<String, dynamic> dbData = {
        'tipo_servicio': 'mnt prv regular stac',
        'cod_metrica': widget.codMetrica,
        'hora_inicio': _horaController.text,
        'hora_fin': _horaFinController.text,
        'comentario_general': _comentarioGeneralController.text,
        'recomendacion': _selectedRecommendation,
        'fisico': _selectedFisico,
        'operacional': _selectedOperacional,
        'metrologico': _selectedMetrologico,
        // Datos de pruebas metrológicas iniciales
        ..._convertTestDataToDbFormat(_initialTestsData, 'inicial'),
        // Datos de pruebas metrológicas finales
        ..._convertTestDataToDbFormat(_finalTestsData, 'final'),

        // Retorno a Cero
        'retorno_cero_inicial_valoracion':
            _fieldData['Retorno a cero']?['initial_value'] ?? '',
        'retorno_cero_inicial_carga':
            _fieldData['Retorno a cero']?['initial_load'] ?? '',
        'retorno_cero_inicial_unidad':
            _fieldData['Retorno a cero']?['initial_unit'] ?? '',
        'retorno_cero_final_valoracion':
            _fieldData['Retorno a cero']?['solution_value'] ?? '',
        'retorno_cero_final_carga':
            _fieldData['Retorno a cero']?['final_load'] ?? '',
        'retorno_cero_final_unidad':
            _fieldData['Retorno a cero']?['final_unit'] ?? '',

        // Sección Estructural
        'losas_aproximacion_estado':
            _fieldData['Losas de aproximación (daños o grietas)']
                    ?['initial_value'] ??
                '',
        'losas_aproximacion_solucion':
            _fieldData['Losas de aproximación (daños o grietas)']
                    ?['solution_value'] ??
                '',
        'losas_aproximacion_comentario':
            _lazasAproximacionComentarioController.text,
        'losas_aproximacion_foto':
            getFotosString('Losas de aproximación (daños o grietas)'),

        'fundaciones_estado':
            _fieldData['Fundaciones (daños o grietas)']?['initial_value'] ?? '',
        'fundaciones_solucion': _fieldData['Fundaciones (daños o grietas)']
                ?['solution_value'] ??
            '',
        'fundaciones_comentario': _fundacionesComentarioController.text,
        'fundaciones_foto': getFotosString('Fundaciones (daños o grietas)'),

        // Sección de limpieza y drenaje
        'limpieza_perimetro_estado':
            _fieldData['Limpieza de perímetro de balanza']?['initial_value'] ??
                '',
        'limpieza_perimetro_solucion':
            _fieldData['Limpieza de perímetro de balanza']?['solution_value'] ??
                '',
        'limpieza_perimetro_comentario':
            _limpiezaPerimetroComentarioController.text,
        'limpieza_perimetro_foto':
            getFotosString('Limpieza de perímetro de balanza'),

        'fosa_humedad_estado':
            _fieldData['Fosa libre de humedad']?['initial_value'] ?? '',
        'fosa_humedad_solucion':
            _fieldData['Fosa libre de humedad']?['solution_value'] ?? '',
        'fosa_humedad_comentario': _fosaHumedadComentarioController.text,
        'fosa_humedad_foto': getFotosString('Fosa libre de humedad'),

        'drenaje_libre_estado':
            _fieldData['Drenaje libre']?['initial_value'] ?? '',
        'drenaje_libre_solucion':
            _fieldData['Drenaje libre']?['solution_value'] ?? '',
        'drenaje_libre_comentario': _drenajeComentarioController.text,
        'drenaje_libre_foto': getFotosString('Drenaje libre'),

        'bomba_sumidero_estado':
            _fieldData['Bomba de sumidero funcional']?['initial_value'] ?? '',
        'bomba_sumidero_solucion':
            _fieldData['Bomba de sumidero funcional']?['solution_value'] ?? '',
        'bomba_sumidero_comentario': _bombaSumideroComentarioController.text,
        'bomba_sumidero_foto': getFotosString('Bomba de sumidero funcional'),

        // Sección de Chequeo Mecánico
        'corrosion_estado': _fieldData['Corrosión']?['initial_value'] ?? '',
        'corrosion_solucion': _fieldData['Corrosión']?['solution_value'] ?? '',
        'corrosion_comentario': _corrosionComentarioController.text,
        'corrosion_foto': getFotosString('Corrosión'),

        'grietas_estado': _fieldData['Grietas']?['initial_value'] ?? '',
        'grietas_solucion': _fieldData['Grietas']?['solution_value'] ?? '',
        'grietas_comentario': _grietasComentarioController.text,
        'grietas_foto': getFotosString('Grietas'),

        'tapas_pernos_estado':
            _fieldData['Tapas superiores y pernos']?['initial_value'] ?? '',
        'tapas_pernos_solucion':
            _fieldData['Tapas superiores y pernos']?['solution_value'] ?? '',
        'tapas_pernos_comentario': _tapasPernosComentarioController.text,
        'tapas_pernos_foto': getFotosString('Tapas superiores y pernos'),

        'desgaste_estres_estado':
            _fieldData['Desgaste y estrés']?['initial_value'] ?? '',
        'desgaste_estres_solucion':
            _fieldData['Desgaste y estrés']?['solution_value'] ?? '',
        'desgaste_estres_comentario': _desgasteEstresComentarioController.text,
        'desgaste_estres_foto': getFotosString('Desgaste y estrés'),

        'escombros_estado':
            _fieldData['Acumulación de escombros o materiales externos']
                    ?['initial_value'] ??
                '',
        'escombros_solucion':
            _fieldData['Acumulación de escombros o materiales externos']
                    ?['solution_value'] ??
                '',
        'escombros_comentario': _escombrosComentarioController.text,
        'escombros_foto':
            getFotosString('Acumulación de escombros o materiales externos'),

        'rieles_laterales_estado':
            _fieldData['Verificación de rieles laterales']?['initial_value'] ??
                '',
        'rieles_laterales_solucion':
            _fieldData['Verificación de rieles laterales']?['solution_value'] ??
                '',
        'rieles_laterales_comentario':
            _rielesLateralesComentarioController.text,
        'rieles_laterales_foto':
            getFotosString('Verificación de rieles laterales'),

        'paragolpes_long_estado':
            _fieldData['Verificación de paragolpes longitudinales']
                    ?['initial_value'] ??
                '',
        'paragolpes_long_solucion':
            _fieldData['Verificación de paragolpes longitudinales']
                    ?['solution_value'] ??
                '',
        'paragolpes_long_comentario':
            _paragolpesLongitudinalesComentarioController.text,
        'paragolpes_long_foto':
            getFotosString('Verificación de paragolpes longitudinales'),

        'paragolpes_transv_estado':
            _fieldData['Verificación de paragolpes transversales']
                    ?['initial_value'] ??
                '',
        'paragolpes_transv_solucion':
            _fieldData['Verificación de paragolpes transversales']
                    ?['solution_value'] ??
                '',
        'paragolpes_transv_comentario':
            _paragolpesTransversalesComentarioController.text,
        'paragolpes_transv_foto':
            getFotosString('Verificación de paragolpes transversales'),

        // Sección de Verificaciones eléctricas
        'cable_homerun_estado': _fieldData['Condición de cable de Home Run']
                ?['initial_value'] ??
            '',
        'cable_homerun_solucion': _fieldData['Condición de cable de Home Run']
                ?['solution_value'] ??
            '',
        'cable_homerun_comentario': _cableHomeRunComentarioController.text,
        'cable_homerun_foto': getFotosString('Condición de cable de Home Run'),

        'cable_celda_celda_estado':
            _fieldData['Condición de cable de célula a célula']
                    ?['initial_value'] ??
                '',
        'cable_celda_celda_solucion':
            _fieldData['Condición de cable de célula a célula']
                    ?['solution_value'] ??
                '',
        'cable_celda_celda_comentario':
            _cableCeldaCeldaComentarioController.text,
        'cable_celda_celda_foto':
            getFotosString('Condición de cable de célula a célula'),

        'conexion_celdas_estado':
            _fieldData['Conexión segura a celdas de carga']?['initial_value'] ??
                '',
        'conexion_celdas_solucion':
            _fieldData['Conexión segura a celdas de carga']
                    ?['solution_value'] ??
                '',
        'conexion_celdas_comentario': _conexionCeldasComentarioController.text,
        'conexion_celdas_foto':
            getFotosString('Conexión segura a celdas de carga'),

        'cables_conectados_estado':
            _fieldData['Cables correctamente conectados y asegurados']
                    ?['initial_value'] ??
                '',
        'cables_conectados_solucion':
            _fieldData['Cables correctamente conectados y asegurados']
                    ?['solution_value'] ??
                '',
        'cables_conectados_comentario':
            _cablesConectadosComentarioController.text,
        'cables_conectados_foto':
            getFotosString('Cables correctamente conectados y asegurados'),

        'funda_conector_estado':
            _fieldData['Funda de goma y conector ajustados']
                    ?['initial_value'] ??
                '',
        'funda_conector_solucion':
            _fieldData['Funda de goma y conector ajustados']
                    ?['solution_value'] ??
                '',
        'funda_conector_comentario': _fundaConectorComentarioController.text,
        'funda_conector_foto':
            getFotosString('Funda de goma y conector ajustados'),

        'conector_terminacion_estado':
            _fieldData['Conector de terminación ajustado']?['initial_value'] ??
                '',
        'conector_terminacion_solucion':
            _fieldData['Conector de terminación ajustado']?['solution_value'] ??
                '',
        'conector_terminacion_comentario':
            _conectorTerminacionComentarioController.text,
        'conector_terminacion_foto':
            getFotosString('Conector de terminación ajustado'),

        // Sección de protección contra rayos
        'proteccion_rayos_estado':
            _fieldData['Sistema de protección contra rayos conectado a tierra']
                    ?['initial_value'] ??
                '',
        'proteccion_rayos_solucion':
            _fieldData['Sistema de protección contra rayos conectado a tierra']
                    ?['solution_value'] ??
                '',
        'proteccion_rayos_comentario':
            _proteccionRayosComentarioController.text,
        'proteccion_rayos_foto': getFotosString(
            'Sistema de protección contra rayos conectado a tierra'),

        'conexion_tierra_estado':
            _fieldData['Conexión de la correa de tierra del Strike shield']
                    ?['initial_value'] ??
                '',
        'conexion_tierra_solucion':
            _fieldData['Conexión de la correa de tierra del Strike shield']
                    ?['solution_value'] ??
                '',
        'conexion_tierra_comentario': _correaTierraComentarioController.text,
        'conexion_tierra_foto':
            getFotosString('Conexión de la correa de tierra del Strike shield'),

        'tension_neutro_estado':
            _fieldData['Tensión entre neutro y tierra adecuada']
                    ?['initial_value'] ??
                '',
        'tension_neutro_solucion':
            _fieldData['Tensión entre neutro y tierra adecuada']
                    ?['solution_value'] ??
                '',
        'tension_neutro_comentario':
            _tensionNeutroTierraComentarioController.text,
        'tension_neutro_foto':
            getFotosString('Tensión entre neutro y tierra adecuada'),

        'impresion_conectada_estado':
            _fieldData['Impresora conectada al mismo Strike Shield']
                    ?['initial_value'] ??
                '',
        'impresion_conectada_solucion':
            _fieldData['Impresora conectada al mismo Strike Shield']
                    ?['solution_value'] ??
                '',
        'impresion_conectada_comentario':
            _impresoraShieldComentarioController.text,
        'impresion_conectada_foto':
            getFotosString('Impresora conectada al mismo Strike Shield'),

        // Sección de Terminal
        'carcasa_limpia_estado': _fieldData[
                    'Carcasa, lente y el teclado estan limpios, sin daños y sellados']
                ?['initial_value'] ??
            '',
        'carcasa_limpia_solucion': _fieldData[
                    'Carcasa, lente y el teclado estan limpios, sin daños y sellados']
                ?['solution_value'] ??
            '',
        'carcasa_limpia_comentario': _terminalCarcasaComentarioController.text,
        'carcasa_limpia_foto': getFotosString(
            'Carcasa, lente y el teclado estan limpios, sin daños y sellados'),

        'voltaje_bateria_estado':
            _fieldData['Voltaje de la batería es adecuado']?['initial_value'] ??
                '',
        'voltaje_bateria_solucion':
            _fieldData['Voltaje de la batería es adecuado']
                    ?['solution_value'] ??
                '',
        'voltaje_bateria_comentario': _terminalBateriaComentarioController.text,
        'voltaje_bateria_foto':
            getFotosString('Voltaje de la batería es adecuado'),

        'teclado_funcional_estado':
            _fieldData['Teclado operativo correctamente']?['initial_value'] ??
                '',
        'teclado_funcional_solucion':
            _fieldData['Teclado operativo correctamente']?['solution_value'] ??
                '',
        'teclado_funcional_comentario':
            _terminalTecladoComentarioController.text,
        'teclado_funcional_foto':
            getFotosString('Teclado operativo correctamente'),

        'brillo_pantalla_estado':
            _fieldData['Brillo de pantalla adecuado']?['initial_value'] ?? '',
        'brillo_pantalla_solucion':
            _fieldData['Brillo de pantalla adecuado']?['solution_value'] ?? '',
        'brillo_pantalla_comentario':
            _terminalPantallaComentarioController.text,
        'brillo_pantalla_foto': getFotosString('Brillo de pantalla adecuado'),

        'registro_rendimiento_estado':
            _fieldData['Registros de rendimiento de cambio PDX OK']
                    ?['initial_value'] ??
                '',
        'registro_rendimiento_solucion':
            _fieldData['Registros de rendimiento de cambio PDX OK']
                    ?['solution_value'] ??
                '',
        'registro_rendimiento_comentario':
            _terminalRegistrosComentarioController.text,
        'registro_rendimiento_foto':
            getFotosString('Registros de rendimiento de cambio PDX OK'),

        'pantallas_mt_estado':
            _fieldData['Pantallas de servicio de MT indican operación normal']
                    ?['initial_value'] ??
                '',
        'pantallas_mt_solucion':
            _fieldData['Pantallas de servicio de MT indican operación normal']
                    ?['solution_value'] ??
                '',
        'pantallas_mt_comentario': _terminalServicioComentarioController.text,
        'pantallas_mt_foto': getFotosString(
            'Pantallas de servicio de MT indican operación normal'),

        'backup_insite_estado':
            _fieldData['Archivos de configuración respaldados con InSite']
                    ?['initial_value'] ??
                '',
        'backup_insite_solucion':
            _fieldData['Archivos de configuración respaldados con InSite']
                    ?['solution_value'] ??
                '',
        'backup_insite_comentario': _terminalBackupComentarioController.text,
        'backup_insite_foto':
            getFotosString('Archivos de configuración respaldados con InSite'),

        'terminal_operativo_estado':
            _fieldData['Terminal devuelto a la disponibilidad operativo']
                    ?['initial_value'] ??
                '',
        'terminal_operativo_solucion':
            _fieldData['Terminal devuelto a la disponibilidad operativo']
                    ?['solution_value'] ??
                '',
        'terminal_operativo_comentario':
            _terminalOperativoComentarioController.text,
        'terminal_operativo_foto':
            getFotosString('Terminal devuelto a la disponibilidad operativo'),

        // Sección de Calibración
        'calibracion_estado':
            _fieldData['Calibración de balanza realiza y dentro de tolerancia']
                    ?['initial_value'] ??
                '',
        'calibracion_solucion':
            _fieldData['Calibración de balanza realiza y dentro de tolerancia']
                    ?['solution_value'] ??
                '',
        'calibracion_comentario': _calibracionComentarioController.text,
        'calibracion_foto': getFotosString(
            'Calibración de balanza realiza y dentro de tolerancia'),
      };

      // Verificar si ya existe un registro
      final existing = await db.query(
        'mnt_prv_regular_stac',
        where: 'cod_metrica = ?',
        whereArgs: [widget.codMetrica],
      );

      if (existing.isNotEmpty) {
        await db.update(
          'mnt_prv_regular_stac',
          dbData,
          where: 'cod_metrica = ?',
          whereArgs: [widget.codMetrica],
        );
      } else {
        await db.insert(
          'mnt_prv_regular_stac',
          dbData,
        );
      }

      await db.close();
      _showSnackBar(
        context,
        'Datos guardados exitosamente',
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );

      _isDataSaved.value = true;
    } catch (e) {
      _showSnackBar(
          context, 'Error al guardar pruebas metrológicas: ${e.toString()}');
      debugPrint('Error al guardar pruebas metrológicas: $e');
      _isDataSaved.value =
          false; // Asegurarse de mantenerlo en false si hay error
    }
  }

  Map<String, dynamic> _convertTestDataToDbFormat(
    Map<String, dynamic> testData,
    String testType,
  ) {
    final Map<String, dynamic> result = {};

    // Retorno a Cero
    if (testData['return_to_zero'] != null) {
      final rtz = testData['return_to_zero'];
      result['retorno_cero_${testType}_valoracion'] = rtz['value'] ?? '';
      result['retorno_cero_${testType}_carga'] =
          double.tryParse(rtz['load']?.toString() ?? '0') ?? 0;
      result['retorno_cero_${testType}_unidad'] = rtz['unit'] ?? 'kg';
    }

    // Excentricidad
    if (testData['eccentricity'] != null) {
      final ecc = testData['eccentricity'];
      result['excentricidad_${testType}_tipo_plataforma'] =
          ecc['platform'] ?? '';
      result['excentricidad_${testType}_opcion_prueba'] = ecc['option'] ?? '';
      result['excentricidad_${testType}_carga'] =
          double.tryParse(ecc['load']?.toString() ?? '0') ?? 0;
      result['excentricidad_${testType}_ruta_imagen'] = ecc['imagePath'] ?? '';
      final positions = ecc['positions'] ?? [];
      result['excentricidad_${testType}_cantidad_posiciones'] =
          positions.length.toString();

      for (int i = 0; i < positions.length && i < 6; i++) {
        final pos = positions[i];
        final prefix = 'excentricidad_${testType}_pos${i + 1}';
        final indicacion =
            double.tryParse(pos['indication']?.toString() ?? '0') ?? 0;
        final posicion =
            double.tryParse(pos['position']?.toString() ?? '0') ?? 0;
        final retorno = double.tryParse(pos['return']?.toString() ?? '0') ?? 0;

        result['${prefix}_numero'] = pos['position']?.toString() ?? '';
        result['${prefix}_indicacion'] = indicacion;
        result['${prefix}_retorno'] = retorno;
        result['${prefix}_error'] = indicacion - posicion;
      }
    }

    // Repetibilidad
    if (testData['repeatability'] != null) {
      final rep = testData['repeatability'];
      final loadCount = rep['repetibilityCount'] ?? 1;
      final rowCount = rep['rowCount'] ?? 3;

      result['repetibilidad_${testType}_cantidad_cargas'] =
          loadCount.toString();
      result['repetibilidad_${testType}_cantidad_pruebas'] =
          rowCount.toString();

      final loads = rep['loads'] ?? [];

      for (int i = 0; i < loads.length && i < 3; i++) {
        final load = loads[i];
        final loadPrefix = 'repetibilidad_${testType}_carga${i + 1}';
        result['${loadPrefix}_valor'] =
            double.tryParse(load['value']?.toString() ?? '0') ?? 0;

        final indications = load['indications'] ?? [];

        for (int j = 0; j < indications.length && j < 10; j++) {
          final indication =
              double.tryParse(indications[j]['value']?.toString() ?? '0') ?? 0;
          final returnVal =
              double.tryParse(indications[j]['return']?.toString() ?? '0') ?? 0;

          final testPrefix = '${loadPrefix}_prueba${j + 1}';
          result['${testPrefix}_indicacion'] = indication;
          result['${testPrefix}_retorno'] = returnVal;
        }
      }
    }

    return result;
  }

  Future<void> _showCommentDialog(BuildContext context, String label) async {
    List<File> photos = _fieldPhotos[label] ?? [];

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                'AGREGAR FOTOGRAFÍA PARA: $label',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        final XFile? photo = await _imagePicker.pickImage(
                            source: ImageSource.camera);
                        if (photo != null) {
                          final fileName = basename(photo.path);
                          setState(() {
                            photos.add(File(photo.path));
                            _fieldPhotos[label] = photos;
                            _fieldData[label] ??= {};
                            _fieldData[label]!['foto'] = fileName;
                          });
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrange,
                        foregroundColor: Colors.white,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.camera_alt),
                          const SizedBox(width: 8),
                          Text(photos.isEmpty
                              ? 'TOMAR FOTO'
                              : 'TOMAR OTRA FOTO'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (photos.isNotEmpty)
                      Text(
                        'Fotos tomadas: ${photos.length}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    const SizedBox(height: 10),
                    Wrap(
                      children: photos.map((photo) {
                        return Stack(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Image.file(photo, width: 100, height: 100),
                            ),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: IconButton(
                                icon: const Icon(Icons.delete_outline_rounded,
                                    color: Colors.red),
                                onPressed: () {
                                  setState(() {
                                    photos.remove(photo);
                                    _fieldPhotos[label] = photos;
                                    if (photos.isEmpty) {
                                      _fieldData[label]?.remove('foto');
                                    }
                                  });
                                },
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    // No necesitamos marcar 'foto_tomada' ya que verificamos directamente _fieldPhotos
                  },
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final balanza = Provider.of<BalanzaProvider>(context).selectedBalanza;

    return WillPopScope(
      onWillPop: () => _onWillPop(context),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          toolbarHeight: 80,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'SOPORTE TÉCNICO',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'CLIENTE: ${widget.selectedPlantaNombre}\nCÓDIGO: ${widget.codMetrica}',
                style: TextStyle(
                  fontSize: 10,
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          backgroundColor: isDarkMode ? Colors.transparent : Colors.white,
          elevation: 0,
          flexibleSpace: isDarkMode
              ? ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(color: Colors.black.withOpacity(0.4)),
                  ),
                )
              : null,
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.only(
            top: kToolbarHeight + MediaQuery.of(context).padding.top + 40, // Altura del AppBar + Altura de la barra de estado + un poco de espacio extra
            left: 16.0, // Tu padding horizontal original
            right: 16.0, // Tu padding horizontal original
            bottom: 16.0, // Tu padding inferior original
          ),
          child: Column(
            children: [
              const Text(
                'MANTENIMIENTO PREVENTIVO REGULAR\nSTAC',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _horaController,
                decoration: InputDecoration(
                  labelText: 'Hora de Inicio de Servicio',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20)),
                  suffixIcon: const Icon(Icons.access_time),
                ),
                readOnly: true,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(
                      Icons.info,
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'La hora se extrae automáticamente del sistema, este campo no es editable.',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDarkMode ? Colors.white70 : Colors.black54,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Pruebas Metrológicas Iniciales
              MetrologicalTestsContainer(
                testType: 'Inicial',
                initialData: _initialTestsData,
                onTestsDataChanged: (data) {
                  setState(() {
                    _initialTestsData = data;
                  });
                },
                selectedUnit: _selectedUnitInicial,
                onUnitChanged: (unit) {
                  setState(() {
                    _selectedUnitInicial = unit;
                  });
                },
              ),
              const SizedBox(height: 20.0),
              const Text(
                'ESTADO GENERAL DEL INSTRUMENTO',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF9DEAE5), // Color personalizado
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20.0),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'LOSAS DE APROXIMACIÓN / VERIFICACIONES DE LA FUNDACIÓN:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black54, // Color personalizado
                  ),
                  textAlign: TextAlign.left,
                ),
              ),
              const SizedBox(height: 20.0),
              _buildDropdownFieldWithComment(
                  context,
                  'Losas de aproximación (daños o grietas)',
                  _lazasAproximacionComentarioController),
              const SizedBox(height: 20.0),
              _buildDropdownFieldWithComment(
                  context,
                  'Fundaciones (daños o grietas)',
                  _fundacionesComentarioController),
              const SizedBox(height: 20.0),
              _buildDropdownFieldWithComment(
                  context,
                  'Limpieza de perímetro de balanza',
                  _limpiezaPerimetroComentarioController),
              const SizedBox(height: 20.0),
              _buildDropdownFieldWithComment(context, 'Fosa libre de humedad',
                  _fosaHumedadComentarioController),
              const SizedBox(height: 20.0),
              _buildDropdownFieldWithComment(
                  context, 'Drenaje libre', _drenajeComentarioController),
              const SizedBox(height: 20.0),
              _buildDropdownFieldWithComment(
                  context,
                  'Bomba de sumidero funcional',
                  _bombaSumideroComentarioController),
              const SizedBox(height: 20.0),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'PUENTE DE PESAJE:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black54,
                  ),
                  textAlign: TextAlign.left,
                ),
              ),
              const SizedBox(height: 20.0),
              _buildDropdownFieldWithComment(
                  context, 'Corrosión', _corrosionComentarioController),
              const SizedBox(height: 20.0),
              _buildDropdownFieldWithComment(
                  context, 'Grietas', _grietasComentarioController),
              const SizedBox(height: 20.0),
              _buildDropdownFieldWithComment(
                  context,
                  'Tapas superiores y pernos',
                  _tapasPernosComentarioController),
              const SizedBox(height: 20.0),
              _buildDropdownFieldWithComment(context, 'Desgaste y estrés',
                  _desgasteEstresComentarioController),
              const SizedBox(height: 20.0),
              _buildDropdownFieldWithComment(
                  context,
                  'Acumulación de escombros o materiales externos',
                  _escombrosComentarioController),
              const SizedBox(height: 20.0),
              _buildDropdownFieldWithComment(
                  context,
                  'Verificación de rieles laterales',
                  _rielesLateralesComentarioController),
              const SizedBox(height: 20.0),
              _buildDropdownFieldWithComment(
                  context,
                  'Verificación de paragolpes longitudinales',
                  _paragolpesLongitudinalesComentarioController),
              const SizedBox(height: 20.0),
              _buildDropdownFieldWithComment(
                  context,
                  'Verificación de paragolpes transversales',
                  _paragolpesTransversalesComentarioController),
              const SizedBox(height: 20.0),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'VERIFICACIONES DEL CABLE DE LA CELDA DE CARGA:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black54,
                  ),
                  textAlign: TextAlign.left,
                ),
              ),
              const SizedBox(height: 20.0),
              _buildDropdownFieldWithComment(
                  context,
                  'Condición de cable de Home Run',
                  _cableHomeRunComentarioController),
              const SizedBox(height: 20.0),
              _buildDropdownFieldWithComment(
                  context,
                  'Condición de cable de célula a célula',
                  _cableCeldaCeldaComentarioController),
              const SizedBox(height: 20.0),
              _buildDropdownFieldWithComment(
                  context,
                  'Conexión segura a celdas de carga',
                  _conexionCeldasComentarioController),
              const SizedBox(height: 20.0),
              _buildDropdownFieldWithComment(
                  context,
                  'Funda de goma y conector ajustados',
                  _fundaConectorComentarioController),
              const SizedBox(height: 20.0),
              _buildDropdownFieldWithComment(
                  context,
                  'Conector de terminación ajustado',
                  _conectorTerminacionComentarioController),
              const SizedBox(height: 20.0),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'COMPROBACIÓN DE ATERRAMIENTO:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black54,
                  ),
                  textAlign: TextAlign.left,
                ),
              ),
              const SizedBox(height: 20.0),
              _buildDropdownFieldWithComment(
                  context,
                  'Sistema de protección contra rayos conectado a tierra',
                  _proteccionRayosComentarioController),
              const SizedBox(height: 20.0),
              _buildDropdownFieldWithComment(
                  context,
                  'Conexión de la correa de tierra del Strike shield',
                  _correaTierraComentarioController),
              const SizedBox(height: 20.0),
              _buildDropdownFieldWithComment(
                  context,
                  'Tensión entre neutro y tierra adecuada',
                  _tensionNeutroTierraComentarioController),
              const SizedBox(height: 20.0),
              _buildDropdownFieldWithComment(
                  context,
                  'Impresora conectada al mismo Strike Shield',
                  _impresoraShieldComentarioController),
              const SizedBox(height: 20.0),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'CHEQUEO DEL TERMINAL DE LA BALANZA:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black54,
                  ),
                  textAlign: TextAlign.left,
                ),
              ),
              const SizedBox(height: 20.0),
              _buildDropdownFieldWithComment(
                  context,
                  'Carcasa, lente y el teclado estan limpios, sin daños y sellados',
                  _terminalCarcasaComentarioController),
              const SizedBox(height: 20.0),
              _buildDropdownFieldWithComment(
                  context,
                  'Voltaje de la batería es adecuado',
                  _terminalBateriaComentarioController),
              const SizedBox(height: 20.0),
              _buildDropdownFieldWithComment(
                  context,
                  'Teclado operativo correctamente',
                  _terminalTecladoComentarioController),
              const SizedBox(height: 20.0),
              _buildDropdownFieldWithComment(
                  context,
                  'Brillo de pantalla adecuado',
                  _terminalPantallaComentarioController),
              const SizedBox(height: 20.0),
              _buildDropdownFieldWithComment(
                  context,
                  'Registros de rendimiento de cambio PDX OK',
                  _terminalRegistrosComentarioController),
              const SizedBox(height: 20.0),
              _buildDropdownFieldWithComment(
                  context,
                  'Pantallas de servicio de MT indican operación normal',
                  _terminalServicioComentarioController),
              const SizedBox(height: 20.0),
              _buildDropdownFieldWithComment(
                  context,
                  'Archivos de configuración respaldados con InSite',
                  _terminalBackupComentarioController),
              const SizedBox(height: 20.0),
              _buildDropdownFieldWithComment(
                  context,
                  'Terminal devuelto a la disponibilidad operativo',
                  _terminalOperativoComentarioController),
              const SizedBox(height: 20.0),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'CALIBRACIÓN / VERIFICACIÓN:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black54,
                  ),
                  textAlign: TextAlign.left,
                ),
              ),
              const SizedBox(height: 20.0),
              _buildDropdownFieldWithComment(
                  context,
                  'Calibración de balanza realiza y dentro de tolerancia',
                  _calibracionComentarioController), // Resto del formulario (estado general del instrumento, etc.)
              // Pruebas Metrológicas Finales
              MetrologicalTestsContainer(
                testType: 'Final',
                initialData: _finalTestsData,
                onTestsDataChanged: (data) {
                  setState(() {
                    _finalTestsData = data;
                  });
                },
                selectedUnit: _selectedUnitFinal,
                onUnitChanged: (unit) {
                  setState(() {
                    _selectedUnitFinal = unit;
                  });
                },
              ),
              // Estado Final de la Balanza
              const SizedBox(height: 20),
              const Text(
                'ESTADO FINAL DE LA BALANZA',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFf5b041),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _comentarioGeneralController,
                decoration: InputDecoration(
                  labelText: 'Comentario General',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20)),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value:
                    _selectedRecommendation, // Variable para almacenar la selección
                decoration: InputDecoration(
                  labelText: 'Recomendación',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                ),
                items: [
                  'Diagnostico',
                  'Mnt Preventivo Regular',
                  'Mnt Preventivo Avanzado',
                  'Mnt Correctivo',
                  'Ajustes Metrológicos',
                  'Calibración',
                  'Sin recomendación'
                ]
                    .map((String value) => DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        ))
                    .toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedRecommendation =
                        newValue; // Actualiza la selección
                  });
                },
              ),
              const SizedBox(height: 20.0), // Espaciado entre los campos
              DropdownButtonFormField<String>(
                value: _selectedFisico, // Variable para almacenar la selección
                decoration: InputDecoration(
                  labelText: 'Físico',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                ),
                items: ['Bueno', 'Aceptable', 'Malo', 'No aplica']
                    .map((String value) => DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        ))
                    .toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedFisico = newValue; // Actualiza la selección
                  });
                },
              ),
              const SizedBox(height: 20.0), // Espaciado entre los campos
              DropdownButtonFormField<String>(
                value:
                    _selectedOperacional, // Variable para almacenar la selección
                decoration: InputDecoration(
                  labelText: 'Operacional',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                ),
                items: ['Bueno', 'Aceptable', 'Malo', 'No aplica']
                    .map((String value) => DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        ))
                    .toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedOperacional = newValue; // Actualiza la selección
                  });
                },
              ),
              const SizedBox(height: 20.0), // Espaciado entre los campos
              DropdownButtonFormField<String>(
                value:
                    _selectedMetrologico, // Variable para almacenar la selección
                decoration: InputDecoration(
                  labelText: 'Metrológico',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                ),
                items: ['Bueno', 'Aceptable', 'Malo', 'No aplica']
                    .map((String value) => DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        ))
                    .toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedMetrologico = newValue; // Actualiza la selección
                  });
                },
              ),
              const SizedBox(height: 20.0),
              TextFormField(
                controller: _horaFinController,
                decoration: InputDecoration(
                  labelText: 'Hora Final del Servicio',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20)),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.access_time),
                    onPressed: () {
                      final ahora = DateTime.now();
                      final horaFormateada =
                          DateFormat('HH:mm:ss').format(ahora);
                      _horaFinController.text = horaFormateada;
                    },
                  ),
                ),
                readOnly: true,
              ),
              const SizedBox(height: 20.0),
              // Botones de acción
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: ValueListenableBuilder<bool>(
                      valueListenable: _isSaveButtonPressed,
                      builder: (context, isSaving, child) {
                        return ElevatedButton(
                          onPressed: isSaving
                              ? null
                              : () => _saveAllDataAndPhotos(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF195375),
                          ),
                          child: isSaving
                              ? const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Colors.white),
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    Text('Guardando...',
                                        style: TextStyle(fontSize: 16)),
                                  ],
                                )
                              : const Text('GUARDAR DATOS'),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  ValueListenableBuilder<bool>(
                    valueListenable: _isDataSaved,
                    builder: (context, isSaved, child) {
                      return Expanded(
                        child: ElevatedButton(
                          onPressed: isSaved
                              ? () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          FinServicioMntPrvStacScreen(
                                        dbName: widget.dbName,
                                        dbPath: widget.dbPath,
                                        otValue: widget.otValue,
                                        selectedCliente: widget.selectedCliente,
                                        selectedPlantaNombre:
                                            widget.selectedPlantaNombre,
                                        codMetrica: widget.codMetrica,
                                      ),
                                    ),
                                  );
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                            isSaved ? const Color(0xFF167D1D) : Colors.grey,
                          ),
                          child: const Text('SIGUIENTE'),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String labelText,
      {Widget? suffixIcon}) {
    return InputDecoration(
      labelText: labelText,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20.0)),
      suffixIcon: suffixIcon, // Agregar el parámetro suffixIcon
    );
  }

  Widget _buildDropdownFieldWithComment(
    BuildContext context,
    String label,
    TextEditingController commentController, {
    List<String>? customOptions,
  }) {
    // Opciones para el estado inicial
    final List<String> initialOptions =
        customOptions ?? ['1 Bueno', '2 Aceptable', '3 Malo', '4 No aplica'];

    // Opciones para el estado final (solución)
    final List<String> solutionOptions = [
      'Sí',
      'Se intentó',
      'No',
      'No aplica'
    ];

    // Validar y obtener valor actual para estado inicial
    String currentInitialValue =
        _fieldData[label]?['initial_value'] ?? initialOptions.first;
    if (!initialOptions.contains(currentInitialValue)) {
      currentInitialValue = initialOptions.first;
    }

    // Validar y obtener valor actual para estado final (solución)
    String currentSolutionValue =
        _fieldData[label]?['solution_value'] ?? solutionOptions.first;
    if (!solutionOptions.contains(currentSolutionValue)) {
      currentSolutionValue = solutionOptions.first;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Dropdown para estado inicial
        Row(
          children: [
            Expanded(
              flex: 5,
              child: DropdownButtonFormField<String>(
                value: currentInitialValue,
                decoration: _buildInputDecoration(label),
                items: initialOptions.map((String value) {
                  if (customOptions != null) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }
                  Color textColor;
                  Icon? icon;
                  switch (value) {
                    case '1 Bueno':
                      textColor = Colors.green;
                      icon =
                          const Icon(Icons.check_circle, color: Colors.green);
                      break;
                    case '2 Aceptable':
                      textColor = Colors.orange;
                      icon = const Icon(Icons.warning, color: Colors.orange);
                      break;
                    case '3 Malo':
                      textColor = Colors.red;
                      icon = const Icon(Icons.error, color: Colors.red);
                      break;
                    case '4 No aplica':
                      textColor = Colors.grey;
                      icon = const Icon(Icons.block, color: Colors.grey);
                      break;
                    default:
                      textColor = Colors.black;
                      icon = null;
                  }
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Row(
                      children: [
                        if (icon != null) icon,
                        if (icon != null) const SizedBox(width: 8),
                        Text(value, style: TextStyle(color: textColor)),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (newValue) {
                  if (newValue != null) {
                    setState(() {
                      _fieldData[label] ??= {};
                      _fieldData[label]!['initial_value'] = newValue;
                    });
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor seleccione una opción';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 10),
            IconButton(
              onPressed: () => _showCommentDialog(context, label),
              icon: Stack(
                children: [
                  Icon(
                    _fieldPhotos[label]?.isNotEmpty == true
                        ? Icons.check_circle
                        : Icons.camera_alt_rounded,
                    color: _fieldPhotos[label]?.isNotEmpty == true
                        ? Colors.green
                        : null,
                  ),
                  if (_fieldPhotos[label]?.isNotEmpty == true)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '${_fieldPhotos[label]?.length ?? 0}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 12.0),

        // Dropdown para estado final (solución)
        Row(
          children: [
            Expanded(
              flex: 5,
              child: DropdownButtonFormField<String>(
                value: currentSolutionValue,
                decoration: _buildInputDecoration('¿Se solucionó el problema?'),
                items: solutionOptions.map((String value) {
                  Color textColor;
                  Icon? icon;
                  switch (value) {
                    case 'Sí':
                      textColor = Colors.green;
                      icon = const Icon(Icons.check_circle_outline,
                          color: Colors.green);
                      break;
                    case 'Se intentó':
                      textColor = Colors.orange;
                      icon = const Icon(Icons.build_circle_outlined,
                          color: Colors.orange);
                      break;
                    case 'No':
                      textColor = Colors.red;
                      icon =
                          const Icon(Icons.cancel_rounded, color: Colors.red);
                      break;
                    case 'No aplica':
                      textColor = Colors.grey;
                      icon =
                          const Icon(Icons.block_outlined, color: Colors.grey);
                      break;
                    default:
                      textColor = Colors.black;
                      icon = null;
                  }
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Row(
                      children: [
                        if (icon != null) icon,
                        if (icon != null) const SizedBox(width: 8),
                        Text(value, style: TextStyle(color: textColor)),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (newValue) {
                  if (newValue != null) {
                    setState(() {
                      _fieldData[label] ??= {};
                      _fieldData[label]!['solution_value'] = newValue;
                    });
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor seleccione una opción';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(flex: 1, child: SizedBox()),
          ],
        ),

        const SizedBox(height: 12.0),

        // Campo de comentario
        Row(
          children: [
            Expanded(
              flex: 5,
              child: TextFormField(
                controller: commentController,
                decoration: _buildInputDecoration('Comentario $label'),
                onTap: () {
                  if (commentController.text == 'Sin Comentario') {
                    commentController.clear();
                  }
                },
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(flex: 1, child: SizedBox()),
          ],
        ),

        const SizedBox(height: 12.0),

        // Línea divisoria sutil
        Divider(
          thickness: 0.5,
          color: Colors.grey.withOpacity(0.8),
          height: 20,
        ),
      ],
    );
  }

  @override
  void dispose() {
    _horaController.dispose();
    _horaFinController.dispose();
    _comentarioGeneralController.dispose();
    _isSaveButtonPressed.dispose();
    _isDataSaved.dispose();
    super.dispose();
  }
}
