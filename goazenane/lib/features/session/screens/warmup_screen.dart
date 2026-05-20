import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

class WarmupScreen extends ConsumerStatefulWidget {
  final int sessionId;
  const WarmupScreen({super.key, required this.sessionId});

  @override
  ConsumerState<WarmupScreen> createState() => _WarmupScreenState();
}

class _WarmupScreenState extends ConsumerState<WarmupScreen> {
  int _currentStep = 0;
  int _timerSeconds = 60;
  Timer? _timer;
  bool _timerRunning = false;

  static const _warmupSteps = [
    WarmupStep(
      title: 'Movilidad articular',
      description: 'Círculos de cuello, hombros, caderas, tobillos. 5 repeticiones cada articulación en ambas direcciones.',
      duration: 90,
      icon: Icons.loop,
    ),
    WarmupStep(
      title: 'Activación cardiovascular',
      description: 'Marcha en el sitio o saltos suaves. Eleva la temperatura corporal gradualmente.',
      duration: 60,
      icon: Icons.directions_run,
    ),
    WarmupStep(
      title: 'Activación específica',
      description: 'Ejercicios de movilidad relacionados con el entrenamiento de hoy. Movimientos suaves al 40–50% del esfuerzo.',
      duration: 90,
      icon: Icons.accessibility_new,
    ),
    WarmupStep(
      title: 'Series de aproximación',
      description: 'Realiza 1–2 series del primer ejercicio compuesto al 40–60% de tu peso habitual antes de empezar.',
      duration: 0,
      icon: Icons.bar_chart,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _timerSeconds = _warmupSteps[0].duration;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    setState(() => _timerRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_timerSeconds > 0) {
        setState(() => _timerSeconds--);
      } else {
        t.cancel();
        setState(() => _timerRunning = false);
        if (_currentStep < _warmupSteps.length - 1) {
          _nextStep();
        }
      }
    });
  }

  void _nextStep() {
    _timer?.cancel();
    if (_currentStep < _warmupSteps.length - 1) {
      setState(() {
        _currentStep++;
        _timerSeconds = _warmupSteps[_currentStep].duration;
        _timerRunning = false;
      });
    }
  }

  void _finishWarmup() {
    _timer?.cancel();
    context.go('/session/${widget.sessionId}');
  }

  @override
  Widget build(BuildContext context) {
    final step = _warmupSteps[_currentStep];
    final isLast = _currentStep == _warmupSteps.length - 1;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text('Calentamiento', style: AppTextStyles.headlineLarge),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Progress dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _warmupSteps.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: i == _currentStep ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: i <= _currentStep
                        ? AppColors.primary
                        : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Icon + title
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(step.icon, color: AppColors.primary, size: 40),
            ),
            const SizedBox(height: 20),

            Text(step.title, style: AppTextStyles.displaySmall, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Text(step.description, style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),

            const Spacer(),

            // Timer
            if (step.duration > 0) ...[
              Text(
                _formatTime(_timerSeconds),
                style: AppTextStyles.metricHuge,
              ),
              const SizedBox(height: 16),
              if (!_timerRunning)
                FilledButton.icon(
                  onPressed: _startTimer,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Iniciar temporizador'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                )
              else
                FilledButton.icon(
                  onPressed: _nextStep,
                  icon: const Icon(Icons.skip_next),
                  label: const Text('Saltar'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.surfaceVariant,
                    foregroundColor: AppColors.textSecondary,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
            ],

            if (isLast)
              FilledButton.icon(
                onPressed: _finishWarmup,
                icon: const Icon(Icons.fitness_center),
                label: const Text('¡Empezar entrenamiento!'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  textStyle: AppTextStyles.headlineSmall,
                ),
              ),

            if (!isLast && !_timerRunning && step.duration > 0)
              const SizedBox(height: 12),
            if (!isLast && step.duration == 0)
              FilledButton.icon(
                onPressed: _nextStep,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Siguiente'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

class WarmupStep {
  final String title;
  final String description;
  final int duration; // 0 = no timer
  final IconData icon;
  const WarmupStep({
    required this.title,
    required this.description,
    required this.duration,
    required this.icon,
  });
}

