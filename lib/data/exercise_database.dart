class Exercise {
  final String id;
  final String name;
  final String targetMuscle; // Antes "muscleGroup", renombrado para compatibilidad
  final String category;    
  final String scientificNote;
  final List<String> alternativeIds; // Añadido para compatibilidad

  Exercise({
    required this.id,
    required this.name,
    required this.targetMuscle,
    required this.category,
    required this.scientificNote,
    this.alternativeIds = const [], // Valor por defecto para no romper código antiguo
  });
}

class ExerciseDatabase {
  // Renombrado a 'allExercises' para que home_screen.dart lo encuentre
  static List<Exercise> allExercises = [
    // --- PECHO ---
    Exercise(
      id: 'bench_press_barbell',
      name: 'Press Banca con Barra',
      targetMuscle: 'Pecho',
      category: 'Barra',
      scientificNote: 'El rey de la fuerza de empuje. Alta activación del pectoral mayor y tríceps.',
    ),
    Exercise(
      id: 'incline_db_press',
      name: 'Press Inclinado Mancuernas',
      targetMuscle: 'Pecho',
      category: 'Mancuerna',
      scientificNote: 'Superior para la porción clavicular (pectoral superior).',
    ),
    Exercise(
      id: 'chest_fly_cable',
      name: 'Aperturas en Polea (Cruce)',
      targetMuscle: 'Pecho',
      category: 'Cable',
      scientificNote: 'Tensión constante, ideal para estrés metabólico.',
    ),
    Exercise(
      id: 'dips_weighted',
      name: 'Fondos en Paralelas (Dips)',
      targetMuscle: 'Pecho',
      category: 'Corporal',
      scientificNote: 'Gran activación del pectoral inferior y tríceps.',
    ),
    Exercise(
      id: 'machine_chest_press',
      name: 'Press de Pecho en Máquina',
      targetMuscle: 'Pecho',
      category: 'Máquina',
      scientificNote: 'Estabilidad máxima para llegar al fallo muscular seguro.',
    ),

    // --- ESPALDA ---
    Exercise(
      id: 'pull_up',
      name: 'Dominadas (Pull Ups)',
      targetMuscle: 'Espalda',
      category: 'Corporal',
      scientificNote: 'El mejor constructor de amplitud dorsal.',
    ),
    Exercise(
      id: 'lat_pulldown',
      name: 'Jalón al Pecho (Polea)',
      targetMuscle: 'Espalda',
      category: 'Cable',
      scientificNote: 'Alternativa biomecánica controlada a las dominadas.',
    ),
    Exercise(
      id: 'barbell_row',
      name: 'Remo con Barra (Pendlay)',
      targetMuscle: 'Espalda',
      category: 'Barra',
      scientificNote: 'Constructor de densidad y fuerza bruta.',
    ),
    Exercise(
      id: 'cable_row_seated',
      name: 'Remo en Polea Baja',
      targetMuscle: 'Espalda',
      category: 'Cable',
      scientificNote: 'Permite aislar el dorsal ancho eliminando inercia.',
    ),
    Exercise(
      id: 'single_arm_db_row',
      name: 'Remo con Mancuerna',
      targetMuscle: 'Espalda',
      category: 'Mancuerna',
      scientificNote: 'Corrige asimetrías y permite rango extendido.',
    ),
    Exercise(
      id: 'face_pull',
      name: 'Face Pull',
      targetMuscle: 'Hombro',
      category: 'Cable',
      scientificNote: 'Crucial para salud del manguito rotador.',
    ),

    // --- PIERNAS ---
    Exercise(
      id: 'squat_barbell',
      name: 'Sentadilla con Barra',
      targetMuscle: 'Pierna',
      category: 'Barra',
      scientificNote: 'Máximo reclutamiento de unidades motoras.',
    ),
    Exercise(
      id: 'leg_press',
      name: 'Prensa de Piernas 45°',
      targetMuscle: 'Pierna',
      category: 'Máquina',
      scientificNote: 'Carga alta sin fatiga axial en la columna.',
    ),
    Exercise(
      id: 'romanian_deadlift',
      name: 'Peso Muerto Rumano',
      targetMuscle: 'Pierna',
      category: 'Barra',
      scientificNote: 'El mejor para isquiosurales basado en estiramiento.',
    ),
    Exercise(
      id: 'leg_extension',
      name: 'Extensiones de Cuádriceps',
      targetMuscle: 'Pierna',
      category: 'Máquina',
      scientificNote: 'Aislamiento puro del recto femoral.',
    ),
    Exercise(
      id: 'hamstring_curl_seated',
      name: 'Curl Femoral Sentado',
      targetMuscle: 'Pierna',
      category: 'Máquina',
      scientificNote: 'Biomecánicamente superior al tumbado.',
    ),
    Exercise(
      id: 'bulgarian_split_squat',
      name: 'Sentadilla Búlgara',
      targetMuscle: 'Pierna',
      category: 'Mancuerna',
      scientificNote: 'El rey unilateral para glúteo y cuádriceps.',
    ),
    Exercise(
      id: 'standing_calf_raise',
      name: 'Elevación de Talones',
      targetMuscle: 'Pierna',
      category: 'Máquina',
      scientificNote: 'Enfocado en el gastrocnemio.',
    ),

    // --- HOMBROS ---
    Exercise(
      id: 'military_press',
      name: 'Press Militar',
      targetMuscle: 'Hombro',
      category: 'Barra',
      scientificNote: 'Constructor de masa global del hombro.',
    ),
    Exercise(
      id: 'db_shoulder_press',
      name: 'Press Hombros Mancuernas',
      targetMuscle: 'Hombro',
      category: 'Mancuerna',
      scientificNote: 'Mayor rango de movimiento que la barra.',
    ),
    Exercise(
      id: 'lateral_raises',
      name: 'Elevaciones Laterales',
      targetMuscle: 'Hombro',
      category: 'Mancuerna',
      scientificNote: 'Esencial para la anchura (cabeza lateral).',
    ),
    Exercise(
      id: 'cable_lateral_raise',
      name: 'Elevaciones Laterales Polea',
      targetMuscle: 'Hombro',
      category: 'Cable',
      scientificNote: 'Tensión constante desde el inicio.',
    ),

    // --- BRAZOS ---
    Exercise(
      id: 'barbell_curl',
      name: 'Curl de Bíceps con Barra',
      targetMuscle: 'Brazos',
      category: 'Barra',
      scientificNote: 'Clásico constructor de masa.',
    ),
    Exercise(
      id: 'incline_db_curl',
      name: 'Curl Inclinado Mancuernas',
      targetMuscle: 'Brazos',
      category: 'Mancuerna',
      scientificNote: 'Enfatiza la cabeza larga (pico del bíceps).',
    ),
    Exercise(
      id: 'hammer_curl',
      name: 'Curl Martillo',
      targetMuscle: 'Brazos',
      category: 'Mancuerna',
      scientificNote: 'Enfoca braquial y braquiorradial (densidad).',
    ),
    Exercise(
      id: 'tricep_pushdown',
      name: 'Extensión Tríceps Polea',
      targetMuscle: 'Brazos',
      category: 'Cable',
      scientificNote: 'Aislamiento seguro para tríceps.',
    ),
    Exercise(
      id: 'skullcrushers',
      name: 'Press Francés',
      targetMuscle: 'Brazos',
      category: 'Barra Z',
      scientificNote: 'Gran activación de la cabeza larga.',
    ),
    Exercise(
      id: 'overhead_tricep_extension',
      name: 'Extensión Tríceps Trasnuca',
      targetMuscle: 'Brazos',
      category: 'Cable',
      scientificNote: 'Maximiza la hipertrofia por estiramiento.',
    ),
  ];

  // --- LÓGICA DE ALTERNATIVAS ---
  static List<Exercise> getAlternativesFor(String exerciseName) {
    String name = exerciseName.toLowerCase();

    if (name.contains('banca') || name.contains('bench')) {
      return allExercises.where((e) => e.name.contains('Mancuernas') && e.targetMuscle == 'Pecho').toList();
    }
    if (name.contains('dominada') || name.contains('pull up')) {
      return allExercises.where((e) => e.id == 'lat_pulldown').toList();
    }
    if (name.contains('remo') || name.contains('row')) {
      return allExercises.where((e) => (e.name.contains('Remo') || e.name.contains('Row')) && e.name != exerciseName).toList();
    }
    if (name.contains('sentadilla') || name.contains('squat')) {
      return allExercises.where((e) => e.id == 'leg_press' || e.id == 'bulgarian_split_squat').toList();
    }
    if (name.contains('militar') || name.contains('overhead')) {
      return allExercises.where((e) => e.id == 'db_shoulder_press').toList();
    }

    // Fallback genérico usando 'targetMuscle' en vez de 'muscleGroup'
    return allExercises.where((e) => 
      e.targetMuscle == _getMuscleGroupFor(exerciseName) && 
      e.name != exerciseName
    ).take(3).toList();
  }

  static String _getMuscleGroupFor(String name) {
    var ex = allExercises.firstWhere(
      (e) => e.name.toLowerCase() == name.toLowerCase(), 
      orElse: () => Exercise(id: '', name: '', targetMuscle: '', category: '', scientificNote: '')
    );
    return ex.targetMuscle;
  }
  
  static List<Exercise> search(String query) {
    return allExercises.where((e) => e.name.toLowerCase().contains(query.toLowerCase())).toList();
  }
}