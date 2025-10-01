import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:service_met/screens/calibracion/pruebas_metrologicas/excentricidad/excentricidad_screen.dart';
import 'package:service_met/screens/calibracion/pruebas_metrologicas/linealidad/linealidad_screen.dart';
import 'package:service_met/screens/calibracion/pruebas_metrologicas/repetibilidad/repetibilidad_screen.dart';
import 'package:service_met/screens/calibracion/rca_final_screen.dart';
import '../../provider/balanza_provider.dart';

class CalibrationFlowScreen extends StatefulWidget {
  final String codMetrica;
  final String secaValue;
  final String sessionId;
  final Map<String, dynamic> selectedBalanza;

  const CalibrationFlowScreen({
    super.key,
    required this.codMetrica,
    required this.secaValue,
    required this.sessionId,
    required this.selectedBalanza,
  });

  @override
  State<CalibrationFlowScreen> createState() => _CalibrationFlowScreenState();
}

class _CalibrationFlowScreenState extends State<CalibrationFlowScreen> {
  int _currentStep = 0;
  DateTime? _lastPressedTime;

  final List<Map<String, dynamic>> _stepInfo = [
    {'title': 'Exc', 'icon': Icons.center_focus_strong},
    {'title': 'Rep', 'icon': Icons.repeat},
    {'title': 'Lin', 'icon': Icons.show_chart},
  ];

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
      ),
    );
  }

  Future<bool> _onWillPop() async {
    final now = DateTime.now();
    if (_lastPressedTime == null ||
        now.difference(_lastPressedTime!) > const Duration(seconds: 2)) {
      _lastPressedTime = now;
      _showSnackBar(
          'Presione nuevamente para salir. Los datos no guardados se perderán.',
          isError: true);
      return false;
    }
    return true;
  }

  Future<void> _showConfirmationDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true, // Cambiar a true para mejor UX
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.green, size: 28),
              const SizedBox(width: 12),
              Text(
                'FINALIZAR PRUEBAS',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            '¿Estás seguro de que deseas finalizar las pruebas metrológicas?',
            style: GoogleFonts.inter(fontSize: 15),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Seguir Editando',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _navigateToRcaFinalScreen();
              },
              child: Text(
                'Continuar',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          ],
        );
      },
    );
  }

  void _navigateToRcaFinalScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RcaFinalScreen(
          secaValue: widget.secaValue,
          sessionId: widget.sessionId,
          selectedBalanza: widget.selectedBalanza,
          codMetrica: widget.codMetrica,
        ),
      ),
    );
  }

  void _navigateToStep(int stepIndex) {
    if (stepIndex >= 0 && stepIndex < _stepInfo.length) {
      setState(() {
        _currentStep = stepIndex;
      });
    }
  }

  void _onStepCompleted() {
    _showSnackBar('Datos de ${_stepInfo[_currentStep]['title']} guardados correctamente');

    // Navegar automáticamente al siguiente paso si no es el último
    if (_currentStep < _stepInfo.length - 1) {
      Future.delayed(const Duration(milliseconds: 800), () {
        _navigateToStep(_currentStep + 1);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: _buildAppBar(isDarkMode),
        body: Column(
          children: [
            _buildStepIndicator(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: _buildCurrentStepContent(),
              ),
            ),
            _buildBottomButtons(),
          ],
        ),
        floatingActionButton: _buildSpeedDial(),
        floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDarkMode) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(70),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
          child: AppBar(
            toolbarHeight: 70,
            title: Column(
              children: [
                Text(
                  'CALIBRACIÓN',
                  style: GoogleFonts.poppins(
                    color: isDarkMode ? Colors.white : Colors.black,
                    fontWeight: FontWeight.w700,
                    fontSize: 16.0,
                  ),
                ),
                Text(
                  'Pruebas Metrológicas',
                  style: GoogleFonts.inter(
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                    fontWeight: FontWeight.w400,
                    fontSize: 12.0,
                  ),
                ),
              ],
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

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Fila de círculos conectados
          SizedBox(
            height: 40,
            child: Stack(
              children: [
                // Línea de fondo continua
                Positioned(
                  top: 19,
                  left: 40,
                  right: 40,
                  child: Container(
                    height: 2,
                    color: Colors.grey[300],
                  ),
                ),
                // Círculos
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(_stepInfo.length, (index) {
                    return GestureDetector(
                      onTap: () => _navigateToStep(index),
                      child: _buildStepCircle(index),
                    );
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Fila de títulos
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(_stepInfo.length, (index) {
              final isActive = index == _currentStep;

              return Expanded(
                child: GestureDetector(
                  onTap: () => _navigateToStep(index),
                  child: Text(
                    _stepInfo[index]['title'],
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      height: 1.2,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      color: isActive ? const Color(0xFF667EEA) : Colors.grey[600],
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildStepCircle(int index) {
    final isActive = index == _currentStep;

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive ? const Color(0xFF667EEA) : Colors.grey[300],
        border: Border.all(
          color: isActive ? const Color(0xFF667EEA) : Colors.transparent,
          width: 3,
        ),
        boxShadow: isActive
            ? [
          BoxShadow(
            color: const Color(0xFF667EEA).withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ]
            : null,
      ),
      child: Center(
        child: Icon(
          _stepInfo[index]['icon'],
          color: isActive ? Colors.white : Colors.grey[600],
          size: 24,
        ),
      ),
    );
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 0:
        return ExcentricidadScreen(
          sessionId: widget.sessionId,
          codMetrica: widget.codMetrica,
          secaValue: widget.secaValue,
          selectedBalanza: widget.selectedBalanza,
          onDataSaved: _onStepCompleted, // Cambiar por la nueva función
        );
      case 1:
        return RepetibilidadScreen(
          sessionId: widget.sessionId,
          codMetrica: widget.codMetrica,
          secaValue: widget.secaValue,
          onDataSaved: _onStepCompleted, // Cambiar por la nueva función
        );
      case 2:
        return LinealidadScreen(
          sessionId: widget.sessionId,
          codMetrica: widget.codMetrica,
          secaValue: widget.secaValue,
          onDataSaved: _onStepCompleted, // Cambiar por la nueva función
        );
      default:
        return const Center(child: Text('Paso no disponible'));
    }
  }

  Widget _buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Botón Anterior
            if (_currentStep > 0)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _navigateToStep(_currentStep - 1),
                  icon: const Icon(Icons.arrow_back, size: 18),
                  label: const Text('Anterior'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey[700],
                    side: BorderSide(color: Colors.grey[400]!),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

            if (_currentStep > 0) const SizedBox(width: 12),

            // Botón Siguiente o Finalizar
            Expanded(
              child: _currentStep < _stepInfo.length - 1
                  ? ElevatedButton.icon(
                onPressed: () => _navigateToStep(_currentStep + 1),
                icon: const Icon(Icons.arrow_forward, size: 18),
                label: const Text('Siguiente'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF667EEA),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 2,
                  textStyle: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
                  : ElevatedButton.icon(
                onPressed: _showConfirmationDialog,
                icon: const Icon(Icons.check_circle, size: 18),
                label: const Text('Finalizar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 2,
                  textStyle: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpeedDial() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: SpeedDial(
        icon: Icons.menu,
        activeIcon: Icons.close,
        spacing: 12,
        spaceBetweenChildren: 12,
        iconTheme: const IconThemeData(color: Colors.black87, size: 24),
        backgroundColor: const Color(0xFFF9E300),
        foregroundColor: Colors.black87,
        overlayColor: Colors.black,
        overlayOpacity: 0.5,
        elevation: 8,
        animationCurve: Curves.easeInOut,
        children: [
          SpeedDialChild(
            child: const Icon(Icons.info_outline, size: 24),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            label: 'Info de la balanza',
            labelStyle: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            labelBackgroundColor: Colors.blue,
            onTap: _showBalanzaInfo,
          ),
          SpeedDialChild(
            child: const Icon(Icons.history, size: 24),
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            label: 'Último servicio',
            labelStyle: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            labelBackgroundColor: Colors.orange,
            onTap: _showLastServiceData,
          ),
        ],
      ),
    );
  }

  void _showBalanzaInfo() {
    final balanza = Provider.of<BalanzaProvider>(context, listen: false)
        .selectedBalanza;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      children: [
                        Icon(Icons.scale, color: Colors.blue, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Información de la Balanza',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: Colors.grey[300]),
                  const SizedBox(height: 8),
                  // Content
                  Expanded(
                    child: balanza != null
                        ? ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      children: [
                        _buildDetailContainer(
                            'Código Métrica', balanza.cod_metrica),
                        _buildDetailContainer(
                            'Unidades', balanza.unidad.toString()),
                        _buildSectionHeader('Rango 1'),
                        _buildDetailContainer('pmax1', balanza.cap_max1),
                        _buildDetailContainer('d1', balanza.d1.toString()),
                        _buildDetailContainer('e1', balanza.e1.toString()),
                        _buildDetailContainer('dec1', balanza.dec1.toString()),
                        _buildSectionHeader('Rango 2'),
                        _buildDetailContainer('pmax2', balanza.cap_max2),
                        _buildDetailContainer('d2', balanza.d2.toString()),
                        _buildDetailContainer('e2', balanza.e2.toString()),
                        _buildDetailContainer('dec2', balanza.dec2.toString()),
                        _buildSectionHeader('Rango 3'),
                        _buildDetailContainer('pmax3', balanza.cap_max3),
                        _buildDetailContainer('d3', balanza.d3.toString()),
                        _buildDetailContainer('e3', balanza.e3.toString()),
                        _buildDetailContainer('dec3', balanza.dec3.toString()),
                        const SizedBox(height: 20),
                      ],
                    )
                        : Center(
                      child: Text(
                        'No hay información disponible',
                        style: GoogleFonts.inter(fontSize: 15),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showLastServiceData() {
    final lastServiceData =
        Provider.of<BalanzaProvider>(context, listen: false).lastServiceData;

    if (lastServiceData == null) {
      _showSnackBar('No hay datos de servicio disponibles', isError: true);
      return;
    }

    final Map<String, String> fieldLabels = {
      'reg_fecha': 'Fecha del Último Servicio',
      'reg_usuario': 'Técnico Responsable',
      'seca': 'Último SECA',
      'exc': 'Excentricidad',
    };

    for (int i = 1; i <= 30; i++) {
      fieldLabels['rep$i'] = 'Repetibilidad $i';
    }

    for (int i = 1; i <= 60; i++) {
      fieldLabels['lin$i'] = 'Linealidad $i';
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      children: [
                        Icon(Icons.history, color: Colors.orange, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Último Servicio',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: Colors.grey[300]),
                  const SizedBox(height: 8),
                  // Content
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      children: [
                        ...lastServiceData.entries
                            .where((entry) =>
                        entry.value != null &&
                            fieldLabels.containsKey(entry.key))
                            .map((entry) => _buildDetailContainer(
                            fieldLabels[entry.key]!,
                            entry.key == 'reg_fecha'
                                ? DateFormat('dd/MM/yyyy')
                                .format(DateTime.parse(entry.value))
                                : entry.value.toString()))
                            .toList(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF667EEA),
        ),
      ),
    );
  }

  Widget _buildDetailContainer(String label, String value) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final borderColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.white.withOpacity(0.1)
        : Colors.grey.withOpacity(0.2);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white.withOpacity(0.03)
            : Colors.grey.withOpacity(0.03),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: textColor,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 1,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: textColor.withOpacity(0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}