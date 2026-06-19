import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/drift.dart' as drift;
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/database/app_database.dart';
import '../../../core/services/database_provider.dart';
import '../../home/providers/home_provider.dart';
import '../../home/widgets/phase_badge.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Perfil'),
        titleTextStyle: AppTextStyles.headlineLarge,
      ),
      body: user.when(
        data: (u) {
          if (u == null) return const SizedBox();
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            children: [
              // Avatar + nombre
              _ProfileHeader(user: u),
              const SizedBox(height: 16),

              // Ciclo menstrual
              if (!u.usaAnticonceptivos) ...[
                _CyclePicker(user: u),
                const SizedBox(height: 16),
              ],

              // Sueño manual
              _SleepEntry(userId: u.id),
              const SizedBox(height: 16),

              // FC reposo manual
              _HrEntry(userId: u.id),
              const SizedBox(height: 16),

              // Mi Band
              _MiBandCard(user: u),
              const SizedBox(height: 16),

              // Metodología científica
              _MethodologyCard(),
              const SizedBox(height: 16),

              // Reset / peligro
              _DangerZone(),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (_, __) => const SizedBox(),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final User user;
  const _ProfileHeader({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, color: AppColors.primary, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.nombre, style: AppTextStyles.headlineLarge),
                Text(
                  '${user.nivelExperiencia.capitalize()} · ${user.diasDisponibles} días/semana',
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  '${user.pesoKg.toStringAsFixed(1)} kg · ${user.alturaCm.toStringAsFixed(0)} cm · ${user.porcentajeGrasa.toStringAsFixed(1)}% grasa',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CyclePicker extends ConsumerWidget {
  final User user;
  const _CyclePicker({required this.user});

  static const _fases = [
    ('menstruacion', 'Menstruación'),
    ('folicular', 'Folicular'),
    ('ovulacion', 'Ovulación'),
    ('lutea', 'Lútea'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Fase del ciclo', style: AppTextStyles.headlineSmall),
              PhaseBadge(phase: user.faseCicloActual),
            ],
          ),
          const SizedBox(height: 12),
          Text('¿En qué fase te encuentras esta semana?', style: AppTextStyles.bodyMedium),
          const SizedBox(height: 10),
          Row(
            children: _fases.map((f) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: GestureDetector(
                  onTap: () async {
                    await ref.read(databaseProvider).userDao.updateUser(
                      UsersCompanion(
                        id: drift.Value(user.id),
                        nombre: drift.Value(user.nombre),
                        fechaNacimiento: drift.Value(user.fechaNacimiento),
                        pesoKg: drift.Value(user.pesoKg),
                        alturaCm: drift.Value(user.alturaCm),
                        porcentajeGrasa: drift.Value(user.porcentajeGrasa),
                        objetivo: drift.Value(user.objetivo),
                        nivelExperiencia: drift.Value(user.nivelExperiencia),
                        diasDisponibles: drift.Value(user.diasDisponibles),
                        equipamiento: drift.Value(user.equipamiento),
                        limitaciones: drift.Value(user.limitaciones),
                        duracionSesionMax: drift.Value(user.duracionSesionMax),
                        usaAnticonceptivos: drift.Value(user.usaAnticonceptivos),
                        faseCicloActual: drift.Value(f.$1),
                        fechaRegistro: drift.Value(user.fechaRegistro),
                        tieneMiBand: drift.Value(user.tieneMiBand),
                        miBandMacAddress: drift.Value(user.miBandMacAddress),
                        onboardingCompleto: drift.Value(user.onboardingCompleto),
                      ),
                    );
                    ref.invalidate(userProvider);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: user.faseCicloActual == f.$1
                          ? AppColors.primary
                          : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      f.$2,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: user.faseCicloActual == f.$1
                            ? Colors.white
                            : AppColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }
}

class _SleepEntry extends ConsumerStatefulWidget {
  final int userId;
  const _SleepEntry({required this.userId});

  @override
  ConsumerState<_SleepEntry> createState() => _SleepEntryState();
}

class _SleepEntryState extends ConsumerState<_SleepEntry> {
  double _hours = 7.5;

  Future<void> _save() async {
    await ref.read(databaseProvider).sleepDao.insertSleepLog(
      SleepLogCompanion(
        userId: drift.Value(widget.userId),
        fecha: drift.Value(DateTime.now()),
        horasTotales: drift.Value(_hours),
        fuente: const drift.Value('manual'),
      ),
    );
    ref.invalidate(todaySleepProvider);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sueño registrado'), backgroundColor: AppColors.success),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sueño de anoche', style: AppTextStyles.headlineSmall),
          const SizedBox(height: 4),
          Text('Registro manual si no tienes Mi Band', style: AppTextStyles.bodySmall),
          const SizedBox(height: 12),
          Row(
            children: [
              Text('${_hours.toStringAsFixed(1)} h', style: AppTextStyles.displaySmall.copyWith(color: AppColors.info)),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: AppColors.info,
                    inactiveTrackColor: AppColors.surfaceVariant,
                    thumbColor: AppColors.info,
                  ),
                  child: Slider(
                    value: _hours,
                    min: 3,
                    max: 12,
                    divisions: 18,
                    onChanged: (v) => setState(() => _hours = v),
                  ),
                ),
              ),
              FilledButton(
                onPressed: _save,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.info,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Guardar'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HrEntry extends ConsumerStatefulWidget {
  final int userId;
  const _HrEntry({required this.userId});

  @override
  ConsumerState<_HrEntry> createState() => _HrEntryState();
}

class _HrEntryState extends ConsumerState<_HrEntry> {
  final _hrCtrl = TextEditingController();

  Future<void> _save() async {
    final hr = double.tryParse(_hrCtrl.text);
    if (hr == null) return;
    await ref.read(databaseProvider).sleepDao.insertSleepLog(
      SleepLogCompanion(
        userId: drift.Value(widget.userId),
        fecha: drift.Value(DateTime.now()),
        horasTotales: const drift.Value(0),
        fcReposoMatutina: drift.Value(hr),
        fuente: const drift.Value('manual'),
      ),
    );
    _hrCtrl.clear();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('FC en reposo guardada'), backgroundColor: AppColors.success),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('FC en reposo matutina', style: AppTextStyles.headlineSmall),
          const SizedBox(height: 4),
          Text('Tómala antes de levantarte', style: AppTextStyles.bodySmall),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _hrCtrl,
                  keyboardType: TextInputType.number,
                  style: AppTextStyles.headlineMedium.copyWith(color: AppColors.error),
                  decoration: const InputDecoration(
                    hintText: 'bpm',
                    suffixText: 'bpm',
                    filled: true,
                    fillColor: AppColors.surfaceVariant,
                    border: OutlineInputBorder(borderSide: BorderSide.none),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton(
                onPressed: _save,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.error,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Icon(Icons.save),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiBandCard extends ConsumerWidget {
  final User user;
  const _MiBandCard({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => context.go('/mi-band-setup'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.watch, color: AppColors.info, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Mi Band 3', style: AppTextStyles.headlineSmall),
                  Text(
                    user.tieneMiBand
                        ? user.miBandMacAddress.isNotEmpty
                            ? 'Conectada: ${user.miBandMacAddress}'
                            : 'Sin vincular'
                        : 'Sin wearable configurado',
                    style: AppTextStyles.bodySmall.copyWith(
                        color: user.tieneMiBand
                            ? AppColors.success
                            : AppColors.textDisabled),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textDisabled),
          ],
        ),
      ),
    );
  }
}

class _MethodologyCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.science, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text('Base científica', style: AppTextStyles.headlineSmall),
            ],
          ),
          const SizedBox(height: 10),
          ...const [
            '• Schoenfeld BJ (2010, 2016) — Hipertrofia y frecuencia',
            '• Israetel M et al. — MEV, MAV, MRV',
            '• Helms ER (2014) — Proteína en déficit calórico',
            '• Sims ST (2022) — Fisiología femenina y rendimiento',
          ].map((ref) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(ref, style: AppTextStyles.bodySmall),
              )),
        ],
      ),
    );
  }
}

class _DangerZone extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Zona de peligro', style: AppTextStyles.headlineSmall.copyWith(color: AppColors.error)),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => _confirmReset(context, ref),
            icon: const Icon(Icons.delete_forever, color: AppColors.error),
            label: const Text('Borrar todos los datos'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
              minimumSize: const Size(double.infinity, 44),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('¿Borrar todo?'),
        content: const Text(
            'Esta acción eliminará todos tus datos: entrenamiento, progreso y fotos. No se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Borrar todo'),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      context.go('/onboarding');
    }
  }
}

extension on String {
  String capitalize() => isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}

