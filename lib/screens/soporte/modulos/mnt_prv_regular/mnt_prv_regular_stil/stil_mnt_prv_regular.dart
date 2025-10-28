import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:service_met/provider/balanza_provider.dart';
import 'package:service_met/screens/soporte/modulos/mnt_prv_regular/mnt_prv_regular_stil/fin_servicio_stil.dart';
import 'package:service_met/screens/soporte/modulos/mnt_prv_regular/mnt_prv_regular_stil/widgets/estado_general_widget.dart';
import 'package:service_met/screens/soporte/modulos/mnt_prv_regular/mnt_prv_regular_stil/widgets/pruebas_metrologicas_widget.dart';
import 'controllers/mnt_prv_regular_stil_controller.dart';
import 'models/mnt_prv_regular_stil_model.dart';

class StilMntPrvRegularStacScreen extends StatefulWidget {
  final String nReca;
  final String secaValue;
  final String sessionId;
  final String codMetrica;

  const StilMntPrvRegularStacScreen({
    super.key,
    required this.nReca,
    required this.secaValue,
    required this.sessionId,
    required this.codMetrica,
  });

  @override
  _StilMntPrvRegularStacScreenState createState() =>
      _StilMntPrvRegularStacScreenState();
}

class _StilMntPrvRegularStacScreenState extends State<StilMntPrvRegularStacScreen> {
  late MntPrvRegularStilModel _model;
  late MntPrvRegularStilController _controller;
  final _formKey = GlobalKey<FormState>();
  DateTime? _lastPressedTime;
  final ValueNotifier<bool> _isSaveButtonPressed = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _isDataSaved = ValueNotifier<bool>(false);
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final ValueNotifier<bool> _isFabVisible = ValueNotifier<bool>(true);

  @override
  void initState() {
    super.initState();
    _initializeModel();
    _controller = MntPrvRegularStilController(model: _model);
    _actualizarHora();
  }

  void _initializeModel() {
    // Inicializar campos de estado
    final camposEstado = {
      'Vibración': CampoEstado(),
      'Polvo': CampoEstado(),
      'Temperatura': CampoEstado(),
      'Humedad': CampoEstado(),
      'Mesada': CampoEstado(),
      'Iluminación': CampoEstado(),
      'Limpieza de Fosa': CampoEstado(),
      'Estado de Drenaje': CampoEstado(),
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
      'Limpieza general': CampoEstado(),
      'Golpes al terminal': CampoEstado(),
      'Nivelacion': CampoEstado(),
      'Limpieza receptor': CampoEstado(),
      'Golpes al receptor de carga': CampoEstado(),
      'Encendido': CampoEstado(),
      'Limitador de movimiento': CampoEstado(),
      'Suspensión': CampoEstado(),
      'Limitador de carga': CampoEstado(),
      'Celda de carga': CampoEstado(),
      'Tapa de caja sumadora': CampoEstado(),
      'Humedad Interna': CampoEstado(),
      'Estado de prensacables': CampoEstado(),
      'Estado de borneas': CampoEstado(),
    };

    _model = MntPrvRegularStilModel(
      // ❌ ELIMINAR: dbName, dbPath, otValue, selectedCliente, selectedPlantaNombre
      codMetrica: widget.codMetrica,
      sessionId: widget.sessionId, // ✅ AGREGAR
      secaValue: widget.secaValue, // ✅ AGREGAR
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

  Future<bool> _onWillPop(BuildContext context) async {
    final now = DateTime.now();
    if (_lastPressedTime == null ||
        now.difference(_lastPressedTime!) > const Duration(seconds: 2)) {
      _lastPressedTime = now;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Presione nuevamente para retroceder. Los datos registrados se perderán.',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return false;
    }
    return true;
  }

  Future<double> _getD1FromDatabase() async {
    try {
      // ✅ PRIMERO intentar con el controller
      return await _controller.getD1FromDatabase();
    } catch (e) {
      // ✅ FALLBACK: intentar con el provider de balanza
      try {
        final balanza = Provider.of<BalanzaProvider>(context, listen: false)
            .selectedBalanza;
        return balanza?.d1 ?? 0.1;
      } catch (e) {
        debugPrint('Error al obtener d1 del provider: $e');
        return 0.1;
      }
    }
  }

  void _showSnackBar(BuildContext context, String message,
      {Color? backgroundColor, Color? textColor}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: textColor ?? Colors.black),
        ),
        backgroundColor: backgroundColor ?? Colors.grey,
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

  InputDecoration _buildInputDecoration(String labelText, {Widget? suffixIcon}) {
    return InputDecoration(
      labelText: labelText,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20.0)),
      suffixIcon: suffixIcon,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final balanza = Provider.of<BalanzaProvider>(context).selectedBalanza;

    return WillPopScope(
      onWillPop: () async => _onWillPop(context),
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
        body: Form(
          key: _formKey,
          child: Column(
            children: [
              // Contenido principal con scroll
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    top: kToolbarHeight + MediaQuery.of(context).padding.top + 40,
                    left: 16.0,
                    right: 16.0,
                    bottom: 16.0,
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'MNT PRV REGULAR STIL',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20.0),
                      TextFormField(
                        readOnly: true,
                        initialValue: _model.horaInicio,
                        decoration: _buildInputDecoration(
                          'Hora de Inicio de Servicio',
                          suffixIcon: const Icon(Icons.access_time),
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info,
                              color: isDarkMode ? Colors.white70 : Colors.black54,
                              size: 16.0,
                            ),
                            const SizedBox(width: 8.0),
                            Expanded(
                              child: Text(
                                'La hora se extrae automáticamente del sistema, este campo no es editable.',
                                style: TextStyle(
                                  fontSize: 12.0,
                                  color: isDarkMode ? Colors.white70 : Colors.black54,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20.0),
                      // Indicador de páginas
                      SmoothPageIndicator(
                        controller: _pageController,
                        count: 3,
                        effect: WormEffect(
                          dotHeight: 10,
                          dotWidth: 10,
                          dotColor: Colors.grey,
                          activeDotColor: Theme.of(context).primaryColor,
                        ),
                        onDotClicked: (index) {
                          _pageController.animateToPage(
                            index,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                      ),
                      const SizedBox(height: 20.0),

                      // Contenedor de páginas
                      SizedBox(
                        height: 800, // Altura fija para el PageView
                        child: PageView(
                          controller: _pageController,
                          onPageChanged: (int page) {
                            setState(() {
                              _currentPage = page;
                            });
                          },
                          children: [
                            // Página 1: Pruebas metrológicas iniciales
                            Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.black87.withOpacity(0.2)
                                    : Colors.black54.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              padding: const EdgeInsets.all(16.0),
                              child: SingleChildScrollView(
                                child: Column(
                                  children: [
                                    PruebasMetrologicasWidget(
                                      pruebas: _model.pruebasIniciales,
                                      isInicial: true,
                                      onChanged: () => setState(() {}),
                                      getD1FromDatabase: _getD1FromDatabase,
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Página 2: Estado general del instrumento
                            Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.black87.withOpacity(0.2)
                                    : Colors.black54.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              padding: const EdgeInsets.all(16.0),
                              child: SingleChildScrollView(
                                child: Column(
                                  children: [
                                    EstadoGeneralWidget(
                                      campos: _model.camposEstado,
                                      controller: _controller,
                                      onFieldChanged: () => setState(() {}),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Página 3: Pruebas finales
                            Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.black87.withOpacity(0.2)
                                    : Colors.black54.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              padding: const EdgeInsets.all(16.0),
                              child: SingleChildScrollView(
                                child: Column(
                                  children: [
                                    PruebasMetrologicasWidget(
                                      pruebas: _model.pruebasFinales,
                                      isInicial: false,
                                      onChanged: () => setState(() {}),
                                      getD1FromDatabase: _getD1FromDatabase,
                                    ),
                                    const SizedBox(height: 20.0),
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        _controller.copiarPruebasInicialesAFinales();
                                        setState(() {});
                                        _showSnackBar(context, 'Datos copiados de pruebas iniciales a finales');
                                      },
                                      icon: const Icon(Icons.content_copy, color: Colors.white),
                                      label: const Text('COPIAR DE PRUEBAS INICIALES'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ESTADO FINAL DE LA BALANZA (fuera del PageView)
                      if (_currentPage == 2) ...[
                        const SizedBox(height: 20.0),
                        const Text(
                          'ESTADO FINAL DE LA BALANZA',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFf5b041),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20.0),
                        TextFormField(
                          onChanged: (value) => _model.comentarioGeneral = value,
                          decoration: _buildInputDecoration('Comentario General'),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 20.0),
                        DropdownButtonFormField<String>(
                          value: _model.recomendacion.isEmpty ? null : _model.recomendacion,
                          decoration: _buildInputDecoration('Recomendación'),
                          items: [
                            'Diagnostico',
                            'Mnt Preventivo Regular',
                            'Mnt Preventivo Avanzado',
                            'Mnt Correctivo',
                            'Ajustes Metrológicos',
                            'Calibración',
                            'Sin recomendación'
                          ].map((String value) => DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          )).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _model.recomendacion = newValue ?? '';
                            });
                          },
                        ),
                        const SizedBox(height: 20.0),
                        DropdownButtonFormField<String>(
                          value: _model.estadoFisico.isEmpty ? null : _model.estadoFisico,
                          decoration: _buildInputDecoration('Físico'),
                          items: ['Bueno', 'Aceptable', 'Malo', 'No aplica']
                              .map((String value) => DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          )).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _model.estadoFisico = newValue ?? '';
                            });
                          },
                        ),
                        const SizedBox(height: 20.0),
                        DropdownButtonFormField<String>(
                          value: _model.estadoOperacional.isEmpty ? null : _model.estadoOperacional,
                          decoration: _buildInputDecoration('Operacional'),
                          items: ['Bueno', 'Aceptable', 'Malo', 'No aplica']
                              .map((String value) => DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          )).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _model.estadoOperacional = newValue ?? '';
                            });
                          },
                        ),
                        const SizedBox(height: 20.0),
                        DropdownButtonFormField<String>(
                          value: _model.estadoMetrologico.isEmpty ? null : _model.estadoMetrologico,
                          decoration: _buildInputDecoration('Metrológico'),
                          items: ['Bueno', 'Aceptable', 'Malo', 'No aplica']
                              .map((String value) => DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          )).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _model.estadoMetrologico = newValue ?? '';
                            });
                          },
                        ),
                        const SizedBox(height: 20.0),
                        TextFormField(
                          readOnly: true,
                          onChanged: (value) => _model.horaFin = value,
                          decoration: _buildInputDecoration(
                            'Hora Final del Servicio',
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.access_time),
                              onPressed: () {
                                final ahora = DateTime.now();
                                final horaFormateada = DateFormat('HH:mm:ss').format(ahora);
                                setState(() {
                                  _model.horaFin = horaFormateada;
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info,
                                color: isDarkMode ? Colors.white70 : Colors.black54,
                                size: 16.0,
                              ),
                              const SizedBox(width: 8.0),
                              Expanded(
                                child: Text(
                                  'Para registrar la hora final del servicio debe dar click al icono del reloj, este obtendra la hora del sistema, una vez registrado este dato no se podra modificar.',
                                  style: TextStyle(
                                    fontSize: 12.0,
                                    color: isDarkMode ? Colors.white70 : Colors.black54,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20.0),
                        Row(
                          children: [
                            Expanded(
                              child: ValueListenableBuilder<bool>(
                                valueListenable: _isSaveButtonPressed,
                                builder: (context, isSaving, child) {
                                  return ElevatedButton(
                                    onPressed: isSaving
                                        ? null
                                        : () async {
                                      if (_formKey.currentState!.validate()) {
                                        _isSaveButtonPressed.value = true;
                                        FocusScope.of(context).unfocus();
                                        await _controller.saveData(context);
                                        _isSaveButtonPressed.value = false;
                                        _isDataSaved.value = true;
                                      }
                                    },
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
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        ),
                                        SizedBox(width: 10),
                                        Text('Guardando...', style: TextStyle(fontSize: 16)),
                                      ],
                                    )
                                        : const Text('GUARDAR DATOS'),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ValueListenableBuilder<bool>(
                                valueListenable: _isDataSaved,
                                builder: (context, isSaved, child) {
                                  return ElevatedButton(
                                    onPressed: isSaved
                                        ? () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => FinServicioMntPrvStilScreen(
                                            sessionId: widget.sessionId,
                                            secaValue: widget.secaValue,
                                            codMetrica: widget.codMetrica,
                                            nReca: widget.nReca,
                                          ),
                                        ),
                                      );
                                    }
                                        : null,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isSaved ? const Color(0xFF167D1D) : Colors.grey,
                                    ),
                                    child: const Text('SIGUIENTE'),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20.0),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: ValueListenableBuilder<bool>(
          valueListenable: _isFabVisible,
          builder: (context, isVisible, child) {
            return AnimatedOpacity(
              opacity: isVisible ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: child,
            );
          },
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
                onTap: () => _showBalanzaInfo(context, balanza),
              ),
            ],
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }

  void _showBalanzaInfo(BuildContext context, dynamic balanza) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                const Text('Información de la balanza', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                if (balanza != null) ...[
                  _buildDetailContainer('Código Métrica', balanza.cod_metrica, Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black, Colors.grey),
                  _buildDetailContainer('Unidades', balanza.unidad.toString(), Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black, Colors.grey),
                  _buildDetailContainer('pmax1', balanza.cap_max1, Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black, Colors.grey),
                  _buildDetailContainer('d1', balanza.d1.toString(), Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black, Colors.grey),
                  _buildDetailContainer('e1', balanza.e1.toString(), Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black, Colors.grey),
                  _buildDetailContainer('dec1', balanza.dec1.toString(), Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black, Colors.grey),
                  _buildDetailContainer('pmax2', balanza.cap_max2, Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black, Colors.grey),
                  _buildDetailContainer('d2', balanza.d2.toString(), Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black, Colors.grey),
                  _buildDetailContainer('e2', balanza.e2.toString(), Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black, Colors.grey),
                  _buildDetailContainer('dec2', balanza.dec2.toString(), Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black, Colors.grey),
                  _buildDetailContainer('pmax3', balanza.cap_max3, Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black, Colors.grey),
                  _buildDetailContainer('d3', balanza.d3.toString(), Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black, Colors.grey),
                  _buildDetailContainer('e3', balanza.e3.toString(), Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black, Colors.grey),
                  _buildDetailContainer('dec3', balanza.dec3.toString(), Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black, Colors.grey),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}