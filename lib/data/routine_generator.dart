import 'exercise_database.dart';

class RoutineGenerator {
  // Esta función ahora coincide exactamente con lo que pide tu Home Screen
  static List<Exercise> generate(int trainingDays, int weekday) {
    List<String> workoutIds = [];

    // --- LÓGICA DE 3 DÍAS (FULL BODY) ---
    if (trainingDays == 3) {
      if (weekday == 1 || weekday == 3 || weekday == 5) {
        workoutIds = [
          'squat_barbell', 'bench_press_barbell', 'lat_pulldown', 
          'military_press', 'barbell_curl', 'tricep_pushdown'
        ];
      }
    }
    
    // --- LÓGICA DE 4 DÍAS (TORSO / PIERNA) ---
    else if (trainingDays == 4) {
      if (weekday == 1 || weekday == 4) { // Torso
        workoutIds = [
          'bench_press_barbell', 'barbell_row', 'military_press', 
          'pull_up', 'incline_db_press', 'lateral_raises'
        ];
      } else if (weekday == 2 || weekday == 5) { // Pierna
        workoutIds = [
          'squat_barbell', 'romanian_deadlift', 'leg_press', 
          'leg_extension', 'hamstring_curl_seated', 'standing_calf_raise'
        ];
      }
    }

    // --- LÓGICA DE 5 DÍAS (PPL) ---
    else {
      if (weekday == 1) workoutIds = ['bench_press_barbell', 'military_press', 'incline_db_press', 'lateral_raises', 'tricep_pushdown'];
      else if (weekday == 2) workoutIds = ['romanian_deadlift', 'pull_up', 'barbell_row', 'face_pull', 'barbell_curl'];
      else if (weekday == 3) workoutIds = ['squat_barbell', 'leg_press', 'leg_extension', 'hamstring_curl_seated', 'standing_calf_raise'];
      else if (weekday == 4) workoutIds = ['bench_press_barbell', 'lat_pulldown', 'db_shoulder_press', 'hammer_curl', 'skullcrushers'];
      else if (weekday == 5) workoutIds = ['romanian_deadlift', 'bulgarian_split_squat', 'leg_press', 'hamstring_curl_seated'];
    }

    if (workoutIds.isEmpty) return [];

    // Mapeo seguro usando la nueva base de datos
    return workoutIds.map((id) {
      try {
        // Busca en la lista estática 'allExercises'
        return ExerciseDatabase.allExercises.firstWhere((e) => e.id == id);
      } catch (e) {
        // Si falla, crea un ejercicio genérico compatible
        return Exercise(
          id: id, 
          name: id.replaceAll('_', ' ').toUpperCase(), 
          targetMuscle: 'General', 
          category: 'General', 
          scientificNote: '',
          alternativeIds: []
        );
      }
    }).toList();
  }
}