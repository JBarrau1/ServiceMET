import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:service_met/home_screen.dart';
import 'package:service_met/providers/calibration_provider.dart';
import 'package:service_met/repositories/calibration_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database/app_database.dart';
import 'database/soporte_tecnico/database_helper_ajustes.dart';
import 'database/soporte_tecnico/database_helper_diagnostico.dart';
import 'database/soporte_tecnico/database_helper_instalacion.dart';
import 'database/soporte_tecnico/database_helper_mnt_correctivo.dart';
import 'database/soporte_tecnico/database_helper_mnt_prv_avanzado_stac.dart';
import 'database/soporte_tecnico/database_helper_mnt_prv_avanzado_stil.dart';
import 'database/soporte_tecnico/database_helper_mnt_prv_regular_stac.dart';
import 'database/soporte_tecnico/database_helper_mnt_prv_regular_stil.dart';
import 'database/soporte_tecnico/database_helper_relevamiento.dart';
import 'database/soporte_tecnico/database_helper_verificaciones.dart';
import 'package:service_met/provider/balanza_provider.dart';
import 'package:provider/provider.dart';
import 'login/screens/initial_setup_screen.dart';
import 'login/screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Inicializa la base de datos local
  await AppDatabase().database;
  await DatabaseHelperAjustes().database;
  await DatabaseHelperDiagnostico().database;
  await DatabaseHelperInstalacion().database;
  await DatabaseHelperMntCorrectivo().database;
  await DatabaseHelperMntPrvAvanzadoStac().database;
  await DatabaseHelperMntPrvAvanzadoStil().database;
  await DatabaseHelperMntPrvRegularStac().database;
  await DatabaseHelperMntPrvRegularStil().database;
  await DatabaseHelperRelevamiento().database;
  await DatabaseHelperVerificaciones().database;

  // NUEVO: Verificar si se completó el setup inicial
  final prefs = await SharedPreferences.getInstance();
  final setupCompleted = prefs.getBool('setup_completed') ?? false;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BalanzaProvider()),
        ChangeNotifierProvider(
          create: (_) => CalibrationProvider(CalibrationRepository()),
        ),
      ],
      child: MyApp(setupCompleted: setupCompleted),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool setupCompleted;

  const MyApp({super.key, required this.setupCompleted});

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
        // MODIFICADO: Decidir ruta inicial basado en setup
        initialRoute: setupCompleted ? '/login' : '/setup',
        routes: {
          '/setup': (context) => const InitialSetupScreen(), // NUEVO
          '/login': (context) => const LoginScreen(),
          '/home': (context) => const HomeScreen(),
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
      scaffoldBackgroundColor: scaffoldBackgroundColor,
      primaryColor: primaryColor,
      canvasColor: scaffoldBackgroundColor,
      cardColor: scaffoldBackgroundColor,
      disabledColor: Colors.grey[400],

      colorScheme: baseTheme.colorScheme.copyWith(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: scaffoldBackgroundColor,
        onSurface: textColor,
        brightness: Brightness.light,
      ),

      textTheme: GoogleFonts.interTextTheme(baseTheme.textTheme).copyWith(
        displayLarge: const TextStyle(color: textColor),
        displayMedium: const TextStyle(color: textColor),
        displaySmall: const TextStyle(color: textColor),
        headlineMedium: const TextStyle(color: textColor),
        headlineSmall: const TextStyle(color: textColor),
        titleLarge: const TextStyle(color: textColor),
        titleMedium: const TextStyle(color: textColor),
        titleSmall: const TextStyle(color: textColor),
        bodyLarge: const TextStyle(color: textColor),
        bodyMedium: const TextStyle(color: textColor),
        bodySmall: TextStyle(color: Colors.grey[800]),
        labelLarge: const TextStyle(color: Colors.white),
        labelSmall: TextStyle(color: Colors.grey[800]),
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: Colors.black),
        elevation: 1,
      ),

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

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: primaryColor,
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

      iconTheme: const IconThemeData(color: textColor),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: primaryColor,
        ),
      ),

      dividerTheme: const DividerThemeData(
        thickness: 1,
        space: 1,
      ).copyWith(color: Colors.grey[300]),

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
              return Colors.white;
            }
            return Colors.grey;
          },
        ),
        trackColor: MaterialStateProperty.resolveWith<Color?>(
              (states) {
            if (states.contains(MaterialState.selected)) {
              return const Color(0xFF457D41);
            }
            return Colors.black12;
          },
        ),
      ),
    );
  }

  ThemeData _buildDarkTheme(BuildContext context) {
    const primaryColor = Color(0xFFFFFFFF);
    const secondaryColor = Color(0xFFFFFFFF);
    const textColor = Colors.white;
    const scaffoldBackgroundColor = Color(0xFF121212);

    final baseTheme = ThemeData.dark();

    return baseTheme.copyWith(
      scaffoldBackgroundColor: scaffoldBackgroundColor,
      primaryColor: primaryColor,
      canvasColor: const Color(0xFF1E1E1E),
      cardColor: const Color(0xFF1E1E1E),
      disabledColor: Colors.grey[600],

      colorScheme: baseTheme.colorScheme.copyWith(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: const Color(0xFF1E1E1E),
        onSurface: textColor,
        brightness: Brightness.dark,
      ),

      textTheme: GoogleFonts.interTextTheme(baseTheme.textTheme).copyWith(
        displayLarge: const TextStyle(color: textColor),
        displayMedium: const TextStyle(color: textColor),
        displaySmall: const TextStyle(color: textColor),
        headlineMedium: const TextStyle(color: textColor),
        headlineSmall: const TextStyle(color: textColor),
        titleLarge: const TextStyle(color: textColor),
        titleMedium: const TextStyle(color: textColor),
        titleSmall: const TextStyle(color: textColor),
        bodyLarge: const TextStyle(color: textColor),
        bodyMedium: const TextStyle(color: textColor),
        bodySmall: const TextStyle(color: Colors.white70),
        labelLarge: const TextStyle(color: Colors.black),
        labelSmall: const TextStyle(color: Colors.white70),
      ),

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

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: primaryColor,
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

      iconTheme: const IconThemeData(color: textColor),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: primaryColor,
        ),
      ),

      dividerTheme: const DividerThemeData(
        thickness: 1,
        space: 1,
      ).copyWith(color: Colors.grey[700]),

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
              return Colors.white;
            }
            return Colors.grey;
          },
        ),
        trackColor: MaterialStateProperty.resolveWith<Color?>(
              (states) {
            if (states.contains(MaterialState.selected)) {
              return const Color(0xFF457D41);
            }
            return Colors.black12;
          },
        ),
      ),
    );
  }
}