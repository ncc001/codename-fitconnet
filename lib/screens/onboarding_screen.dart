import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'home_screen.dart'; 

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  // --- CONTROLADORES DE TEXTO ---
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // --- VARIABLES DE PERFIL ---
  int _age = 25;
  double _weight = 70.0;
  String _gender = "Hombre";
  String _level = "Intermedio";
  String _goal = "Hipertrofia";
  int _daysPerWeek = 4;
  String _weakPoint = "pecho";
  
  // Variable para ocultar/mostrar contraseña
  bool _obscurePassword = true;

  // --- LISTAS FIJAS ---
  final List<String> _levels = ["Principiante", "Intermedio", "Avanzado"];
  final List<String> _goals = ["Hipertrofia", "Fuerza", "Pérdida de Grasa"];
  final List<int> _daysOptions = [3, 4, 5, 6];
  final Map<String, String> _weakPointOptions = {
    'pecho': 'Pecho',
    'espalda': 'Espalda',
    'pierna': 'Pierna',
    'brazo': 'Brazos',
    'hombro': 'Hombros',
    'ninguno': 'Ninguno'
  };

  // --- LÓGICA DE NAVEGACIÓN ---
  void _nextPage() {
    // VALIDACIONES DEL REGISTRO (Paso 1)
    if (_currentStep == 1) { 
       if (_nameController.text.isEmpty) {
         _showError("Por favor escribe tu nombre");
         return;
       }
       if (_emailController.text.isEmpty || !_emailController.text.contains('@')) {
         _showError("Escribe un correo válido");
         return;
       }
       if (_passwordController.text.length < 6) {
         _showError("La contraseña debe tener al menos 6 caracteres");
         return;
       }
       // Nota: Aquí validaremos con Firebase en el futuro
    }

    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    setState(() => _currentStep++);
  }

  void _previousPage() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep--);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  void _finishOnboarding(bool isManual) async {
    var box = Hive.box('settings');

    // Guardar datos
    await box.put('userName', _nameController.text);
    await box.put('userEmail', _emailController.text);
    // Nota: La contraseña NO se debe guardar en local por seguridad, 
    // pero la usaremos para crear el usuario en Firebase pronto.
    
    await box.put('userAge', _age);
    await box.put('userWeight', _weight);
    await box.put('userGender', _gender);
    await box.put('userLevel', _level);
    await box.put('userGoal', _goal);
    await box.put('daysPerWeek', _daysPerWeek);
    await box.put('weakPoint', _weakPoint);
    await box.put('isManualMode', isManual);
    
    await box.put('seenOnboarding', true);

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      resizeToAvoidBottomInset: true, 
      body: SafeArea(
        child: Column(
          children: [
            // BARRA DE PROGRESO
            LinearProgressIndicator(
              value: (_currentStep + 1) / 5,
              backgroundColor: Colors.grey[800],
              color: const Color(0xFF00E676),
              minHeight: 4,
            ),
            
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStep1Welcome(),
                  _buildStep2Auth(), 
                  _buildStep3Biometrics(),
                  _buildStep4Config(),
                  _buildStep5Decision(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- PASO 1: BIENVENIDA ---
// --- PASO 1: BIENVENIDA MEJORADA ---
// --- PASO 1: BIENVENIDA MEJORADA ---
  Widget _buildStep1Welcome() {
    return Padding(
      padding: const EdgeInsets.all(30.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Un contenedor con brillo para el logo
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: const Color(0xFF00E676).withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF00E676).withOpacity(0.5), width: 2),
              boxShadow: [
                 BoxShadow(color: const Color(0xFF00E676).withOpacity(0.2), blurRadius: 20, spreadRadius: 5)
              ]
            ),
            child: const Icon(Icons.fitness_center, size: 80, color: Color(0xFF00E676)),
          ),
          
          const SizedBox(height: 40),
          
          const Text(
            "FIT-CONNECT", 
            style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.5)
          ),
          
          const SizedBox(height: 20),
          
          // AQUÍ ESTÁ LA EXPLICACIÓN QUE QUERÍAS 👇
          const Text(
            "Entrenamiento Inteligente\nBasado en Evidencia.", 
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.w600)
          ),
          
          const SizedBox(height: 15),
          
          const Text(
            "Algoritmos que ajustan tu volumen, descanso y selección de ejercicios para garantizar la hipertrofia.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.5),
          ),
          
          const Spacer(),
          
          _buildNextButton("COMENZAR MI CAMBIO", _nextPage),
          
          const SizedBox(height: 10),
          const Text("Versión Alpha 1.0", style: TextStyle(color: Colors.white24, fontSize: 10)),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // --- PASO 2: REGISTRO (CAMBIO SOLICITADO) ---
  Widget _buildStep2Auth() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          const Text("Crea tu cuenta", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
          const Text("Completa tus datos para iniciar.", style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 30),
          
          // 1. INPUT NOMBRE
          TextField(
            controller: _nameController,
            style: const TextStyle(color: Colors.white),
            decoration: _inputDeco("Nombre Completo", Icons.person),
          ),
          const SizedBox(height: 15),

          // 2. INPUT CORREO (PRINCIPAL)
          TextField(
            controller: _emailController,
            style: const TextStyle(color: Colors.white),
            keyboardType: TextInputType.emailAddress,
            decoration: _inputDeco("Correo Electrónico", Icons.email),
          ),
          const SizedBox(height: 15),

          // 3. INPUT CONTRASEÑA
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.lock, color: Colors.grey),
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off, color: Colors.grey),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
              hintText: "Contraseña",
              hintStyle: const TextStyle(color: Colors.grey),
              filled: true,
              fillColor: const Color(0xFF1E1E1E),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),

          const SizedBox(height: 30),
          
          // BOTÓN DE CONTINUAR (Navegación principal)
          _buildNextButton("REGISTRARME", _nextPage),

          const SizedBox(height: 30),
          
          // DIVISOR
          Row(
            children: [
              Expanded(child: Divider(color: Colors.grey[800])),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Text("O ingresa con", style: TextStyle(color: Colors.grey)),
              ),
              Expanded(child: Divider(color: Colors.grey[800])),
            ],
          ),
          const SizedBox(height: 20),

          // BOTÓN GOOGLE (SECUNDARIO - ABAJO)
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: () {
                // SIMULACIÓN DE GOOGLE
                _nameController.text = "Nelson Carrión (Google)"; 
                _emailController.text = "nelson@gmail.com";
                _passwordController.text = "googleauth123"; // Dummy pass
                _nextPage();
              },
              icon: const Icon(Icons.g_mobiledata, color: Colors.white, size: 28),
              label: const Text("Google", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.grey),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          // Aquí agregaremos Facebook/Apple en el futuro
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // --- PASO 3: BIOMETRÍA ---
  Widget _buildStep3Biometrics() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          const Text("Datos Físicos", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 30),

          Row(
            children: [
              _buildGenderCard("Hombre", Icons.male, _gender == "Hombre"),
              const SizedBox(width: 15),
              _buildGenderCard("Mujer", Icons.female, _gender == "Mujer"),
            ],
          ),
          const SizedBox(height: 40),

          _buildCounterInput("Edad", "$_age años", 
            onMinus: () => setState(() => _age > 14 ? _age-- : null),
            onPlus: () => setState(() => _age < 90 ? _age++ : null),
          ),
          
          const SizedBox(height: 30),

          _buildCounterInput("Peso Corporal", "${_weight.toStringAsFixed(1)} kg", 
            onMinus: () => setState(() => _weight > 40 ? _weight -= 0.5 : null),
            onPlus: () => setState(() => _weight < 150 ? _weight += 0.5 : null),
          ),

          const Spacer(),
          _buildNavigationRow(),
        ],
      ),
    );
  }

  // --- PASO 4: CONFIGURACIÓN ---
  Widget _buildStep4Config() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: ListView(
        children: [
          const SizedBox(height: 20),
          const Text("Tu Plan", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 30),

          _buildLabel("Nivel de Experiencia"),
          DropdownButtonFormField<String>(
            value: _level,
            dropdownColor: const Color(0xFF1E1E1E),
            style: const TextStyle(color: Colors.white),
            decoration: _inputDeco("", null),
            items: _levels.map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
            onChanged: (val) => setState(() => _level = val!),
          ),
          const SizedBox(height: 20),

          _buildLabel("Objetivo"),
          DropdownButtonFormField<String>(
            value: _goal,
            dropdownColor: const Color(0xFF1E1E1E),
            style: const TextStyle(color: Colors.white),
            decoration: _inputDeco("", null),
            items: _goals.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
            onChanged: (val) => setState(() => _goal = val!),
          ),
          const SizedBox(height: 20),

          _buildLabel("Días Disponibles"),
          DropdownButtonFormField<int>(
            value: _daysPerWeek,
            dropdownColor: const Color(0xFF1E1E1E),
            style: const TextStyle(color: Colors.white),
            decoration: _inputDeco("", null),
            items: _daysOptions.map((d) => DropdownMenuItem(value: d, child: Text("$d Días"))).toList(),
            onChanged: (val) => setState(() => _daysPerWeek = val!),
          ),
          const SizedBox(height: 20),

          _buildLabel("Punto Débil"),
          DropdownButtonFormField<String>(
            value: _weakPoint,
            dropdownColor: const Color(0xFF1E1E1E),
            style: const TextStyle(color: Colors.white),
            decoration: _inputDeco("", null),
            items: _weakPointOptions.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
            onChanged: (val) => setState(() => _weakPoint = val!),
          ),

          const SizedBox(height: 40),
          _buildNavigationRow(),
        ],
      ),
    );
  }

  // --- PASO 5: DECISIÓN ---
  Widget _buildStep5Decision() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const SizedBox(height: 30),
          const Text("Elige tu camino", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 40),

          _buildDecisionCard(
            title: "Plan Científico (Auto)",
            desc: "La IA genera tu rutina óptima según tus datos.",
            icon: Icons.auto_awesome,
            color: const Color(0xFF00E676),
            onTap: () => _finishOnboarding(false),
          ),
          
          const SizedBox(height: 20),

          _buildDecisionCard(
            title: "Armar mi Rutina",
            desc: "Diseña tu plan manualmente con nuestra guía.",
            icon: Icons.edit_note,
            color: Colors.blueAccent,
            onTap: () => _finishOnboarding(true),
          ),
          
          const Spacer(),
           TextButton.icon(
            onPressed: _previousPage,
            icon: const Icon(Icons.arrow_back, color: Colors.grey),
            label: const Text("Volver a Configuración", style: TextStyle(color: Colors.grey)),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // --- WIDGETS PERSONALIZADOS ---

  Widget _buildNavigationRow() {
    return Row(
      children: [
        if (_currentStep > 0 && _currentStep != 1) // El paso 1 (Registro) tiene su propio botón grande
          InkWell(
            onTap: _previousPage,
            borderRadius: BorderRadius.circular(30),
            child: Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),
        
        if (_currentStep > 0 && _currentStep != 1) const SizedBox(width: 15),

        if (_currentStep != 1) // El paso 1 tiene su botón dentro del formulario
          Expanded(child: _buildNextButton("CONTINUAR", _nextPage)),
      ],
    );
  }

  Widget _buildCounterInput(String label, String value, {required VoidCallback onMinus, required VoidCallback onPlus}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF00E676), fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(onPressed: onMinus, icon: const Icon(Icons.remove_circle_outline, color: Colors.grey, size: 30)),
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              IconButton(onPressed: onPlus, icon: const Icon(Icons.add_circle_outline, color: Color(0xFF00E676), size: 30)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNextButton(String text, VoidCallback onPressed) {
    return SizedBox(
      height: 55,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00E676),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(text, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }

  Widget _buildGenderCard(String label, IconData icon, bool isSelected) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _gender = label),
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF00E676).withOpacity(0.2) : const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? const Color(0xFF00E676) : Colors.transparent),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 35, color: isSelected ? const Color(0xFF00E676) : Colors.grey),
              const SizedBox(height: 8),
              Text(label, style: TextStyle(color: isSelected ? const Color(0xFF00E676) : Colors.grey, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDecisionCard({required String title, required String desc, required IconData icon, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 40),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 5),
                  Text(desc, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
  
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4),
      child: Text(text, style: const TextStyle(color: Color(0xFF00E676), fontWeight: FontWeight.bold)),
    );
  }

  InputDecoration _inputDeco(String hint, IconData? icon) {
    return InputDecoration(
      prefixIcon: icon != null ? Icon(icon, color: Colors.grey) : null,
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey),
      filled: true,
      fillColor: const Color(0xFF1E1E1E),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    );
  }
}