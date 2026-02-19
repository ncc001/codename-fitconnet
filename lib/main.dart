import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart'; 
import 'screens/onboarding_screen.dart'; // Tu pantalla de registro/pasos
import 'screens/home_screen.dart';

void main() async {
  // 1. Motor de Flutter listo
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Inicializamos fechas en español (por si usas el calendario en el Home)
  await initializeDateFormatting('es_ES', null);

  // 3. INICIALIZAMOS HIVE 🧠
  await Hive.initFlutter();

  // 4. Abrimos las cajas de memoria fundamentales
  await Hive.openBox('settings');         // Para saber si userExists
  await Hive.openBox('exercise_history'); // Para tus récords en Puente Piedra
  await Hive.openBox('user_prefs');       // Para peso, sexo, edad

  // 5. Arrancamos la App
  runApp(const FitConnectApp());
}

class FitConnectApp extends StatelessWidget {
  const FitConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    // LEEMOS EL CEREBRO: ¿Ya se registró Nelson antes?
    var box = Hive.box('settings');
    bool userExists = box.get('userName') != null;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Fit Connect',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        primaryColor: const Color(0xFF00E676),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          elevation: 0,
        ),
      ),
      // LA LÓGICA QUE IMPORTA:
      // Si ya existe -> Home. Si es nuevo -> Registro/Onboarding.
      home: userExists ? const HomeScreen() : const OnboardingScreen(),
    );
  }
}