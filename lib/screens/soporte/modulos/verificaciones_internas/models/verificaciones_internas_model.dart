import 'dart:io';

class VerificacionesInternasModel {
  final String codMetrica;
  final String sessionId;
  final String secaValue;

  // Pruebas metrológicas
  PruebasMetrologicas pruebasIniciales;
  PruebasMetrologicas pruebasFinales;

  // Reporte y Evaluación
  String reporteFalla;
  String evaluacion;
  String excentricidadEstadoGeneral;
  String repetibilidadEstadoGeneral;
  String linealidadEstadoGeneral;

  // Comentarios (Lista de 10)
  List<ComentarioData> comentarios;

  // Estado general
  String horaInicio;
  String horaFin;

  VerificacionesInternasModel({
    required this.codMetrica,
    required this.sessionId,
    required this.secaValue,
    PruebasMetrologicas? pruebasIniciales,
    PruebasMetrologicas? pruebasFinales,
    this.reporteFalla = '',
    this.evaluacion = '',
    this.excentricidadEstadoGeneral = 'Cumple',
    this.repetibilidadEstadoGeneral = 'Cumple',
    this.linealidadEstadoGeneral = 'Cumple',
    List<ComentarioData>? comentarios,
    this.horaInicio = '',
    this.horaFin = '',
  })  : pruebasIniciales = pruebasIniciales ?? PruebasMetrologicas(),
        pruebasFinales = pruebasFinales ?? PruebasMetrologicas(),
        comentarios = comentarios ?? [];

  // Método para copiar pruebas iniciales a finales
  void copiarPruebasInicialesAFinales() {
    pruebasFinales = PruebasMetrologicas.fromOther(pruebasIniciales);
  }

  // Método para resetear el modelo
  void reset() {
    pruebasIniciales = PruebasMetrologicas();
    pruebasFinales = PruebasMetrologicas();
    reporteFalla = '';
    evaluacion = '';
    excentricidadEstadoGeneral = 'Cumple';
    repetibilidadEstadoGeneral = 'Cumple';
    linealidadEstadoGeneral = 'Cumple';
    comentarios.clear();
    horaInicio = '';
    horaFin = '';
  }
}

class ComentarioData {
  String comentario;
  List<File> fotos;

  ComentarioData({
    this.comentario = '',
    List<File>? fotos,
  }) : fotos = fotos ?? [];
}

class PruebasMetrologicas {
  RetornoCero retornoCero;
  Excentricidad? excentricidad;
  Repetibilidad? repetibilidad;
  Linealidad? linealidad;

  PruebasMetrologicas({
    RetornoCero? retornoCero,
    this.excentricidad,
    this.repetibilidad,
    this.linealidad,
  }) : retornoCero = retornoCero ?? RetornoCero();

  // Constructor de copia
  PruebasMetrologicas.fromOther(PruebasMetrologicas other)
      : retornoCero = RetornoCero.fromOther(other.retornoCero),
        excentricidad = other.excentricidad != null
            ? Excentricidad.fromOther(other.excentricidad!)
            : null,
        repetibilidad = other.repetibilidad != null
            ? Repetibilidad.fromOther(other.repetibilidad!)
            : null,
        linealidad = other.linealidad != null
            ? Linealidad.fromOther(other.linealidad!)
            : null;
}

class RetornoCero {
  String estado;
  String estabilidad;
  String valor;
  String unidad;

  RetornoCero({
    this.estado = '1 Bueno',
    this.estabilidad = '1 Bueno',
    this.valor = '',
    this.unidad = 'kg',
  });

  // Constructor de copia
  RetornoCero.fromOther(RetornoCero other)
      : estado = other.estado,
        estabilidad = other.estabilidad,
        valor = other.valor,
        unidad = other.unidad;
}

class Excentricidad {
  bool activo;
  String? tipoPlataforma;
  String? puntosIndicador;
  String? imagenPath;
  String carga;
  List<PosicionExcentricidad> posiciones;

  Excentricidad({
    this.activo = false,
    this.tipoPlataforma,
    this.puntosIndicador,
    this.imagenPath,
    this.carga = '',
    List<PosicionExcentricidad>? posiciones,
  }) : posiciones = posiciones ?? [];

  // Constructor de copia
  Excentricidad.fromOther(Excentricidad other)
      : activo = other.activo,
        tipoPlataforma = other.tipoPlataforma,
        puntosIndicador = other.puntosIndicador,
        imagenPath = other.imagenPath,
        carga = other.carga,
        posiciones = other.posiciones
            .map((pos) => PosicionExcentricidad.fromOther(pos))
            .toList();
}

class PosicionExcentricidad {
  String posicion;
  String indicacion;
  String retorno;

  PosicionExcentricidad({
    required this.posicion,
    this.indicacion = '',
    this.retorno = '0',
  });

  // Constructor de copia
  PosicionExcentricidad.fromOther(PosicionExcentricidad other)
      : posicion = other.posicion,
        indicacion = other.indicacion,
        retorno = other.retorno;
}

class Repetibilidad {
  bool activo;
  int cantidadCargas;
  int cantidadPruebas;
  List<CargaRepetibilidad> cargas;

  Repetibilidad({
    this.activo = false,
    this.cantidadCargas = 1,
    this.cantidadPruebas = 3,
    List<CargaRepetibilidad>? cargas,
  }) : cargas = cargas ?? [CargaRepetibilidad()];

  // Constructor de copia
  Repetibilidad.fromOther(Repetibilidad other)
      : activo = other.activo,
        cantidadCargas = other.cantidadCargas,
        cantidadPruebas = other.cantidadPruebas,
        cargas = other.cargas
            .map((carga) => CargaRepetibilidad.fromOther(carga))
            .toList();
}

class CargaRepetibilidad {
  String valor;
  List<PruebaRepetibilidad> pruebas;

  CargaRepetibilidad({
    this.valor = '',
    List<PruebaRepetibilidad>? pruebas,
  }) : pruebas = pruebas ?? List.generate(3, (index) => PruebaRepetibilidad());

  // Constructor de copia
  CargaRepetibilidad.fromOther(CargaRepetibilidad other)
      : valor = other.valor,
        pruebas = other.pruebas
            .map((prueba) => PruebaRepetibilidad.fromOther(prueba))
            .toList();
}

class PruebaRepetibilidad {
  String indicacion;
  String retorno;

  PruebaRepetibilidad({
    this.indicacion = '',
    this.retorno = '0',
  });

  // Constructor de copia
  PruebaRepetibilidad.fromOther(PruebaRepetibilidad other)
      : indicacion = other.indicacion,
        retorno = other.retorno;
}

class Linealidad {
  bool activo;
  String ultimaCargaLt;
  String carga;
  String incremento;

  // Campos para Método 2
  String iLsubn;
  String lsubn;
  String io;
  String ltn;

  List<PuntoLinealidad> puntos;

  Linealidad({
    this.activo = false,
    this.ultimaCargaLt = '0',
    this.carga = '',
    this.incremento = '',
    this.iLsubn = '',
    this.lsubn = '',
    this.io = '0',
    this.ltn = '',
    List<PuntoLinealidad>? puntos,
  }) : puntos = puntos ?? [];

  // Constructor de copia
  Linealidad.fromOther(Linealidad other)
      : activo = other.activo,
        ultimaCargaLt = other.ultimaCargaLt,
        carga = other.carga,
        incremento = other.incremento,
        iLsubn = other.iLsubn,
        lsubn = other.lsubn,
        io = other.io,
        ltn = other.ltn,
        puntos = other.puntos
            .map((punto) => PuntoLinealidad.fromOther(punto))
            .toList();
}

class PuntoLinealidad {
  String lt;
  String indicacion;
  String retorno;

  PuntoLinealidad({
    this.lt = '',
    this.indicacion = '',
    this.retorno = '0',
  });

  // Constructor de copia
  PuntoLinealidad.fromOther(PuntoLinealidad other)
      : lt = other.lt,
        indicacion = other.indicacion,
        retorno = other.retorno;
}
