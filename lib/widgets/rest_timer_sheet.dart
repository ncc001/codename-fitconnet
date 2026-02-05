import 'dart:async';
import 'package:flutter/material.dart';

class RestTimerSheet extends StatefulWidget {
  const RestTimerSheet({super.key});

  @override
  State<RestTimerSheet> createState() => _RestTimerSheetState();
}

class _RestTimerSheetState extends State<RestTimerSheet> {
  // Configuración científica: 90 segundos (1:30 min) por defecto para hipertrofia
  static const int _defaultTime = 90; 
  int _secondsRemaining = _defaultTime;
  Timer? _timer;
  bool _isRunning = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    setState(() => _isRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        _stopTimer();
        // Aquí podríamos vibrar o sonar
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    setState(() => _isRunning = false);
  }

  void _addTime(int seconds) {
    setState(() => _secondsRemaining += seconds);
  }

  String _formatTime(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      height: 350,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
          ),
          const SizedBox(height: 20),
          const Text("RECUPERACIÓN DE ATP", style: TextStyle(letterSpacing: 1.5, fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
          const SizedBox(height: 10),
          
          // Reloj Grande
          Text(
            _formatTime(_secondsRemaining),
            style: TextStyle(
              fontSize: 80, 
              fontWeight: FontWeight.w900, 
              color: _secondsRemaining < 10 ? Colors.red : Colors.blueAccent,
              fontFeatures: const [FontFeature.tabularFigures()], // Evita que los números "bailen"
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Botones de control
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _TimeControlButton(label: "-30s", onPressed: () => _addTime(-30)),
              const SizedBox(width: 20),
              FloatingActionButton(
                onPressed: _isRunning ? _stopTimer : _startTimer,
                backgroundColor: _isRunning ? Colors.orange : Colors.green,
                child: Icon(_isRunning ? Icons.pause : Icons.play_arrow),
              ),
              const SizedBox(width: 20),
              _TimeControlButton(label: "+30s", onPressed: () => _addTime(30)),
            ],
          ),
          
          const SizedBox(height: 20),
          const Text(
            "Ciencia: Descansar al menos 90s optimiza la síntesis de proteínas en la siguiente serie.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _TimeControlButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _TimeControlButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        backgroundColor: Colors.grey[100],
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
    );
  }
}