import 'package:service_met/screens/soporte/modulos/mnt_prv_regular/mnt_prv_regular_stil/models/mnt_prv_regular_stil_model.dart';
import 'dart:io';

class DiagnosticoModel {
  String sessionId;
  String secaValue;
  String nReca;
  String codMetrica;
  String userName;
  String clienteId;
  String plantaCodigo;

  // Horas
  String horaInicio = '';
  String horaFin = '';

  // Información General
  String reporteFalla = '';
  String evaluacion = '';

  // Comentarios
  List<String?> comentarios = List.filled(10, null);

  // Pruebas Metrológicas (Solo Iniciales para Diagnóstico)
  PruebasMetrologicas pruebasIniciales = PruebasMetrologicas();

  // Fotos (Mapeo de nombre de campo a lista de archivos)
  Map<String, List<File>> fieldPhotos = {};

  DiagnosticoModel({
    required this.sessionId,
    required this.secaValue,
    required this.nReca,
    required this.codMetrica,
    required this.userName,
    required this.clienteId,
    required this.plantaCodigo,
  });

  // Método para añadir fotos
  void addPhoto(String field, File photo) {
    if (!fieldPhotos.containsKey(field)) {
      fieldPhotos[field] = [];
    }
    fieldPhotos[field]!.add(photo);
  }

  // Método para limpiar fotos de un campo
  void clearPhotos(String field) {
    if (fieldPhotos.containsKey(field)) {
      fieldPhotos[field]!.clear();
    }
  }
}
