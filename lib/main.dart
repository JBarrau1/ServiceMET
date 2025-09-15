import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:service_met/home_screen.dart';
import 'package:service_met/providers/calibration_provider.dart';
import 'package:service_met/repositories/calibration_repository.dart';
import 'database/app_database.dart';
import 'database/app_database_sop.dart';
import 'login_screen.dart';
import 'package:service_met/screens/calibracion/selec_cliente.dart';
import 'package:service_met/provider/balanza_provider.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  // Inicializa la base de datos local
  await AppDatabase().database; // Esta línea creará la BD si no existe
  await DatabaseHelperSop().database;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BalanzaProvider()),
        ChangeNotifierProvider(
          create: (_) => CalibrationProvider(CalibrationRepository()),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BalanzaProvider()),
      ],
      child: MaterialApp(
        title: 'ServiceMET',
        debugShowCheckedModeBanner: false,
        theme: _buildLightTheme(context),
        darkTheme: _buildDarkTheme(context),
        themeMode: ThemeMode.system,
        initialRoute: '/login',
        routes: {
          '/login': (context) => const LoginScreen(),
          '/home': (context) => const HomeScreen(), // Cambia aquí
          '/calibracion': (context) => const CalibracionScreen(
            dbName: '',
            userName: '',
            secaValue: '',
            sessionId: '',
          ),
        },
      ),
    );
  }

  ThemeData _buildLightTheme(BuildContext context) {
    const primaryColor = Color(0xFFd99700);
    const secondaryColor = Color(0xFFd99700);
    const textColor = Colors.black;
    const scaffoldBackgroundColor = Colors.white;

    final baseTheme = ThemeData.light();

    return baseTheme.copyWith(
      // Colores base
      scaffoldBackgroundColor: scaffoldBackgroundColor,
      primaryColor: primaryColor,
      canvasColor: scaffoldBackgroundColor,
      cardColor: scaffoldBackgroundColor,
      disabledColor: Colors.grey[400],

      // Esquema de color
      colorScheme: baseTheme.colorScheme.copyWith(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: scaffoldBackgroundColor,
        onSurface: textColor,
        brightness: Brightness.light,
      ),

      // Textos
      textTheme: GoogleFonts.interTextTheme(baseTheme.textTheme).copyWith(
        displayLarge: const TextStyle(color: textColor),
        displayMedium: const TextStyle(color: textColor),
        displaySmall: const TextStyle(color: textColor),
        headlineMedium: const TextStyle(color: textColor),
        headlineSmall: const TextStyle(color: textColor),
        titleLarge: const TextStyle(color: textColor),
        titleMedium: const TextStyle(color: textColor), // Usado en AppBar
        titleSmall: const TextStyle(color: textColor),
        bodyLarge: const TextStyle(color: textColor),
        bodyMedium: const TextStyle(color: textColor), // Default para Text()
        bodySmall: TextStyle(color: Colors.grey[800]),
        labelLarge: const TextStyle(color: Colors.white), // Botones
        labelSmall: TextStyle(color: Colors.grey[800]),
      ),

      // AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: Colors.black), // <-- Ahora negro
        elevation: 1,
      ),

      // Inputs
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.all(16),
        labelStyle: TextStyle(color: Colors.grey[800]),
        hintStyle: TextStyle(color: Colors.grey[600]),
        prefixIconColor: Colors.grey[800],
        suffixIconColor: Colors.grey[800],
      ),

      // Botones
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: primaryColor, // Usa primaryColor en ambos temas
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20), // Igual en ambos temas
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
        ),
      ),

      // Iconos
      iconTheme: const IconThemeData(color: textColor),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: primaryColor,
        ),
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        thickness: 1,
        space: 1,
      ).copyWith(color: Colors.grey[300]),

      // Otras configuraciones
      snackBarTheme: SnackBarThemeData(
        backgroundColor: Colors.grey[800],
        contentTextStyle: const TextStyle(color: Colors.white),
      ),
      popupMenuTheme: PopupMenuThemeData(
        textStyle: const TextStyle(color: textColor),
      ),
      bottomSheetTheme: const BottomSheetThemeData(),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.grey[200]!,
        labelStyle: const TextStyle(color: textColor),
        secondaryLabelStyle: const TextStyle(color: Colors.white),
      ),
      dialogTheme: DialogThemeData(backgroundColor: scaffoldBackgroundColor),

      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith<Color?>(
              (states) {
            if (states.contains(MaterialState.selected)) {
              return Colors.white; // color del thumb activo
            }
            return Colors.grey; // color del thumb inactivo
          },
        ),
        trackColor: MaterialStateProperty.resolveWith<Color?>(
              (states) {
            if (states.contains(MaterialState.selected)) {
              return const Color(0xFF457D41); // pista activa
            }
            return Colors.black12; // pista inactiva
          },
        ),
      ),
    );
  }

  ThemeData _buildDarkTheme(BuildContext context) {
    const primaryColor = Color(0xFFFFFFFF); // Correcto para una constante
    const secondaryColor = Color(0xFFFFFFFF);
    const textColor = Colors.white;
    const scaffoldBackgroundColor = Color(0xFF121212);

    final baseTheme = ThemeData.dark();

    return baseTheme.copyWith(
      // Colores base
      scaffoldBackgroundColor: scaffoldBackgroundColor,
      primaryColor: primaryColor,
      canvasColor: const Color(0xFF1E1E1E),
      cardColor: const Color(0xFF1E1E1E),
      disabledColor: Colors.grey[600],

      // Esquema de color
      colorScheme: baseTheme.colorScheme.copyWith(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: const Color(0xFF1E1E1E),
        onSurface: textColor,
        brightness: Brightness.dark,
      ),

      // Textos
      textTheme: GoogleFonts.interTextTheme(baseTheme.textTheme).copyWith(
        displayLarge: const TextStyle(color: textColor),
        displayMedium: const TextStyle(color: textColor),
        displaySmall: const TextStyle(color: textColor),
        headlineMedium: const TextStyle(color: textColor),
        headlineSmall: const TextStyle(color: textColor),
        titleLarge: const TextStyle(color: textColor),
        titleMedium: const TextStyle(color: textColor), // Usado en AppBar
        titleSmall: const TextStyle(color: textColor),
        bodyLarge: const TextStyle(color: textColor),
        bodyMedium: const TextStyle(color: textColor), // Default para Text()
        bodySmall: const TextStyle(color: Colors.white70),
        labelLarge: const TextStyle(color: Colors.black), // Botones
        labelSmall: const TextStyle(color: Colors.white70),
      ),

      // AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E1E1E),
        titleTextStyle: TextStyle(
          color: textColor,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: textColor),
        elevation: 1,
      ),

      // Inputs
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey[800],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.all(16),
        labelStyle: TextStyle(color: Colors.white70),
        hintStyle: TextStyle(color: Colors.white54),
        prefixIconColor: Colors.white70,
        suffixIconColor: Colors.white70,
      ),

      // Botones
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white, // Texto
          backgroundColor: primaryColor, // Fondo
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
        ),
      ),

      // Iconos
      iconTheme: const IconThemeData(color: textColor),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: primaryColor,
        ),
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        thickness: 1,
        space: 1,
      ).copyWith(color: Colors.grey[700]),

      // Otras configuraciones
      snackBarTheme: const SnackBarThemeData(
        contentTextStyle: TextStyle(color: textColor),
      ).copyWith(backgroundColor: const Color(0xFF1E1E1E)),
      popupMenuTheme: const PopupMenuThemeData(
        textStyle: TextStyle(color: textColor),
      ).copyWith(color: const Color(0xFF1E1E1E)),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xFF1E1E1E),
      ),
      chipTheme: const ChipThemeData(
        labelStyle: TextStyle(color: textColor),
        secondaryLabelStyle: TextStyle(color: Colors.black),
      ).copyWith(backgroundColor: Colors.grey[700]!),
      dialogTheme: DialogThemeData(backgroundColor: const Color(0xFF1E1E1E)),

      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith<Color?>(
              (states) {
            if (states.contains(MaterialState.selected)) {
              return Colors.white; // color del thumb activo
            }
            return Colors.grey; // color del thumb inactivo
          },
        ),
        trackColor: MaterialStateProperty.resolveWith<Color?>(
              (states) {
            if (states.contains(MaterialState.selected)) {
              return const Color(0xFF457D41); // pista activa
            }
            return Colors.black12; // pista inactiva
          },
        ),
      ),
    );
  }
}
