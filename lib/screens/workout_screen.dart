import 'dart:async';
import 'dart:ui'; 
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Para HapticFeedback (Vibración nativa)
import 'package:hive_flutter/hive_flutter.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:wakelock_plus/wakelock_plus.dart'; // Para mantener pantalla encendida
import '../data/exercise_database.dart'; 

class WorkoutScreen extends StatefulWidget {
  final String exerciseName;
  final int targetSets; 
  final String targetReps; 
  final int restSeconds;

  const WorkoutScreen({
    super.key, 
    required this.exerciseName, 
    this.targetSets = 4,
    this.targetReps = "10-12",
    this.restSeconds = 90, 
  });

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  late String currentExerciseName;
  List<Map<String, dynamic>> setsData = [];
  List<Map<String, String>> previousValues = [];
  final ScrollController _scrollController = ScrollController(); 
  
  Timer? _timer;         
  Timer? _alarmTimer;    
  int _alarmLoopCount = 0; 

  final ValueNotifier<int> _timeLeftNotifier = ValueNotifier(0);
  final ValueNotifier<bool> _isRestFinishedNotifier = ValueNotifier(false);
  final ValueNotifier<bool> _isPausedNotifier = ValueNotifier(false);
  
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isLoading = true;
  String _historyText = "Cargando...";

  @override
  void initState() {
    super.initState();
    currentExerciseName = widget.exerciseName;
    _configureAudioSession(); // Configura el audio para pausar/reanudar Spotify
    _initializeRealData(); 
  }

  // --- CONFIGURACIÓN DE AUDIO CORRECTA ---
  Future<void> _configureAudioSession() async {
    final AudioContext audioContext = AudioContext(
      iOS: AudioContextIOS(
        category: AVAudioSessionCategory.playback, 
        options: {AVAudioSessionOptions.duckOthers}, // CORREGIDO: {} en lugar de []
      ),
      android: AudioContextAndroid(
        isSpeakerphoneOn: true,
        stayAwake: true,
        contentType: AndroidContentType.sonification,
        usageType: AndroidUsageType.assistanceSonification,
        // gainTransient: Pide el audio, pausa a los demás, y lo devuelve al terminar
        audioFocus: AndroidAudioFocus.gainTransient, 
      ),
    );
    await AudioPlayer.global.setAudioContext(audioContext);
  }
  
  @override
  void dispose() {
    WakelockPlus.disable(); // Asegurar que la pantalla se apague al salir
    _timer?.cancel();
    _alarmTimer?.cancel(); 
    _audioPlayer.dispose();
    _scrollController.dispose();
    _timeLeftNotifier.dispose();
    _isRestFinishedNotifier.dispose();
    _isPausedNotifier.dispose();
    for (var set in setsData) { set['weight'].dispose(); set['reps'].dispose(); }
    super.dispose();
  }

  Future<void> _initializeRealData() async {
    setState(() => _isLoading = true); 

    var historyBox = await Hive.openBox('exercise_history');
    var sessionData = historyBox.get(currentExerciseName);
    
    String newHistoryText = "Nuevo Ejercicio";
    List<dynamic> savedSets = []; 

    if (sessionData != null && sessionData is Map) {
      if (sessionData['sets'] != null) savedSets = sessionData['sets'];
      var maxW = sessionData['max_weight'] ?? 0.0;
      if (maxW > 0) newHistoryText = "Récord: ${maxW}kg";
    }

    List<Map<String, dynamic>> tempSets = [];
    List<Map<String, String>> tempPrev = []; 
    String defaultRepVal = widget.targetReps.split('-')[0].trim(); 

    for (int i = 0; i < widget.targetSets; i++) {
      String savedWeight = "";
      String savedReps = defaultRepVal; 
      bool savedCompleted = false;

      if (i < savedSets.length) {
        var s = savedSets[i];
        savedWeight = s['weight']?.toString() ?? "";
        savedReps = s['reps']?.toString() ?? defaultRepVal;
        savedCompleted = s['completed'] ?? false;
      }

      tempSets.add({
        "weight": TextEditingController(text: savedWeight),
        "reps": TextEditingController(text: savedReps), 
        "isCompleted": savedCompleted, 
      });

      tempPrev.add({
        "weight": savedWeight.isEmpty ? "-" : savedWeight,
        "reps": savedReps
      });
    }

    if (mounted) {
      setState(() {
        setsData = tempSets;
        previousValues = tempPrev; 
        _historyText = newHistoryText;
        _isLoading = false;
      });
      Future.delayed(const Duration(milliseconds: 300), _scrollToActiveSet);
    }
  }

  Future<bool> _onWillPop() async {
    WakelockPlus.disable(); // Desactivar Wakelock si usan botón atrás
    await _saveWorkoutResult(); 
    if (mounted) {
      Navigator.pop(context, currentExerciseName);
    }
    return false; 
  }

  void _goBack() => _onWillPop();
  void _saveAndExit() => _onWillPop();

  void _showSwapConfirmation(Exercise newExercise) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text("Confirmar Cambio", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text("¿Cambiar a ${newExercise.name}?\n\nSe reiniciará esta sesión.", style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCELAR", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E676)),
            onPressed: () {
              Navigator.pop(ctx); 
              setState(() => currentExerciseName = newExercise.name);
              _initializeRealData();
              _saveWorkoutResult(); 
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Cambiado a: ${newExercise.name}"), backgroundColor: const Color(0xFF00E676), duration: const Duration(seconds: 1)));
            },
            child: const Text("SÍ, CAMBIAR", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  void _showSwapOptions() {
    List<Exercise> alternatives = ExerciseDatabase.getAlternativesFor(currentExerciseName);
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: const [Icon(Icons.science, color: Color(0xFF00E676)), SizedBox(width: 10), Text("Alternativa Científica", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))]),
              const SizedBox(height: 5),
              const Text("Si la máquina está ocupada, usa esta opción biomecánicamente similar.", style: TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 20),
              if (alternatives.isEmpty)
                Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(10)), child: const Text("No se encontró un sustituto directo en la base de datos.", style: TextStyle(color: Colors.grey)))
              else
                ...alternatives.map((alt) => ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 5),
                    title: Text(alt.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: Text("💡 ${alt.scientificNote}", style: const TextStyle(color: Color(0xFF00E676), fontStyle: FontStyle.italic, fontSize: 12)),
                    trailing: const Icon(Icons.touch_app, color: Color(0xFF00E676), size: 20),
                    onTap: () { Navigator.pop(context); _showSwapConfirmation(alt); },
                  )).toList(),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveWorkoutResult() async {
    double maxWeightToday = 0.0;
    List<Map<String, dynamic>> setsToSave = [];
    for (var set in setsData) {
      String wText = set['weight'].text;
      String rText = set['reps'].text;
      if (wText.isNotEmpty) {
        double w = double.tryParse(wText) ?? 0.0;
        if (w > maxWeightToday) maxWeightToday = w;
      }
      setsToSave.add({'weight': wText, 'reps': rText, 'completed': set['isCompleted']});
    }
    var historyBox = await Hive.openBox('exercise_history');
    await historyBox.put(currentExerciseName, {'sets': setsToSave, 'max_weight': maxWeightToday, 'date': DateTime.now().toString()});
  }

  int _getActiveSetIndex() => setsData.indexWhere((set) => set['isCompleted'] == false);

  void _scrollToActiveSet() {
    int activeIndex = _getActiveSetIndex();
    if (activeIndex != -1 && _scrollController.hasClients) {
      _scrollController.animateTo(activeIndex * 80.0, duration: const Duration(milliseconds: 600), curve: Curves.easeOut);
    }
  }

  // --- TIMERS ---
  void _startRestTimer() { 
    WakelockPlus.enable(); // MANTENER PANTALLA
    _timeLeftNotifier.value = widget.restSeconds; 
    _isRestFinishedNotifier.value = false; 
    _isPausedNotifier.value = false; 
    HapticFeedback.mediumImpact(); 
    _showTimerOverlay(); 
    _resumeInternalTimer(); 
  }

  void _resumeInternalTimer() { _timer?.cancel(); _timer = Timer.periodic(const Duration(seconds: 1), (timer) { if (!mounted) { timer.cancel(); return; } if (_isPausedNotifier.value) return; if (_timeLeftNotifier.value > 0) { _timeLeftNotifier.value--; } else { timer.cancel(); _finishTimerSequence(); } }); }
  void _finishTimerSequence() { if (!mounted) return; _isRestFinishedNotifier.value = true; _triggerSafeAlarmLoop(); }
  void _triggerSafeAlarmLoop() { _alarmTimer?.cancel(); _alarmLoopCount = 0; _playAlarmSignal(); _alarmTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) { if (!mounted || !_isRestFinishedNotifier.value) { timer.cancel(); return; } if (_alarmLoopCount >= 20) { timer.cancel(); _audioPlayer.stop(); return; } _playAlarmSignal(); _alarmLoopCount++; }); }
  
  void _playAlarmSignal() { 
    _audioPlayer.stop(); 
    _audioPlayer.play(AssetSource('sounds/bell.mp3'), volume: 0.8); 
    HapticFeedback.heavyImpact(); 
  }
  
  void _stopTimerAndClose() { 
    WakelockPlus.disable(); // APAGAR PANTALLA PERMITIDO
    _timer?.cancel(); 
    _alarmTimer?.cancel(); 
    _audioPlayer.stop(); 
    if (mounted && Navigator.canPop(context)) { 
      Navigator.of(context).pop(); 
      Future.delayed(const Duration(milliseconds: 300), _scrollToActiveSet); 
    } 
  }
  
  void _togglePause() => _isPausedNotifier.value = !_isPausedNotifier.value;
  void _addTime(int seconds) => _timeLeftNotifier.value += seconds;
  void _subtractTime(int seconds) { if (_timeLeftNotifier.value > seconds) _timeLeftNotifier.value -= seconds; else _timeLeftNotifier.value = 0; }

  void _showTimerOverlay() {
    showDialog(context: context, barrierDismissible: false, builder: (context) {
        return ValueListenableBuilder<bool>(valueListenable: _isRestFinishedNotifier, builder: (context, isFinished, child) {
            Color bgColor = isFinished ? const Color(0xFFD50000) : const Color(0xFF121212);
            return Scaffold(backgroundColor: bgColor, body: SafeArea(child: SizedBox(width: double.infinity, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Spacer(flex: 2), Text(isFinished ? "¡A ENTRENAR!" : "RECUPERANDO...", style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 2), textAlign: TextAlign.center),
                      const SizedBox(height: 30), ValueListenableBuilder<int>(valueListenable: _timeLeftNotifier, builder: (context, time, _) => Text(_formatTime(time), style: TextStyle(fontSize: 100, fontWeight: FontWeight.w900, color: isFinished ? Colors.white : const Color(0xFF00E676), fontFeatures: const [FontFeature.tabularFigures()]))),
                      const SizedBox(height: 40),
                      if (!isFinished) ValueListenableBuilder<bool>(valueListenable: _isPausedNotifier, builder: (context, isPaused, _) => Row(mainAxisAlignment: MainAxisAlignment.center, children: [_timerControlBtn(Icons.replay_30, "-30", () => _subtractTime(30)), const SizedBox(width: 25), InkWell(onTap: _togglePause, borderRadius: BorderRadius.circular(50), child: Container(padding: const EdgeInsets.all(20), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: Icon(isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded, color: Colors.black, size: 50))), const SizedBox(width: 25), _timerControlBtn(Icons.forward_30, "+30", () => _addTime(30))])),
                      const Spacer(flex: 2), Padding(padding: const EdgeInsets.only(bottom: 40), child: TextButton.icon(onPressed: _stopTimerAndClose, icon: Icon(isFinished ? Icons.check_circle : Icons.stop_circle_outlined, color: Colors.white, size: 30), label: Text(isFinished ? "LISTO" : "DETENER", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)), style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15), backgroundColor: Colors.white10, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)), side: const BorderSide(color: Colors.white24))))
                    ]))));
          });
    }).then((_) { 
      WakelockPlus.disable(); // Asegurar desactivación al cerrar modal
      _timer?.cancel(); _alarmTimer?.cancel(); _audioPlayer.stop(); 
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(backgroundColor: Color(0xFF121212), body: Center(child: CircularProgressIndicator()));

    return WillPopScope(
      onWillPop: _onWillPop, 
      child: Scaffold(
        backgroundColor: const Color(0xFF121212),
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(currentExerciseName.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)), Text(_historyText, style: const TextStyle(color: Color(0xFF00E676), fontSize: 12))]),
          actions: [Container(margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 10), child: TextButton.icon(onPressed: _showSwapOptions, icon: const Icon(Icons.swap_horiz, size: 16, color: Colors.black), label: const Text("Alternativa", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)), style: TextButton.styleFrom(backgroundColor: const Color(0xFF00E676), padding: const EdgeInsets.symmetric(horizontal: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)))))],
          leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: _goBack),
        ),
        body: Column(
          children: [
            Container(padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10), color: Colors.black, child: Row(children: const [SizedBox(width: 40, child: Text("#", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))), Expanded(child: Center(child: Text("PESO (KG)", style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1)))), Expanded(child: Center(child: Text("REPS", style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1)))), SizedBox(width: 80, child: Center(child: Icon(Icons.check, color: Colors.grey, size: 18)))])),
            Expanded(child: ListView.separated(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(vertical: 10), itemCount: widget.targetSets, separatorBuilder: (c, i) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final set = setsData[index];
                  bool isDone = set['isCompleted'];
                  bool isActive = (index == _getActiveSetIndex()) && !isDone; 
                  bool isFuture = !isDone && !isActive;
                  String prevWeight = ""; 
                  String prevReps = "";
                  if (index < previousValues.length) { prevWeight = previousValues[index]['weight']!; prevReps = previousValues[index]['reps']!; }

                  return Opacity(
                    opacity: isFuture ? 0.3 : 1.0,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 5),
                      decoration: BoxDecoration(color: isDone ? const Color(0xFF1B2E21) : const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(12), border: Border.all(color: isActive ? const Color(0xFF00E676) : Colors.transparent, width: 1.5)),
                      child: Row(
                        children: [
                          SizedBox(width: 35, child: CircleAvatar(radius: 12, backgroundColor: isDone ? const Color(0xFF00E676) : Colors.grey[800], child: Text("${index + 1}", style: TextStyle(color: isDone ? Colors.black : Colors.white, fontSize: 12, fontWeight: FontWeight.bold)))),
                          Expanded(child: Column(children: [_buildInput(set['weight'], "0", isActive), if (isActive && prevWeight != "-") Text("Ant: ${prevWeight}kg", style: TextStyle(color: Colors.grey[600], fontSize: 10))])),
                          const SizedBox(width: 10),
                          Expanded(child: Column(children: [_buildRepStepper(set['reps'], isActive), if (isActive && prevReps.isNotEmpty) Text("Ant: $prevReps", style: TextStyle(color: Colors.grey[600], fontSize: 10))])),
                          SizedBox(width: 80, child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                              if (isDone) Padding(padding: const EdgeInsets.only(right: 5), child: GestureDetector(onTap: () { HapticFeedback.mediumImpact(); setState(() { set['isCompleted'] = false; }); _saveWorkoutResult(); }, child: const Icon(Icons.delete_outline, color: Colors.grey, size: 24))),
                              GestureDetector(onTap: () { if (!isDone) { if (set['weight'].text.isEmpty || set['reps'].text.isEmpty) { HapticFeedback.heavyImpact(); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Row(children: const [Icon(Icons.warning_amber_rounded, color: Colors.white), SizedBox(width: 10), Text("¡Faltan datos!")]), backgroundColor: Colors.orange[800], behavior: SnackBarBehavior.floating, margin: const EdgeInsets.all(20))); return; } setState(() => set['isCompleted'] = true); _saveWorkoutResult(); _startRestTimer(); } }, child: Icon(isDone ? Icons.check_circle : Icons.circle_outlined, size: 32, color: isDone ? const Color(0xFF00E676) : (isActive ? Colors.white : Colors.grey))),
                            ])),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(padding: const EdgeInsets.all(20), child: ElevatedButton(onPressed: _saveAndExit, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E1E1E), foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 55), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: const BorderSide(color: Colors.white10)), elevation: 0), child: const Text("GUARDAR Y SALIR", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1))))
          ],
        ),
      ),
    );
  }

  Widget _buildRepStepper(TextEditingController controller, bool isEnabled) {
    return Container(
      height: 45, decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(10)),
      child: Stack(alignment: Alignment.center, children: [
          TextField(controller: controller, enabled: isEnabled, keyboardType: const TextInputType.numberWithOptions(decimal: true), textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 18), decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.zero)),
          if (isEnabled) ...[
            Positioned(left: 0, top: 0, bottom: 0, child: GestureDetector(onTap: () { int val = int.tryParse(controller.text) ?? 0; if (val > 0) { controller.text = (val - 1).toString(); HapticFeedback.lightImpact(); } }, child: Container(width: 35, color: Colors.transparent, child: const Icon(Icons.remove, color: Colors.grey, size: 16)))),
            Positioned(right: 0, top: 0, bottom: 0, child: GestureDetector(onTap: () { int val = int.tryParse(controller.text) ?? 0; controller.text = (val + 1).toString(); HapticFeedback.lightImpact(); }, child: Container(width: 35, color: Colors.transparent, child: const Icon(Icons.add, color: Color(0xFF00E676), size: 16)))),
          ]
        ]),
    );
  }

  Widget _buildInput(TextEditingController controller, String placeholder, bool isEnabled) {
    return Container(height: 45, decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(10)), child: Center(child: TextField(controller: controller, enabled: isEnabled, keyboardType: const TextInputType.numberWithOptions(decimal: true), textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 18), decoration: InputDecoration(hintText: placeholder, hintStyle: TextStyle(color: Colors.grey[800], fontSize: 18), border: InputBorder.none, contentPadding: EdgeInsets.zero))));
  }
  Widget _timerControlBtn(IconData icon, String label, VoidCallback onTap) { return Column(children: [IconButton(onPressed: onTap, icon: Icon(icon, color: Colors.white, size: 28), padding: EdgeInsets.zero, constraints: const BoxConstraints()), const SizedBox(height: 5), Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10))]); }
  String _formatTime(int totalSeconds) { int min = totalSeconds ~/ 60; int sec = totalSeconds % 60; return "${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}"; }
}