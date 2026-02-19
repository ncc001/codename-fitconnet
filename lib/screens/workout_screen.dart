import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:hive_flutter/hive_flutter.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz;
 

import '../data/exercise_database.dart'; 

class WorkoutScreen extends StatefulWidget {
  final String exerciseName;
  final int targetSets;
  final String targetReps;
  final int restSeconds;
  
  // FECHA DEL CALENDARIO (Vital para que no se mezclen los días)
  final DateTime trainingDate; 

  const WorkoutScreen({
    super.key,
    required this.exerciseName,
    this.targetSets = 4,
    this.targetReps = "10-12",
    this.restSeconds = 90,
    required this.trainingDate, 
  });

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> with WidgetsBindingObserver {
  late String currentExerciseName;
  List<Map<String, dynamic>> setsData = [];
  List<Map<String, String>> previousValues = [];
  final ScrollController _scrollController = ScrollController();

  Timer? _timer;
  Timer? _alarmTimer;
  int _alarmLoopCount = 0;
  DateTime? _timerEndTime; 
  int _frozenTimeLeft = 0;

  final ValueNotifier<int> _timeLeftNotifier = ValueNotifier(0);
  final ValueNotifier<bool> _isRestFinishedNotifier = ValueNotifier(false);
  final ValueNotifier<bool> _isPausedNotifier = ValueNotifier(false);

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isLoading = true;
  String _historyText = "Cargando...";

  int _optimalSets = 4;
  String _optimalReps = "10-12";

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WakelockPlus.enable(); 

    currentExerciseName = widget.exerciseName;
    _initNotifications();
    _configureAudioSession();
    _initializeRealData();
  }

  // --- 1. CONFIGURACIÓN ---

  Future<void> _initNotifications() async {
    tz.initializeTimeZones();
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
  }

  Future<void> _configureAudioSession() async {
    final AudioContext audioContext = AudioContext(
      android: const AudioContextAndroid(
        isSpeakerphoneOn: true,
        stayAwake: true,
        contentType: AndroidContentType.sonification,
        usageType: AndroidUsageType.assistanceSonification,
        audioFocus: AndroidAudioFocus.gainTransient,
      ),
    );
    await AudioPlayer.global.setAudioContext(audioContext);
  }

  // --- 2. LÓGICA DE DATOS ---

  void _calculateOptimalVolume() {
    var settingsBox = Hive.box('settings');
    bool isManual = settingsBox.get('isManualMode', defaultValue: false);

    if (isManual) {
      _optimalSets = 3; 
      _optimalReps = ""; 
      return; 
    }

    final name = currentExerciseName.toLowerCase();
    if (name.contains('sentadilla') || name.contains('muerto') || name.contains('banca')) {
      _optimalSets = 4; _optimalReps = "6-8"; return;
    }
    if (name.contains('prensa') || name.contains('zancada') || name.contains('remo')) {
      _optimalSets = 4; _optimalReps = "8-10"; return;
    }
    _optimalSets = 3; _optimalReps = "12-15";
  }

  Future<void> _initializeRealData() async {
    setState(() => _isLoading = true);
    _calculateOptimalVolume();
    
    var historyBox = await Hive.openBox('exercise_history');
    var sessionData = historyBox.get(currentExerciseName);
    
    String newHistoryText = "Nuevo Ejercicio";
    List<dynamic> savedSets = [];
    
    if (sessionData != null && sessionData is Map) {
      String lastSavedDate = sessionData['date']?.toString().split(' ')[0] ?? "";
      String selectedCalendarDate = widget.trainingDate.toString().split(' ')[0];

      if (lastSavedDate == selectedCalendarDate) {
        savedSets = sessionData['sets'] ?? [];
      } else {
        savedSets = []; 
      }

      var maxW = sessionData['max_weight'] ?? 0.0;
      if (maxW > 0) newHistoryText = "Récord: ${maxW}kg";
    }

    List<Map<String, dynamic>> tempSets = [];
    String defaultRepVal = _optimalReps.isNotEmpty ? _optimalReps.split('-')[0].trim() : "";

    for (int i = 0; i < _optimalSets; i++) {
      String weightToShow = "";
      String repsToShow = defaultRepVal;
      bool completedStatus = false;

      if (i < savedSets.length) {
        var s = savedSets[i];
        weightToShow = s['weight']?.toString() ?? "";
        repsToShow = s['reps']?.toString() ?? defaultRepVal;
        completedStatus = s['completed'] ?? false;
      }

      tempSets.add({
        "weight": TextEditingController(text: weightToShow),
        "reps": TextEditingController(text: repsToShow),
        "isCompleted": completedStatus
      });
    }

    if (mounted) {
      setState(() {
        setsData = tempSets;
        _historyText = newHistoryText;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveWorkoutResult() async {
    double maxWeightToday = 0.0;
    List<Map<String, dynamic>> setsToSave = [];
    
    for (var set in setsData) {
      String wText = set['weight'].text;
      if (wText.isNotEmpty) {
        double w = double.tryParse(wText) ?? 0.0;
        if (w > maxWeightToday) maxWeightToday = w;
      }
      setsToSave.add({
        'weight': wText, 
        'reps': set['reps'].text, 
        'completed': set['isCompleted']
      });
    }

    var historyBox = await Hive.openBox('exercise_history');
    String dateToSave = widget.trainingDate.toString().split(' ')[0]; 

    await historyBox.put(currentExerciseName, {
      'sets': setsToSave,
      'max_weight': maxWeightToday,
      'date': dateToSave, 
    });
  }

  // --- 3. NOTIFICACIONES ---
  // (Mismo código de notificaciones que ya tenías)
  Future<void> _showDynamicIslandNotification({required bool isCountdown, required int secondsBase}) async {
    int whenTime = isCountdown ? DateTime.now().millisecondsSinceEpoch + (secondsBase * 1000) : DateTime.now().millisecondsSinceEpoch - (secondsBase * 1000);
    final androidDetails = AndroidNotificationDetails('workout_timer_channel', 'Temporizador', importance: Importance.max, priority: Priority.max, ongoing: true, autoCancel: false, showWhen: true, when: whenTime, usesChronometer: true, chronometerCountDown: isCountdown, color: const Color(0xFF00E676));
    await flutterLocalNotificationsPlugin.show(0, isCountdown ? 'Descansando...' : 'Entrenando...', isCountdown ? 'Tiempo restante' : 'Tiempo transcurrido', NotificationDetails(android: androidDetails));
  } 
  Future<void> _cancelNotification() async { await flutterLocalNotificationsPlugin.cancel(0); }

  // --- 4. LIFECYCLE ---
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    WakelockPlus.disable();
    _cancelNotification();
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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      if (_timerEndTime != null && !_isRestFinishedNotifier.value) {
        final remaining = _timerEndTime!.difference(DateTime.now()).inSeconds;
        if (remaining > 0) _showDynamicIslandNotification(isCountdown: true, secondsBase: remaining);
      }
    } else if (state == AppLifecycleState.resumed) {
       _cancelNotification();
       _syncTimerUI();
       WakelockPlus.enable();
    }
  }

  // --- 5. TIMER ---
  void _syncTimerUI() {
    if (!mounted || _timerEndTime == null || _isPausedNotifier.value) return;
    final now = DateTime.now();
    final difference = _timerEndTime!.difference(now).inSeconds;
    if (difference <= 0) { _timer?.cancel(); _timeLeftNotifier.value = 0; _finishTimerSequence(); } else { _timeLeftNotifier.value = difference; }
  }
  void _finishTimerSequence() { if (!mounted) return; _cancelNotification(); _isRestFinishedNotifier.value = true; _triggerSafeAlarmLoop(); }
  void _triggerSafeAlarmLoop() { _alarmTimer?.cancel(); _alarmLoopCount = 0; _playAlarmSignal(); _alarmTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) { if (!mounted || !_isRestFinishedNotifier.value || _alarmLoopCount >= 20) { timer.cancel(); _audioPlayer.stop(); return; } _playAlarmSignal(); _alarmLoopCount++; }); }
  void _playAlarmSignal() { _audioPlayer.stop(); _audioPlayer.play(AssetSource('sounds/bell.mp3'), volume: 0.8); HapticFeedback.heavyImpact(); }
  void _resumeInternalTimer() { _timer?.cancel(); if (_isPausedNotifier.value) { _timerEndTime = DateTime.now().add(Duration(seconds: _frozenTimeLeft)); _isPausedNotifier.value = false; } _timer = Timer.periodic(const Duration(milliseconds: 200), (timer) => _syncTimerUI()); }
  void _startRestTimer() { WakelockPlus.enable(); int duration = _getAdaptiveRestTime(); _timerEndTime = DateTime.now().add(Duration(seconds: duration)); _timeLeftNotifier.value = duration; _isRestFinishedNotifier.value = false; _isPausedNotifier.value = false; HapticFeedback.mediumImpact(); _showTimerOverlay(); _resumeInternalTimer(); }
  void _stopTimerAndClose() { _cancelNotification(); _timer?.cancel(); _alarmTimer?.cancel(); _audioPlayer.stop(); if (mounted && Navigator.canPop(context)) { Navigator.of(context).pop(); Future.delayed(const Duration(milliseconds: 300), _scrollToActiveSet); } }
  void _togglePause() { if (_isPausedNotifier.value) { _resumeInternalTimer(); } else { _timer?.cancel(); _isPausedNotifier.value = true; if (_timerEndTime != null) _frozenTimeLeft = _timerEndTime!.difference(DateTime.now()).inSeconds; } }
  int _getAdaptiveRestTime() { var settingsBox = Hive.box('settings'); if (settingsBox.get('isManualMode', defaultValue: false)) return widget.restSeconds; final name = currentExerciseName.toLowerCase(); if (name.contains('sentadilla') || name.contains('muerto') || name.contains('banca')) return 180; if (name.contains('prensa') || name.contains('zancada') || name.contains('remo')) return 120; return 90; }

  // --- 6. UI ---
  void _scrollToActiveSet() { int activeIndex = _getActiveSetIndex(); if (activeIndex != -1 && _scrollController.hasClients) _scrollController.animateTo(activeIndex * 80.0, duration: const Duration(milliseconds: 600), curve: Curves.easeOut); }
  int _getActiveSetIndex() => setsData.indexWhere((set) => set['isCompleted'] == false);
  
  void _showSwapOptions() {
    List<Exercise> alternatives = ExerciseDatabase.getAlternativesFor(currentExerciseName);
    showModalBottomSheet(context: context, backgroundColor: const Color(0xFF1E1E1E), isScrollControlled: true, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (context) {
        return Padding(padding: const EdgeInsets.fromLTRB(20, 20, 20, 40), child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text("Alternativa Científica", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              if (alternatives.isEmpty) const Text("No hay alternativas directas registradas.", style: TextStyle(color: Colors.grey)) else ...alternatives.map((alt) => ListTile(title: Text(alt.name, style: const TextStyle(color: Colors.white)), subtitle: Text(alt.scientificNote, style: const TextStyle(color: Color(0xFF00E676), fontSize: 12)), onTap: () { Navigator.pop(context); setState(() => currentExerciseName = alt.name); _initializeRealData(); },)),
            ]));
      });
  }

  void _showTimerOverlay() {
    showDialog(context: context, barrierDismissible: false, builder: (context) {
        return ValueListenableBuilder<bool>(valueListenable: _isRestFinishedNotifier, builder: (context, isFinished, child) {
            Color bgColor = isFinished ? const Color(0xFFD50000) : const Color(0xFF121212);
            return Scaffold(backgroundColor: bgColor, body: SafeArea(child: SizedBox(width: double.infinity, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Spacer(flex: 2), Text(isFinished ? "¡A ENTRENAR!" : "RECUPERANDO...", style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 2)),
                      const SizedBox(height: 30), ValueListenableBuilder<int>(valueListenable: _timeLeftNotifier, builder: (context, time, _) => Text(_formatTime(time), style: TextStyle(fontSize: 100, fontWeight: FontWeight.w900, color: isFinished ? Colors.white : const Color(0xFF00E676)))),
                      const SizedBox(height: 40),
                      if (!isFinished) ValueListenableBuilder<bool>(valueListenable: _isPausedNotifier, builder: (context, isPaused, _) => Row(mainAxisAlignment: MainAxisAlignment.center, children: [IconButton(onPressed: () => setState(() => _timerEndTime = _timerEndTime?.subtract(const Duration(seconds: 30))), icon: const Icon(Icons.replay_30, color: Colors.white)), const SizedBox(width: 25), InkWell(onTap: _togglePause, child: Container(padding: const EdgeInsets.all(20), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: Icon(isPaused ? Icons.play_arrow : Icons.pause, color: Colors.black, size: 50))), const SizedBox(width: 25), IconButton(onPressed: () => setState(() => _timerEndTime = _timerEndTime?.add(const Duration(seconds: 30))), icon: const Icon(Icons.forward_30, color: Colors.white))])),
                      const Spacer(flex: 2), Padding(padding: const EdgeInsets.only(bottom: 40), child: TextButton.icon(onPressed: _stopTimerAndClose, icon: const Icon(Icons.check_circle, color: Colors.white), label: Text(isFinished ? "LISTO" : "DETENER", style: const TextStyle(color: Colors.white, fontSize: 18))))
                    ]))));
          });
    }).then((_) { _timer?.cancel(); _alarmTimer?.cancel(); _audioPlayer.stop(); _cancelNotification(); });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(backgroundColor: Color(0xFF121212), body: Center(child: CircularProgressIndicator()));
    
    return PopScope(
      canPop: false, 
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;
        WakelockPlus.disable(); 
        await _saveWorkoutResult(); 
        if (context.mounted) Navigator.pop(context, currentExerciseName);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF121212), 
        appBar: AppBar(
          backgroundColor: Colors.black, 
          title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(currentExerciseName.toUpperCase(), style: const TextStyle(fontSize: 16)), Text(_historyText, style: const TextStyle(color: Color(0xFF00E676), fontSize: 12))]), 
          actions: [IconButton(onPressed: _showSwapOptions, icon: const Icon(Icons.swap_horiz, color: Color(0xFF00E676)))]
        ), 
        body: Column(
          children: [
            Container(padding: const EdgeInsets.symmetric(vertical: 15), color: Colors.black, child: const Row(children: [SizedBox(width: 40, child: Text("#", textAlign: TextAlign.center)), Expanded(child: Center(child: Text("PESO (KG)"))), Expanded(child: Center(child: Text("REPS"))), SizedBox(width: 80, child: Center(child: Icon(Icons.check, size: 18)))])),
            Expanded(
              child: ListView.separated(
                controller: _scrollController, 
                padding: const EdgeInsets.symmetric(vertical: 10), 
                itemCount: setsData.length, 
                separatorBuilder: (c, i) => const SizedBox(height: 10), 
                itemBuilder: (context, index) {
                  final set = setsData[index]; 
                  bool isDone = set['isCompleted']; 
                  bool isActive = (index == _getActiveSetIndex()) && !isDone;
                  return Opacity(
                    opacity: (!isDone && !isActive) ? 0.3 : 1.0, 
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 10), 
                      padding: const EdgeInsets.symmetric(vertical: 8), 
                      decoration: BoxDecoration(color: isDone ? const Color(0xFF1B2E21) : const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(12), border: Border.all(color: isActive ? const Color(0xFF00E676) : Colors.transparent)), 
                      child: Row(
                        children: [
                          SizedBox(width: 35, child: CircleAvatar(radius: 12, backgroundColor: isDone ? const Color(0xFF00E676) : Colors.grey[800], child: Text("${index + 1}", style: const TextStyle(fontSize: 12)))),
                          Expanded(child: _buildInput(set['weight'], "0", isActive)), 
                          const SizedBox(width: 10),
                          Expanded(child: _buildRepStepper(set['reps'], isActive)),
                          
                          // --- AQUÍ ESTÁ EL BOTÓN DE CHECK CON VALIDACIÓN ---
                          SizedBox(width: 80, child: Row(
                            mainAxisAlignment: MainAxisAlignment.end, 
                            children: [
                              if (isDone) IconButton(icon: const Icon(Icons.delete_outline, color: Colors.grey), onPressed: () { setState(() => set['isCompleted'] = false); _saveWorkoutResult(); }),
                              IconButton(
                                icon: Icon(isDone ? Icons.check_circle : Icons.circle_outlined, color: isDone ? const Color(0xFF00E676) : Colors.white), 
                                onPressed: () { 
                                  // 🔥 VALIDACIÓN: SI EL PESO ESTÁ VACÍO, ALERTA ROJA 🔥
                                  if (set['weight'].text.isEmpty) {
                                     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("¡Faltan datos! Ingresa el peso."), backgroundColor: Colors.red, duration: Duration(milliseconds: 800)));
                                     return;
                                  }
                                  setState(() => set['isCompleted'] = true); 
                                  _saveWorkoutResult(); 
                                  _startRestTimer(); 
                                }
                              )
                            ]
                          )),
                        ]
                      )
                    )
                  );
                }
              )
            ),
            Padding(padding: const EdgeInsets.all(20), child: ElevatedButton(onPressed: () async { WakelockPlus.disable(); await _saveWorkoutResult(); if (context.mounted) Navigator.pop(context, currentExerciseName); }, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E1E1E), minimumSize: const Size(double.infinity, 55)), child: const Text("GUARDAR Y SALIR")))
          ]
        )
      )
    );
  }

  Widget _buildRepStepper(TextEditingController controller, bool isEnabled) {
    return Container(height: 45, decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(10)), child: Stack(alignment: Alignment.center, children: [
          TextField(controller: controller, enabled: isEnabled, keyboardType: TextInputType.number, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(border: InputBorder.none)),
          if (isEnabled) ...[
            Positioned(left: 0, child: IconButton(icon: const Icon(Icons.remove, size: 16), onPressed: () { int val = int.tryParse(controller.text) ?? 0; if (val > 0) controller.text = (val - 1).toString(); })),
            Positioned(right: 0, child: IconButton(icon: const Icon(Icons.add, size: 16), onPressed: () { int val = int.tryParse(controller.text) ?? 0; controller.text = (val + 1).toString(); })),
          ]
        ]));
  }

  Widget _buildInput(TextEditingController controller, String placeholder, bool isEnabled) {
    return Container(height: 45, decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(10)), child: TextField(controller: controller, enabled: isEnabled, keyboardType: TextInputType.number, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white), decoration: InputDecoration(hintText: placeholder, border: InputBorder.none)));
  }

  String _formatTime(int totalSeconds) { int min = totalSeconds ~/ 60; int sec = totalSeconds % 60; return "${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}"; }
}