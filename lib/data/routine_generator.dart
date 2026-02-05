import 'exercise_database.dart';

class RoutineGenerator {
  
  // Método principal: "Dame la rutina para hoy"
  static List<Map<String, dynamic>> generate(int trainingDays, int weekday) {
    // weekday: 1 = Lunes, 7 = Domingo
    
    if (trainingDays == 3) return _get3DaySplit(weekday);
    if (trainingDays == 4) return _get4DaySplit(weekday);
    if (trainingDays == 5) return _get5DaySplit(weekday);
    
    // Por defecto (si no hay config), devolvemos Torso (Lunes)
    return _getTorsoRoutine();
  }

  // --- LÓGICA 3 DÍAS (FULL BODY) ---
  // Lunes (1), Miércoles (3), Viernes (5)
  static List<Map<String, dynamic>> _get3DaySplit(int day) {
    if (day == 1 || day == 5) return _getFullBodyA(); // Lun y Vie
    if (day == 3) return _getFullBodyB();             // Mié
    return []; // Días de descanso
  }

  // --- LÓGICA 4 DÍAS (TORSO / PIERNA) ---
  // Lun (1), Mar (2), Jue (4), Vie (5)
  static List<Map<String, dynamic>> _get4DaySplit(int day) {
    if (day == 1 || day == 4) return _getTorsoRoutine(); // Torso
    if (day == 2 || day == 5) return _getPiernaRoutine(); // Pierna
    return []; // Mié, Sáb, Dom descanso
  }

  // --- LÓGICA 5 DÍAS (HÍBRIDA) ---
  // Lun (Torso), Mar (Pierna), Jue (Empuje), Vie (Tracción), Sáb (Pierna)
  static List<Map<String, dynamic>> _get5DaySplit(int day) {
    if (day == 1) return _getTorsoRoutine();
    if (day == 2) return _getPiernaRoutine();
    if (day == 4) return _getEmpujeRoutine(); // Push
    if (day == 5) return _getTraccionRoutine(); // Pull
    if (day == 6) return _getPiernaRoutine(); // Leg (focus diferente idealmente, pero usamos base)
    return []; // Mié y Dom descanso
  }

  // --- DEFINICIÓN DE RUTINAS (Usando tu BD Científica) ---
  
  static List<Map<String, dynamic>> _getTorsoRoutine() {
    return [
      _buildEx("pecho_press_inclinado_manc", 4, "8-10", true), // Compuesto pesado
      _buildEx("espalda_jalon_pecho", 4, "10-12", false),
      _buildEx("hombro_press_mancuerna", 3, "8-12", false),
      _buildEx("pecho_press_plano_maq", 3, "12-15", false), // Fatiga metabólica
      _buildEx("espalda_remo_pecho_apoyado", 3, "12-15", false),
      _buildEx("hombro_elev_lat_polea", 3, "15-20", false),
    ];
  }

  static List<Map<String, dynamic>> _getPiernaRoutine() {
    return [
      _buildEx("pierna_sentadilla_hack", 4, "6-10", true), // Pesado
      _buildEx("pierna_peso_muerto_rumano", 3, "8-12", false),
      _buildEx("pierna_prensa", 3, "12-15", false),
      _buildEx("pierna_curl_sentado", 3, "12-15", false),
      _buildEx("pierna_bulgara", 2, "12-15", false), // Unilateral opcional (id inventado si no existe)
    ];
  }

  static List<Map<String, dynamic>> _getFullBodyA() {
    return [
      _buildEx("pierna_sentadilla_hack", 3, "8-10", true),
      _buildEx("pecho_press_inclinado_manc", 3, "8-10", false),
      _buildEx("espalda_jalon_pecho", 3, "10-12", false),
      _buildEx("hombro_elev_lat_polea", 3, "15", false),
      _buildEx("brazo_curl_bayesiano", 3, "12", false),
    ];
  }

  static List<Map<String, dynamic>> _getFullBodyB() {
    return [
      _buildEx("pierna_peso_muerto_rumano", 3, "8-10", true),
      _buildEx("hombro_press_mancuerna", 3, "8-10", false),
      _buildEx("espalda_remo_pecho_apoyado", 3, "10-12", false),
      _buildEx("pecho_press_plano_maq", 3, "12", false),
      _buildEx("brazo_triceps_katana", 3, "12", false),
    ];
  }

  static List<Map<String, dynamic>> _getEmpujeRoutine() {
    return [
      _buildEx("pecho_press_inclinado_manc", 4, "8-10", true),
      _buildEx("hombro_press_mancuerna", 3, "10-12", false),
      _buildEx("pecho_press_plano_maq", 3, "12-15", false),
      _buildEx("hombro_elev_lat_polea", 4, "15-20", false),
      _buildEx("brazo_triceps_katana", 3, "12-15", false),
    ];
  }

  static List<Map<String, dynamic>> _getTraccionRoutine() {
    return [
      _buildEx("espalda_jalon_pecho", 4, "8-12", true),
      _buildEx("espalda_remo_pecho_apoyado", 3, "10-12", false),
      _buildEx("hombro_face_pull", 3, "15", false), // (Face pull)
      _buildEx("brazo_curl_bayesiano", 4, "12-15", false),
    ];
  }

  // Helper para construir el objeto rápido y buscar nombre bonito
  static Map<String, dynamic> _buildEx(String id, int sets, String reps, bool weakPoint) {
    // Buscamos el nombre bonito en la BD, si no existe usamos el ID
    String displayName = id;
    final exerciseObj = ExerciseDatabase.allExercises.firstWhere(
      (e) => e.id == id, 
      orElse: () => Exercise(id: id, name: id.replaceAll('_', ' ').toUpperCase(), targetMuscle: '', alternativeIds: [], scientificNote: '')
    );
    
    if (exerciseObj.name != id.toUpperCase()) displayName = exerciseObj.name;

    return {
      "name": displayName, // Nombre real (ej: "Press Inclinado")
      "id": id,            // ID Técnico (ej: "pecho_press...") para búsquedas futuras
      "muscle": exerciseObj.targetMuscle,
      "sets": sets,
      "reps": reps,
      "rest": "90s",
      "isWeakPoint": weakPoint
    };
  }
}