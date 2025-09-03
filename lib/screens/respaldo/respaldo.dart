import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';

class BackupService {
  static Future<List<FileSystemEntity>> getDatabaseFiles() async {
    final databasesDir = await getDatabasesPath();
    final dbDir = Directory(databasesDir);
    return dbDir.existsSync()
        ? dbDir.listSync().cast<FileSystemEntity>()
        : <FileSystemEntity>[];
  }

  static Future<List<FileSystemEntity>> getSoporteTecnicoDatabases() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final soporteTecDir = Directory('${appDir.path}/.soporte_tec');

      if (!soporteTecDir.existsSync()) return [];

      return soporteTecDir
          .listSync()
          .where((file) => file is File && file.path.endsWith('.db'))
          .toList();
    } catch (e) {
      debugPrint('Error al obtener bases de soporte técnico: $e');
      return [];
    }
  }

  static Future<List<FileSystemEntity>> getPrecargaBackups() async {
    try {
      final databasesPath = await getDatabasesPath();
      final backupDir = Directory('$databasesPath/backups');

      if (!backupDir.existsSync()) return [];

      return backupDir
          .listSync()
          .where((file) =>
      file is File &&
          (file.path.endsWith('.db') ||
              file.path.endsWith('.bak') ||
              file.path.endsWith('.sqlite')))
          .toList();
    } catch (e) {
      debugPrint('Error al obtener backups: $e');
      return [];
    }
  }

  static Future<List<FileSystemEntity>> getCsvFiles() async {
    final appDir = await getApplicationDocumentsDirectory();
    return appDir
        .listSync(recursive: true)
        .where((file) => file.path.endsWith('.csv'))
        .toList();
  }

  static Future<bool> copyFileToDirectory(
      String sourcePath, String destinationDir) async {
    try {
      final fileName = sourcePath.split('/').last;
      final destinationPath = '$destinationDir/$fileName';
      await File(sourcePath).copy(destinationPath);
      return true;
    } catch (e) {
      throw Exception('Failed to copy file: $e');
    }
  }
}

class DateTimeAuthService {
  static String generateCurrentPassword() {
    final now = DateTime.now();

    // Formato: DDMMYY-HHMM (ej. 040825-1118 para 04/08/2025 11:18)
    final datePart = '${now.day.toString().padLeft(2, '0')}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.year.toString().substring(2)}';

    final timePart = '${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}';

    return '$datePart-$timePart';
  }

  static bool authenticate(String enteredPassword) {
    final currentPassword = generateCurrentPassword();

    // Aceptar contraseña actual o del minuto anterior por sincronización
    final previousMinute = DateTime.now().subtract(const Duration(minutes: 1));
    final previousPassword = _generatePasswordForDateTime(previousMinute);

    return enteredPassword == currentPassword || enteredPassword == previousPassword;
  }

  static String _generatePasswordForDateTime(DateTime dateTime) {
    final datePart = '${dateTime.day.toString().padLeft(2, '0')}'
        '${dateTime.month.toString().padLeft(2, '0')}'
        '${dateTime.year.toString().substring(2)}';

    final timePart = '${dateTime.hour.toString().padLeft(2, '0')}'
        '${dateTime.minute.toString().padLeft(2, '0')}';

    return '$datePart-$timePart';
  }
}

class RespaldoScreen extends StatefulWidget {
  const RespaldoScreen({super.key});

  @override
  _RespaldoScreenState createState() => _RespaldoScreenState();
}

class _RespaldoScreenState extends State<RespaldoScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();


  bool _isAuthenticated = false;
  bool _isLoading = false;
  bool _isSelectionMode = false;

  List<FileSystemEntity> _databases = [];
  List<FileSystemEntity> _csvFiles = [];
  List<FileSystemEntity> _precargaBackups = [];
  List<FileSystemEntity> _soporteTecDbs = [];

  final Set<FileSystemEntity> _selectedFiles = {};

  @override
  void initState() {
    super.initState();
    if (_isAuthenticated) {
      _loadFiles();
    }
  }

  Future<void> _loadFiles() async {
    setState(() => _isLoading = true);
    try {
      final databases = await BackupService.getDatabaseFiles();
      final csvFiles = await BackupService.getCsvFiles();
      final precargaBackups = await BackupService.getPrecargaBackups();
      final soporteTecDbs = await BackupService.getSoporteTecnicoDatabases();

      setState(() {
        _databases = databases;
        _csvFiles = csvFiles;
        _precargaBackups = precargaBackups;
        _soporteTecDbs = soporteTecDbs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorDialog('Error al cargar archivos', e.toString());
    }
  }

  void _authenticate() {
    if (DateTimeAuthService.authenticate(_passwordController.text)) {
      setState(() => _isAuthenticated = true);
      _loadFiles();
    } else {
      _showErrorDialog(
          'Error de autenticación',
          'Ingreso incorrecto. Por favor, verifica la contraseña ingresada.'
      );
    }
  }

  Future<void> _downloadFile(FileSystemEntity file) async {
    try {
      final selectedDirectory = await FilePicker.platform.getDirectoryPath();
      if (selectedDirectory == null) return;

      final success =
      await BackupService.copyFileToDirectory(file.path, selectedDirectory);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Archivo descargado en: $selectedDirectory')),
        );
      }
    } catch (e) {
      _showErrorDialog('Error al descargar', e.toString());
    }
  }

  Future<void> _downloadSelectedFiles() async {
    try {
      final selectedDirectory = await FilePicker.platform.getDirectoryPath();
      if (selectedDirectory == null) return;

      int successCount = 0;
      for (var file in _selectedFiles) {
        try {
          await BackupService.copyFileToDirectory(file.path, selectedDirectory);
          successCount++;
        } catch (e) {
          debugPrint('Error al copiar ${file.path}: $e');
        }
      }

      setState(() {
        _selectedFiles.clear();
        _isSelectionMode = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                '$successCount archivos descargados en: $selectedDirectory')),
      );
    } catch (e) {
      _showErrorDialog('Error al descargar', e.toString());
    }
  }

  Future<void> _deleteFile(FileSystemEntity file) async {
    try {
      await File(file.path).delete();
      setState(() => _loadFiles());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Archivo eliminado')),
      );
    } catch (e) {
      _showErrorDialog('Error al eliminar', e.toString());
    }
  }

  Future<void> _deleteSelectedFiles() async {
    try {
      for (var file in _selectedFiles) {
        await File(file.path).delete();
      }

      setState(() {
        _loadFiles();
        _selectedFiles.clear();
        _isSelectionMode = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_selectedFiles.length} archivos eliminados')),
      );
    } catch (e) {
      _showErrorDialog('Error al eliminar', e.toString());
    }
  }

  void _toggleFileSelection(FileSystemEntity file) {
    setState(() {
      if (_selectedFiles.contains(file)) {
        _selectedFiles.remove(file);
        if (_selectedFiles.isEmpty) _isSelectionMode = false;
      } else {
        _selectedFiles.add(file);
        _isSelectionMode = true;
      }
    });
  }

  void _showFileOptions(FileSystemEntity file) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('Descargar'),
            onTap: () {
              Navigator.pop(context);
              _downloadFile(file);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete),
            title: const Text('Eliminar'),
            onTap: () {
              Navigator.pop(context);
              _confirmDelete(file);
            },
          ),
        ],
      ),
    );
  }

  void _confirmDelete(FileSystemEntity file) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar archivo'),
        content:
        Text('¿Estás seguro de eliminar ${file.uri.pathSegments.last}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteFile(file);
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteSelected() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar archivos'),
        content: Text(
            '¿Estás seguro de eliminar ${_selectedFiles.length} archivos seleccionados?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteSelectedFiles();
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  List<FileSystemEntity> _filterFiles(
      List<FileSystemEntity> files, String query) {
    if (query.isEmpty) return files;
    return files
        .where((file) => file.path.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  Widget _buildFileList(String title, List<FileSystemEntity> files) {
    if (files.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Text('No hay $title disponibles',
            style: const TextStyle(color: Colors.grey)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$title:',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
        ),
        ...files.map((file) => _buildFileItem(file)),
      ],
    );
  }

  Widget _buildFileItem(FileSystemEntity file) {
    final fileInfo = File(file.path);
    final stat = fileInfo.statSync();
    final modified = DateTime.fromMillisecondsSinceEpoch(
        stat.modified.millisecondsSinceEpoch);
    final isSelected = _selectedFiles.contains(file);

    return ListTile(
      leading: _isSelectionMode
          ? Checkbox(
        value: isSelected,
        onChanged: (_) => _toggleFileSelection(file),
      )
          : Icon(_getFileIcon(file)),
      title: Text(
        file.uri.pathSegments.last,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Text(
        '${_formatBytes(stat.size)} - ${DateFormat('dd/MM/yyyy HH:mm').format(modified)}',
        style: const TextStyle(fontSize: 12),
      ),
      trailing: _isSelectionMode
          ? null
          : IconButton(
        icon: const Icon(Icons.download),
        onPressed: () => _downloadFile(file),
      ),
      onTap: () => _isSelectionMode
          ? _toggleFileSelection(file)
          : _showFileOptions(file),
      onLongPress: () => _toggleFileSelection(file),
    );
  }

  IconData _getFileIcon(FileSystemEntity file) {
    if (file.path.endsWith('.csv')) return Icons.table_chart;
    if (file.path.endsWith('.db')) return Icons.storage;
    return Icons.insert_drive_file;
  }

  String _formatBytes(int bytes, {int decimals = 2}) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    final i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(decimals)} ${suffixes[i]}';
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Buscar archivos...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
        ),
        onChanged: (value) => setState(() {}),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      toolbarHeight: 70,
      title: _isSelectionMode
          ? Text('${_selectedFiles.length} seleccionados')
          : Text(
        'RESPALDO DE DATOS',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w900,
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : Colors.black,
        ),
      ),
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.transparent
          : Colors.white,
      elevation: 0,
      flexibleSpace: Theme.of(context).brightness == Brightness.dark
          ? ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
          child: Container(color: Colors.black.withOpacity(0.1)),
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
      actions: _isSelectionMode
          ? [
        IconButton(
          icon: const Icon(Icons.delete),
          onPressed: _confirmDeleteSelected,
        ),
        IconButton(
          icon: const Icon(Icons.download),
          onPressed: _downloadSelectedFiles,
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => setState(() {
            _selectedFiles.clear();
            _isSelectionMode = false;
          }),
        ),
      ]
          : null,
    );
  }

  InputDecoration _buildInputDecoration(String labelText) {
    return InputDecoration(
      labelText: labelText,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
    );
  }

  Widget _buildAuthScreen() {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'AUTENTICACIÓN REQUERIDA',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 20.0),
            Text(
              'Para acceder a los respaldos de datos, ingresa la contraseña proporcionada por el área de sistemas.',
              textAlign: TextAlign.left,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
              ),
            ),
            const SizedBox(height: 20.0),
            TextField(
              controller: _passwordController,
              decoration: _buildInputDecoration('Ingrese la contraseña'),
              obscureText: false,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _authenticate,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              child: const Text('Ingresar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackupScreen() {
    final filteredDbs = _filterFiles(_databases, _searchController.text);
    final filteredCsvs = _filterFiles(_csvFiles, _searchController.text);
    final filteredBackups = _filterFiles(_precargaBackups, _searchController.text);
    final filteredSoporteTec = _filterFiles(_soporteTecDbs, _searchController.text);

    return Scaffold(
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          _buildSearchField(),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFileList('RESPALDOS DE CALIBRACIÓN', filteredBackups),
                    const SizedBox(height: 20),
                    _buildFileList('BASES DE DATOS PRINCIPALES', filteredDbs),
                    const SizedBox(height: 20),
                    _buildFileList('RESPALDOS DE SOPORTE TÉCNICO', filteredSoporteTec),
                    const SizedBox(height: 20),
                    _buildFileList('ARCHIVOS CSV', filteredCsvs),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAuthenticated) {
      return _buildAuthScreen();
    }

    return _buildBackupScreen();
  }
}