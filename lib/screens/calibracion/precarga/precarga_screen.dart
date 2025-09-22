// precarga_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../servicios/servicio_screen.dart';
import 'precarga_controller.dart';
import 'widgets/step_indicator.dart';
import 'widgets/cliente_step.dart';
import 'widgets/planta_step.dart';
import 'widgets/seca_step.dart';
import 'widgets/balanza_step.dart';
import 'widgets/equipos_step.dart';


class PrecargaScreen extends StatefulWidget {
  final String userName;

  const PrecargaScreen({
    super.key,
    required this.userName,
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

  // Controllers de balanza
  final Map<String, TextEditingController> _balanzaControllers = {
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

  @override
  void initState() {
    super.initState();
    controller = PrecargaController();
    _fechaController.text = controller.formatDate(DateTime.now());

    // Inicializar datos
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  Future<void> _initializeData() async {
    try {
      await controller.fetchClientes();
      await controller.fetchEquipos();
    } catch (e) {
      _showSnackBar('Error al inicializar: $e', isError: true);
    }
  }

  @override
  void dispose() {
    _fechaController.dispose();
    _nRecaController.dispose();
    _stickerController.dispose();

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
            return Column(
              children: [
                const StepIndicator(),
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
              'CALIBRACION',
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
        return controller.validateStep(0) ? () => controller.nextStep() : null;

      case 1: // Planta
        return controller.validateStep(1) ? () => controller.nextStep() : null;

      case 2: // SECA
        return controller.secaConfirmed
            ? () => controller.nextStep()
            : () => _confirmSeca();

      case 3: // Balanza
        return controller.validateStep(3) ? () => controller.nextStep() : null;

      case 4: // Equipos
        return () => _saveAndNavigate();

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
    if (!_validateFinalFields()) return;

    try {
      // Preparar datos de la balanza
      final balanzaData = <String, String>{};
      _balanzaControllers.forEach((key, controller) {
        balanzaData[key] = controller.text.trim();
      });

      // Guardar todos los datos
      await controller.saveAllData(
        userName: widget.userName,
        fechaServicio: _fechaController.text,
        nReca: _nRecaController.text.trim(),
        sticker: _stickerController.text.trim(),
        balanzaData: balanzaData,
      );

      _showSnackBar('Datos guardados correctamente');

      // Navegar al siguiente módulo
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ServicioScreen(
            codMetrica: _balanzaControllers['cod_metrica']!.text,
            nReca: _nRecaController.text,
            secaValue: controller.generatedSeca!,
            sessionId: controller.generatedSessionId!,
            dbName: '',
          ),
        ),
      );
    } catch (e) {
      _showSnackBar('Error al guardar: $e', isError: true);
    }
  }

  bool _validateFinalFields() {
    if (_nRecaController.text.trim().isEmpty) {
      _showSnackBar('Por favor ingrese el N° RECA');
      return false;
    }

    if (_stickerController.text.trim().isEmpty) {
      _showSnackBar('Por favor ingrese el N° Sticker');
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