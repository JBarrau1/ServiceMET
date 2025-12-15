import 'package:service_met/screens/soporte/modulos/mnt_prv_regular/mnt_prv_regular_stil/models/mnt_prv_regular_stil_model.dart';
import 'dart:io';

class InspeccionItem {
  String estado; // Bueno, Malo, Regular, No aplica
  String? solucion; // Reparado, Cambiado, Ajustado, etc.
  String? comentario;
  List<File> fotos;

  InspeccionItem({
    this.estado = 'Bueno',
    this.solucion,
    this.comentario,
    List<File>? fotos,
  }) : fotos = fotos ?? [];
}

class MntCorrectivoModel {
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

  // Comentarios Finales
  List<String?> comentarios = List.filled(10, null);

  // Pruebas Metrológicas
  PruebasMetrologicas pruebasIniciales =
      PruebasMetrologicas(linealidad: Linealidad());
  PruebasMetrologicas pruebasFinales =
      PruebasMetrologicas(linealidad: Linealidad());

  // Inspección Visual y Entorno
  // Map de 'Label' -> InspeccionItem
  Map<String, InspeccionItem> inspeccionItems = {};

  // Constructor
  MntCorrectivoModel({
    required this.sessionId,
    required this.secaValue,
    required this.nReca,
    required this.codMetrica,
    required this.userName,
    required this.clienteId,
    required this.plantaCodigo,
  }) {
    _initInspeccionItems();
  }

  void _initInspeccionItems() {
    final labels = [
      'Vibración',
      'Polvo',
      'Temperatura',
      'Humedad',
      'Mesada',
      'Iluminación',
      'Limpieza de Fosa',
      'Estado de Drenaje',
      'Carcasa',
      'Teclado Fisico',
      'Display Fisico',
      'Fuente de poder',
      'Bateria operacional',
      'Bracket',
      'Teclado Operativo',
      'Display Operativo',
      'Contector de celda',
      'Bateria de memoria',
      'Limpieza general',
      'Golpes al terminal',
      'Nivelacion',
      'Limpieza receptor',
      'Golpes al receptor de carga',
      'Encendido',
      'Limitador de movimiento',
      'Suspensión',
      'Limitador de carga',
      'Celda de carga',
      'Tapa de caja sumadora',
      'Humedad Interna',
      'Estado de prensacables',
      'Estado de borneas'
    ];

    for (var label in labels) {
      inspeccionItems[label] = InspeccionItem();
    }
  }

  // Helper para fotos de cualquier campo (metrológico o inspección)
  // En MntCorrectivo, las fotos de inspección van dentro de InspeccionItem.
  // Las fotos de excentricidad van en el objeto Excentricidad (path).
  // Pero necesitamos un método unificado para agregarlas si usamos un controller genérico.
}
