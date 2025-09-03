import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:service_met/screens/calibracion/pruebas_metrologicas/excentricidad/excentricidad_screen.dart';
import 'package:service_met/screens/calibracion/pruebas_metrologicas/linealidad/linealidad_screen.dart';
import 'package:service_met/screens/calibracion/pruebas_metrologicas/repetibilidad/repetibilidad_screen.dart';
import 'package:service_met/screens/calibracion/rca_final_screen.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
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
  final PageController _pageController = PageController();
  int _currentPage = 0;
  DateTime? _lastPressedTime;

  void _showSnackBar(BuildContext context, String message,
      {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<bool> _onWillPop(BuildContext context) async {
    final now = DateTime.now();
    if (_lastPressedTime == null ||
        now.difference(_lastPressedTime!) > const Duration(seconds: 2)) {
      _lastPressedTime = now;
      _showSnackBar(context,
          'Presione nuevamente para retroceder. Los datos registrados se perderán.');
      return false;
    }
    return true;
  }

  Future<void> _showConfirmationDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'CONFIRMACIÓN',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 17,
            ),
          ),
          content: const Text(
              '¿Estás seguro de que deseas finalizar las pruebas metrológicas?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _navigateToRcaFinalScreen(context);
              },
              child: const Text('Aceptar'),
            )
          ],
        );
      },
    );
  }

  void _navigateToRcaFinalScreen(BuildContext context) {
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

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final balanza = Provider.of<BalanzaProvider>(context).selectedBalanza;

    return WillPopScope(
      onWillPop: () => _onWillPop(context),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          toolbarHeight: 70,
          title: const Text(
            'CALIBRACIÓN',
            style: TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.w900,
            ),
          ),
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.transparent
              : Colors.white,
          elevation: 0,
          flexibleSpace: Theme.of(context).brightness == Brightness.dark
              ? ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
              child: Container(
                color: Colors.black.withOpacity(0.4),
              ),
            ),
          )
              : null,
          iconTheme: IconThemeData(color: Theme.of(context).iconTheme.color),
          titleTextStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black,
          ),
          centerTitle: true,
        ),
        body: Stack(
          children: [
            // Contenido principal con padding para la AppBar
            Padding(
              padding: const EdgeInsets.only(top: kToolbarHeight), // Añade espacio para la AppBar
              child: Column(
                children: [
                  Expanded(

                    child: PageView(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() {
                          _currentPage = index;
                        });
                      },
                      children: [
                        // Página 1: Excentricidad
                        ExcentricidadScreen(
                          sessionId: widget.sessionId,
                          codMetrica: widget.codMetrica,
                          secaValue: widget.secaValue,
                          selectedBalanza: widget.selectedBalanza,
                          onNext: () => _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          ),
                        ),

                        // Página 2: Repetibilidad
                        RepetibilidadScreen(
                          sessionId: widget.sessionId,
                          codMetrica: widget.codMetrica,
                          secaValue: widget.secaValue,
                          onNext: () => _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          ),
                        ),

                        // Página 3: Linealidad
                        LinealidadScreen(
                          sessionId: widget.sessionId,
                          codMetrica: widget.codMetrica,
                          secaValue: widget.secaValue,
                          onNext: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RcaFinalScreen(
                                  secaValue: widget.secaValue,
                                  selectedBalanza: widget.selectedBalanza,
                                  codMetrica: widget.codMetrica,
                                  sessionId: widget.sessionId,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  // Espacio reservado para los botones
                  const SizedBox(height: 100),
                ],
              ),
            ),
            // Botones de navegación fijos en la parte inferior
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    SmoothPageIndicator(
                      controller: _pageController,
                      count: 3,
                      effect: const WormEffect(
                        dotHeight: 10,
                        dotWidth: 10,
                        activeDotColor: Color(0xFF3a6d8b),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (_currentPage > 0)
                          TextButton(
                            onPressed: () => _pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            ),
                            child: const Text('Anterior'),
                          )
                        else
                          const SizedBox(width: 100),

                        if (_currentPage < 2)
                          ElevatedButton(
                            onPressed: () => _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF478b3a),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Siguiente'),
                          )
                        else
                          ElevatedButton(
                            onPressed: () => _showConfirmationDialog(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF478b3a),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Finalizar Pruebas Metrológicas'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 80.0),
          child: SpeedDial(
            icon: Icons.menu,
            activeIcon: Icons.close,
            iconTheme: const IconThemeData(color: Colors.black54),
            backgroundColor: const Color(0xFFF9E300),
            foregroundColor: Colors.white,
            children: [
              SpeedDialChild(
                child: const Icon(Icons.info),
                backgroundColor: Colors.blueAccent,
                label: 'Información de la balanza',
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (BuildContext context) {
                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              const Text(
                                'Información de la balanza',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 10),
                              if (balanza != null) ...[
                                _buildDetailContainer(
                                    'Código Métrica',
                                    balanza.cod_metrica,
                                    Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.color ??
                                        Colors.black,
                                    Colors.grey),
                                _buildDetailContainer(
                                    'Unidades',
                                    balanza.unidad.toString(),
                                    Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.color ??
                                        Colors.black,
                                    Colors.grey),
                                _buildDetailContainer(
                                    'pmax1',
                                    balanza.cap_max1,
                                    Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.color ??
                                        Colors.black,
                                    Colors.grey),
                                _buildDetailContainer(
                                    'd1',
                                    balanza.d1.toString(),
                                    Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.color ??
                                        Colors.black,
                                    Colors.grey),
                                _buildDetailContainer(
                                    'e1',
                                    balanza.e1.toString(),
                                    Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.color ??
                                        Colors.black,
                                    Colors.grey),
                                _buildDetailContainer(
                                    'dec1',
                                    balanza.dec1.toString(),
                                    Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.color ??
                                        Colors.black,
                                    Colors.grey),
                                _buildDetailContainer(
                                    'pmax2',
                                    balanza.cap_max2,
                                    Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.color ??
                                        Colors.black,
                                    Colors.grey),
                                _buildDetailContainer(
                                    'd2',
                                    balanza.d2.toString(),
                                    Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.color ??
                                        Colors.black,
                                    Colors.grey),
                                _buildDetailContainer(
                                    'e2',
                                    balanza.e2.toString(),
                                    Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.color ??
                                        Colors.black,
                                    Colors.grey),
                                _buildDetailContainer(
                                    'dec2',
                                    balanza.dec2.toString(),
                                    Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.color ??
                                        Colors.black,
                                    Colors.grey),
                                _buildDetailContainer(
                                    'pmax3',
                                    balanza.cap_max3,
                                    Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.color ??
                                        Colors.black,
                                    Colors.grey),
                                _buildDetailContainer(
                                    'd3',
                                    balanza.d3.toString(),
                                    Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.color ??
                                        Colors.black,
                                    Colors.grey),
                                _buildDetailContainer(
                                    'e3',
                                    balanza.e3.toString(),
                                    Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.color ??
                                        Colors.black,
                                    Colors.grey),
                                _buildDetailContainer(
                                    'dec3',
                                    balanza.dec3.toString(),
                                    Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.color ??
                                        Colors.black,
                                    Colors.grey),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              SpeedDialChild(
                child: const Icon(Icons.info),
                backgroundColor: Colors.orangeAccent,
                label: 'Datos del Último Servicio',
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (BuildContext context) {
                      final lastServiceData = Provider.of<BalanzaProvider>(context, listen: false).lastServiceData;
                      if (lastServiceData == null) {
                        return const Center(child: Text('No hay datos de servicio'));
                      }

                      final textColor = Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black;
                      final dividerColor = Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black;

                      final Map<String, String> fieldLabels = {
                        'reg_fecha': 'Fecha del Último Servicio',
                        'reg_usuario': 'Técnico Responsable',
                        'seca': 'Último SECA',
                        'exc': 'Exc',
                      };

                      for (int i = 1; i <= 30; i++) {
                        fieldLabels['rep$i'] = 'rep $i';
                      }

                      for (int i = 1; i <= 60; i++) {
                        fieldLabels['lin$i'] = 'lin $i';
                      }

                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'REGISTRO DE ÚLTIMOS SERVICIOS DE CALIBRACIÓN',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              ...lastServiceData.entries
                                  .where((entry) => entry.value != null && fieldLabels.containsKey(entry.key))
                                  .map((entry) => _buildDetailContainer(
                                  fieldLabels[entry.key]!,
                                  entry.key == 'reg_fecha'
                                      ? DateFormat('yyyy-MM-dd').format(DateTime.parse(entry.value))
                                      : entry.value.toString(),
                                  textColor,
                                  dividerColor)),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }

  Widget _buildDetailContainer(
      String label, String value, Color textColor, Color borderColor) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
          ),
          Text(
            value,
            style: TextStyle(color: textColor),
          ),
        ],
      ),
    );
  }
}