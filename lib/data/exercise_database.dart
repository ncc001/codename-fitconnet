class Exercise {
  final String id;
  final String name;
  final String targetMuscle;
  final List<String> alternativeIds; // Lista de opciones
  final String scientificNote;       // ¡El dato clave!

  const Exercise({
    required this.id,
    required this.name,
    required this.targetMuscle,
    required this.alternativeIds,
    required this.scientificNote,
  });
}

class ExerciseDatabase {
  // TU LISTA MAESTRA DE DATOS CIENTÍFICOS
  static final List<Map<String, dynamic>> _rawData = [
    {
      "ID": "pecho_press_inclinado_manc",
      "NOMBRE": "Press Inclinado con Mancuernas",
      "PATRON": "empuje_horizontal",
      "ES_COMPUESTO": true,
      "MUSCULO_OBJETIVO": "pecho_superior",
      "SUSTITUTO_ID": "pecho_press_inclinado_maq", // ID DEL SUSTITUTO
      "NOTA_CIENTIFICA": "Mejor rango de movimiento (ROM) que la barra; enfoca la porción clavicular."
    },
    {
      "ID": "pecho_press_inclinado_maq",
      "NOMBRE": "Press Inclinado en Máquina",
      "PATRON": "empuje_horizontal",
      "ES_COMPUESTO": true,
      "MUSCULO_OBJETIVO": "pecho_superior",
      "SUSTITUTO_ID": "pecho_press_inclinado_manc",
      "NOTA_CIENTIFICA": "Mayor estabilidad que las mancuernas, ideal para ir al fallo."
    },
    {
      "ID": "pecho_press_plano_maq",
      "NOMBRE": "Press de Pecho en Máquina",
      "PATRON": "empuje_horizontal",
      "ES_COMPUESTO": true,
      "MUSCULO_OBJETIVO": "pecho_medio",
      "SUSTITUTO_ID": "pecho_press_banca_manc",
      "NOTA_CIENTIFICA": "Más estable que la barra libre, permite llegar al fallo real sin riesgo."
    },
    {
      "ID": "espalda_jalon_pecho",
      "NOMBRE": "Jalón al Pecho (Agarre Neutro)",
      "PATRON": "traccion_vertical",
      "ES_COMPUESTO": true,
      "MUSCULO_OBJETIVO": "dorsales",
      "SUSTITUTO_ID": "espalda_dominadas_asistidas",
      "NOTA_CIENTIFICA": "El agarre neutro alinea mejor las fibras del dorsal."
    },
    {
      "ID": "espalda_remo_pecho_apoyado",
      "NOMBRE": "Remo con Pecho Apoyado",
      "PATRON": "traccion_horizontal",
      "ES_COMPUESTO": true,
      "MUSCULO_OBJETIVO": "espalda_alta",
      "SUSTITUTO_ID": "espalda_remo_mancuerna",
      "NOTA_CIENTIFICA": "Al apoyar el pecho, eliminas la fatiga lumbar. Todo el estímulo va a la espalda."
    },
    {
      "ID": "hombro_press_mancuerna",
      "NOMBRE": "Press Militar Mancuernas",
      "PATRON": "empuje_vertical",
      "ES_COMPUESTO": true,
      "MUSCULO_OBJETIVO": "deltoides_anterior",
      "SUSTITUTO_ID": "hombro_press_maquina",
      "NOTA_CIENTIFICA": "Las mancuernas permiten un recorrido más natural que la barra."
    },
    {
      "ID": "hombro_elev_lat_polea",
      "NOMBRE": "Elevaciones Laterales Polea",
      "PATRON": "aislamiento",
      "ES_COMPUESTO": false,
      "MUSCULO_OBJETIVO": "deltoides_lateral",
      "SUSTITUTO_ID": "hombro_elev_lat_manc",
      "NOTA_CIENTIFICA": "Tensión constante en todo el recorrido, superior a la mancuerna."
    },
    {
      "ID": "pierna_sentadilla_hack",
      "NOMBRE": "Sentadilla Hack",
      "PATRON": "rodilla",
      "ES_COMPUESTO": true,
      "MUSCULO_OBJETIVO": "cuadriceps",
      "SUSTITUTO_ID": "pierna_prensa",
      "NOTA_CIENTIFICA": "El rey de los cuádriceps modernos. Mayor estabilidad que la libre."
    },
    {
      "ID": "pierna_prensa",
      "NOMBRE": "Prensa de Piernas 45º",
      "PATRON": "rodilla",
      "ES_COMPUESTO": true,
      "MUSCULO_OBJETIVO": "cuadriceps",
      "SUSTITUTO_ID": "pierna_sentadilla_hack",
      "NOTA_CIENTIFICA": "Permite mover grandes cargas sin cargar la columna vertebral."
    },
    {
      "ID": "pierna_curl_sentado",
      "NOMBRE": "Curl Femoral Sentado",
      "PATRON": "aislamiento",
      "ES_COMPUESTO": false,
      "MUSCULO_OBJETIVO": "isquios",
      "SUSTITUTO_ID": "pierna_peso_muerto_rumano",
      "NOTA_CIENTIFICA": "Superior al 'tumbado' porque estira más el isquiotibial en la cadera."
    },
    {
      "ID": "pierna_peso_muerto_rumano",
      "NOMBRE": "Peso Muerto Rumano",
      "PATRON": "bisagra_cadera",
      "ES_COMPUESTO": true,
      "MUSCULO_OBJETIVO": "gluteo_isquios",
      "SUSTITUTO_ID": "pierna_curl_sentado",
      "NOTA_CIENTIFICA": "El mejor ejercicio de estiramiento bajo carga para la cadena posterior."
    },
    {
      "ID": "brazo_curl_bayesiano",
      "NOMBRE": "Curl Bayessiano (Polea)",
      "PATRON": "aislamiento",
      "ES_COMPUESTO": false,
      "MUSCULO_OBJETIVO": "biceps",
      "SUSTITUTO_ID": "brazo_curl_inclinado",
      "NOTA_CIENTIFICA": "Aprovecha el estiramiento máximo del bíceps."
    },
    {
      "ID": "brazo_triceps_katana",
      "NOMBRE": "Extensión Katana",
      "PATRON": "aislamiento",
      "ES_COMPUESTO": false,
      "MUSCULO_OBJETIVO": "triceps",
      "SUSTITUTO_ID": "brazo_triceps_polea",
      "NOTA_CIENTIFICA": "Trabaja el tríceps en posición estirada (cabeza larga)."
    }
  ];

  // Convertimos tu Mapa en Objetos Útiles
  static List<Exercise> get allExercises {
    return _rawData.map((data) {
      return Exercise(
        id: data['ID'],
        name: data['NOMBRE'],
        targetMuscle: data['MUSCULO_OBJETIVO'],
        // Aquí convertimos el SUSTITUTO_ID único en una Lista para el futuro
        alternativeIds: [data['SUSTITUTO_ID']], 
        scientificNote: data['NOTA_CIENTIFICA'],
      );
    }).toList();
  }

  // LÓGICA INTELIGENTE: Buscar por nombre
  static Exercise? findByName(String name) {
    try {
      // Búsqueda flexible (ignora mayúsculas/minúsculas)
      return allExercises.firstWhere((e) => e.name.toLowerCase().contains(name.toLowerCase()));
    } catch (e) {
      return null; 
    }
  }

  // LÓGICA INTELIGENTE: Buscar alternativas
  static List<Exercise> getAlternativesFor(String exerciseName) {
    final current = findByName(exerciseName);
    if (current == null) return [];

    // Buscamos los ejercicios cuyos IDs coincidan con el SUSTITUTO_ID del actual
    return allExercises.where((e) => current.alternativeIds.contains(e.id)).toList();
  }
}