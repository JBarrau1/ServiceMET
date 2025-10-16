// precarga_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:service_met/screens/calibracion/servicio_screen.dart';
import '../../../database/app_database.dart';
import 'precarga_controller.dart';
import 'widgets/step_indicator.dart';
import 'widgets/cliente_step.dart';
import 'widgets/planta_step.dart';
import 'widgets/seca_step.dart';
import 'widgets/balanza_step.dart';
import 'widgets/tipo_servicio_step.dart';


class PrecargaScreenSop extends StatefulWidget {
  final String userName;
  final int initialStep;
  final String? sessionId;
  final String? secaValue;

  const PrecargaScreenSop({
    super.key,
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
        // AGREGAR ESTA LÍNEA:
        controller.setCurrentStep(-1); // Iniciar en selección de tipo de servicio
      }

      controller.updateStepErrors();
    } catch (e) {
      _showSnackBar('Error al inicializar: $e', isError: true);
    }
  }

  Future<void> _loadExistingSession() async {
    try {
      final dbHelper = AppDatabase();
      final registro = await dbHelper.getRegistroBySeca(
        widget.secaValue!,
        widget.sessionId!,
      );

      if (registro != null) {
        controller.setInternalValues(
          sessionId: widget.sessionId!,
          seca: widget.secaValue!,
          clienteName: registro['cliente']?.toString(),
          clienteRazonSocial: registro['razon_social']?.toString(),
          plantaDir: registro['dir_planta']?.toString(),
          plantaDep: registro['dep_planta']?.toString(),
          plantaCodigo: registro['cod_planta']?.toString(),
        );

        await Future.delayed(const Duration(milliseconds: 200));

        if (widget.initialStep > 0 && widget.initialStep <= 4) {
          controller.setCurrentStep(widget.initialStep);
        }
      }
    } catch (e) {
      debugPrint('Error al cargar sesión existente: $e');
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
                const StepIndicator(),

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
                        Icon(Icons.error_outline, color: Colors.red[700], size: 24),
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

              _buildSummaryRow('Tipo de Servicio', controller.selectedTipoServicioLabel ?? 'N/A'),
              _buildSummaryRow('OTST', controller.generatedSeca ?? 'N/A'),
              _buildSummaryRow('Cliente', controller.selectedClienteName ?? 'N/A'),
              _buildSummaryRow('Planta', controller.selectedPlantaNombre ?? 'N/A'),
              _buildSummaryRow('Código Métrica', _balanzaControllers['cod_metrica']?.text ?? 'N/A'),
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
          // Botón Anterior
          if (controller.currentStep > -1) // CAMBIAR DE 0 A -1
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

          // Botón Siguiente/Finalizar
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
      case -1: // AGREGAR ESTE CASE COMPLETO
        return controller.canProceedToStep(-1)
            ? () => controller.nextStep()
            : null;

      case 0: // Cliente (resto del código sin cambios)
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

      case 4: // Equipos
        return controller.canProceedToStep(4)
            ? () => _saveAndNavigate()
            : null;

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
        return controller.secaConfirmed ? 'Siguiente' : 'Confirmar SECA';
      case 4:
        return 'Finalizar y Continuar';
      default:
        return 'Siguiente';
    }
  }

  Color _getNextButtonColor(PrecargaControllerSop controller) {
    switch (controller.currentStep) {
      case 2:
        return controller.secaConfirmed ? const Color(0xFF667EEA) : Colors.green;
      case 4:
        return Colors.green;
      default:
        return const Color(0xFF667EEA);
    }
  }

  Future<void> _confirmSeca() async {
    try {
      await controller.confirmSeca(widget.userName, _fechaController.text);
      _showSnackBar('SECA confirmado: ${controller.generatedSeca}');
    } catch (e) {
      if (e is SecaExistsException) {
        _showExistingSecaDialog(e.fechaUltimoServicio);
      } else {
        _showSnackBar('Error al confirmar SECA: $e', isError: true);
      }
    }
  }

  void _showExistingSecaDialog(String fechaServicio) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(
            'SECA Ya Registrado',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('El SECA "${controller.generatedSeca}" ya tiene registros anteriores.'),
              const SizedBox(height: 10),
              Text('Fecha del último servicio: $fechaServicio'),
              const SizedBox(height: 10),
              const Text('¿Desea crear una NUEVA sesión para este SECA?'),
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
                      widget.userName,
                      _fechaController.text
                  );
                  Navigator.of(dialogContext).pop();
                  _showSnackBar('Nueva sesión creada: ${controller.generatedSessionId}');
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

      // NUEVO: Mostrar confirmación de guardado de fotos
      if (controller.fotosTomadas && controller.baseFotoPath != null) {
        final photoCount = controller.balanzaPhotos['identificacion']?.length ?? 0;

        // Diálogo de confirmación con detalles
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

      // Navegar al siguiente módulo
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ServicioScreen(
              codMetrica: _balanzaControllers['cod_metrica']!.text,
              nReca: _nRecaController.text,
              secaValue: controller.generatedSeca!,
              sessionId: controller.generatedSessionId!,
            ),
          ),
        );
      }
    } catch (e) {
      _showSnackBar('Error al guardar: $e', isError: true);
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
                        Icon(Icons.folder_open,
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