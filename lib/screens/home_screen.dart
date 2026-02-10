import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'workout_screen.dart';
import '../data/routine_generator.dart';
import '../data/exercise_database.dart'; // Importante para entender la clase Exercise

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String selectedGoal = 'Hipertrofia';
  int trainingDays = 4;
  
  // CORRECCIÓN: Ahora es una lista de OBJETOS Exercise, no de Mapas simples
  List<Exercise> dailyRoutine = [];

  @override
  void initState() {
    super.initState();
    _generateRoutine();
  }

  void _generateRoutine() {
    // Calculamos el día de la semana (1 = Lunes, 7 = Domingo)
    int weekday = DateTime.now().weekday;
    
    setState(() {
      // Ahora esto funciona porque los tipos coinciden
      dailyRoutine = RoutineGenerator.generate(trainingDays, weekday);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Texto para el saludo según la hora
    var hour = DateTime.now().hour;
    String greeting = hour < 12 ? 'Buenos días' : (hour < 18 ? 'Buenas tardes' : 'Buenas noches');

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'FIT-CONNECT',
          style: GoogleFonts.bebasNeue(
            fontSize: 28, 
            letterSpacing: 2, 
            color: const Color(0xFF00E676)
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              // Aquí podrías abrir configuración para cambiar trainingDays
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$greeting, Nelson',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 5),
            Text(
              '¿Listo para romperla?',
              style: GoogleFonts.bebasNeue(
                fontSize: 32, 
                color: Colors.white
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Selector de Días (Visual)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Días de entreno:", style: TextStyle(color: Colors.white70)),
                DropdownButton<int>(
                  value: trainingDays,
                  dropdownColor: const Color(0xFF1E1E1E),
                  style: const TextStyle(color: Color(0xFF00E676)),
                  underline: Container(height: 1, color: const Color(0xFF00E676)),
                  items: [3, 4, 5].map((int value) {
                    return DropdownMenuItem<int>(
                      value: value,
                      child: Text("$value Días/Semana"),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      trainingDays = newValue!;
                      _generateRoutine();
                    });
                  },
                ),
              ],
            ),

            const SizedBox(height: 20),
            Text(
              "RUTINA DE HOY",
              style: TextStyle(
                color: Colors.grey[400], 
                fontWeight: FontWeight.bold, 
                letterSpacing: 1.2
              ),
            ),
            const SizedBox(height: 10),

            // LISTA DE EJERCICIOS
            Expanded(
              child: dailyRoutine.isEmpty 
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.bed_outlined, color: Colors.grey, size: 50),
                      const SizedBox(height: 10),
                      Text(
                        "Día de Descanso",
                        style: GoogleFonts.bebasNeue(fontSize: 24, color: Colors.grey),
                      ),
                      const Text(
                        "Recupérate para mañana.",
                        style: TextStyle(color: Colors.grey),
                      )
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: dailyRoutine.length,
                  itemBuilder: (context, index) {
                    final exercise = dailyRoutine[index];
                    
                    return Card(
                      color: const Color(0xFF1E1E1E),
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00E676).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8)
                          ),
                          child: const Icon(Icons.fitness_center, color: Color(0xFF00E676)),
                        ),
                        title: Text(
                          exercise.name, // Usamos la propiedad .name del objeto
                          style: const TextStyle(
                            color: Colors.white, 
                            fontWeight: FontWeight.bold,
                            fontSize: 16
                          ),
                        ),
                        subtitle: Text(
                          "${exercise.targetMuscle} • ${exercise.category}", // Usamos las propiedades nuevas
                          style: TextStyle(color: Colors.grey[400], fontSize: 12),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
                        onTap: () async {
                          // Navegamos a la pantalla de entrenamiento
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => WorkoutScreen(
                                exerciseName: exercise.name,
                                // Estos valores son referenciales, el WorkoutScreen ahora calcula lo óptimo
                                targetSets: 4, 
                                targetReps: "8-12",
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
            ),
          ],
        ),
      ),
    );
  }
}