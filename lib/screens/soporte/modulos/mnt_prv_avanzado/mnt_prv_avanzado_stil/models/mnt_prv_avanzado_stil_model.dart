import 'dart:io';

class MntPrvAvanzadoStilModel {
  final String codMetrica;
  final String sessionId;
  final String secaValue;

  // Campos de estado general
  Map<String, CampoEstadoAvanzadoStil> camposEstado;

  // Pruebas metrológicas
  PruebasMetrologicas pruebasIniciales;
  PruebasMetrologicas pruebasFinales;

  // Estado general
  String comentarioGeneral;
  String recomendacion;
  String estadoFisico;
  String estadoOperacional;
  String estadoMetrologico;
  String horaInicio;
  String horaFin;
  String fechaProxServicio;

  MntPrvAvanzadoStilModel({
    required this.codMetrica,
    required this.sessionId,
    required this.secaValue,
    required this.camposEstado,
    PruebasMetrologicas? pruebasIniciales,
    PruebasMetrologicas? pruebasFinales,
    this.comentarioGeneral = '',
    this.recomendacion = '',
    this.estadoFisico = '',
    this.estadoOperacional = '',
    this.estadoMetrologico = '',
    this.horaInicio = '',
    this.horaFin = '',
    this.fechaProxServicio = '',
  })  : pruebasIniciales = pruebasIniciales ?? PruebasMetrologicas(),
        pruebasFinales = pruebasFinales ?? PruebasMetrologicas();

  // Método para copiar pruebas iniciales a finales
  void copiarPruebasInicialesAFinales() {
    pruebasFinales = PruebasMetrologicas.fromOther(pruebasIniciales);
  }

  // Método para resetear el modelo
  void reset() {
    camposEstado.forEach((key, value) {
      value.initialValue = '4 No aplica';
      value.solutionValue = 'No aplica';
      value.comentario = 'Sin comentario';
      value.fotos.clear();
    });

    pruebasIniciales = PruebasMetrologicas();
    pruebasFinales = PruebasMetrologicas();

    comentarioGeneral = '';
    recomendacion = '';
    estadoFisico = '';
    estadoOperacional = '';
    estadoMetrologico = '';
    horaInicio = '';
    horaFin = '';
    fechaProxServicio = '';
  }
}

class CampoEstadoAvanzadoStil {
  String initialValue;
  String solutionValue;
  String comentario;
  List<File> fotos;

  CampoEstadoAvanzadoStil({
    this.initialValue = '4 No aplica',
    this.solutionValue = 'No aplica',
    this.comentario = 'Sin comentario',
    List<File>? fotos,
  }) : fotos = fotos ?? [];

  // Método para agregar foto
  void agregarFoto(File foto) {
    fotos.add(foto);
  }

  // Método para eliminar foto
  void eliminarFoto(int index) {
    if (index >= 0 && index < fotos.length) {
      fotos.removeAt(index);
    }
  }

  // Método para limpiar fotos
  void limpiarFotos() {
    fotos.clear();
  }
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
