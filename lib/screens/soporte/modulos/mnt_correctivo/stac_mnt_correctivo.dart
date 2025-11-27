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
import '../../../../database/soporte_tecnico/database_helper_mnt_correctivo.dart';
import 'fin_servicio_mntcorrectivo.dart';

class StacMntCorrectivoScreen extends StatefulWidget {
  final String sessionId;
  final String secaValue;
  final String nReca;
  final String codMetrica;
  final String userName; // ✅ AGREGAR
  final String clienteId; // ✅ AGREGAR
  final String plantaCodigo; // ✅ AGREGAR

  const StacMntCorrectivoScreen({
    super.key,
    required this.sessionId,
    required this.secaValue,
    required this.nReca,
    required this.codMetrica,
    required this.userName, // ✅ AGREGAR
    required this.clienteId, // ✅ AGREGAR
    required this.plantaCodigo, // ✅ AGREGAR
  });

  @override
  State<StacMntCorrectivoScreen> createState() =>
      _StacMntCorrectivoScreenState();
}

class _StacMntCorrectivoScreenState extends State<StacMntCorrectivoScreen> {
  final TextEditingController _reporteFallaController = TextEditingController();
  final TextEditingController _evaluacionController = TextEditingController();
  final TextEditingController _horaController = TextEditingController();
  final TextEditingController _horaFinController = TextEditingController();
  final List<TextEditingController> _comentariosControllers = [];
  final List<FocusNode> _comentariosFocusNodes = [];
  int _comentariosCount = 0;

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

  //campos igual a mnt prv regular
  final TextEditingController _vibracionComentarioController =
      TextEditingController();
  final TextEditingController _polvoComentarioController =
      TextEditingController();
  final TextEditingController _teperaturaComentarioController =
      TextEditingController();
  final TextEditingController _humedadComentarioController =
      TextEditingController();
  final TextEditingController _mesadaComentarioController =
      TextEditingController();
  final TextEditingController _iluminacionComentarioController =
      TextEditingController();
  final TextEditingController _limpiezaFosaComentarioController =
      TextEditingController();
  final TextEditingController _estadoDrenajeComentarioController =
      TextEditingController();
  final TextEditingController _carcasaComentarioController =
      TextEditingController();
  final TextEditingController _tecladoFisicoComentarioController =
      TextEditingController();
  final TextEditingController _displayFisicoComentarioController =
      TextEditingController();
  final TextEditingController _fuentePoderComentarioController =
      TextEditingController();
  final TextEditingController _bateriaOperacionalComentarioController =
      TextEditingController();
  final TextEditingController _bracketComentarioController =
      TextEditingController();
  final TextEditingController _tecladoOperativoComentarioController =
      TextEditingController();
  final TextEditingController _displayOperativoComentarioController =
      TextEditingController();
  final TextEditingController _contectorCeldaComentarioController =
      TextEditingController();
  final TextEditingController _bateriaMemoriaComentarioController =
      TextEditingController();
  final TextEditingController _limpiezaGeneralComentarioController =
      TextEditingController();
  final TextEditingController _golpesTerminalComentarioController =
      TextEditingController();
  final TextEditingController _nivelacionComentarioController =
      TextEditingController();
  final TextEditingController _limpiezaReceptorComentarioController =
      TextEditingController();
  final TextEditingController _golpesReceptorComentarioController =
      TextEditingController();
  final TextEditingController _encendidoComentarioController =
      TextEditingController();
  final TextEditingController _limitadorMovimientoComentarioController =
      TextEditingController();
  final TextEditingController _suspensionComentarioController =
      TextEditingController();
  final TextEditingController _limitadorCargaComentarioController =
      TextEditingController();
  final TextEditingController _celdaCargaComentarioController =
      TextEditingController();
  final TextEditingController _tapaCajaComentarioController =
      TextEditingController();
  final TextEditingController _humedadInternaComentarioController =
      TextEditingController();
  final TextEditingController _estadoPrensacablesComentarioController =
      TextEditingController();
  final TextEditingController _estadoBorneasComentarioController =
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

    // Forzar actualización de la UI después de la inicialización
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {});
      }
    });

    final List<String> camposEstadoGeneral = [
      'Vibración',
      'Polvo',
      'Temperatura',
      'Humedad',
      'Mesada',
      'Iluminación',
      'Limpieza de Fosa',
      'Estado de Drenaje',
      'Carcasa',
      'Teclado Fisico',
      'Display Fisico',
      'Fuente de poder',
      'Bateria operacional',
      'Bracket',
      'Teclado Operativo',
      'Display Operativo',
      'Contector de celda',
      'Bateria de memoria',
      'Limpieza general',
      'Golpes al terminal',
      'Nivelacion',
      'Limpieza receptor',
      'Golpes al receptor de carga',
      'Encendido',
      'Limitador de movimiento',
      'Suspensión',
      'Limitador de carga',
      'Celda de carga',
      'Tapa de caja sumadora',
      'Humedad Interna',
      'Estado de prensacables',
      'Estado de borneas'
    ];

    for (final campo in camposEstadoGeneral) {
      _fieldData[campo] = {
        'initial_value': '4 No aplica', // Estado inicial
        'solution_value': 'No aplica' // Estado final/solución
      };
    }

    _vibracionComentarioController.text = "Sin comentario";
    _polvoComentarioController.text = "Sin comentario";
    _teperaturaComentarioController.text = "Sin comentario";
    _humedadComentarioController.text = "Sin comentario";
    _mesadaComentarioController.text = "Sin comentario";
    _iluminacionComentarioController.text = "Sin comentario";
    _limpiezaFosaComentarioController.text = "Sin comentario";
    _estadoDrenajeComentarioController.text = "Sin comentario";
    _carcasaComentarioController.text = "Sin comentario";
    _tecladoFisicoComentarioController.text = "Sin comentario";
    _displayFisicoComentarioController.text = "Sin comentario";
    _fuentePoderComentarioController.text = "Sin comentario";
    _bateriaOperacionalComentarioController.text = "Sin comentario";
    _bracketComentarioController.text = "Sin comentario";
    _tecladoOperativoComentarioController.text = "Sin comentario";
    _displayOperativoComentarioController.text = "Sin comentario";
    _contectorCeldaComentarioController.text = "Sin comentario";
    _bateriaMemoriaComentarioController.text = "Sin comentario";
    _limpiezaGeneralComentarioController.text = "Sin comentario";
    _golpesTerminalComentarioController.text = "Sin comentario";
    _nivelacionComentarioController.text = "Sin comentario";
    _limpiezaReceptorComentarioController.text = "Sin comentario";
    _golpesReceptorComentarioController.text = "Sin comentario";
    _encendidoComentarioController.text = "Sin comentario";
    _limitadorMovimientoComentarioController.text = "Sin comentario";
    _suspensionComentarioController.text = "Sin comentario";
    _limitadorCargaComentarioController.text = "Sin comentario";
    _celdaCargaComentarioController.text = "Sin comentario";
    _tapaCajaComentarioController.text = "Sin comentario";
    _humedadInternaComentarioController.text = "Sin comentario";
    _estadoPrensacablesComentarioController.text = "Sin comentario";
    _estadoBorneasComentarioController.text = "Sin comentario";
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

  void _agregarComentario(BuildContext context) {
    if (_comentariosCount >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Máximo 10 comentarios permitidos'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _comentariosControllers.add(TextEditingController());
      _comentariosFocusNodes.add(FocusNode());
      _comentariosCount++;
    });
  }

  void _eliminarComentario(int index) {
    setState(() {
      _comentariosControllers[index].dispose();
      _comentariosFocusNodes[index].dispose();
      _comentariosControllers.removeAt(index);
      _comentariosFocusNodes.removeAt(index);
      _comentariosCount--;
    });
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
            '${widget.secaValue}_${widget.codMetrica}_diagnostico.zip';

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
      // ✅ Usar DatabaseHelperSop
      final dbHelper = DatabaseHelperMntCorrectivo();

      // Preparar comentarios
      final Map<String, dynamic> comentariosData = {};
      for (int i = 0; i < _comentariosControllers.length; i++) {
        comentariosData['comentario_${i + 1}'] =
            _comentariosControllers[i].text.isNotEmpty
                ? _comentariosControllers[i].text
                : null;
      }

      // ✅ Convertir todos los datos a un mapa para la base de datos
      final Map<String, dynamic> dbData = {
        // ✅ AGREGAR CAMPOS CLAVE
        'session_id': widget.sessionId,
        'cod_metrica': widget.codMetrica,
        'otst': widget.secaValue,
        'estado_servicio': 'Completo',

        // Campos existentes
        'tipo_servicio': 'mnt correctivo',
        'hora_inicio': _horaController.text,
        'hora_fin': _horaFinController.text,
        'reporte': _reporteFallaController.text,
        'evaluacion': _evaluacionController.text,

        // Datos de pruebas metrológicas
        ..._convertTestDataToDbFormat(_initialTestsData, 'inicial'),
        ..._convertTestDataToDbFormat(_finalTestsData, 'final'),

        // Comentarios
        ...comentariosData,

        // Retorno a Cero (si existe)
        'retorno_cero_inicial_valoracion':
            _fieldData['Retorno a cero']?['initial_value'] ?? '',
        'retorno_cero_inicial_carga':
            _fieldData['Retorno a cero']?['initial_load'] ?? '',
        'retorno_cero_inicial_unidad':
            _fieldData['Retorno a cero']?['initial_unit'] ?? '',

        // Entorno de instalación
        'vibracion_estado': _fieldData['Vibración']?['initial_value'] ?? '',
        'vibracion_solucion': _fieldData['Vibración']?['solution_value'] ?? '',
        'vibracion_comentario': _vibracionComentarioController.text,
        'vibracion_foto': _getFotosString('Vibración'),

        'polvo_estado': _fieldData['Polvo']?['initial_value'] ?? '',
        'polvo_solucion': _fieldData['Polvo']?['solution_value'] ?? '',
        'polvo_comentario': _polvoComentarioController.text,
        'polvo_foto': _getFotosString('Polvo'),

        'temperatura_estado': _fieldData['Temperatura']?['initial_value'] ?? '',
        'temperatura_solucion':
            _fieldData['Temperatura']?['solution_value'] ?? '',
        'temperatura_comentario': _teperaturaComentarioController.text,
        'temperatura_foto': _getFotosString('Temperatura'),

        'humedad_estado': _fieldData['Humedad']?['initial_value'] ?? '',
        'humedad_solucion': _fieldData['Humedad']?['solution_value'] ?? '',
        'humedad_comentario': _humedadComentarioController.text,
        'humedad_foto': _getFotosString('Humedad'),

        'mesada_estado': _fieldData['Mesada']?['initial_value'] ?? '',
        'mesada_solucion': _fieldData['Mesada']?['solution_value'] ?? '',
        'mesada_comentario': _mesadaComentarioController.text,
        'mesada_foto': _getFotosString('Mesada'),

        'iluminacion_estado': _fieldData['Iluminación']?['initial_value'] ?? '',
        'iluminacion_solucion':
            _fieldData['Iluminación']?['solution_value'] ?? '',
        'iluminacion_comentario': _iluminacionComentarioController.text,
        'iluminacion_foto': _getFotosString('Iluminación'),

        'limpieza_fosa_estado':
            _fieldData['Limpieza de Fosa']?['initial_value'] ?? '',
        'limpieza_fosa_solucion':
            _fieldData['Limpieza de Fosa']?['solution_value'] ?? '',
        'limpieza_fosa_comentario': _limpiezaFosaComentarioController.text,
        'limpieza_fosa_foto': _getFotosString('Limpieza de Fosa'),

        'estado_drenaje_estado':
            _fieldData['Estado de Drenaje']?['initial_value'] ?? '',
        'estado_drenaje_solucion':
            _fieldData['Estado de Drenaje']?['solution_value'] ?? '',
        'estado_drenaje_comentario': _estadoDrenajeComentarioController.text,
        'estado_drenaje_foto': _getFotosString('Estado de Drenaje'),

        // Terminal de pesaje
        'carcasa_estado': _fieldData['Carcasa']?['initial_value'] ?? '',
        'carcasa_solucion': _fieldData['Carcasa']?['solution_value'] ?? '',
        'carcasa_comentario': _carcasaComentarioController.text,
        'carcasa_foto': _getFotosString('Carcasa'),

        'teclado_fisico_estado':
            _fieldData['Teclado Fisico']?['initial_value'] ?? '',
        'teclado_fisico_solucion':
            _fieldData['Teclado Fisico']?['solution_value'] ?? '',
        'teclado_fisico_comentario': _tecladoFisicoComentarioController.text,
        'teclado_fisico_foto': _getFotosString('Teclado Fisico'),

        'display_fisico_estado':
            _fieldData['Display Fisico']?['initial_value'] ?? '',
        'display_fisico_solucion':
            _fieldData['Display Fisico']?['solution_value'] ?? '',
        'display_fisico_comentario': _displayFisicoComentarioController.text,
        'display_fisico_foto': _getFotosString('Display Fisico'),

        'fuente_poder_estado':
            _fieldData['Fuente de poder']?['initial_value'] ?? '',
        'fuente_poder_solucion':
            _fieldData['Fuente de poder']?['solution_value'] ?? '',
        'fuente_poder_comentario': _fuentePoderComentarioController.text,
        'fuente_poder_foto': _getFotosString('Fuente de poder'),

        'bateria_operacional_estado':
            _fieldData['Bateria operacional']?['initial_value'] ?? '',
        'bateria_operacional_solucion':
            _fieldData['Bateria operacional']?['solution_value'] ?? '',
        'bateria_operacional_comentario':
            _bateriaOperacionalComentarioController.text,
        'bateria_operacional_foto': _getFotosString('Bateria operacional'),

        'bracket_estado': _fieldData['Bracket']?['initial_value'] ?? '',
        'bracket_solucion': _fieldData['Bracket']?['solution_value'] ?? '',
        'bracket_comentario': _bracketComentarioController.text,
        'bracket_foto': _getFotosString('Bracket'),

        'teclado_operativo_estado':
            _fieldData['Teclado Operativo']?['initial_value'] ?? '',
        'teclado_operativo_solucion':
            _fieldData['Teclado Operativo']?['solution_value'] ?? '',
        'teclado_operativo_comentario':
            _tecladoOperativoComentarioController.text,
        'teclado_operativo_foto': _getFotosString('Teclado Operativo'),

        'display_operativo_estado':
            _fieldData['Display Operativo']?['initial_value'] ?? '',
        'display_operativo_solucion':
            _fieldData['Display Operativo']?['solution_value'] ?? '',
        'display_operativo_comentario':
            _displayOperativoComentarioController.text,
        'display_operativo_foto': _getFotosString('Display Operativo'),

        'conector_celda_estado':
            _fieldData['Contector de celda']?['initial_value'] ?? '',
        'conector_celda_solucion':
            _fieldData['Contector de celda']?['solution_value'] ?? '',
        'conector_celda_comentario': _contectorCeldaComentarioController.text,
        'conector_celda_foto': _getFotosString('Contector de celda'),

        'bateria_memoria_estado':
            _fieldData['Bateria de memoria']?['initial_value'] ?? '',
        'bateria_memoria_solucion':
            _fieldData['Bateria de memoria']?['solution_value'] ?? '',
        'bateria_memoria_comentario': _bateriaMemoriaComentarioController.text,
        'bateria_memoria_foto': _getFotosString('Bateria de memoria'),

        // Estado general de la balanza
        'limpieza_general_estado':
            _fieldData['Limpieza general']?['initial_value'] ?? '',
        'limpieza_general_solucion':
            _fieldData['Limpieza general']?['solution_value'] ?? '',
        'limpieza_general_comentario':
            _limpiezaGeneralComentarioController.text,
        'limpieza_general_foto': _getFotosString('Limpieza general'),

        'golpes_terminal_estado':
            _fieldData['Golpes al terminal']?['initial_value'] ?? '',
        'golpes_terminal_solucion':
            _fieldData['Golpes al terminal']?['solution_value'] ?? '',
        'golpes_terminal_comentario': _golpesTerminalComentarioController.text,
        'golpes_terminal_foto': _getFotosString('Golpes al terminal'),

        'nivelacion_estado': _fieldData['Nivelacion']?['initial_value'] ?? '',
        'nivelacion_solucion':
            _fieldData['Nivelacion']?['solution_value'] ?? '',
        'nivelacion_comentario': _nivelacionComentarioController.text,
        'nivelacion_foto': _getFotosString('Nivelacion'),

        'limpieza_receptor_estado':
            _fieldData['Limpieza receptor']?['initial_value'] ?? '',
        'limpieza_receptor_solucion':
            _fieldData['Limpieza receptor']?['solution_value'] ?? '',
        'limpieza_receptor_comentario':
            _limpiezaReceptorComentarioController.text,
        'limpieza_receptor_foto': _getFotosString('Limpieza receptor'),

        'golpes_receptor_estado':
            _fieldData['Golpes al receptor de carga']?['initial_value'] ?? '',
        'golpes_receptor_solucion':
            _fieldData['Golpes al receptor de carga']?['solution_value'] ?? '',
        'golpes_receptor_comentario': _golpesReceptorComentarioController.text,
        'golpes_receptor_foto': _getFotosString('Golpes al receptor de carga'),

        'encendido_estado': _fieldData['Encendido']?['initial_value'] ?? '',
        'encendido_solucion': _fieldData['Encendido']?['solution_value'] ?? '',
        'encendido_comentario': _encendidoComentarioController.text,
        'encendido_foto': _getFotosString('Encendido'),

        // Balanza/Plataforma
        'limitador_movimiento_estado':
            _fieldData['Limitador de movimiento']?['initial_value'] ?? '',
        'limitador_movimiento_solucion':
            _fieldData['Limitador de movimiento']?['solution_value'] ?? '',
        'limitador_movimiento_comentario':
            _limitadorMovimientoComentarioController.text,
        'limitador_movimiento_foto': _getFotosString('Limitador de movimiento'),

        'suspension_estado': _fieldData['Suspensión']?['initial_value'] ?? '',
        'suspension_solucion':
            _fieldData['Suspensión']?['solution_value'] ?? '',
        'suspension_comentario': _suspensionComentarioController.text,
        'suspension_foto': _getFotosString('Suspensión'),

        'limitador_carga_estado':
            _fieldData['Limitador de carga']?['initial_value'] ?? '',
        'limitador_carga_solucion':
            _fieldData['Limitador de carga']?['solution_value'] ?? '',
        'limitador_carga_comentario': _limitadorCargaComentarioController.text,
        'limitador_carga_foto': _getFotosString('Limitador de carga'),

        'celda_carga_estado':
            _fieldData['Celda de carga']?['initial_value'] ?? '',
        'celda_carga_solucion':
            _fieldData['Celda de carga']?['solution_value'] ?? '',
        'celda_carga_comentario': _celdaCargaComentarioController.text,
        'celda_carga_foto': _getFotosString('Celda de carga'),

        // Caja sumadora
        'tapa_caja_estado':
            _fieldData['Tapa de caja sumadora']?['initial_value'] ?? '',
        'tapa_caja_solucion':
            _fieldData['Tapa de caja sumadora']?['solution_value'] ?? '',
        'tapa_caja_comentario': _tapaCajaComentarioController.text,
        'tapa_caja_foto': _getFotosString('Tapa de caja sumadora'),

        'humedad_interna_estado':
            _fieldData['Humedad Interna']?['initial_value'] ?? '',
        'humedad_interna_solucion':
            _fieldData['Humedad Interna']?['solution_value'] ?? '',
        'humedad_interna_comentario': _humedadInternaComentarioController.text,
        'humedad_interna_foto': _getFotosString('Humedad Interna'),

        'estado_prensacables_estado':
            _fieldData['Estado de prensacables']?['initial_value'] ?? '',
        'estado_prensacables_solucion':
            _fieldData['Estado de prensacables']?['solution_value'] ?? '',
        'estado_prensacables_comentario':
            _estadoPrensacablesComentarioController.text,
        'estado_prensacables_foto': _getFotosString('Estado de prensacables'),

        'estado_borneas_estado':
            _fieldData['Estado de borneas']?['initial_value'] ?? '',
        'estado_borneas_solucion':
            _fieldData['Estado de borneas']?['solution_value'] ?? '',
        'estado_borneas_comentario': _estadoBorneasComentarioController.text,
        'estado_borneas_foto': _getFotosString('Estado de borneas'),
      };

      // ✅ USAR UPSERT (actualiza si existe, inserta si no)
      await dbHelper.upsertRegistroRelevamiento(dbData);

      _showSnackBar(
        context,
        'Datos guardados exitosamente',
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );

      setState(() {
        _isDataSaved.value = true;
      });
    } catch (e) {
      _showSnackBar(
        context,
        'Error al guardar: ${e.toString()}',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      debugPrint('Error al guardar: $e');
      _isDataSaved.value = false;
    }
  }

  String _getFotosString(String label) {
    return _fieldPhotos[label]?.map((f) => basename(f.path)).join(',') ?? '';
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

  void _showConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text(
            '¿QUÉ ACCIÓN DESEAS REALIZAR?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
          content: const Text('Selecciona la opción que corresponda:'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            const SizedBox(height: 8.0),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FinServicioMntcorrectivoScreen(
                      nReca: widget.nReca,
                      secaValue: widget.secaValue,
                      sessionId: widget.sessionId,
                      codMetrica: widget.codMetrica,
                      userName: widget.userName,
                      clienteId: widget.clienteId,
                      plantaCodigo: widget.plantaCodigo,
                      tableName: 'mnt_correctivo',
                    ),
                  ),
                );
              },
              child: const Text('FINALIZAR MNT CORRECTIVO'),
            ),
          ],
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
                'CÓDIGO MET: ${widget.codMetrica}',
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
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Text(
                'MANTENIMIENTO CORRECTIVO',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20.0),
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
              const SizedBox(height: 20.0),
              TextFormField(
                controller: _reporteFallaController,
                decoration: InputDecoration(
                  labelText: 'Reporte de falla:',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  alignLabelWithHint: true,
                ),
                maxLength: 800,
                maxLines: 8,
                minLines: 4,
              ),
              const SizedBox(height: 20.0),
              TextFormField(
                controller: _evaluacionController,
                decoration: InputDecoration(
                  labelText: 'Evaluación y análisis técnico de fallas:',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  alignLabelWithHint: true,
                ),
                maxLength: 800,
                maxLines: 8,
                minLines: 4,
              ),
              const SizedBox(height: 8.0),
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
                'COMENTARIOS, OBSERVACIONES Y RECOMENDACIONES',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFf5b041),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              // Botón para agregar comentarios
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: () => _agregarComentario(context),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text(
                    'Agregar',
                    style: TextStyle(fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFeCA400),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 20.0),

              // Lista de comentarios
              Column(
                children:
                    List.generate(_comentariosControllers.length, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _comentariosControllers[index],
                            focusNode: _comentariosFocusNodes[index],
                            decoration: InputDecoration(
                              labelText: 'Comentario ${index + 1}',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              suffixText:
                                  '${_comentariosControllers[index].text.length}/200',
                              suffixStyle: TextStyle(
                                color:
                                    _comentariosControllers[index].text.length >
                                            200
                                        ? Colors.red
                                        : Colors.grey,
                              ),
                            ),
                            maxLength: 200,
                            maxLines: 3,
                            buildCounter: (context,
                                    {required currentLength,
                                    required isFocused,
                                    maxLength}) =>
                                null,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _eliminarComentario(index),
                        ),
                      ],
                    ),
                  );
                }),
              ),

              if (_comentariosControllers.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'No hay comentarios agregados',
                    style: TextStyle(
                        color: Colors.grey, fontStyle: FontStyle.italic),
                  ),
                ),
              const Text(
                'ESTADO GENERAL DEL INSTRUMENTO',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF9DEAE5), // Color personalizado
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10.0),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'ENTORNO DE INSTALACIÓN:',
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
                  context, 'Vibración', _vibracionComentarioController),
              const SizedBox(height: 20.0),
              _buildDropdownFieldWithComment(
                  context, 'Polvo', _polvoComentarioController),
              const SizedBox(height: 20.0),
              _buildDropdownFieldWithComment(
                  context, 'Temperatura', _teperaturaComentarioController),
              const SizedBox(height: 20.0),
              _buildDropdownFieldWithComment(
                  context, 'Humedad', _humedadComentarioController),
              const SizedBox(height: 20.0),
              _buildDropdownFieldWithComment(
                  context, 'Mesada', _mesadaComentarioController),
              const SizedBox(height: 20.0),
              _buildDropdownFieldWithComment(
                  context, 'Iluminación', _iluminacionComentarioController),
              const SizedBox(height: 10.0),
              _buildDropdownFieldWithComment(context, 'Limpieza de Fosa',
                  _limpiezaFosaComentarioController),
              const SizedBox(height: 10.0),
              _buildDropdownFieldWithComment(context, 'Estado de Drenaje',
                  _estadoDrenajeComentarioController),
              const SizedBox(height: 10.0),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'TERMINAL DE PESAJE:',
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
                  context, 'Carcasa', _carcasaComentarioController),
              const SizedBox(height: 20.0),
              _buildDropdownFieldWithComment(context, 'Teclado Fisico',
                  _tecladoFisicoComentarioController),
              const SizedBox(height: 20.0),
              _buildDropdownFieldWithComment(context, 'Display Fisico',
                  _displayFisicoComentarioController),
              const SizedBox(height: 20.0),
              _buildDropdownFieldWithComment(
                  context, 'Fuente de poder', _fuentePoderComentarioController),
              const SizedBox(height: 20.0),
              _buildDropdownFieldWithComment(context, 'Bateria operacional',
                  _bateriaOperacionalComentarioController),
              const SizedBox(height: 20.0),
              _buildDropdownFieldWithComment(
                  context, 'Bracket', _bracketComentarioController),
              const SizedBox(height: 20.0),
              _buildDropdownFieldWithComment(context, 'Teclado Operativo',
                  _tecladoOperativoComentarioController),
              const SizedBox(height: 20.0),
              _buildDropdownFieldWithComment(context, 'Display Operativo',
                  _displayOperativoComentarioController),
              const SizedBox(height: 20.0),
              _buildDropdownFieldWithComment(context, 'Contector de celda',
                  _contectorCeldaComentarioController),
              const SizedBox(height: 20.0),
              _buildDropdownFieldWithComment(context, 'Bateria de memoria',
                  _bateriaMemoriaComentarioController),
              const SizedBox(height: 20.0),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'ESTADO GENERAL DE LA BALANZA:',
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
              _buildDropdownFieldWithComment(context, 'Limpieza general',
                  _limpiezaGeneralComentarioController),
              const SizedBox(height: 20.0),
              _buildDropdownFieldWithComment(context, 'Golpes al terminal',
                  _golpesTerminalComentarioController),
              const SizedBox(height: 20.0),
              _buildDropdownFieldWithComment(
                  context, 'Nivelacion', _nivelacionComentarioController),
              const SizedBox(height: 20.0),
              _buildDropdownFieldWithComment(context, 'Limpieza receptor',
                  _limpiezaReceptorComentarioController),
              const SizedBox(height: 20.0),
              _buildDropdownFieldWithComment(
                  context,
                  'Golpes al receptor de carga',
                  _golpesReceptorComentarioController),
              const SizedBox(height: 20.0),
              _buildDropdownFieldWithComment(
                  context, 'Encendido', _encendidoComentarioController),
              const SizedBox(height: 20.0),
              const Text(
                'BALANZA | PLATAFORMA:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF16a085), // Color personalizado
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20.0),
              _buildDropdownFieldWithComment(context, 'Limitador de movimiento',
                  _limitadorMovimientoComentarioController),
              const SizedBox(height: 20.0),
              _buildDropdownFieldWithComment(
                  context, 'Suspensión', _suspensionComentarioController),
              const SizedBox(height: 20.0),
              _buildDropdownFieldWithComment(context, 'Limitador de carga',
                  _limitadorCargaComentarioController),
              const SizedBox(height: 20.0),
              _buildDropdownFieldWithComment(
                  context, 'Celda de carga', _celdaCargaComentarioController),
              const SizedBox(height: 20.0),
              const Text(
                'CAJA SUMADORA:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFa3e4d7), // Color personalizado
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20.0),
              _buildDropdownFieldWithComment(context, 'Tapa de caja sumadora',
                  _tapaCajaComentarioController),
              const SizedBox(height: 20.0),
              _buildDropdownFieldWithComment(context, 'Humedad Interna',
                  _humedadInternaComentarioController),
              const SizedBox(height: 20.0),
              _buildDropdownFieldWithComment(context, 'Estado de prensacables',
                  _estadoPrensacablesComentarioController),
              const SizedBox(height: 20.0),
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
                              ? () => _showConfirmationDialog(context)
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
      children: [
        // Dropdown para estado inicial
        Row(
          children: [
            Expanded(
              flex: 5,
              child: DropdownButtonFormField<String>(
                initialValue: currentInitialValue,
                decoration: _buildInputDecoration('Estado inicial $label'),
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
                initialValue: currentSolutionValue,
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
            const Expanded(
                flex: 1, child: SizedBox()), // Espacio vacío para alinear
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
      ],
    );
  }

  @override
  void dispose() {
    for (var controller in _comentariosControllers) {
      controller.dispose();
    }
    for (var focusNode in _comentariosFocusNodes) {
      focusNode.dispose();
    }
    _horaController.dispose();
    _horaFinController.dispose();
    _isSaveButtonPressed.dispose();
    _isDataSaved.dispose();
    super.dispose();
  }
}
