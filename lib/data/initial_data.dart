import 'package:hive/hive.dart';
import '../models/exercise_model.dart';

// Función para cargar los datos del Excel la primera vez
Future<void> loadInitialData() async {
  final box = await Hive.openBox<Exercise>('exercises');

  if (box.isEmpty) {
    
    final List<Map<String, dynamic>> data = [
      {
        "ID": "pecho_press_inclinado_manc",
        "NOMBRE": "Press Inclinado con Mancuernas",
        "PATRON": "empuje_horizontal",
        "ES_COMPUESTO": true,
        "MUSCULO_OBJETIVO": "pecho_superior",
        "SUSTITUTO_ID": "pecho_press_inclinado_maq",
        "NOTA_CIENTIFICA": "Mejor rango de movimiento (ROM) que la barra; enfoca la porción clavicular (estética)."
      },
      {
        "ID": "pecho_press_plano_maq",
        "NOMBRE": "Press de Pecho en Máquina",
        "PATRON": "empuje_horizontal",
        "ES_COMPUESTO": true,
        "MUSCULO_OBJETIVO": "pecho_medio",
        "SUSTITUTO_ID": "pecho_press_banca_manc",
        "NOTA_CIENTIFICA": "Más estable que la barra libre, permite llegar al fallo real sin riesgo de morir aplastado."
      },
      {
        "ID": "espalda_jalon_pecho",
        "NOMBRE": "Jalón al Pecho (Agarre Neutro)",
        "PATRON": "traccion_vertical",
        "ES_COMPUESTO": true,
        "MUSCULO_OBJETIVO": "dorsales",
        "SUSTITUTO_ID": "espalda_dominadas_asistidas",
        "NOTA_CIENTIFICA": "El agarre neutro alinea mejor las fibras del dorsal que el agarre ancho prono."
      },
      {
        "ID": "espalda_remo_pecho_apoyado",
        "NOMBRE": "Remo con Pecho Apoyado (Máquina/T)",
        "PATRON": "traccion_horizontal",
        "ES_COMPUESTO": true,
        "MUSCULO_OBJETIVO": "espalda_alta",
        "SUSTITUTO_ID": "espalda_remo_mancuerna",
        "NOTA_CIENTIFICA": "Al apoyar el pecho, eliminas la fatiga lumbar. Todo el estímulo va a la espalda (Alto SFR)."
      },
      {
        "ID": "hombro_press_mancuerna",
        "NOMBRE": "Press Militar Mancuernas Sentado",
        "PATRON": "empuje_vertical",
        "ES_COMPUESTO": true,
        "MUSCULO_OBJETIVO": "deltoides_anterior",
        "SUSTITUTO_ID": "hombro_press_maquina",
        "NOTA_CIENTIFICA": "Sentado elimina la inestabilidad. Las mancuernas permiten un recorrido más natural que la barra."
      },
      {
        "ID": "hombro_elev_lat_polea",
        "NOMBRE": "Elevaciones Laterales en Polea",
        "PATRON": "aislamiento",
        "ES_COMPUESTO": false,
        "MUSCULO_OBJETIVO": "deltoides_lateral",
        "SUSTITUTO_ID": "hombro_elev_lat_manc",
        "NOTA_CIENTIFICA": "La polea mantiene tensión constante en todo el recorrido, a diferencia de la mancuerna que pierde tensión abajo."
      },
      {
        "ID": "pierna_sentadilla_hack",
        "NOMBRE": "Sentadilla Hack",
        "PATRON": "rodilla",
        "ES_COMPUESTO": true,
        "MUSCULO_OBJETIVO": "cuadriceps",
        "SUSTITUTO_ID": "pierna_prensa_45",
        "NOTA_CIENTIFICA": "El rey de los cuádriceps modernos. Mucha más estabilidad que la sentadilla libre, mayor hipertrofia local."
      },
      {
        "ID": "pierna_prensa",
        "NOMBRE": "Prensa de Piernas 45 Grados",
        "PATRON": "rodilla",
        "ES_COMPUESTO": true,
        "MUSCULO_OBJETIVO": "cuadriceps",
        "SUSTITUTO_ID": "pierna_bulgara",
        "NOTA_CIENTIFICA": "Permite mover grandes cargas sin cargar la columna vertebral."
      },
      {
        "ID": "pierna_curl_sentado",
        "NOMBRE": "Curl Femoral Sentado",
        "PATRON": "aislamiento",
        "ES_COMPUESTO": false,
        "MUSCULO_OBJETIVO": "isquios",
        "SUSTITUTO_ID": "pierna_curl_tumbado",
        "NOTA_CIENTIFICA": "Estudios recientes demuestran que es superior al 'tumbado' porque estira más el isquiotibial en la cadera."
      },
      {
        "ID": "pierna_peso_muerto_rumano",
        "NOMBRE": "Peso Muerto Rumano (Mancuernas)",
        "PATRON": "bisagra_cadera",
        "ES_COMPUESTO": true,
        "MUSCULO_OBJETIVO": "gluteo_isquios",
        "SUSTITUTO_ID": "pierna_hip_thrust",
        "NOTA_CIENTIFICA": "El mejor ejercicio de estiramiento bajo carga para la cadena posterior."
      },
      {
        "ID": "brazo_curl_bayesiano",
        "NOMBRE": "Curl de Bíceps en Polea (Espalda a la polea)",
        "PATRON": "aislamiento",
        "ES_COMPUESTO": false,
        "MUSCULO_OBJETIVO": "biceps",
        "SUSTITUTO_ID": "brazo_curl_inclinado",
        "NOTA_CIENTIFICA": "Aprovecha el estiramiento máximo del bíceps (stretch-mediated hypertrophy)."
      },
      {
        "ID": "brazo_triceps_katana",
        "NOMBRE": "Extension Tríceps Katana (Sobre cabeza)",
        "PATRON": "aislamiento",
        "ES_COMPUESTO": false,
        "MUSCULO_OBJETIVO": "triceps_cabeza_larga",
        "SUSTITUTO_ID": "brazo_triceps_polea",
        "NOTA_CIENTIFICA": "Trabaja el tríceps en posición estirada, crucial para el crecimiento de la cabeza larga."
      }
    ];

    for (var item in data) {
      final exercise = Exercise(
        id: item['ID'],
        name: item['NOMBRE'],
        pattern: item['PATRON'],
        isCompound: item['ES_COMPUESTO'],
        targetMuscle: item['MUSCULO_OBJETIVO'],
        substituteId: item['SUSTITUTO_ID'],
        scientificNote: item['NOTA_CIENTIFICA'],
      );
      await box.put(exercise.id, exercise);
    }
    print('✅ Base de datos cargada.');
  }
}