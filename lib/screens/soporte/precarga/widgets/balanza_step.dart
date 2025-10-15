// widgets/balanza_step.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../precarga_controller.dart';

class BalanzaStep extends StatefulWidget {
  final Map<String, TextEditingController> balanzaControllers;
  final TextEditingController nRecaController;
  final TextEditingController stickerController;

  const BalanzaStep({
    Key? key,
    required this.balanzaControllers,
    required this.nRecaController,
    required this.stickerController,
    required String secaValue,
    required String sessionId,
    required String selectedPlantaCodigo,
    required String selectedCliente, required bool loadFromSharedPreferences,
  }) : super(key: key);

  @override
  State<BalanzaStep> createState() => _BalanzaStepState();
}

class _BalanzaStepState extends State<BalanzaStep> {
  @override
  void initState() {
    super.initState();
    // Actualizar el código métrica cuando se selecciona una balanza
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = Provider.of<PrecargaControllerSop>(context, listen: false);
      if (controller.selectedBalanza != null) {
        _fillBalanzaData(controller.selectedBalanza!);
      }
    });
  }

  void _fillBalanzaData(Map<String, dynamic> balanza) {
    widget.balanzaControllers['cod_metrica']?.text = balanza['cod_metrica']?.toString() ?? '';
    widget.balanzaControllers['categoria_balanza']?.text = balanza['categoria']?.toString() ?? '';
    widget.balanzaControllers['cod_int']?.text = balanza['cod_interno']?.toString() ?? '';
    widget.balanzaControllers['tipo_equipo']?.text = balanza['tipo_instrumento']?.toString() ?? '';
    widget.balanzaControllers['marca']?.text = balanza['marca']?.toString() ?? '';
    widget.balanzaControllers['modelo']?.text = balanza['modelo']?.toString() ?? '';
    widget.balanzaControllers['serie']?.text = balanza['serie']?.toString() ?? '';
    widget.balanzaControllers['unidades']?.text = balanza['unidad']?.toString() ?? '';
    widget.balanzaControllers['ubicacion']?.text = balanza['ubicacion']?.toString() ?? '';

    // Datos de rangos
    widget.balanzaControllers['cap_max1']?.text = balanza['cap_max1']?.toString() ?? '';
    widget.balanzaControllers['d1']?.text = balanza['d1']?.toString() ?? '';
    widget.balanzaControllers['e1']?.text = balanza['e1']?.toString() ?? '';
    widget.balanzaControllers['dec1']?.text = balanza['dec1']?.toString() ?? '';

    widget.balanzaControllers['cap_max2']?.text = balanza['cap_max2']?.toString() ?? '0';
    widget.balanzaControllers['d2']?.text = balanza['d2']?.toString() ?? '0';
    widget.balanzaControllers['e2']?.text = balanza['e2']?.toString() ?? '0';
    widget.balanzaControllers['dec2']?.text = balanza['dec2']?.toString() ?? '0';

    widget.balanzaControllers['cap_max3']?.text = balanza['cap_max3']?.toString() ?? '0';
    widget.balanzaControllers['d3']?.text = balanza['d3']?.toString() ?? '0';
    widget.balanzaControllers['e3']?.text = balanza['e3']?.toString() ?? '0';
    widget.balanzaControllers['dec3']?.text = balanza['dec3']?.toString() ?? '0';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PrecargaControllerSop>(
      builder: (context, controller, child) {
        return Column(
          children: [
            // Título
            Text(
              'IDENTIFICACIÓN DE BALANZA',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : const Color(0xFF2C3E50),
              ),
            ).animate().fadeIn(duration: 600.ms),

            const SizedBox(height: 30),

            // Botones de selección de balanza
            _buildBalanzaSelectionButtons(controller),

            const SizedBox(height: 30),

            // Información de la balanza seleccionada o formulario para nueva
            if (controller.selectedBalanza != null || controller.isNewBalanza)
              _buildBalanzaForm(controller),

            const SizedBox(height: 30),

            // Campos RECA y Sticker
            _buildRecaAndStickerFields(),

            const SizedBox(height: 30),

            // Sección de fotografías
            _buildPhotoSection(controller),
          ],
        );
      },
    );
  }

  Widget _buildBalanzaSelectionButtons(PrecargaControllerSop controller) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _showBalanzasDialog(controller),
            icon: const Icon(Icons.search),
            label: const Text('Ver Balanzas'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF326677),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              controller.createNewBalanza();
              _initializeNewBalanzaFields(controller);
            },
            icon: const Icon(Icons.add),
            label: const Text('Nueva Balanza'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF327734),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),

            ),
          ),
        ),
      ],
    ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.3);
  }

  void _initializeNewBalanzaFields(PrecargaControllerSop controller) {
    // Inicializar campos para nueva balanza
    widget.balanzaControllers['cod_metrica']?.text = controller.selectedBalanza?['cod_metrica'] ?? '';
    widget.balanzaControllers['cap_max2']?.text = '0';
    widget.balanzaControllers['d2']?.text = '0';
    widget.balanzaControllers['e2']?.text = '0';
    widget.balanzaControllers['dec2']?.text = '0';
    widget.balanzaControllers['cap_max3']?.text = '0';
    widget.balanzaControllers['d3']?.text = '0';
    widget.balanzaControllers['e3']?.text = '0';
    widget.balanzaControllers['dec3']?.text = '0';
  }

  Widget _buildBalanzaForm(PrecargaControllerSop controller) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            controller.isNewBalanza ? 'NUEVA BALANZA' : 'BALANZA SELECCIONADA',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: controller.isNewBalanza ? Colors.green[700] : Colors.blue[700],
            ),
          ),

          const SizedBox(height: 20),

          // Código métrica (solo lectura)
          _buildTextField(
            controller: widget.balanzaControllers['cod_metrica']!,
            label: 'Código Métrica',
            readOnly: true,
            prefixIcon: Icons.qr_code,
          ),

          const SizedBox(height: 16),

          // Categoría
          _buildCategoriaField(),

          const SizedBox(height: 16),

          // Código interno
          _buildTextField(
            controller: widget.balanzaControllers['cod_int']!,
            label: 'Código Interno',
            prefixIcon: Icons.tag,
            readOnly: false, // AGREGAR ESTA LÍNEA
          ),

          const SizedBox(height: 16),

          // Tipo de equipo - Dropdown
          _buildTipoEquipoField(controller),

          const SizedBox(height: 16),

          // Marca - Dropdown
          _buildMarcaField(controller),

          const SizedBox(height: 16),

          // Modelo
          _buildTextField(
            controller: widget.balanzaControllers['modelo']!,
            label: 'Modelo',
            prefixIcon: Icons.precision_manufacturing,
            readOnly: false, // AGREGAR ESTA LÍNEA
          ),

          const SizedBox(height: 16),

          // Serie
          _buildTextField(
            controller: widget.balanzaControllers['serie']!,
            label: 'Serie',
            prefixIcon: Icons.confirmation_number,
            readOnly: false, // AGREGAR ESTA LÍNEA
          ),

          const SizedBox(height: 16),

          // Unidad - Dropdown
          _buildUnidadField(controller),

          const SizedBox(height: 16),

          // Ubicación
          _buildTextField(
            controller: widget.balanzaControllers['ubicacion']!,
            label: 'Ubicación',
            prefixIcon: Icons.location_on,
          ),

          const SizedBox(height: 30),

          // Rangos de medición
          _buildRangoSection(),
        ],
      ),
    ).animate(delay: 400.ms).fadeIn().slideY(begin: 0.3);
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    IconData? prefixIcon,
    bool readOnly = false,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: readOnly,
      ),
      readOnly: readOnly,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
    );
  }

  Widget _buildTipoEquipoField(PrecargaControllerSop controller) {
    return TypeAheadField<String>(
      // Opcional: usa tu propio controller (el mismo que ya tienes)
      controller: widget.balanzaControllers['tipo_equipo']!,
      suggestionsCallback: (pattern) async {
        if (pattern.isEmpty) return controller.tiposEquipo;
        return controller.tiposEquipo
            .where((t) => t.toLowerCase().contains(pattern.toLowerCase()))
            .toList();
      },
      // NUEVO en v5: construyes el TextField con el builder
      builder: (context, textController, focusNode) {
        return TextField(
          controller: textController, // ¡usar SIEMPRE el que te pasan!
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: 'Tipo de Equipo',
            prefixIcon: const Icon(Icons.scale),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onChanged: (value) => setState(() {}),
        );
      },
      itemBuilder: (context, suggestion) {
        return Padding(
          padding: const EdgeInsets.all(8),
          child: Text(suggestion),
        );
      },
      // NUEVO nombre (antes onSuggestionSelected)
      onSelected: (suggestion) {
        widget.balanzaControllers['tipo_equipo']!.text = suggestion;
        setState(() {});
      },
      hideOnEmpty: true,
      hideOnLoading: true,
      debounceDuration: const Duration(milliseconds: 300),
    );
  }

  Widget _buildMarcaField(PrecargaControllerSop controller) {
    // Si es balanza existente, mostrar campo de solo lectura
    if (!controller.isNewBalanza) {
      return _buildTextField(
        controller: widget.balanzaControllers['marca']!,
        label: 'Marca',
        readOnly: true,
        prefixIcon: Icons.business,
      );
    }

    // Si es balanza nueva, mostrar TypeAheadField
    return TypeAheadField<String>(
      controller: widget.balanzaControllers['marca']!,
      suggestionsCallback: (pattern) async {
        if (pattern.isEmpty) return controller.marcasBalanzas;
        return controller.marcasBalanzas
            .where((m) => m.toLowerCase().contains(pattern.toLowerCase()))
            .toList();
      },
      builder: (context, textController, focusNode) {
        return TextField(
          controller: textController,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: 'Marca',
            prefixIcon: const Icon(Icons.business),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onChanged: (value) => setState(() {}),
        );
      },
      itemBuilder: (context, suggestion) {
        return Padding(
          padding: const EdgeInsets.all(8),
          child: Text(suggestion),
        );
      },
      onSelected: (suggestion) {
        widget.balanzaControllers['marca']!.text = suggestion;
        setState(() {});
      },
      hideOnEmpty: true,
      hideOnLoading: true,
      debounceDuration: const Duration(milliseconds: 300),
    );
  }

  Widget _buildUnidadField(PrecargaControllerSop controller) {
    // Si es balanza existente, mostrar campo de solo lectura
    if (!controller.isNewBalanza) {
      return _buildTextField(
        controller: widget.balanzaControllers['unidades']!,
        label: 'Unidad',
        readOnly: true,
        prefixIcon: Icons.straighten,
      );
    }

    // Si es balanza nueva, mostrar dropdown
    return DropdownButtonFormField<String>(
      value: widget.balanzaControllers['unidades']!.text.isNotEmpty
          ? widget.balanzaControllers['unidades']!.text
          : null,
      decoration: InputDecoration(
        labelText: 'Unidad',
        prefixIcon: const Icon(Icons.straighten),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      items: controller.unidadesPermitidas.map((String unidad) {
        return DropdownMenuItem<String>(
          value: unidad,
          child: Text(unidad),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          widget.balanzaControllers['unidades']!.text = newValue ?? '';
        });
      },
    );
  }

  Widget _buildRangoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'RANGOS DE MEDICIÓN',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.blue[700],
          ),
        ),

        const SizedBox(height: 20),

        // Rango 1
        _buildRangoCard('RANGO 1', [
          ['cap_max1', 'd1'],
          ['e1', 'dec1'],
        ], Colors.blue),

        const SizedBox(height: 16),

        // Rango 2 (Opcional)
        _buildRangoCard('RANGO 2', [
          ['cap_max2', 'd2'],
          ['e2', 'dec2'],
        ], Colors.orange),

        const SizedBox(height: 16),

        // Rango 3 (Opcional)
        _buildRangoCard('RANGO 3', [
          ['cap_max3', 'd3'],
          ['e3', 'dec3'],
        ], Colors.green),
      ],
    );
  }

  Widget _buildCategoriaField() {
    return DropdownButtonFormField<String>(
      value: widget.balanzaControllers['categoria_balanza']!.text.isNotEmpty
          ? widget.balanzaControllers['categoria_balanza']!.text
          : null,
      decoration: InputDecoration(
        labelText: 'Categoría',
        prefixIcon: const Icon(Icons.category),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      items: const [
        DropdownMenuItem<String>(
          value: 'STAC',
          child: Text('STAC'),
        ),
        DropdownMenuItem<String>(
          value: 'STIL',
          child: Text('STIL'),
        ),
      ],
      onChanged: (String? newValue) {
        setState(() {
          widget.balanzaControllers['categoria_balanza']!.text = newValue ?? '';
        });
      },
    );
  }

  Widget _buildRangoCard(String title, List<List<String>> fields, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 12),
          ...fields.map((row) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: row.map((fieldKey) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _buildTextField(
                    controller: widget.balanzaControllers[fieldKey]!,
                    label: fieldKey.toUpperCase(),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                  ),
                ),
              )).toList(),
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildRecaAndStickerFields() {
    return Row(
      children: [
        Expanded(
          child: _buildTextField(
            controller: widget.nRecaController,
            label: 'N° RECA *',
            prefixIcon: Icons.assignment,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildTextField(
            controller: widget.stickerController,
            label: 'N° Sticker *',
            prefixIcon: Icons.local_offer,
          ),
        ),
      ],
    ).animate(delay: 600.ms).fadeIn().slideX(begin: 0.3);
  }

  Widget _buildPhotoSection(PrecargaControllerSop controller) {
    final photos = controller.balanzaPhotos['identificacion'] ?? <File>[];
    final fotoPathSeleccionada = controller.baseFotoPath != null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: controller.fotosTomadas ? Colors.green[300]! : Colors.grey[300]!,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Text(
            'FOTOGRAFÍAS DE IDENTIFICACIÓN',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: controller.fotosTomadas ? Colors.green[700] : Colors.grey[600],
            ),
          ),

          const SizedBox(height: 10),

          Text(
            'Máximo 5 fotos (${photos.length}/5)',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),

          const SizedBox(height: 20),

          // Mostrar estado de la ubicación seleccionada
          if (fotoPathSeleccionada)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green[600], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ubicación seleccionada:',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: Colors.green[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          controller.baseFotoPath!,
                          style: GoogleFonts.robotoMono(
                            fontSize: 10,
                            color: Colors.green[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // Botón para tomar foto (deshabilitado si no hay carpeta seleccionada)
          ElevatedButton.icon(
            onPressed: photos.length < 5
                ? () async {
              try {
                await controller.takePhoto();

                final currentCount = controller.balanzaPhotos['identificacion']?.length ?? 0;
                final savedPath = controller.baseFotoPath;

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.check_circle,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Foto guardada ($currentCount/5)',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        if (savedPath != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            '📁 $savedPath',
                            style: GoogleFonts.robotoMono(fontSize: 10),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 3),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error al tomar foto: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
                : null,
            icon: const Icon(Icons.camera_alt),
            label: const Text('Tomar Foto'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFc0101a),
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey[400],
            ),
          ),

          const SizedBox(height: 20),

          // Grid de fotos
          if (photos.isNotEmpty)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1,
              ),
              itemCount: photos.length,
              itemBuilder: (context, index) {
                final photo = photos[index];
                return GestureDetector(
                  onTap: () => _showFullScreenPhoto(photo),
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            photo,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () {
                            controller.removePhoto(photo);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Foto eliminada'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          },
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 4,
                        left: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${index + 1}/5',
                            style: GoogleFonts.robotoMono(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    ).animate(delay: 700.ms).fadeIn().slideY(begin: 0.3);
  }

  void _showBalanzasDialog(PrecargaControllerSop controller) {
    final TextEditingController searchController = TextEditingController();
    List<Map<String, dynamic>> filteredBalanzas = controller.balanzas;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                'BALANZAS DISPONIBLES',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: 500,
                child: Column(
                  children: [
                    // Campo de búsqueda
                    TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        labelText: 'Buscar balanza',
                        hintText: 'Cod. Métrica, Cod. Interno o Serie',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: searchController.text.isNotEmpty
                            ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            searchController.clear();
                            setDialogState(() {
                              filteredBalanzas = controller.balanzas;
                            });
                          },
                        )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onChanged: (value) {
                        setDialogState(() {
                          if (value.isEmpty) {
                            filteredBalanzas = controller.balanzas;
                          } else {
                            filteredBalanzas = controller.balanzas.where((balanza) {
                              final codMetrica = balanza['cod_metrica']?.toString().toLowerCase() ?? '';
                              final codInterno = balanza['cod_interno']?.toString().toLowerCase() ?? '';
                              final serie = balanza['serie']?.toString().toLowerCase() ?? '';
                              final searchLower = value.toLowerCase();

                              return codMetrica.contains(searchLower) ||
                                  codInterno.contains(searchLower) ||
                                  serie.contains(searchLower);
                            }).toList();
                          }
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    // Lista de balanzas filtradas
                    Expanded(
                      child: filteredBalanzas.isEmpty
                          ? const Center(
                        child: Text('No se encontraron balanzas'),
                      )
                          : ListView.builder(
                        itemCount: filteredBalanzas.length,
                        itemBuilder: (context, index) {
                          final balanza = filteredBalanzas[index];
                          final estadoCalibacion = balanza['estado_calibracion'] ?? 'sin_registro';
                          final tieneRegistro = balanza['tiene_registro'] ?? false;

                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: estadoCalibacion == 'calibrada'
                                    ? Colors.green[300]!
                                    : estadoCalibacion == 'no_calibrada'
                                    ? Colors.orange[300]!
                                    : Colors.grey[300]!,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ListTile(
                              leading: _buildEstadoIcon(estadoCalibacion),
                              title: Text(
                                'CÓDIGO: ${balanza['cod_metrica']}',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Cod. Interno: ${balanza['cod_interno'] ?? 'N/A'}'),
                                  Text('Serie: ${balanza['serie'] ?? 'N/A'}'),
                                  Text('Marca: ${balanza['marca'] ?? 'N/A'}'),
                                  Text('Modelo: ${balanza['modelo'] ?? 'N/A'}'),
                                  if (tieneRegistro)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        estadoCalibacion == 'calibrada'
                                            ? '✓ Balanza Calibrada'
                                            : '⚠ Requiere Concluir',
                                        style: TextStyle(
                                          color: estadoCalibacion == 'calibrada'
                                              ? Colors.green[700]
                                              : Colors.orange[700],
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                              onTap: () {
                                // Mostrar alerta si la balanza no está calibrada
                                if (tieneRegistro && estadoCalibacion == 'no_calibrada') {
                                  _showCalibrationWarningDialog(balanza, controller);
                                } else {
                                  controller.selectBalanza(balanza);
                                  _fillBalanzaData(balanza);
                                  Navigator.pop(context);
                                }
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    searchController.dispose();
                    Navigator.pop(context);
                  },
                  child: const Text('Cerrar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildEstadoIcon(String estado) {
    switch (estado) {
      case 'calibrada':
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green[100],
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check_circle,
            color: Colors.green[700],
            size: 24,
          ),
        );
      case 'no_calibrada':
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.orange[100],
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.warning,
            color: Colors.orange[700],
            size: 24,
          ),
        );
      default:
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.help_outline,
            color: Colors.grey[700],
            size: 24,
          ),
        );
    }
  }

  void _showCalibrationWarningDialog(Map<String, dynamic> balanza, PrecargaControllerSop controller) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          icon: Icon(
            Icons.warning_amber_rounded,
            color: Colors.orange[700],
            size: 48,
          ),
          title: Text(
            'ADVERTENCIA',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: Colors.orange[700],
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'La balanza ${balanza['cod_metrica']} tiene un registro pero NO está marcada como "Balanza Calibrada".',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 14),
              ),
              const SizedBox(height: 16),
              Text(
                '¿Desea continuar con esta balanza?',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                controller.selectBalanza(balanza);
                _fillBalanzaData(balanza);
                Navigator.pop(context); // Cerrar alerta
                Navigator.pop(context); // Cerrar diálogo de balanzas
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[700],
                foregroundColor: Colors.white,
              ),
              child: const Text('Continuar'),
            ),
          ],
        );
      },
    );
  }

  void _showFullScreenPhoto(File photo) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(10),
          child: InteractiveViewer(
            panEnabled: true,
            minScale: 0.5,
            maxScale: 3.0,
            child: Stack(
              children: [
                Center(
                  child: Image.file(
                    photo,
                    fit: BoxFit.contain,
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}