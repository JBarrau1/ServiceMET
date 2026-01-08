// lib/login/models/user_model.dart

class UserModel {
  final String usuario;
  final String nombre1;
  final String apellido1;
  final String apellido2;
  final String pass;
  final String tituloAbr;
  final String estado;
  final String accesoApp; // Nuevo campo

  UserModel({
    required this.usuario,
    required this.nombre1,
    required this.apellido1,
    required this.apellido2,
    required this.pass,
    required this.tituloAbr,
    required this.estado,
    this.accesoApp = '0', // Default a '0' (acceso denegado por defecto)
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      usuario: map['usuario']?.toString() ?? '',
      nombre1: map['nombre1']?.toString() ?? '',
      apellido1: map['apellido1']?.toString() ?? '',
      apellido2: map['apellido2']?.toString() ?? '',
      pass: map['pass']?.toString() ?? '',
      tituloAbr: map['titulo_abr']?.toString() ?? '',
      estado: map['estado']?.toString() ?? '',
      accesoApp: map['acceso_app']?.toString() ?? '0', // Default '0'
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'usuario': usuario,
      'nombre1': nombre1,
      'apellido1': apellido1,
      'apellido2': apellido2,
      'pass': pass,
      'titulo_abr': tituloAbr,
      'estado': estado,
      'acceso_app': accesoApp, // Guardar nuevo campo
      'fecha_guardado': DateTime.now().toIso8601String(),
    };
  }

  String get fullName => '$tituloAbr $nombre1 $apellido1'.trim();

  bool get isActive => estado.toUpperCase() == 'ACTIVO';
}
