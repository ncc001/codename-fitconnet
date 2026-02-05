import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart'; // Para fechas en español (opcional)
import 'screens/onboarding_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  // 1. Aseguramos que el motor de Flutter esté listo antes de todo
  WidgetsFlutterBinding.ensureInitialized();

  // 2. INICIALIZAMOS EL CEREBRO (HIVE) 🧠
  await Hive.initFlutter();

  // 3. Abrimos las cajas de memoria que usaremos
  // 'settings': Para nombre del usuario, modo manual/auto, etc.
  await Hive.openBox('settings');
  // 'exercise_history': Para guardar los pesos y reps
  await Hive.openBox('exercise_history');

  // 4. Arrancamos la App
  runApp(const FitConnectApp());
}

class FitConnectApp extends StatelessWidget {
  const FitConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Leemos si ya existe un usuario guardado para saber a dónde ir
    var box = Hive.box('settings');
    bool userExists = box.get('userName') != null;

    return MaterialApp(
      debugShowCheckedModeBanner: false, // Quitamos la etiqueta "Debug"
      title: 'Fit Connect',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        primaryColor: const Color(0xFF00E676),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          elevation: 0,
        ),
      ),
      // Si el usuario ya existe, vamos al Home. Si no, al Registro.
      home: userExists ? const HomeScreen() : const OnboardingScreen(),
    );
  }
}