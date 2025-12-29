// ignore_for_file: unused_element, library_private_types_in_public_api, deprecated_member_use

import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';

class UltServiciosScreen extends StatefulWidget {
  const UltServiciosScreen({super.key});

  @override
  _UltServiciosScreenState createState() => _UltServiciosScreenState();
}

class _UltServiciosScreenState extends State<UltServiciosScreen> {
  List<FileSystemEntity> csvFiles = [];

  bool isLoading = true;
  final Set<String> _loadedPaths = {};
  String _searchQuery = '';
  String? _customFolderPath;

  @override
  void initState() {
    super.initState();
    _loadCustomPath().then((_) => _loadCSVFiles());
    _loadCSVFiles();
  }

  Future<void> _requestPermissions() async {
    final status = await Permission.manageExternalStorage.request();
    if (!status.isGranted) {
      throw Exception("Permiso denegado");
    }
  }

  Future<void> _selectFolderAndLoadCSVs() async {
    try {
      await _requestPermissions();

      String? selectedDir = await FilePicker.platform
          .getDirectoryPath(dialogTitle: 'Selecciona carpeta con CSVs');

      if (selectedDir == null) return;

      final directory = Directory(selectedDir);
      if (!await directory.exists()) {
        _showSnackBar('La carpeta seleccionada no existe.', isError: true);
        return;
      }

      final files = await directory.list().toList();
      final csvFilesFromPicker = files
          .where((f) => f is File && f.path.toLowerCase().endsWith('.csv'))
          .toList();

      setState(() {
        csvFiles = [
          ...csvFiles.where((f) => !_loadedPaths.contains(f.path)),
          ...csvFilesFromPicker.where((f) => !_loadedPaths.contains(f.path)),
        ];
        _loadedPaths.addAll(csvFilesFromPicker.map((f) => f.path));
        csvFiles.sort((a, b) => File(b.path)
            .lastModifiedSync()
            .compareTo(File(a.path).lastModifiedSync()));
      });
    } catch (e) {
      _showSnackBar('Error al acceder a la carpeta: ${e.toString()}',
          isError: true);
    }
  }

  Future<void> _loadCustomPath() async {
    final prefs = await SharedPreferences.getInstance();
    _customFolderPath = prefs.getString('custom_csv_folder');
  }

  Future<void> _saveCustomPath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('custom_csv_folder', path);
  }

  Future<void> _pickCustomFolder() async {
    String? selectedDir = await FilePicker.platform
        .getDirectoryPath(dialogTitle: 'Selecciona carpeta con CSVs');
    if (selectedDir != null) {
      setState(() {
        _customFolderPath = selectedDir;
      });
      await _saveCustomPath(selectedDir);
      _loadCSVFiles();
    }
  }

  Future<void> _loadCSVFiles() async {
    setState(() => isLoading = true);
    _loadedPaths.clear();

    try {
      // 1. Directorio interno de la app
      final internalDir = await getApplicationSupportDirectory();
      final internalCsvDir = Directory('${internalDir.path}/csv_servicios');

      // 2. Directorio de descargas del dispositivo
      final downloadsDir = await getDownloadsDirectory();

      List<FileSystemEntity> allFiles = [];

      // Cargar archivos del directorio interno
      if (await internalCsvDir.exists()) {
        final internalFiles = await internalCsvDir.list().toList();
        allFiles.addAll(
            internalFiles.where((f) => f.path.toLowerCase().endsWith('.csv')));
      }

      // Cargar archivos del directorio de descargas
      if (downloadsDir != null) {
        final downloadsFiles = await downloadsDir.list().toList();
        allFiles.addAll(downloadsFiles.where((f) =>
            f.path.toLowerCase().endsWith('.csv') &&
            path.basename(f.path).startsWith('calibracion_')));
      }

      // 3. Carpeta personalizada seleccionada por el usuario
      if (_customFolderPath != null) {
        final customDir = Directory(_customFolderPath!);
        if (await customDir.exists()) {
          final customFiles = await customDir.list().toList();
          allFiles.addAll(
              customFiles.where((f) => f.path.toLowerCase().endsWith('.csv')));
        }
      }

      setState(() {
        csvFiles = allFiles
            .where((file) => !_loadedPaths.contains(file.path))
            .toList();

        // Eliminar duplicados y ordenar por fecha
        csvFiles = csvFiles.toSet().toList();
        csvFiles.sort((a, b) => File(b.path)
            .lastModifiedSync()
            .compareTo(File(a.path).lastModifiedSync()));

        _loadedPaths.addAll(csvFiles.map((f) => f.path));
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      _showSnackBar('Error al cargar archivos: ${e.toString()}', isError: true);
    }
  }

  Future<void> _openFile(FileSystemEntity file) async {
    try {
      final result = await OpenFilex.open(file.path);
      if (result.type != ResultType.done && mounted) {
        _showSnackBar('No se pudo abrir el archivo', isError: true);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error al abrir archivo: ${e.toString()}', isError: true);
      }
    }
  }

  Future<void> _deleteFile(FileSystemEntity file) async {
    final fileName = path.basename(file.path);

    final bool confirmado = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('CONFIRMAR ELIMINACIÓN',
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                  '¿Está seguro que desea eliminar permanentemente el archivo:'),
              const SizedBox(height: 8),
              Text(fileName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.error,
                  )),
              const SizedBox(height: 8),
              const Text('Esta acción no se puede deshacer.',
                  style: TextStyle(fontSize: 12)),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Eliminar'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmado == true && mounted) {
      try {
        await file.delete();
        _showSnackBar('Archivo "$fileName" eliminado');
        _loadCSVFiles();
      } catch (e) {
        _showSnackBar('Error al eliminar: ${e.toString()}', isError: true);
      }
    }
  }

  Future<void> _shareFile(FileSystemEntity file) async {
    try {
      await Share.shareXFiles([XFile(file.path)],
          text:
              'Compartiendo registro de calibración: ${path.basename(file.path)}');
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error al compartir archivo: ${e.toString()}',
            isError: true);
      }
    }
  }

  Future<void> _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) _showSnackBar('Nombre de archivo copiado al portapapeles');
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

  List<FileSystemEntity> get _filteredFiles {
    if (_searchQuery.isEmpty) return csvFiles;
    return csvFiles
        .where((file) => path
            .basename(file.path)
            .toLowerCase()
            .contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final iconColor = isDarkMode ? Colors.white70 : Colors.black54;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 70,
        title: Text(
          'HISTORIAL',
          style: GoogleFonts.inter(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black,
            fontWeight: FontWeight.w900,
            fontSize: 16.0,
          ),
        ),
        backgroundColor: isDarkMode ? Colors.transparent : Colors.white,
        elevation: 0,
        flexibleSpace: isDarkMode ? _buildBlurBackground() : null,
        iconTheme: IconThemeData(color: textColor),
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.folder_copy_rounded),
            tooltip: 'Seleccionar carpeta',
            onPressed: _selectFolderAndLoadCSVs,
          ),
          IconButton(
            icon: Icon(Icons.refresh_outlined, color: textColor),
            onPressed: _loadCSVFiles,
            tooltip: 'Actualizar lista',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar archivos...',
                prefixIcon: Icon(Icons.search, color: iconColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
        ),
      ),
      body: _buildBodyContent(isDarkMode, textColor),
    );
  }

  Widget _buildBlurBackground() {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: Container(color: Colors.black.withOpacity(0.5)),
      ),
    );
  }

  Widget _buildBodyContent(bool isDarkMode, Color textColor) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_filteredFiles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_off, size: 50, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty
                  ? 'No hay registros de servicios disponibles'
                  : 'No se encontraron archivos con "$_searchQuery"',
              style: TextStyle(fontSize: 16, color: textColor),
            ),
            if (_searchQuery.isEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Los archivos exportados aparecerán aquí automáticamente',
                style:
                    TextStyle(fontSize: 12, color: textColor.withOpacity(0.7)),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _filteredFiles.length,
      itemBuilder: (context, index) {
        final file = _filteredFiles[index];
        final fileName = path.basename(file.path);
        final fileDate = File(file.path).lastModifiedSync();
        final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(fileDate);
        final fileSize =
            (File(file.path).lengthSync() / 1024).toStringAsFixed(2);
        final isInternal = file.path.contains('csv_servicios');

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _openFile(file),
            onLongPress: () => _copyToClipboard(fileName),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isInternal ? Icons.storage : Icons.file_download,
                        color: isInternal ? Colors.green : Colors.blue,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          fileName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '$fileSize KB',
                        style: TextStyle(
                          fontSize: 12,
                          color: textColor.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        formattedDate,
                        style: TextStyle(
                          fontSize: 12,
                          color: textColor.withOpacity(0.7),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        isInternal ? 'Interno' : 'Descargas',
                        style: TextStyle(
                          fontSize: 12,
                          color: isInternal ? Colors.green : Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: Icon(Icons.share, size: 20, color: Colors.orange),
                        onPressed: () => _shareFile(file),
                        tooltip: 'Compartir',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      if (isInternal)
                        IconButton(
                          icon: Icon(Icons.delete, size: 20, color: Colors.red),
                          onPressed: () => _deleteFile(file),
                          tooltip: 'Eliminar',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
