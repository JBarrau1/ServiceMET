import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityBanner extends StatefulWidget {
  const ConnectivityBanner({super.key});

  @override
  _ConnectivityBannerState createState() => _ConnectivityBannerState();
}

class _ConnectivityBannerState extends State<ConnectivityBanner> {
  late Stream<ConnectivityResult> _connectivityStream;
  bool _isConnected = true;

  @override
  void initState() {
    super.initState();
    _connectivityStream = Connectivity().onConnectivityChanged.map(
        (List<ConnectivityResult> results) => results.first); // Adaptar el tipo

    _connectivityStream.listen((ConnectivityResult result) {
      setState(() {
        _isConnected = result != ConnectivityResult.none;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _isConnected ? Colors.green : Colors.red,
      padding: const EdgeInsets.all(8.0),
      child: Center(
        child: Text(
          _isConnected
              ? 'Estas conectado a Internet'
              : 'No tienes conexión a Internet',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
