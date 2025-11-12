// precarga_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:service_met/screens/calibracion/servicio_screen.dart';
import '../../../database/app_database.dart';
import '../../../models/balanza_model.dart';
import '../../../provider/balanza_provider.dart';
import 'precarga_controller.dart';
import 'widgets/step_indicator.dart';
import 'widgets/cliente_step.dart';
import 'widgets/planta_step.dart';
import 'widgets/seca_step.dart';
import 'widgets/balanza_step.dart';
import 'widgets/equipos_step.dart';


class PrecargaScreen extends StatefulWidget {
  final String userName;
  final int initialStep;
  final String? sessionId;
  final String? secaValue;

  const PrecargaScreen({
    super.key,
    required this.userName,
    this.initialStep = 0,
    this.sessionId,
    this.secaValue,
  });

  @override
  _PrecargaScreenState createState() => _PrecargaScreenState();
}

class _PrecargaScreenState extends State<PrecargaScreen> {
  late PrecargaController controller;
  final TextEditingController _fechaController = TextEditingController();

  // Controllers para campos de entrada
  final TextEditingController _nRecaController = TextEditingController();
  final TextEditingController _stickerController = TextEditingController();

  // Controllers de balanza - PERSISTENTES para evitar memory leaks
  late final Map<String, TextEditingController> _balanzaControllers;

  @override
  void initState() {
    super.initState();
    controller = PrecargaController();
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
      _setupBalanzaCallback();
    });
  }

  void _setupBalanzaCallback() {
    final balanzaProvider = Provider.of<BalanzaProvider>(context, listen: false);

    controller.onBalanzaSelected = (balanzaData) async {
      try {
        // Crear modelo Balanza desde los datos
        final balanza = Balanza(
          cod_metrica: balanzaData['cod_metrica']?.toString() ?? '',
          unidad: balanzaData['unidad']?.toString() ?? '',
          cap_max1: balanzaData['cap_max1']?.toString() ?? '',
          d1: _parseDouble(balanzaData['d1']),
          e1: _parseDouble(balanzaData['e1']),
          dec1: _parseDouble(balanzaData['dec1']),
          cap_max2: balanzaData['cap_max2']?.toString() ?? '0',
          d2: _parseDouble(balanzaData['d2']),
          e2: _parseDouble(balanzaData['e2']),
          dec2: _parseDouble(balanzaData['dec2']),
          cap_max3: balanzaData['cap_max3']?.toString() ?? '0',
          d3: _parseDouble(balanzaData['d3']),
          e3: _parseDouble(balanzaData['e3']),
          dec3: _parseDouble(balanzaData['dec3']),
          n_celdas: balanzaData['n_celdas']?.toString() ?? '',
          exc: _parseDouble(balanzaData['exc']),
        );

        // Actualizar provider con la balanza
        balanzaProvider.setSelectedBalanza(balanza, isNew: controller.isNewBalanza);

        // Si hay datos de servicio, cargarlos
        if (balanzaData['servicio'] != null) {
          balanzaProvider.setLastServiceData(balanzaData['servicio']);
        } else if (controller.isNewBalanza) {
          balanzaProvider.clearLastServiceData();
        }

        debugPrint('✅ BalanzaProvider actualizado: ${balanza.cod_metrica}');
        debugPrint('   Es nueva: ${controller.isNewBalanza}');
        debugPrint('   Tiene servicio anterior: ${balanzaData['servicio'] != null}');

      } catch (e) {
        debugPrint('❌ Error al actualizar BalanzaProvider: $e');
      }
    };
  }


  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }


  Future<void> _initializeData() async {
    try {
      await controller.fetchClientes();
      await controller.fetchEquipos();

      if (widget.sessionId != null && widget.secaValue != null) {
        await _loadExistingSession();
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
    return ChangeNotifierProvider<PrecargaController>(
      create: (_) => controller,
      child: Scaffold(
        appBar: _buildAppBar(),
        body: Consumer<PrecargaController>(
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
              'CALIBRACIÓN',
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

  Widget _buildCurrentStepContent(PrecargaController controller) {
    switch (controller.currentStep) {
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
      case 4:
        return const EquiposStep();
      default:
        return const SizedBox();
    }
  }

  Widget _buildBottomButtons(PrecargaController controller) {
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
          if (controller.currentStep > 0)
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

          if (controller.currentStep > 0) const SizedBox(width: 16),

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

  VoidCallback? _getNextButtonAction(PrecargaController controller) {
    switch (controller.currentStep) {
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

      case 4: // Equipos
        return controller.canProceedToStep(4)
            ? () => _saveAndNavigate()
            : null;

      default:
        return null;
    }
  }

  IconData _getNextButtonIcon(PrecargaController controller) {
    switch (controller.currentStep) {
      case 2:
        return controller.secaConfirmed ? Icons.arrow_forward : Icons.check;
      case 4:
        return Icons.save;
      default:
        return Icons.arrow_forward;
    }
  }

  String _getNextButtonText(PrecargaController controller) {
    switch (controller.currentStep) {
      case 2:
        return controller.secaConfirmed ? 'Siguiente' : 'Confirmar SECA';
      case 4:
        return 'Finalizar y Continuar';
      default:
        return 'Siguiente';
    }
  }

  Color _getNextButtonColor(PrecargaController controller) {
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
    // Validar campos finales
    if (!_validateFinalFields()) return;

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

  bool _validateFinalFields() {
    if (_nRecaController.text.trim().isEmpty) {
      _showSnackBar('Por favor ingrese el Nº RECA');
      return false;
    }

    if (_stickerController.text.trim().isEmpty) {
      _showSnackBar('Por favor ingrese el Nº Sticker');
      return false;
    }

    if (controller.getAllSelectedEquipos().isEmpty) {
      _showSnackBar('Por favor seleccione al menos un equipo');
      return false;
    }

    return true;
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