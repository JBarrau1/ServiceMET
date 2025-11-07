class AppStacConstants {
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
  static const List<String> lozasYFundacionesCampos = [
    'Losas de aproximación (daños o grietas)',
    'Fundaciones (daños o grietas)',
  ];

  static const List<String> limpiezaYDrenajeCampos = [
    'Limpieza de perímetro de balanza',
    'Fosa libre de humedad',
    'Drenaje libre',
    'Bomba de sumidero funcional',
  ];

  static const List<String> chequeoCampos = [
    'Corrosión',
    'Grietas',
    'Tapas superiores y pernos',
    'Desgaste y estrés',
    'Acumulación de escombros o materiales externos',
    'Verificación de rieles laterales',
    'Verificación de paragolpes longitudinales',
    'Verificación de paragolpes transversales',
  ];

  static const List<String> verificacionesElectricasCampos = [
    'Condición de cable de Home Run',
    'Condición de cable de célula a célula',
    'Conexión segura a celdas de carga',
    'Funda de goma y conector ajustados',
    'Conector de terminación ajustado',
    'Los cables están conectados de forma segura a todas las celdas de carga',
    'La funda de goma y el conector del cable están apretados contra la celda de carga',
    'Conector de terminación ajustado y capuchón en su lugar',
  ];

  static const List<String> proteccionRayosCampos = [
    'Sistema de protección contra rayos conectado a tierra',
    'Conexión de la correa de tierra del Strike shield',
    'Tensión entre neutro y tierra adecuada',
    'Impresora conectada al mismo Strike Shield',
  ];

  static const List<String> terminalCampos = [
    'Carcasa, lente y el teclado estan limpios, sin daños y sellados',
    'Voltaje de la batería es adecuado',
    'Teclado operativo correctamente',
    'Brillo de pantalla adecuado',
    'Registros de rendimiento de cambio PDX OK',
    'Pantallas de servicio de MT indican operación normal',
    'Archivos de configuración respaldados con InSite',
    'Terminal devuelto a la disponibilidad operativo',
  ];

  static const List<String> calibracionCampos = [
    'Calibración de balanza realiza y dentro de tolerancia',
  ];

  //Lista completa de todos los campos (para inicialización)
  static List<String> getAllCampos() {
    return [
      ...lozasYFundacionesCampos,
      ...limpiezaYDrenajeCampos,
      ...chequeoCampos,
      ...verificacionesElectricasCampos,
      ...proteccionRayosCampos,
      ...terminalCampos,
      ...calibracionCampos,
    ];
  }
}