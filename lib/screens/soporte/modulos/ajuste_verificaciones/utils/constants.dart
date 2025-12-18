class AppConstants {
  // Opciones de plataforma
  static const Map<String, List<String>> platformOptions = {
    'Rectangular': [
      'Rectangular 3 pts - Ind Derecha',
      'Rectangular 3 pts - Ind Izquierda',
      'Rectangular 3 pts - Ind Frontal',
      'Rectangular 3 pts - Ind Atras',
      'Rectangular 5 pts - Ind Derecha',
      'Rectangular 5 pts - Ind Izquierda',
      'Rectangular 5 pts - Ind Frontal',
      'Rectangular 5 pts - Ind Atras'
    ],
    'Circular': [
      'Circular 5 pts - Ind Derecha',
      'Circular 5 pts - Ind Izquierda',
      'Circular 5 pts - Ind Frontal',
      'Circular 5 pts - Ind Atras',
      'Circular 4 pts - Ind Derecha',
      'Circular 4 pts - Ind Izquierda',
      'Circular 4 pts - Ind Frontal',
      'Circular 4 pts - Ind Atras'
    ],
    'Cuadrada': [
      'Cuadrada - Ind Derecha',
      'Cuadrada - Ind Izquierda',
      'Cuadrada - Ind Frontal',
      'Cuadrada - Ind Atras'
    ],
    'Triangular': [
      'Triangular - Ind Izquierda',
      'Triangular - Ind Frontal',
      'Triangular - Ind Atras',
      'Triangular - Ind Derecha'
    ],
    'Báscula de camión': [
      'Caceta de control Atras',
      'Caceta de control Frontal',
      'Caceta de control Izquierda',
      'Caceta de control Derecha'
    ],
  };

  // Imágenes de opciones
  static const Map<String, String> optionImages = {
    'Rectangular 3 pts - Ind Derecha': 'images/Rectangular_3D.png',
    'Rectangular 3 pts - Ind Izquierda': 'images/Rectangular_3I.png',
    'Rectangular 3 pts - Ind Frontal': 'images/Rectangular_3F.png',
    'Rectangular 3 pts - Ind Atras': 'images/Rectangular_3A.png',
    'Rectangular 5 pts - Ind Derecha': 'images/Rectangular_5D.png',
    'Rectangular 5 pts - Ind Izquierda': 'images/Rectangular_5I.png',
    'Rectangular 5 pts - Ind Frontal': 'images/Rectangular_5F.png',
    'Rectangular 5 pts - Ind Atras': 'images/Rectangular_5A.png',
    'Circular 5 pts - Ind Derecha': 'images/Circular_5D.png',
    'Circular 5 pts - Ind Izquierda': 'images/Circular_5I.png',
    'Circular 5 pts - Ind Frontal': 'images/Circular_5F.png',
    'Circular 5 pts - Ind Atras': 'images/Circular_5A.png',
    'Circular 4 pts - Ind Derecha': 'images/Circular_4D.png',
    'Circular 4 pts - Ind Izquierda': 'images/Circular_4I.png',
    'Circular 4 pts - Ind Frontal': 'images/Circular_4F.png',
    'Circular 4 pts - Ind Atras': 'images/Circular_4A.png',
    'Cuadrada - Ind Derecha': 'images/Cuadrada_D.png',
    'Cuadrada - Ind Izquierda': 'images/Cuadrada_I.png',
    'Cuadrada - Ind Frontal': 'images/Cuadrada_F.png',
    'Cuadrada - Ind Atras': 'images/Cuadrada_A.png',
    'Triangular - Ind Derecha': 'images/Triangular_D.png',
    'Triangular - Ind Izquierda': 'images/Triangular_I.png',
    'Triangular - Ind Frontal': 'images/Triangular_F.png',
    'Triangular - Ind Atras': 'images/Triangular_A.png',
    'Caceta de control Atras': 'images/Caceta_A.png',
    'Caceta de control Frontal': 'images/Caceta_F.png',
    'Caceta de control Izquierda': 'images/Caceta_I.png',
    'Caceta de control Derecha': 'images/Caceta_D.png',
  };

  // Campos de estado general
  static const List<String> entornoInstalacionCampos = [
    'Vibración',
    'Polvo',
    'Temperatura',
    'Humedad',
    'Mesada',
    'Iluminación',
    'Limpieza de Fosa',
    'Estado de Drenaje'
  ];

  static const List<String> terminalPesajeCampos = [
    'Carcasa',
    'Teclado Fisico',
    'Display Fisico',
    'Fuente de poder',
    'Bateria operacional',
    'Bracket',
    'Teclado Operativo',
    'Display Operativo',
    'Contector de celda',
    'Bateria de memoria'
  ];

  static const List<String> estadoGeneralBalanzaCampos = [
    'Limpieza general',
    'Golpes al terminal',
    'Nivelacion',
    'Limpieza receptor',
    'Golpes al receptor de carga',
    'Encendido'
  ];

  static const List<String> balanzaPlataformaCampos = [
    'Limitador de movimiento',
    'Suspensión',
    'Limitador de carga',
    'Celda de carga'
  ];

  static const List<String> cajaSumadoraCampos = [
    'Tapa de caja sumadora',
    'Humedad Interna',
    'Estado de prensacables',
    'Estado de borneas'
  ];
}
