import 'package:hive/hive.dart';

part 'exercise_model.g.dart'; // Esto se generará automáticamente después

@HiveType(typeId: 0) // ID único para este tipo de objeto
class Exercise extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String pattern; // empuje, traccion, etc.

  @HiveField(3)
  final bool isCompound;

  @HiveField(4)
  final String targetMuscle;

  @HiveField(5)
  final String substituteId;

  @HiveField(6)
  final String scientificNote;

  Exercise({
    required this.id,
    required this.name,
    required this.pattern,
    required this.isCompound,
    required this.targetMuscle,
    required this.substituteId,
    required this.scientificNote,
  });
}