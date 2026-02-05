import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart'; // Para formatear la fecha
import '../models/exercise_model.dart';
import '../widgets/rest_timer_sheet.dart'; 

class ExerciseDetailScreen extends StatefulWidget {
  final Exercise exercise;

  const ExerciseDetailScreen({super.key, required this.exercise});

  @override
  State<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen> {
  // Controladores para escribir texto
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _repsController = TextEditingController();
  
  // Caja de logs
  late Box _logsBox;

  @override
  void initState() {
    super.initState();
    _logsBox = Hive.box('logs'); // Referencia a la caja abierta en main
  }

  void _saveSet() {
    if (_weightController.text.isEmpty || _repsController.text.isEmpty) return;

    final newLog = {
      "date": DateTime.now(),
      "exerciseId": widget.exercise.id,
      "weight": double.parse(_weightController.text),
      "reps": int.parse(_repsController.text),
    };

    // Guardamos en Hive
    _logsBox.add(newLog);

    // Limpiamos los campos y cerramos teclado
    _weightController.clear();
    _repsController.clear();
    FocusScope.of(context).unfocus();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("¡Serie Registrada! 💪"), 
        backgroundColor: Color(0xFF00E676),
        duration: Duration(milliseconds: 800),
      )
    );
  }

  String formatIdToName(String id) {
    return id.replaceAll('_', ' ').toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    // Escuchar cambios en la caja de logs para actualizar la lista en tiempo real
    return ValueListenableBuilder(
      valueListenable: _logsBox.listenable(),
      builder: (context, Box box, _) {
        
        // FILTRAR: Buscar solo logs de ESTE ejercicio
        final history = box.values.toList().where((log) => log['exerciseId'] == widget.exercise.id).toList();
        // ORDENAR: El más reciente primero
        history.sort((a, b) => b['date'].compareTo(a['date']));

        return Scaffold(
          backgroundColor: const Color(0xFF121212),
          appBar: AppBar(
            title: const Text('Entrenamiento', style: TextStyle(color: Colors.white)),
            backgroundColor: const Color(0xFF121212),
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. HEADER DEL EJERCICIO
                Center(
                  child: Text(
                    widget.exercise.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 20),

                // 2. INPUTS DE REGISTRO (LO NUEVO)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF00E676).withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      const Text("REGISTRAR SERIE", style: TextStyle(color: Color(0xFF00E676), fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          // INPUT PESO
                          Expanded(
                            child: TextField(
                              controller: _weightController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: Colors.white, fontSize: 18),
                              decoration: _inputDeco("Kg (Peso)"),
                            ),
                          ),
                          const SizedBox(width: 15),
                          // INPUT REPS
                          Expanded(
                            child: TextField(
                              controller: _repsController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: Colors.white, fontSize: 18),
                              decoration: _inputDeco("Reps"),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _saveSet,
                          icon: const Icon(Icons.add, color: Colors.black),
                          label: const Text("GUARDAR SERIE", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E676)),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // 3. BOTÓN TIMER
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => const RestTimerSheet(),
                      );
                    },
                    icon: const Icon(Icons.timer, color: Colors.white),
                    label: const Text("ABRIR TIMER (90s)"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF333333),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // 4. HISTORIAL DE SERIES
                const Text("HISTORIAL RECIENTE", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                
                if (history.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.withOpacity(0.1)),
                    ),
                    child: const Text(
                      "Sin registros aún.\n¡Haz tu primera serie hoy!",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true, // Importante para estar dentro de SingleScrollView
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: history.length > 5 ? 5 : history.length, // Mostrar solo los últimos 5
                    separatorBuilder: (_,__) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final log = history[index];
                      final date = log['date'] as DateTime;
                      final isToday = date.day == DateTime.now().day && date.month == DateTime.now().month;

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isToday ? const Color(0xFF00E676).withOpacity(0.1) : const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(8),
                          border: isToday ? Border.all(color: const Color(0xFF00E676).withOpacity(0.3)) : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat('dd/MM').format(date),
                              style: TextStyle(color: Colors.grey[600], fontSize: 12),
                            ),
                            Text(
                              "${log['weight']} kg",
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text(
                              "x ${log['reps']} reps",
                              style: const TextStyle(color: Colors.white, fontSize: 16),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  
                const SizedBox(height: 50),
              ],
            ),
          ),
        );
      },
    );
  }

  InputDecoration _inputDeco(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.grey),
      filled: true,
      fillColor: const Color(0xFF121212),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xFF00E676)),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}