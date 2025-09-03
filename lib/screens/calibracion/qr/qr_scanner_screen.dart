import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  bool _dialogShown = false;
  bool _torchEnabled = false;
  bool _hasPermission = false;
  bool _isPermissionChecked = false;
  MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  @override
  void initState() {
    super.initState();
    _checkCameraPermission();
  }

  Future<void> _checkCameraPermission() async {
    final status = await Permission.camera.status;
    setState(() {
      _hasPermission = status.isGranted;
      _isPermissionChecked = true;
    });

    if (!_hasPermission) {
      final result = await Permission.camera.request();
      setState(() {
        _hasPermission = result.isGranted;
      });
    }
  }

  void _onDetect(BarcodeCapture capture) {
    if (_dialogShown || !_hasPermission) return;

    final String? code = capture.barcodes.first.rawValue;
    if (code != null && code.isNotEmpty) {
      _dialogShown = true;
      Navigator.pop(context, code);
    }
  }

  void _toggleTorch() {
    setState(() {
      _torchEnabled = !_torchEnabled;
    });
    controller.toggleTorch();
  }

  void _switchCamera() {
    setState(() {
      controller.switchCamera();
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Widget _buildScannerOverlay(BuildContext context) {
    return Stack(
      children: [
        // Marco de escaneo
        Positioned(
          top: MediaQuery.of(context).size.height * 0.25,
          left: MediaQuery.of(context).size.width * 0.15,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.7,
            height: MediaQuery.of(context).size.width * 0.7,
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.green,
                width: 2.0,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        // Esquinas del marco
        _buildCorner(
          context,
          Alignment.topLeft,
          MediaQuery.of(context).size.height * 0.25,
          MediaQuery.of(context).size.width * 0.15,
        ),
        _buildCorner(
          context,
          Alignment.topRight,
          MediaQuery.of(context).size.height * 0.25,
          MediaQuery.of(context).size.width * 0.15,
        ),
        _buildCorner(
          context,
          Alignment.bottomLeft,
          MediaQuery.of(context).size.height * 0.25,
          MediaQuery.of(context).size.width * 0.15,
        ),
        _buildCorner(
          context,
          Alignment.bottomRight,
          MediaQuery.of(context).size.height * 0.25,
          MediaQuery.of(context).size.width * 0.15,
        ),
        // Mensaje de ayuda
        Positioned(
          bottom: MediaQuery.of(context).size.height * 0.15,
          left: 0,
          right: 0,
          child: Center(
            child: Text(
              'Coloca el código QR dentro del marco',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCorner(
      BuildContext context, Alignment alignment, double top, double left) {
    return Positioned(
      top: top,
      left: left,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.7,
        height: MediaQuery.of(context).size.width * 0.7,
        alignment: alignment,
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: Colors.green,
                width: 4.0,
              ),
              left: alignment == Alignment.topLeft ||
                      alignment == Alignment.bottomLeft
                  ? BorderSide(
                      color: Colors.green,
                      width: 4.0,
                    )
                  : BorderSide.none,
              right: alignment == Alignment.topRight ||
                      alignment == Alignment.bottomRight
                  ? BorderSide(
                      color: Colors.green,
                      width: 4.0,
                    )
                  : BorderSide.none,
              bottom: BorderSide(
                color: Colors.green,
                width: 4.0,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isPermissionChecked) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!_hasPermission) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'SCANER QR',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              fontSize: 16.0,
            ),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.camera_alt_rounded, size: 50, color: Colors.red),
              const SizedBox(height: 20),
              Text(
                'Permiso de cámara denegado',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  await openAppSettings();
                  _checkCameraPermission();
                },
                child: const Text('Abrir configuración'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        toolbarHeight: 70,
        title: Text(
          'SCANER QR',
          style: GoogleFonts.inter(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 16.0,
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
        actions: [
          IconButton(
            icon: Icon(_torchEnabled ? Icons.flash_on : Icons.flash_off),
            onPressed: _toggleTorch,
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch),
            onPressed: _switchCamera,
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: _onDetect,
            errorBuilder: (context, error) {
              return Scaffold(
                body: Center(
                    child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 50, color: Colors.red),
                    const SizedBox(height: 20),
                    Text(
                      'Error al iniciar la cámara: ${error.toString()}',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          controller = MobileScannerController(
                            detectionSpeed: DetectionSpeed.normal,
                            facing: CameraFacing.back,
                            torchEnabled: false,
                          );
                        });
                      },
                      child: const Text('Reintentar'),
                    ),
                  ],
                )),
              );
            },
          ),
          _buildScannerOverlay(context),
        ],
      ),
    );
  }
}
