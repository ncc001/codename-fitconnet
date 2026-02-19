import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'workout_screen.dart';
import '../data/routine_generator.dart';
import '../data/exercise_database.dart';
import 'package:hive_flutter/hive_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0; 
  int trainingDays = 4;
  
  DateTime _selectedDate = DateTime.now(); 
  bool _isManualMode = false; 
  
  // CORRECCIÓN: Usamos un Mapa para guardar rutinas POR DÍA
  // La clave será la fecha (ej: "2024-02-14") y el valor la lista de ejercicios
  final Map<String, List<Exercise>> _manualRoutines = {};
  
  List<Exercise> dailyRoutine = [];

@override
  void initState() {
    super.initState();
    
    // 🔥 PASO 2: Leemos la memoria antes de cargar la pantalla
    var settingsBox = Hive.box('settings');
    _isManualMode = settingsBox.get('isManualMode', defaultValue: false);
    
    _updateRoutine();
  }
  // Ayudante para convertir la fecha en una "clave" única (YYYY-MM-DD)
  String _getDateKey(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  void _updateRoutine() {
    setState(() {
      if (_isManualMode) {
        // MODO MANUAL: Buscamos la lista específica de ESTE día
        String key = _getDateKey(_selectedDate);
        // Si existe la lista la usamos, si no, lista vacía
        dailyRoutine = List.from(_manualRoutines[key] ?? []);
      } else {
        // MODO AUTO: Algoritmo científico
        int weekday = _selectedDate.weekday;
        dailyRoutine = RoutineGenerator.generate(trainingDays, weekday);
      }
    });
  }

  // --- FUNCIÓN PARA AGREGAR EJERCICIO AL DÍA SELECCIONADO ---
  void _addManualExercise(Exercise ex) {
    setState(() {
      String key = _getDateKey(_selectedDate);
      
      // Si no existe una lista para hoy, la creamos
      if (!_manualRoutines.containsKey(key)) {
        _manualRoutines[key] = [];
      }
      
      // Agregamos el ejercicio
      _manualRoutines[key]!.add(ex);
      
      _updateRoutine(); // Refrescamos la pantalla
    });
  }

  // --- FUNCIÓN PARA BORRAR EJERCICIO ---
  void _deleteManualExercise(int index) {
    setState(() {
      String key = _getDateKey(_selectedDate);
      if (_manualRoutines.containsKey(key)) {
        _manualRoutines[key]!.removeAt(index);
        _updateRoutine();
      }
    });
  }

  void _showAddExerciseModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      isScrollControlled: true, // Permite que ocupe más pantalla si es necesario
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, controller) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text("Elige para el ${DateFormat('EEEE', 'es_ES').format(_selectedDate)}", 
                    style: GoogleFonts.bebasNeue(fontSize: 24, color: Colors.white)),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: controller,
                    itemCount: ExerciseDatabase.allExercises.length,
                    itemBuilder: (context, index) {
                      final ex = ExerciseDatabase.allExercises[index];
                      return ListTile(
                        leading: const Icon(Icons.fitness_center, color: Colors.grey),
                        title: Text(ex.name, style: const TextStyle(color: Colors.white)),
                        subtitle: Text(ex.targetMuscle, style: const TextStyle(color: Color(0xFF00E676))),
                        onTap: () {
                          _addManualExercise(ex);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          }
        );
      },
    );
  }

  Widget _buildWeekCalendar() {
    DateTime now = DateTime.now();
    // Ajustamos para que la semana empiece el Lunes de la fecha actual
    DateTime monday = now.subtract(Duration(days: now.weekday - 1));
    
    return Container(
      height: 85,
      margin: const EdgeInsets.symmetric(vertical: 20),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 7,
        itemBuilder: (context, index) {
          DateTime date = monday.add(Duration(days: index));
          bool isSelected = date.day == _selectedDate.day && date.month == _selectedDate.month;
          bool isToday = date.day == now.day && date.month == now.month;
          String dayName = DateFormat('E', 'es_ES').format(date).toUpperCase().substring(0, 1);
          String dayNumber = date.day.toString();

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDate = date;
                _updateRoutine(); // Al cambiar de día, se carga la rutina de ESE día
              });
            },
            child: Container(
              width: 60,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF00E676) : (isToday ? Colors.white12 : Colors.transparent),
                borderRadius: BorderRadius.circular(16),
                border: isSelected ? null : Border.all(color: Colors.white24),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(dayName, style: TextStyle(color: isSelected ? Colors.black : Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 5),
                  Text(dayNumber, style: TextStyle(color: isSelected ? Colors.black : Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
                  if (isToday && !isSelected)
                    Container(margin: const EdgeInsets.only(top: 5), width: 4, height: 4, decoration: const BoxDecoration(color: Color(0xFF00E676), shape: BoxShape.circle))
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRoutineTab() {
    String fullDate = DateFormat('EEEE d, MMMM', 'es_ES').format(_selectedDate).toUpperCase();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWeekCalendar(),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(12)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_isManualMode ? "MODO MANUAL" : "MODO CIENTÍFICO (AUTO)", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(_isManualMode ? "Personaliza este día" : "Optimizado por IA", style: const TextStyle(color: Colors.grey, fontSize: 10)),
                  ],
                ),
              Switch(
                  value: _isManualMode,
                  activeColor: const Color(0xFF00E676),
                  onChanged: (val) {
                    setState(() {
                      _isManualMode = val;
                      _updateRoutine();
                    });
                    
                    // 🔥 PASO 3: Guardamos la decisión si tocas el botón
                    var settingsBox = Hive.box('settings');
                    settingsBox.put('isManualMode', val); 
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          Text(fullDate, style: GoogleFonts.bebasNeue(fontSize: 24, color: Colors.white, letterSpacing: 1)),
          const SizedBox(height: 10),

          Expanded(
            child: dailyRoutine.isEmpty 
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_isManualMode ? Icons.add_circle_outline : Icons.bed, size: 50, color: Colors.grey),
                    const SizedBox(height: 10),
                    Text(
                      _isManualMode 
                        ? "Día vacío.\nUsa el botón + para agregar ejercicios." 
                        : "Día de Descanso",
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                itemCount: dailyRoutine.length,
                itemBuilder: (context, index) {
                  final ex = dailyRoutine[index];
                  return Card(
                    color: const Color(0xFF1E1E1E),
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.fitness_center, color: Color(0xFF00E676)),
                      ),
                      title: Text(ex.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      subtitle: Text("${ex.targetMuscle} • ${ex.category}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      
                      trailing: _isManualMode 
                        ? IconButton( // En MANUAL mostramos la papelera
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                            onPressed: () => _deleteManualExercise(index),
                          )
                        : const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 16), // En AUTO la flecha
                      
   onTap: () async {
  // Navegamos a la pantalla de entrenamiento
  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => WorkoutScreen(
        // 1. Usamos 'ex.name' porque 'ex' es la variable de tu bucle
        exerciseName: ex.name, 
        
        // 2. Usamos '_selectedDate' porque así llamaste a la variable de fecha arriba
        trainingDate: _selectedDate, 
      ),
    ),
  );
  
  // Opcional: Al volver, actualizamos por si guardaste algo nuevo
  _updateRoutine();
                      },
                    ),
                  );
                },
              ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text('FIT-CONNECT', style: GoogleFonts.bebasNeue(color: const Color(0xFF00E676), fontSize: 28, letterSpacing: 2)),
        actions: [
          if (!_isManualMode)
            Padding(
              padding: const EdgeInsets.only(right: 20),
              child: DropdownButton<int>(
                value: trainingDays,
                dropdownColor: const Color(0xFF1E1E1E),
                style: const TextStyle(color: Color(0xFF00E676), fontWeight: FontWeight.bold),
                underline: Container(),
                icon: const Icon(Icons.calendar_today, color: Color(0xFF00E676), size: 16),
                items: [3, 4, 5].map((int value) => DropdownMenuItem<int>(value: value, child: Text(" $value Días "))).toList(),
                onChanged: (newValue) {
                  setState(() { trainingDays = newValue!; _updateRoutine(); });
                },
              ),
            ),
        ],
      ),
      
      // BOTÓN FLOTANTE: Solo visible en Modo Manual
      floatingActionButton: _isManualMode 
        ? FloatingActionButton(
            onPressed: _showAddExerciseModal,
            backgroundColor: const Color(0xFF00E676),
            child: const Icon(Icons.add, color: Colors.black, size: 30),
          )
        : null,
        
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildRoutineTab(),
          const Center(child: Text("Módulo de Progreso", style: TextStyle(color: Colors.white))),
          const Center(child: Text("Perfil de Usuario", style: TextStyle(color: Colors.white))),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black,
        selectedItemColor: const Color(0xFF00E676),
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Rutina'),
          BottomNavigationBarItem(icon: Icon(Icons.show_chart), label: 'Progreso'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}