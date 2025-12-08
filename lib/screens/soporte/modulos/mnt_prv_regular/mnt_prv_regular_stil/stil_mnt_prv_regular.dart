import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:service_met/provider/balanza_provider.dart';
import 'package:service_met/screens/soporte/modulos/mnt_prv_regular/mnt_prv_regular_stil/fin_servicio_stil.dart';
import 'package:service_met/screens/soporte/modulos/mnt_prv_regular/mnt_prv_regular_stil/widgets/steps/paso_entorno.dart';
import 'package:service_met/screens/soporte/modulos/mnt_prv_regular/mnt_prv_regular_stil/widgets/steps/paso_estado_final.dart';
import 'package:service_met/screens/soporte/modulos/mnt_prv_regular/mnt_prv_regular_stil/widgets/steps/paso_pruebas_iniciales_finales.dart';
import 'package:service_met/screens/soporte/modulos/mnt_prv_regular/mnt_prv_regular_stil/widgets/steps/paso_terminal_balanza_caja.dart';
import 'controllers/mnt_prv_regular_stil_controller.dart';
import 'models/mnt_prv_regular_stil_model.dart';

class StilMntPrvRegularStacScreen extends StatefulWidget {
  final String sessionId;
  final String secaValue;
  final String nReca;
  final String codMetrica;
  final String userName;
  final String clienteId;
  final String plantaCodigo;

  const StilMntPrvRegularStacScreen({
    super.key,
    required this.sessionId,
    required this.secaValue,
    required this.nReca,
    required this.codMetrica,
    required this.userName,
    required this.clienteId,
    required this.plantaCodigo,
  });

  @override
  _StilMntPrvRegularStacScreenState createState() =>
      _StilMntPrvRegularStacScreenState();
}

class _StilMntPrvRegularStacScreenState
    extends State<StilMntPrvRegularStacScreen> {
  late MntPrvRegularStilModel _model;
  late MntPrvRegularStilController _controller;

  int _currentStep = 0;
  bool _isSaving = false;
  DateTime? _lastPressedTime;
  double? _cachedD1; // ✅ Cachear d1 para evitar múltiples consultas

  // ✅ Definición de pasos
  final List<StepData> _steps = [];

  @override
  void initState() {
    super.initState();
    _initializeModel();
    _controller = MntPrvRegularStilController(model: _model);
    _actualizarHora();
    _loadD1Value();
    _initializeSteps();
  }

  void _initializeSteps() {
    _steps.addAll([
      StepData(
        title: 'Pruebas Iniciales',
        subtitle: 'Excentricidad, Repetibilidad, Linealidad',
        icon: Icons.science_outlined,
      ),
      StepData(
        title: 'Entorno de Instalación',
        subtitle: '8 campos de inspección',
        icon: Icons.domain_outlined,
      ),
      StepData(
        title: 'Terminal de Pesaje',
        subtitle: '10 campos de inspección',
        icon: Icons.computer_outlined,
      ),
      StepData(
        title: 'Estado de Balanza',
        subtitle: '6 campos de inspección',
        icon: Icons.balance_outlined,
      ),
      StepData(
        title: 'Caja Sumadora',
        subtitle: '4 campos de inspección',
        icon: Icons.electrical_services_outlined,
      ),
      StepData(
        title: 'Pruebas Finales',
        subtitle: 'Verificación final',
        icon: Icons.task_alt_outlined,
      ),
      StepData(
        title: 'Estado Final',
        subtitle: 'Conclusión del servicio',
        icon: Icons.assignment_turned_in_outlined,
      ),
    ]);
  }

  void _initializeModel() {
    final camposEstado = {
      // Entorno de instalación
      'Vibración': CampoEstado(),
      'Polvo': CampoEstado(),
      'Temperatura': CampoEstado(),
      'Humedad': CampoEstado(),
      'Mesada': CampoEstado(),
      'Iluminación': CampoEstado(),
      'Limpieza de Fosa': CampoEstado(),
      'Estado de Drenaje': CampoEstado(),

      // Terminal de pesaje
      'Carcasa': CampoEstado(),
      'Teclado Fisico': CampoEstado(),
      'Display Fisico': CampoEstado(),
      'Fuente de poder': CampoEstado(),
      'Bateria operacional': CampoEstado(),
      'Bracket': CampoEstado(),
      'Teclado Operativo': CampoEstado(),
      'Display Operativo': CampoEstado(),
      'Contector de celda': CampoEstado(),
      'Bateria de memoria': CampoEstado(),

      // Estado general de la balanza
      'Limpieza general': CampoEstado(),
      'Golpes al terminal': CampoEstado(),
      'Nivelacion': CampoEstado(),
      'Limpieza receptor': CampoEstado(),
      'Golpes al receptor de carga': CampoEstado(),
      'Encendido': CampoEstado(),

      // Balanza/Plataforma
      'Limitador de movimiento': CampoEstado(),
      'Suspensión': CampoEstado(),
      'Limitador de carga': CampoEstado(),
      'Celda de carga': CampoEstado(),

      // Caja sumadora
      'Tapa de caja sumadora': CampoEstado(),
      'Humedad Interna': CampoEstado(),
      'Estado de prensacables': CampoEstado(),
      'Estado de borneas': CampoEstado(),
    };

    _model = MntPrvRegularStilModel(
      codMetrica: widget.codMetrica,
      sessionId: widget.sessionId,
      secaValue: widget.secaValue,
      camposEstado: camposEstado,
      pruebasIniciales: PruebasMetrologicas(),
      pruebasFinales: PruebasMetrologicas(),
    );
  }

  void _actualizarHora() {
    final ahora = DateTime.now();
    final horaFormateada = DateFormat('HH:mm:ss').format(ahora);
    _model.horaInicio = horaFormateada;
  }

  // ✅ Cargar d1 una sola vez
  Future<void> _loadD1Value() async {
    try {
      _cachedD1 = await _controller.getD1FromDatabase();
    } catch (e) {
      try {
        final balanza = Provider.of<BalanzaProvider>(context, listen: false)
            .selectedBalanza;
        _cachedD1 = balanza?.d1 ?? 0.1;
      } catch (e) {
        _cachedD1 = 0.1;
      }
    }
    setState(() {});
  }

  Future<double> _getD1FromCache() async {
    return _cachedD1 ?? 0.1;
  }

  // ✅ Guardar automáticamente al cambiar de paso
  Future<void> _saveCurrentStep() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      await _controller.saveDataToDatabase(context, showMessage: false);
      debugPrint('✅ Paso $_currentStep guardado automáticamente');
    } catch (e) {
      debugPrint('❌ Error al guardar paso $_currentStep: $e');
      _showSnackBar('Error al guardar: ${e.toString()}', isError: true);
    } finally {
      setState(() => _isSaving = false);
    }
  }

  // ✅ Validar paso actual antes de avanzar
  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0: // Pruebas Iniciales
        // Validar que si hay pruebas activadas, estén completas
        return true; // Por ahora permitir continuar

      case 1: // Entorno
      case 2: // Terminal
      case 3: // Balanza
      case 4: // Caja sumadora
        // Verificar que todos los campos tengan estado seleccionado
        final camposDelPaso = _getCamposDelPaso(_currentStep);
        for (var campo in camposDelPaso) {
          if (_model.camposEstado[campo]?.initialValue == null ||
              _model.camposEstado[campo]!.initialValue.isEmpty) {
            _showSnackBar(
              'Por favor complete todos los campos del estado en: $campo',
              isError: true,
            );
            return false;
          }
        }
        return true;

      case 5: // Pruebas Finales
        return true;

      case 6: // Estado Final
        if (_model.comentarioGeneral.isEmpty) {
          _showSnackBar('Por favor complete el Comentario General',
              isError: true);
          return false;
        }
        if (_model.recomendacion.isEmpty) {
          _showSnackBar('Por favor seleccione una Recomendación',
              isError: true);
          return false;
        }
        if (_model.fechaProxServicio.isEmpty) {
          _showSnackBar('Por favor seleccione la fecha del próximo servicio',
              isError: true);
          return false;
        }
        if (_model.estadoFisico.isEmpty ||
            _model.estadoOperacional.isEmpty ||
            _model.estadoMetrologico.isEmpty) {
          _showSnackBar('Por favor complete todos los estados finales',
              isError: true);
          return false;
        }
        if (_model.horaFin.isEmpty) {
          _showSnackBar('Por favor registre la hora final del servicio',
              isError: true);
          return false;
        }
        return true;

      default:
        return true;
    }
  }

  List<String> _getCamposDelPaso(int paso) {
    switch (paso) {
      case 1: // Entorno
        return [
          'Vibración',
          'Polvo',
          'Temperatura',
          'Humedad',
          'Mesada',
          'Iluminación',
          'Limpieza de Fosa',
          'Estado de Drenaje'
        ];
      case 2: // Terminal
        return [
          'Carcasa',
          'Teclado Fisico',
          'Display Fisico',
          'Fuente de poder',
          'Bateria operacional',
          'Bracket',
          'Teclado Operativo',
          'Display Operativo',
          'Contector de celda',
          'Bateria de memoria'
        ];
      case 3: // Balanza
        return [
          'Limpieza general',
          'Golpes al terminal',
          'Nivelacion',
          'Limpieza receptor',
          'Golpes al receptor de carga',
          'Encendido'
        ];
      case 4: // Caja sumadora
        return [
          'Limitador de movimiento',
          'Suspensión',
          'Limitador de carga',
          'Celda de carga',
          'Tapa de caja sumadora',
          'Humedad Interna',
          'Estado de prensacables',
          'Estado de borneas'
        ];
      default:
        return [];
    }
  }

  Future<void> _goToStep(int step) async {
    // Validar paso actual antes de avanzar
    if (step > _currentStep && !_validateCurrentStep()) {
      return;
    }

    // Guardar antes de cambiar de paso
    await _saveCurrentStep();

    setState(() {
      _currentStep = step;
    });
  }

  Future<bool> _onWillPop() async {
    final now = DateTime.now();

    if (_lastPressedTime == null ||
        now.difference(_lastPressedTime!) > const Duration(seconds: 2)) {
      _lastPressedTime = now;

      _showSnackBar(
        'Presione nuevamente para salir. Los datos se guardarán automáticamente.',
        isError: false,
      );

      // Guardar antes de salir
      await _saveCurrentStep();

      return false;
    }

    return true;
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: isError ? 3 : 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final balanza = Provider.of<BalanzaProvider>(context).selectedBalanza;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 80,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'MNT PRV REGULAR STIL',
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
                    filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                    child: Container(color: Colors.black.withOpacity(0.1)),
                  ),
                )
              : null,
          centerTitle: true,
          actions: [
            // ✅ Indicador de guardado automático
            if (_isSaving)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
          ],
        ),
        body: Column(
          children: [
            // ✅ Barra de progreso mejorada
            _buildProgressBar(isDarkMode),

            // ✅ Contenido del paso actual
            Expanded(
              child: _buildStepContent(),
            ),

            // ✅ Botones de navegación
            _buildNavigationButtons(isDarkMode),
          ],
        ),
        floatingActionButton: _buildFloatingActionButton(balanza),
      ),
    );
  }

  Widget _buildProgressBar(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.black26 : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Título del paso actual
          Row(
            children: [
              Icon(
                _steps[_currentStep].icon,
                color: Theme.of(context).primaryColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Paso ${_currentStep + 1} de ${_steps.length}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    Text(
                      _steps[_currentStep].title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _steps[_currentStep].subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDarkMode ? Colors.white60 : Colors.black45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Barra de progreso visual
          Row(
            children: List.generate(_steps.length, (index) {
              final isCompleted = index < _currentStep;
              final isCurrent = index == _currentStep;

              return Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(
                    left: index == 0 ? 0 : 4,
                    right: index == _steps.length - 1 ? 0 : 4,
                  ),
                  decoration: BoxDecoration(
                    color: isCompleted || isCurrent
                        ? Theme.of(context).primaryColor
                        : Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return PasoPruebasIniciales(
          model: _model,
          controller: _controller,
          getIndicationSuggestions: _controller.getIndicationSuggestions,
          getD1FromDatabase: _getD1FromCache,
          onChanged: () => setState(() {}),
        );
      case 1:
        return PasoEntorno(
          model: _model,
          controller: _controller,
          onChanged: () => setState(() {}),
        );
      case 2:
        return PasoTerminal(
          model: _model,
          controller: _controller,
          onChanged: () => setState(() {}),
        );
      case 3:
        return PasoBalanza(
          model: _model,
          controller: _controller,
          onChanged: () => setState(() {}),
        );
      case 4:
        return PasoCajaSumadora(
          model: _model,
          controller: _controller,
          onChanged: () => setState(() {}),
        );
      case 5:
        return PasoPruebasFinales(
          model: _model,
          controller: _controller,
          getIndicationSuggestions: _controller.getIndicationSuggestions,
          getD1FromDatabase: _getD1FromCache,
          onChanged: () => setState(() {}),
        );
      case 6:
        return PasoEstadoFinal(
          model: _model,
          onChanged: () => setState(() {}),
        );
      default:
        return const Center(child: Text('Paso no encontrado'));
    }
  }

  Widget _buildNavigationButtons(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.black26 : Colors.white,
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
          if (_currentStep > 0)
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _goToStep(_currentStep - 1),
                icon: const Icon(Icons.arrow_back),
                label: const Text('ANTERIOR'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),

          if (_currentStep > 0) const SizedBox(width: 12),

          // Botón Siguiente o Finalizar
          Expanded(
            flex: _currentStep == 0 ? 1 : 2,
            child: ElevatedButton.icon(
              onPressed: _isSaving
                  ? null
                  : () async {
                      if (_currentStep < _steps.length - 1) {
                        await _goToStep(_currentStep + 1);
                      } else {
                        // Último paso: finalizar
                        if (_validateCurrentStep()) {
                          await _saveCurrentStep();

                          if (!mounted) return;

                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FinServicioMntPrvStilScreen(
                                sessionId: widget.sessionId,
                                secaValue: widget.secaValue,
                                codMetrica: widget.codMetrica,
                                nReca: widget.nReca,
                                userName: widget.userName,
                                clienteId: widget.clienteId,
                                plantaCodigo: widget.plantaCodigo,
                                tableName: 'mnt_prv_regular_stil',
                              ),
                            ),
                          );
                        }
                      }
                    },
              icon: Icon(
                _currentStep < _steps.length - 1
                    ? Icons.arrow_forward
                    : Icons.check_circle,
              ),
              label: Text(
                _currentStep < _steps.length - 1 ? 'SIGUIENTE' : 'FINALIZAR',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _currentStep < _steps.length - 1
                    ? const Color(0xFF195375)
                    : const Color(0xFF167D1D),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton(dynamic balanza) {
    return FloatingActionButton(
      backgroundColor: const Color(0xFFF9E300),
      child: const Icon(Icons.info_outline, color: Colors.black87),
      onPressed: () => _showBalanzaInfo(context, balanza),
    );
  }

  void _showBalanzaInfo(BuildContext context, dynamic balanza) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Información de la Balanza',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Divider(height: 24),
                if (balanza != null) ...[
                  _buildInfoRow('Código Métrica', balanza.cod_metrica),
                  _buildInfoRow('Unidades', balanza.unidad.toString()),
                  _buildInfoRow('Cap. Máx 1', balanza.cap_max1),
                  _buildInfoRow('d1', balanza.d1.toString()),
                  _buildInfoRow('e1', balanza.e1.toString()),
                  _buildInfoRow('Decimales 1', balanza.dec1.toString()),
                  if (balanza.cap_max2 != null &&
                      balanza.cap_max2.isNotEmpty) ...[
                    const Divider(),
                    _buildInfoRow('Cap. Máx 2', balanza.cap_max2),
                    _buildInfoRow('d2', balanza.d2.toString()),
                    _buildInfoRow('e2', balanza.e2.toString()),
                  ],
                ] else
                  const Text('No hay información de balanza disponible'),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(value),
        ],
      ),
    );
  }
}

// ✅ Clase auxiliar para datos de pasos
class StepData {
  final String title;
  final String subtitle;
  final IconData icon;

  StepData({
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}
