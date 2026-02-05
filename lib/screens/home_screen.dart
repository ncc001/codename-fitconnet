import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'workout_screen.dart'; 
import '../data/routine_generator.dart'; 
import '../data/exercise_database.dart'; 

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String userName = "Atleta";
  int trainingDays = 4;
  bool isManualMode = false; 
  DateTime startDate = DateTime(2026, 2, 2); 
  
  bool _isDayCleared = false;
  DateTime selectedDate = DateTime.now();
  
  final List<String> weekDays = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
  final List<String> months = ["Ene", "Feb", "Mar", "Abr", "May", "Jun", "Jul", "Ago", "Sep", "Oct", "Nov", "Dic"];

  List<Map<String, dynamic>> dailyRoutine = []; 

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() async {
    var box = await Hive.openBox('settings');
    setState(() {
      userName = box.get('userName', defaultValue: 'Atleta');
      trainingDays = box.get('trainingDays', defaultValue: 4);
      isManualMode = box.get('isManualMode', defaultValue: false);
      _isDayCleared = false;
    });
    _loadRoutineForSelectedDate();
  }

  void _loadRoutineForSelectedDate() async {
    String dateKey = selectedDate.toIso8601String().split('T')[0];

    if (isManualMode) {
      var manualBox = await Hive.openBox('manual_routines');
      List<dynamic> saved = manualBox.get(dateKey, defaultValue: []);
      setState(() {
        dailyRoutine = saved.map((e) => Map<String, dynamic>.from(e)).toList();
      });
    } else {
      int weekday = selectedDate.weekday;
      setState(() {
        dailyRoutine = RoutineGenerator.generate(trainingDays, weekday);
      });
    }
  }

  Future<void> _saveManualRoutine() async {
    if (!isManualMode) return;
    String dateKey = selectedDate.toIso8601String().split('T')[0];
    var manualBox = await Hive.openBox('manual_routines');
    await manualBox.put(dateKey, dailyRoutine);
  }

  // --- NUEVO: CREAR EJERCICIO PERSONALIZADO ---
  void _showCreateExerciseDialog() {
    final nameController = TextEditingController();
    String selectedMuscle = "Pecho";
    final List<String> muscles = ["Pecho", "Espalda", "Pierna", "Hombro", "Bíceps", "Tríceps", "Abs", "Cardio"];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text("Crear Ejercicio", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "Nombre del Ejercicio",
                labelStyle: TextStyle(color: Colors.grey),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF00E676))),
              ),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: selectedMuscle,
              dropdownColor: const Color(0xFF333333),
              style: const TextStyle(color: Colors.white),
              items: muscles.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
              onChanged: (val) => selectedMuscle = val!,
              decoration: const InputDecoration(labelText: "Músculo Objetivo", labelStyle: TextStyle(color: Colors.grey)),
            )
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCELAR", style: TextStyle(color: Colors.redAccent))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E676)),
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                // Guardar en Hive 'custom_exercises'
                var customBox = await Hive.openBox('custom_exercises');
                List<dynamic> currentCustoms = customBox.get('list', defaultValue: []);
                
                currentCustoms.add({
                  "id": "custom_${DateTime.now().millisecondsSinceEpoch}",
                  "name": nameController.text,
                  "muscle": selectedMuscle
                });
                
                await customBox.put('list', currentCustoms);
                
                Navigator.pop(ctx); // Cerrar diálogo
                Navigator.pop(context); // Cerrar selector anterior para refrescar
                _showExerciseSelector(); // Reabrir selector actualizado
              }
            },
            child: const Text("GUARDAR", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  // --- SELECTOR MEJORADO ---
  void _showExerciseSelector() async {
    // 1. Cargar ejercicios científicos
    final scientificExercises = ExerciseDatabase.allExercises;
    
    // 2. Cargar ejercicios personalizados
    var customBox = await Hive.openBox('custom_exercises');
    List<dynamic> customsRaw = customBox.get('list', defaultValue: []);
    
    // Combinar listas
    List<Map<String, dynamic>> allOptions = [];
    
    // Convertir científicos a mapa simple
    for (var ex in scientificExercises) {
      allOptions.add({"name": ex.name, "muscle": ex.targetMuscle, "type": "science"});
    }
    // Agregar customs
    for (var c in customsRaw) {
      allOptions.add({"name": c['name'], "muscle": c['muscle'], "type": "custom"});
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, controller) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Seleccionar Ejercicio", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      // BOTÓN CREAR NUEVO
                      ElevatedButton.icon(
                        onPressed: _showCreateExerciseDialog,
                        icon: const Icon(Icons.add, size: 16, color: Colors.black),
                        label: const Text("CREAR", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E676)),
                      )
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: controller,
                    itemCount: allOptions.length,
                    itemBuilder: (context, index) {
                      final ex = allOptions[index];
                      bool isCustom = ex['type'] == "custom";
                      
                      return ListTile(
                        leading: Icon(isCustom ? Icons.person : Icons.science, color: isCustom ? Colors.orange : Colors.blueAccent),
                        title: Text(ex['name'], style: const TextStyle(color: Colors.white)),
                        subtitle: Text(ex['muscle'], style: TextStyle(color: Colors.grey[600])),
                        trailing: const Icon(Icons.add_circle_outline, color: Colors.grey),
                        onTap: () {
                          setState(() {
                            dailyRoutine.add({
                              "name": ex['name'],
                              "muscle": ex['muscle'],
                              "sets": 4, 
                              "reps": "10-12",
                              "rest": "90s",
                              "isWeakPoint": false
                            });
                          });
                          _saveManualRoutine(); 
                          Navigator.pop(context); 
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Añadido a la rutina"), duration: Duration(milliseconds: 800)));
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- RESTO DEL CÓDIGO UI (Sin cambios grandes) ---
  
  String _getWeekRangeText(int weekIndex) {
    DateTime weekStart = startDate.add(Duration(days: (weekIndex - 1) * 7));
    DateTime weekEnd = weekStart.add(const Duration(days: 6));
    String startStr = "${weekStart.day} ${months[weekStart.month - 1]}";
    String endStr = "${weekEnd.day} ${months[weekEnd.month - 1]}";
    return "$startStr - $endStr ${weekEnd.year}";
  }

  int _calculateCurrentWeek() {
    final difference = selectedDate.difference(startDate).inDays;
    if (difference < 0) return 1;
    return (difference / 7).floor() + 1;
  }

  void _toggleMode() async {
    var box = await Hive.openBox('settings');
    bool newMode = !isManualMode;
    await box.put('isManualMode', newMode);
    
    setState(() {
      isManualMode = newMode;
      dailyRoutine = []; 
    });
    _loadRoutineForSelectedDate();
  }

  @override
  Widget build(BuildContext context) {
    final Color accentColor = const Color(0xFF00E676);
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: _selectedIndex == 0 
          ? _buildHomeContent(accentColor) 
          : _selectedIndex == 2 ? _buildProfileView(accentColor) : const Center(child: Text("Progreso (Próximamente)", style: TextStyle(color: Colors.white))),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black,
        selectedItemColor: accentColor,
        unselectedItemColor: Colors.grey[600],
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: "Plan"),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: "Progreso"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Perfil"),
        ],
      ),
    );
  }

  Widget _buildHomeContent(Color accentColor) {
    int currentWeek = _calculateCurrentWeek();
    bool isEmpty = dailyRoutine.isEmpty;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.grey[900]!, Colors.black]),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: accentColor.withOpacity(0.5)), 
              boxShadow: [BoxShadow(color: accentColor.withOpacity(0.1), blurRadius: 15)]
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("SEMANA $currentWeek", style: TextStyle(color: accentColor, fontSize: 24, fontWeight: FontWeight.w900)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: accentColor, borderRadius: BorderRadius.circular(10)),
                      child: Text(isManualMode ? "MANUAL" : "AUTO", style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(Icons.calendar_month, color: Colors.grey, size: 14),
                    const SizedBox(width: 5),
                    Text(_getWeekRangeText(currentWeek), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 15),
                SizedBox(
                  height: 60,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: 7,
                    itemBuilder: (context, index) {
                      DateTime now = DateTime.now();
                      DateTime firstDayOfWeek = now.subtract(Duration(days: now.weekday - 1));
                      DateTime date = firstDayOfWeek.add(Duration(days: index));
                      bool isSelected = date.day == selectedDate.day;
                      return GestureDetector(
                        onTap: () {
                          setState(() { selectedDate = date; _isDayCleared = false; });
                          _loadRoutineForSelectedDate(); 
                        },
                        child: Container(
                          width: 45,
                          margin: const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(color: isSelected ? accentColor : const Color(0xFF333333), borderRadius: BorderRadius.circular(12)),
                          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                              Text(weekDays[index], style: TextStyle(color: isSelected ? Colors.black : Colors.grey, fontSize: 10)),
                              Text("${date.day}", style: TextStyle(color: isSelected ? Colors.black : Colors.white, fontWeight: FontWeight.bold)),
                          ]),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(isEmpty && !isManualMode ? "Descanso" : "Rutina de Hoy", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                if (isManualMode)
                  IconButton(
                    onPressed: _showExerciseSelector,
                    icon: Container(padding: const EdgeInsets.all(5), decoration: BoxDecoration(color: accentColor, shape: BoxShape.circle), child: const Icon(Icons.add, color: Colors.black, size: 20)),
                  )
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: isEmpty ? _buildEmptyState(accentColor) : _buildRoutineList(accentColor),
          ),
          const SizedBox(height: 40), 
        ],
      ),
    );
  }

  Widget _buildEmptyState(Color color) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(border: Border.all(color: Colors.white10), borderRadius: BorderRadius.circular(20)),
      child: Center(child: Column(children: [
            Icon(isManualMode ? Icons.edit_note : Icons.hotel, size: 50, color: Colors.grey[700]), 
            const SizedBox(height: 10),
            Text(isManualMode ? "Rutina Vacía" : "Día de Descanso", style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 15),
            if (isManualMode) ElevatedButton.icon(onPressed: _showExerciseSelector, icon: const Icon(Icons.add, color: Colors.black), label: const Text("Crear Rutina", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)), style: ElevatedButton.styleFrom(backgroundColor: color))
      ])),
    );
  }

  Widget _buildRoutineList(Color color) {
    return Column(
      children: dailyRoutine.asMap().entries.map((entry) {
        int idx = entry.key;
        Map<String, dynamic> exercise = entry.value;
        return Container(
          margin: const EdgeInsets.only(left: 20, right: 20, bottom: 10),
          decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(16), border: exercise['isWeakPoint'] == true ? Border.all(color: color.withOpacity(0.3)) : null),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            title: Text(exercise['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Padding(padding: const EdgeInsets.only(top: 8.0), child: Row(children: [_buildBadge("${exercise['sets']} Sets", color), const SizedBox(width: 8), _buildBadge(exercise['reps'], Colors.blueAccent)])),
            trailing: isManualMode 
              ? IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent), onPressed: () { setState(() { dailyRoutine.removeAt(idx); }); _saveManualRoutine(); })
              : const Icon(Icons.chevron_right, color: Colors.grey),
            onTap: () async {
              final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => WorkoutScreen(exerciseName: exercise['name'], targetSets: exercise['sets'], targetReps: exercise['reps'].toString(), restSeconds: 90)));
              if (result != null && result is String) { setState(() { exercise['name'] = result; _saveManualRoutine(); }); }
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(6)), child: Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)));
  }
  
  Widget _buildProfileView(Color accentColor) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text("Gestión", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        Container(
          decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(15)),
          child: ListTile(
            leading: Icon(isManualMode ? Icons.edit : Icons.smart_toy, color: accentColor),
            title: Text(isManualMode ? "Modo Manual (Activo)" : "Modo Automático", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Text(isManualMode ? "Tú diseñas tu rutina" : "La IA decide por ti", style: const TextStyle(color: Colors.grey, fontSize: 12)),
            trailing: Switch(value: isManualMode, activeColor: accentColor, onChanged: (v) => _toggleMode()),
          ),
        ),
      ],
    );
  }
}