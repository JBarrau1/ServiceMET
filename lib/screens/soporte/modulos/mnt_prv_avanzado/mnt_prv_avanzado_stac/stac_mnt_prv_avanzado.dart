import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:service_met/provider/balanza_provider.dart';
import 'package:service_met/screens/soporte/modulos/mnt_prv_avanzado/mnt_prv_avanzado_stac/models/mnt_prv_avanzado_stac_model.dart';
import 'package:service_met/screens/soporte/modulos/mnt_prv_avanzado/mnt_prv_avanzado_stac/utils/constants.dart';
import 'package:service_met/screens/soporte/modulos/mnt_prv_avanzado/mnt_prv_avanzado_stac/widgets/steps/paso_estado_final.dart';
import 'package:service_met/screens/soporte/modulos/mnt_prv_avanzado/mnt_prv_avanzado_stac/widgets/steps/paso_generico.dart';
import 'package:service_met/screens/soporte/modulos/mnt_prv_avanzado/mnt_prv_avanzado_stac/widgets/steps/paso_pruebas_iniciales_finales.dart';

import 'controllers/mnt_prv_avanzado_stac_controller.dart';
import 'fin_servicio_stac.dart';




class StacMntPrvAvanzadoStacScreen extends StatefulWidget {
  final String sessionId;
  final String secaValue;
  final String nReca;
  final String codMetrica;
  final String userName;
  final String clienteId;
  final String plantaCodigo;

  const StacMntPrvAvanzadoStacScreen({
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
  _StacMntPrvAvanzadoStacScreenState createState() =>
      _StacMntPrvAvanzadoStacScreenState();
}

class _StacMntPrvAvanzadoStacScreenState extends State<StacMntPrvAvanzadoStacScreen> {
  late MntPrvAvanzadoStacModel _model;
  late MntPrvAvanzadoStacController _controller;

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
    _controller = MntPrvAvanzadoStacController(model: _model);
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
        title: 'Lozas y Fundaciones',
        subtitle: '2 campos de inspección',
        icon: Icons.foundation_outlined,
      ),
      StepData(
        title: 'Limpieza y Drenaje',
        subtitle: '4 campos de inspección',
        icon: Icons.cleaning_services_outlined,
      ),
      StepData(
        title: 'Chequeo General',
        subtitle: '8 campos de inspección',
        icon: Icons.checklist_outlined,
      ),
      StepData(
        title: 'Verificaciones Eléctricas',
        subtitle: '8 campos de inspección',
        icon: Icons.electrical_services_outlined,
      ),
      StepData(
        title: 'Protección contra Rayos',
        subtitle: '4 campos de inspección',
        icon: Icons.flash_on_outlined,
      ),
      StepData(
        title: 'Verificaciones de Células',
        subtitle: '7 campos de inspección',
        icon: Icons.grain_outlined, // Ícono de célula/componente
      ),
      StepData(
        title: 'Terminal',
        subtitle: '8 campos de inspección',
        icon: Icons.computer_outlined,
      ),
      StepData(
        title: 'Calibración',
        subtitle: '1 campo de inspección',
        icon: Icons.tune_outlined,
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
    final camposEstado = <String, CampoEstadoAvanzadoStac>{};

    //Inicializar TODOS los campos usando la lista de constants
    for (final campo in AppStacAvanzadoConstants.getAllCampos()) {
      camposEstado[campo] = CampoEstadoAvanzadoStac();
    }

    _model = MntPrvAvanzadoStacModel(
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

      case 10: // Estado Final
        if (_model.comentarioGeneral.isEmpty) {
          _showSnackBar('Por favor complete el Comentario General', isError: true);
          return false;
        }
        if (_model.recomendacion.isEmpty) {
          _showSnackBar('Por favor seleccione una Recomendación', isError: true);
          return false;
        }
        if (_model.fechaProxServicio.isEmpty) {
          _showSnackBar('Por favor seleccione la fecha del próximo servicio', isError: true);
          return false;
        }
        if (_model.estadoFisico.isEmpty ||
            _model.estadoOperacional.isEmpty ||
            _model.estadoMetrologico.isEmpty) {
          _showSnackBar('Por favor complete todos los estados finales', isError: true);
          return false;
        }
        if (_model.horaFin.isEmpty) {
          _showSnackBar('Por favor registre la hora final del servicio', isError: true);
          return false;
        }
        return true;

      default:
        return true;
    }
  }

  List<String> _getCamposDelPaso(int paso) {
    switch (paso) {
      case 1: return AppStacAvanzadoConstants.lozasYFundacionesCampos;
      case 2: return AppStacAvanzadoConstants.limpiezaYDrenajeCampos;
      case 3: return AppStacAvanzadoConstants.chequeoCampos;
      case 4: return AppStacAvanzadoConstants.verificacionesElectricasCampos;
      case 5: return AppStacAvanzadoConstants.proteccionRayosCampos;
      case 6: return AppStacAvanzadoConstants.verificacionesCeldasCampos;
      case 7: return AppStacAvanzadoConstants.terminalCampos;
      case 8: return AppStacAvanzadoConstants.calibracionCampos;
      default: return [];
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
                'MNT PRV AVANZADO STAC',
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
          getD1FromDatabase: _getD1FromCache,
          onChanged: () => setState(() {}),
        );
      case 1:
        return PasoGenerico(
          model: _model,
          controller: _controller,
          onChanged: () => setState(() {}),
          campos: AppStacAvanzadoConstants.lozasYFundacionesCampos,
          titulo: 'LOZAS Y FUNDACIONES',
          subtitulo: 'Inspeccione el estado de lozas y fundaciones',
          icono: Icons.foundation_outlined,
          color: Colors.brown,
        );
      case 2:
        return PasoGenerico(
          model: _model,
          controller: _controller,
          onChanged: () => setState(() {}),
          campos: AppStacAvanzadoConstants.limpiezaYDrenajeCampos,
          titulo: 'LIMPIEZA Y DRENAJE',
          subtitulo: 'Inspeccione limpieza y sistema de drenaje',
          icono: Icons.cleaning_services_outlined,
          color: Colors.lightBlue,
        );
      case 3:
        return PasoGenerico(
          model: _model,
          controller: _controller,
          onChanged: () => setState(() {}),
          campos: AppStacAvanzadoConstants.chequeoCampos,
          titulo: 'CHEQUEO GENERAL',
          subtitulo: 'Inspeccione el estado general del equipo',
          icono: Icons.checklist_outlined,
          color: Colors.teal,
        );
      case 4:
        return PasoGenerico(
          model: _model,
          controller: _controller,
          onChanged: () => setState(() {}),
          campos: AppStacAvanzadoConstants.verificacionesElectricasCampos,
          titulo: 'VERIFICACIONES ELÉCTRICAS',
          subtitulo: 'Inspeccione conexiones y cableado',
          icono: Icons.electrical_services_outlined,
          color: Colors.amber,
        );
      case 5:
        return PasoGenerico(
          model: _model,
          controller: _controller,
          onChanged: () => setState(() {}),
          campos: AppStacAvanzadoConstants.proteccionRayosCampos,
          titulo: 'PROTECCIÓN CONTRA RAYOS',
          subtitulo: 'Verifique sistema de protección eléctrica',
          icono: Icons.flash_on_outlined,
          color: Colors.orange,
        );
      case 6:
        return PasoGenerico(
          model: _model,
          controller: _controller,
          onChanged: () => setState(() {}),
          campos: AppStacAvanzadoConstants.verificacionesCeldasCampos,
          titulo: 'VERIFICACIONES DE CÉLULAS DE CARGA',
          subtitulo: 'Inspeccione células y componentes de pesaje',
          icono: Icons.grain_outlined,
          color: Colors.indigo,
        );
      case 7:
        return PasoGenerico(
          model: _model,
          controller: _controller,
          onChanged: () => setState(() {}),
          campos: AppStacAvanzadoConstants.terminalCampos,
          titulo: 'TERMINAL',
          subtitulo: 'Inspeccione el terminal de pesaje',
          icono: Icons.computer_outlined,
          color: Colors.purple,
        );
      case 8:
        return PasoGenerico(
          model: _model,
          controller: _controller,
          onChanged: () => setState(() {}),
          campos: AppStacAvanzadoConstants.calibracionCampos,
          titulo: 'CALIBRACIÓN',
          subtitulo: 'Verifique la calibración',
          icono: Icons.tune_outlined,
          color: Colors.green,
        );
      case 9:
        return PasoPruebasFinales(
          model: _model,
          controller: _controller,
          getD1FromDatabase: _getD1FromCache,
          onChanged: () => setState(() {}),
        );
      case 10:
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
                        builder: (context) => FinServicioMntAvaStacScreen(
                          sessionId: widget.sessionId,
                          secaValue: widget.secaValue,
                          codMetrica: widget.codMetrica,
                          nReca: widget.nReca,
                          userName: widget.userName,
                          clienteId: widget.clienteId,
                          plantaCodigo: widget.plantaCodigo,
                          tableName: 'mnt_prv_avanzado_stac',
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
                  if (balanza.cap_max2 != null && balanza.cap_max2.isNotEmpty) ...[
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