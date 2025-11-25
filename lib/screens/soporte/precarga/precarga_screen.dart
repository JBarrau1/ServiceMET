// precarga_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:service_met/screens/calibracion/servicio_screen.dart';
import 'package:service_met/screens/soporte/modulos/mnt_prv_regular/mnt_prv_regular_stac/stac_mnt_prv_regular.dart'
    hide StepData;
import '../../../database/soporte_tecnico/database_helper_ajustes.dart';
import '../../../database/soporte_tecnico/database_helper_diagnostico.dart';
import '../../../database/soporte_tecnico/database_helper_instalacion.dart';
import '../../../database/soporte_tecnico/database_helper_mnt_correctivo.dart';
import '../../../database/soporte_tecnico/database_helper_mnt_prv_avanzado_stac.dart';
import '../../../database/soporte_tecnico/database_helper_mnt_prv_avanzado_stil.dart';
import '../../../database/soporte_tecnico/database_helper_mnt_prv_regular_stac.dart';
import '../../../database/soporte_tecnico/database_helper_mnt_prv_regular_stil.dart';
import '../../../database/soporte_tecnico/database_helper_relevamiento.dart';
import '../../../database/soporte_tecnico/database_helper_verificaciones.dart';
import '../modulos/ajuste_verificaciones/stac_ajuste_verificaciones.dart';
import '../modulos/diagnostico/stac_diagnostico.dart';
import '../modulos/instalacion/stac_instalacion.dart';
import '../modulos/mnt_correctivo/stac_mnt_correctivo.dart';
import '../modulos/mnt_prv_avanzado/mnt_prv_avanzado_stac/stac_mnt_prv_avanzado.dart'
    hide StepData;
import '../modulos/mnt_prv_avanzado/mnt_prv_avanzado_stil/stil_mnt_prv_avanzado.dart'
    hide StepData;
import '../modulos/mnt_prv_regular/mnt_prv_regular_stil/stil_mnt_prv_regular.dart'
    hide StepData;
import '../modulos/relevamiento_de_datos/relevamiento_de_datos.dart';
import '../modulos/verificaciones_internas/stac_verificaciones_internas.dart';
import 'precarga_controller.dart';
import 'widgets/step_indicator.dart';
import 'widgets/cliente_step.dart';
import 'widgets/planta_step.dart';
import 'widgets/seca_step.dart';
import 'widgets/balanza_step.dart';
import 'widgets/tipo_servicio_step.dart';

class PrecargaScreenSop extends StatefulWidget {
  final String tableName;
  final String clienteId; // <-- agregado
  final String plantaCodigo; // <-- agregado
  final String userName;
  final int initialStep;
  final String? sessionId;
  final String? secaValue;

  const PrecargaScreenSop({
    super.key,
    required this.tableName,
    required this.clienteId,
    required this.plantaCodigo,
    required this.userName,
    this.initialStep = 0,
    this.sessionId,
    this.secaValue,
  });

  @override
  _PrecargaScreenSopState createState() => _PrecargaScreenSopState();
}

class _PrecargaScreenSopState extends State<PrecargaScreenSop> {
  late PrecargaControllerSop controller;
  final TextEditingController _fechaController = TextEditingController();

  // Controllers para campos de entrada
  final TextEditingController _nRecaController = TextEditingController();
  final TextEditingController _stickerController = TextEditingController();

  // Controllers de balanza - PERSISTENTES para evitar memory leaks
  late final Map<String, TextEditingController> _balanzaControllers;

  @override
  void initState() {
    super.initState();
    controller = PrecargaControllerSop();
    _fechaController.text = controller.formatDate(DateTime.now());

    // Inicializar controllers de balanza una sola vez
    _balanzaControllers = {
      'cod_metrica': TextEditingController(),
      'categoria_balanza': TextEditingController(),
      'cod_int': TextEditingController(),
      'tipo_equipo': TextEditingController(),
      'marca': TextEditingController(),
      'modelo': TextEditingController(),
      'serie': TextEditingController(),
      'unidades': TextEditingController(),
      'num_celdas': TextEditingController(),
      'ubicacion': TextEditingController(),
      'cap_max1': TextEditingController(),
      'd1': TextEditingController(),
      'e1': TextEditingController(),
      'dec1': TextEditingController(),
      'cap_max2': TextEditingController(),
      'd2': TextEditingController(),
      'e2': TextEditingController(),
      'dec2': TextEditingController(),
      'cap_max3': TextEditingController(),
      'd3': TextEditingController(),
      'e3': TextEditingController(),
      'dec3': TextEditingController(),
    };

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  Future<void> _initializeData() async {
    try {
      await controller.fetchClientes();

      if (widget.sessionId != null && widget.secaValue != null) {
        await _loadExistingSession();
      } else {
        controller.setCurrentStep(-1);
      }

      controller.updateStepErrors();
    } catch (e) {
      _showSnackBar('Error al inicializar: $e', isError: true);
    }
  }

  Future<void> _loadExistingSession() async {
    try {
      //OBTENER EL DATABASE HELPER CORRECTO SEGÚN widget.tableName
      dynamic dbHelper;

      switch (widget.tableName) {
        case 'relevamiento_de_datos':
          dbHelper = DatabaseHelperRelevamiento();
          break;
        case 'ajustes_metrologicos':
          dbHelper = DatabaseHelperAjustes();
          break;
        case 'diagnostico':
          dbHelper = DatabaseHelperDiagnostico();
          break;
        case 'mnt_prv_regular_stac':
          dbHelper = DatabaseHelperMntPrvRegularStac();
          break;
        case 'mnt_prv_regular_stil':
          dbHelper = DatabaseHelperMntPrvRegularStil();
          break;
        case 'mnt_prv_avanzado_stac':
          dbHelper = DatabaseHelperMntPrvAvanzadoStac();
          break;
        case 'mnt_prv_avanzado_stil':
          dbHelper = DatabaseHelperMntPrvAvanzadoStil();
          break;
        case 'mnt_correctivo':
          dbHelper = DatabaseHelperMntCorrectivo();
          break;
        case 'instalacion':
          dbHelper = DatabaseHelperInstalacion();
          break;
        case 'verificaciones_internas':
          dbHelper = DatabaseHelperVerificaciones();
          break;
        default:
          throw Exception('Tipo de servicio no válido: ${widget.tableName}');
      }

      final db = await dbHelper.database;

      //CONSULTAR EN LA TABLA INDEPENDIENTE
      final List<Map<String, dynamic>> rows = await db.query(
        dbHelper.tableName, // Usar el nombre de tabla del helper
        where: 'otst = ? AND session_id = ?',
        whereArgs: [widget.secaValue, widget.sessionId],
        orderBy: 'session_id DESC',
        limit: 1,
      );

      if (rows.isEmpty) {
        debugPrint('No se encontró registro con OTST: ${widget.secaValue}');
        return;
      }

      final registroActual = rows.first;

      // Seleccionar tipo de servicio en el controller
      controller.selectTipoServicio(widget.tableName, null);

      controller.setInternalValues(
        sessionId: widget.sessionId!,
        seca: widget.secaValue!,
        clienteName: registroActual['cliente']?.toString(),
        clienteRazonSocial: registroActual['razon_social']?.toString(),
        plantaDir: registroActual['dir_planta']?.toString(),
        plantaDep: registroActual['dep_planta']?.toString(),
        plantaCodigo: registroActual['cod_planta']?.toString(),
        plantaNombre: registroActual['planta']?.toString(),
      );

      final plantaCodigo = registroActual['cod_planta']?.toString();
      if (plantaCodigo != null && plantaCodigo.isNotEmpty) {
        await controller.fetchBalanzas(plantaCodigo);
        debugPrint('Balanzas cargadas: ${controller.balanzas.length}');
      }

      await Future.delayed(const Duration(milliseconds: 200));

      if (widget.initialStep >= -1 && widget.initialStep <= 4) {
        controller.setCurrentStep(widget.initialStep);
      } else {
        controller.setCurrentStep(4);
      }
    } catch (e, st) {
      debugPrint('Error al cargar sesión existente: $e');
      debugPrint(st.toString());
    }
  }

  @override
  void dispose() {
    _fechaController.dispose();
    _nRecaController.dispose();
    _stickerController.dispose();

    // Disponer todos los controllers de balanza
    for (var controller in _balanzaControllers.values) {
      controller.dispose();
    }

    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<PrecargaControllerSop>(
      create: (_) => controller,
      child: Scaffold(
        appBar: _buildAppBar(),
        body: Consumer<PrecargaControllerSop>(
          builder: (context, controller, child) {
            // Mostrar error de validación si existe
            final stepError = controller.stepErrors[controller.currentStep];

            return Column(
              children: [
                StepIndicator(
                  currentStep: controller.currentStep + 1,
                  steps: const [
                    StepData(
                      title: 'Servicio',
                      subtitle: 'Tipo de servicio',
                      icon: Icons.build_circle_outlined,
                    ),
                    StepData(
                      title: 'Cliente',
                      subtitle: 'Selección',
                      icon: Icons.business,
                    ),
                    StepData(
                      title: 'Planta',
                      subtitle: 'Ubicación',
                      icon: Icons.factory,
                    ),
                    StepData(
                      title: 'OTST',
                      subtitle: 'Orden de trabajo',
                      icon: Icons.confirmation_number_outlined,
                    ),
                    StepData(
                      title: 'Balanza',
                      subtitle: 'Datos del equipo',
                      icon: Icons.scale_outlined,
                    ),
                    StepData(
                      title: 'Confirmar',
                      subtitle: 'Resumen final',
                      icon: Icons.check_circle_outline,
                    ),
                  ],
                ),

                // Mostrar alerta de error si hay validación fallida
                if (stepError != null)
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red[300]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline,
                            color: Colors.red[700], size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            stepError,
                            style: GoogleFonts.inter(
                              color: Colors.red[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: _buildCurrentStepContent(controller),
                  ),
                ),
                _buildBottomButtons(controller),
              ],
            );
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return PreferredSize(
      preferredSize: const Size.fromHeight(70),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
          child: AppBar(
            toolbarHeight: 70,
            title: Text(
              'SOPORTE TÉCNICO',
              style: GoogleFonts.poppins(
                color: isDarkMode ? Colors.white : Colors.black,
                fontWeight: FontWeight.w700,
                fontSize: 16.0,
              ),
            ),
            backgroundColor: isDarkMode
                ? Colors.black.withOpacity(0.4)
                : Colors.white.withOpacity(0.7),
            elevation: 0,
            centerTitle: true,
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStepContent(PrecargaControllerSop controller) {
    switch (controller.currentStep) {
      case -1: // NUEVO: Tipo de Servicio
        return const TipoServicioStep();
      case 0:
        return const ClienteStep();
      case 1:
        return const PlantaStep();
      case 2:
        return SecaStep(
          userName: widget.userName,
          fechaServicio: _fechaController.text,
        );
      case 3:
        return BalanzaStep(
          balanzaControllers: _balanzaControllers,
          nRecaController: _nRecaController,
          stickerController: _stickerController,
          secaValue: controller.generatedSeca ?? '',
          sessionId: controller.generatedSessionId ?? '',
          selectedPlantaCodigo: controller.selectedPlantaCodigo ?? '',
          selectedCliente: controller.selectedClienteId ?? '',
          loadFromSharedPreferences: false,
        );
      case 4: // MODIFICAR ESTE CASE
        // En soporte técnico no hay selección de equipos
        // Mostrar pantalla de confirmación final
        return _buildFinalConfirmationStep(controller);
      default:
        return const SizedBox();
    }
  }

  Widget _buildFinalConfirmationStep(PrecargaControllerSop controller) {
    return Column(
      children: [
        Text(
          'CONFIRMACIÓN FINAL',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : const Color(0xFF2C3E50),
          ),
        ).animate().fadeIn(duration: 600.ms),
        const SizedBox(height: 30),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue[50]!, Colors.blue[100]!],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700]),
                  const SizedBox(width: 12),
                  Text(
                    'Resumen del Servicio',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildSummaryRow('Tipo de Servicio',
                  controller.selectedTipoServicioLabel ?? 'N/A'),
              _buildSummaryRow('OTST', controller.generatedSeca ?? 'N/A'),
              _buildSummaryRow(
                  'Cliente', controller.selectedClienteName ?? 'N/A'),
              _buildSummaryRow(
                  'Planta', controller.selectedPlantaNombre ?? 'N/A'),
              _buildSummaryRow('Código Métrica',
                  _balanzaControllers['cod_metrica']?.text ?? 'N/A'),
              _buildSummaryRow('Técnico', widget.userName),
              _buildSummaryRow('Fecha', _fechaController.text),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[300]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Presione "Finalizar y Continuar" para guardar y proceder al servicio.',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.green[800],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.3),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons(PrecargaControllerSop controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (controller.currentStep > -1)
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => controller.previousStep(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Anterior'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[600],
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          if (controller.currentStep > -1) const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _getNextButtonAction(controller),
              icon: Icon(_getNextButtonIcon(controller)),
              label: Text(_getNextButtonText(controller)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _getNextButtonColor(controller),
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  VoidCallback? _getNextButtonAction(PrecargaControllerSop controller) {
    switch (controller.currentStep) {
      case -1: // Tipo de Servicio
        return controller.canProceedToStep(-1)
            ? () => controller.nextStep()
            : null;

      case 0: // Cliente
        return controller.canProceedToStep(0)
            ? () => controller.nextStep()
            : null;

      case 1: // Planta
        return controller.canProceedToStep(1)
            ? () => controller.nextStep()
            : null;

      case 2: // SECA
        return controller.secaConfirmed
            ? () => controller.nextStep()
            : () => _confirmSeca();

      case 3: // Balanza
        return controller.canProceedToStep(3)
            ? () => controller.nextStep()
            : null;

      case 4: // Confirmación Final
        return controller.canProceedToStep(4) ? () => _saveAndNavigate() : null;

      default:
        return null;
    }
  }

  IconData _getNextButtonIcon(PrecargaControllerSop controller) {
    switch (controller.currentStep) {
      case 2:
        return controller.secaConfirmed ? Icons.arrow_forward : Icons.check;
      case 4:
        return Icons.save;
      default:
        return Icons.arrow_forward;
    }
  }

  String _getNextButtonText(PrecargaControllerSop controller) {
    switch (controller.currentStep) {
      case 2:
        return controller.secaConfirmed ? 'Siguiente' : 'Confirmar OTST';
      case 4:
        return 'Finalizar y Continuar';
      default:
        return 'Siguiente';
    }
  }

  Color _getNextButtonColor(PrecargaControllerSop controller) {
    switch (controller.currentStep) {
      case 2:
        return controller.secaConfirmed
            ? const Color(0xFF667EEA)
            : Colors.green;
      case 4:
        return Colors.green;
      default:
        return const Color(0xFF667EEA);
    }
  }

  Future<void> _confirmSeca() async {
    try {
      await controller.confirmSeca(widget.userName, _fechaController.text);
      _showSnackBar('OTST confirmado: ${controller.generatedSeca}');
    } catch (e) {
      if (e is SecaExistsException) {
        _showExistingSecaDialog(e.fechaUltimoServicio);
      } else {
        _showSnackBar('Error al confirmar OTST: $e', isError: true);
      }
    }
  }

  void _showExistingSecaDialog(String fechaServicio) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(
            'OTST Ya Registrado',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  'La OTST "${controller.generatedSeca}" ya tiene registros anteriores.'),
              const SizedBox(height: 10),
              Text('Fecha del último servicio: $fechaServicio'),
              const SizedBox(height: 10),
              const Text('¿Desea crear una NUEVA sesión para este OTST?'),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(FontAwesomeIcons.triangleExclamation,
                        color: Colors.orange, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Los datos anteriores se mantendrán intactos.',
                        style: GoogleFonts.inter(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF667EEA),
              ),
              onPressed: () async {
                try {
                  await controller.createNewSecaSession(
                      widget.userName, _fechaController.text);
                  Navigator.of(dialogContext).pop();
                  _showSnackBar(
                      'Nueva sesión creada: ${controller.generatedSessionId}');
                } catch (e) {
                  Navigator.of(dialogContext).pop();
                  _showSnackBar('Error al crear sesión: $e', isError: true);
                }
              },
              child: const Text('Crear Nueva Sesión'),
            )
          ],
        );
      },
    );
  }

  Future<void> _saveAndNavigate() async {
    try {
      // Preparar datos de la balanza
      final balanzaData = <String, String>{};
      _balanzaControllers.forEach((key, controller) {
        balanzaData[key] = controller.text.trim();
      });

      // Guardar datos en BD
      await controller.saveAllData(
        userName: widget.userName,
        fechaServicio: _fechaController.text,
        nReca: _nRecaController.text.trim(),
        sticker: _stickerController.text.trim(),
        balanzaData: balanzaData,
      );

      _showSnackBar('Datos guardados correctamente');

      // Mostrar confirmación de guardado de fotos
      if (controller.fotosTomadas && controller.baseFotoPath != null) {
        final photoCount =
            controller.balanzaPhotos['identificacion']?.length ?? 0;

        await _showPhotosSavedDialog(
          photoCount: photoCount,
          directoryPath: controller.baseFotoPath!,
        );
      }

      // Crear ZIP de fotos
      String? zipPath;
      try {
        zipPath = await controller.createPhotosZip();
        if (zipPath != null) {
          _showSnackBar('ZIP creado: $zipPath', isError: false);
        }
      } catch (e) {
        debugPrint('Error al crear ZIP: $e');
      }

      // Navegar a la pantalla correspondiente según el tipo de servicio
      if (mounted) {
        final destinationScreen = _getDestinationScreen(controller);

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => destinationScreen,
          ),
        );
      }
    } catch (e) {
      _showSnackBar('Error al guardar: $e', isError: true);
    }
  }

  Widget _getDestinationScreen(PrecargaControllerSop controller) {
    final codMetrica = _balanzaControllers['cod_metrica']!.text;
    final nReca = _nRecaController.text;
    final secaValue = controller.generatedSeca!;
    final sessionId = controller.generatedSessionId!;

    switch (controller.selectedTipoServicio) {
      case 'relevamiento_de_datos':
        return RelevamientoDeDatosScreen(
          userName: widget.userName,
          clienteId: controller.selectedClienteId ?? '',
          plantaCodigo: controller.selectedPlantaCodigo ?? '',
          codMetrica: codMetrica,
          nReca: nReca,
          secaValue: secaValue,
          sessionId: sessionId,
        );

      case 'ajustes_metrologicos':
        return StacAjusteVerificacionesScreen(
          userName: widget.userName,
          clienteId: controller.selectedClienteId ?? '',
          plantaCodigo: controller.selectedPlantaCodigo ?? '',
          codMetrica: codMetrica,
          nReca: nReca,
          secaValue: secaValue,
          sessionId: sessionId,
        );

      case 'diagnostico':
        return StacDiagnosticoScreen(
          userName: widget.userName,
          clienteId: controller.selectedClienteId ?? '',
          plantaCodigo: controller.selectedPlantaCodigo ?? '',
          codMetrica: codMetrica,
          nReca: nReca,
          secaValue: secaValue,
          sessionId: sessionId,
        );

      case 'instalacion':
        return StacInstalacionScreen(
          userName: widget.userName,
          clienteId: controller.selectedClienteId ?? '',
          plantaCodigo: controller.selectedPlantaCodigo ?? '',
          codMetrica: codMetrica,
          nReca: nReca,
          secaValue: secaValue,
          sessionId: sessionId,
        );

      case 'mnt_correctivo':
        return StacMntCorrectivoScreen(
          userName: widget.userName,
          clienteId: controller.selectedClienteId ?? '',
          plantaCodigo: controller.selectedPlantaCodigo ?? '',
          codMetrica: codMetrica,
          nReca: nReca,
          secaValue: secaValue,
          sessionId: sessionId,
        );

      case 'mnt_prv_avanzado_stac':
        return StacMntPrvAvanzadoStacScreen(
          userName: widget.userName,
          clienteId: controller.selectedClienteId ?? '',
          plantaCodigo: controller.selectedPlantaCodigo ?? '',
          codMetrica: codMetrica,
          nReca: nReca,
          secaValue: secaValue,
          sessionId: sessionId,
        );

      case 'mnt_prv_avanzado_stil':
        return MntPrvAvanzadoStilScreen(
          userName: widget.userName,
          clienteId: controller.selectedClienteId ?? '',
          plantaCodigo: controller.selectedPlantaCodigo ?? '',
          codMetrica: codMetrica,
          nReca: nReca,
          secaValue: secaValue,
          sessionId: sessionId,
        );

      case 'mnt_prv_regular_stac':
        return StacMntPrvRegularStacScreen(
          userName: widget.userName,
          clienteId: controller.selectedClienteId ?? '',
          plantaCodigo: controller.selectedPlantaCodigo ?? '',
          codMetrica: codMetrica,
          nReca: nReca,
          secaValue: secaValue,
          sessionId: sessionId,
        );

      case 'mnt_prv_regular_stil':
        return StilMntPrvRegularStacScreen(
          userName: widget.userName,
          clienteId: controller.selectedClienteId ?? '',
          plantaCodigo: controller.selectedPlantaCodigo ?? '',
          codMetrica: codMetrica,
          nReca: nReca,
          secaValue: secaValue,
          sessionId: sessionId,
        );

      case 'verificaciones_internas':
        return StacVerificacionesInternasScreen(
          userName: widget.userName,
          clienteId: controller.selectedClienteId ?? '',
          plantaCodigo: controller.selectedPlantaCodigo ?? '',
          codMetrica: codMetrica,
          nReca: nReca,
          secaValue: secaValue,
          sessionId: sessionId,
        );

      default:
        // Fallback a ServicioScreen
        return ServicioScreen(
          codMetrica: codMetrica,
          nReca: nReca,
          secaValue: secaValue,
          sessionId: sessionId,
        );
    }
  }

  Future<void> _showPhotosSavedDialog({
    required int photoCount,
    required String directoryPath,
  }) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          icon: Icon(
            Icons.check_circle_outline,
            color: Colors.green[600],
            size: 64,
          ),
          title: Text(
            '¡Fotos Guardadas!',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: Colors.green[700],
            ),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.photo_library, color: Colors.green[700]),
                        const SizedBox(width: 8),
                        Text(
                          '$photoCount foto${photoCount != 1 ? 's' : ''} guardada${photoCount != 1 ? 's' : ''}',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.folder_open,
                          color: Colors.green[600],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ubicación:',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green[700],
                                ),
                              ),
                              const SizedBox(height: 4),
                              SelectableText(
                                directoryPath,
                                style: GoogleFonts.robotoMono(
                                  fontSize: 11,
                                  color: Colors.green[800],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Las fotografías están disponibles en el directorio especificado.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton.icon(
              onPressed: () {
                // Copiar ruta al portapapeles
                Clipboard.setData(ClipboardData(text: directoryPath));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Ruta copiada al portapapeles'),
                    duration: Duration(seconds: 2),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              icon: const Icon(Icons.copy),
              label: const Text('Copiar Ruta'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
              ),
              child: const Text('Continuar'),
            ),
          ],
        );
      },
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
