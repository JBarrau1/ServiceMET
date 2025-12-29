import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:service_met/database/soporte_tecnico/database_helper_diagnostico_correctivo.dart';
import 'package:service_met/home/home_screen.dart';
import 'package:service_met/providers/calibration_provider.dart';
import 'package:service_met/repositories/calibration_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database/app_database.dart';
import 'database/soporte_tecnico/database_helper_ajustes.dart';
import 'database/soporte_tecnico/database_helper_instalacion.dart';
import 'database/soporte_tecnico/database_helper_mnt_prv_avanzado_stac.dart';
import 'database/soporte_tecnico/database_helper_mnt_prv_avanzado_stil.dart';
import 'database/soporte_tecnico/database_helper_mnt_prv_regular_stac.dart';
import 'database/soporte_tecnico/database_helper_mnt_prv_regular_stil.dart';
import 'database/soporte_tecnico/database_helper_relevamiento.dart';
import 'database/soporte_tecnico/database_helper_verificaciones.dart';
import 'package:service_met/provider/balanza_provider.dart';
import 'package:provider/provider.dart';
import 'package:service_met/providers/settings_provider.dart';
import 'login/screens/initial_setup_screen.dart';
import 'login/screens/login_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Bloquear orientación si se desea (opcional, buena práctica)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  try {
    // Inicialización paralela para mejorar velocidad de arranque
    await Future.wait([
      Firebase.initializeApp(),
      // Bases de datos críticas (opcionalmente podrían no ser críticas para arranque)
      AppDatabase().database,
      DatabaseHelperAjustes().database,
      DatabaseHelperInstalacion().database,
      DatabaseHelperMntPrvAvanzadoStac().database,
      DatabaseHelperMntPrvAvanzadoStil().database,
      DatabaseHelperMntPrvRegularStac().database,
      DatabaseHelperMntPrvRegularStil().database,
      DatabaseHelperRelevamiento().database,
      DatabaseHelperVerificaciones().database,
      DatabaseHelperDiagnosticoCorrectivo().database,
    ]);
  } catch (e, stack) {
    debugPrint('Error crítico durante la inicialización: $e');
    debugPrint(stack.toString());
    // Aquí se podría reportar a Crashlytics si estuviera configurado
  }

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
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
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
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return MaterialApp(
          title: 'ServiceMET',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.buildLightTheme(context),
          darkTheme: AppTheme.buildDarkTheme(context),
          themeMode: settings.themeMode,
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(settings.textScaleFactor),
              ),
              child: child!,
            );
          },
          // MODIFICADO: Decidir ruta inicial basado en setup
          initialRoute: setupCompleted ? '/login' : '/setup',
          routes: {
            '/setup': (context) => const InitialSetupScreen(),
            '/login': (context) => const LoginScreen(),
            '/home': (context) => const HomeScreen(),
          },
        );
      },
    );
  }
}
