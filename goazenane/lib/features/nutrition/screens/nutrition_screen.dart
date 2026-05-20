import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/database/app_database.dart';
import '../../../core/services/database_provider.dart';
import '../../../core/utils/nutrition_calculator.dart';
import '../../home/providers/home_provider.dart';

class NutritionScreen extends ConsumerStatefulWidget {
  const NutritionScreen({super.key});

  @override
  ConsumerState<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends ConsumerState<NutritionScreen> {
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final plan = ref.watch(todayNutritionPlanProvider);
    final macros = ref.watch(todayMacroProgressProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Nutrición'),
        titleTextStyle: AppTextStyles.headlineLarge,
        actions: [
          user.when(
            data: (u) => u != null
                ? TextButton.icon(
                    onPressed: () => _recalculatePlan(u),
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Recalcular'),
                  )
                : const SizedBox(),
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddFoodDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Añadir alimento'),
        backgroundColor: AppColors.primary,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        children: [
          // Resumen de macros
          plan.when(
            data: (p) => macros.when(
              data: (m) => _MacroSummaryCard(plan: p, consumed: m),
              loading: () => const _LoadingCard(),
              error: (_, __) => const SizedBox(),
            ),
            loading: () => const _LoadingCard(),
            error: (_, __) => const SizedBox(),
          ),

          const SizedBox(height: 16),

          // Agua
          user.when(
            data: (u) => u != null ? _WaterCard(userId: u.id, targetMl: plan.value?.aguaMl ?? 2500) : const SizedBox(),
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
          ),

          const SizedBox(height: 16),

          // Log del día
          user.when(
            data: (u) => u != null ? _TodayFoodLog(userId: u.id) : const SizedBox(),
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
          ),
        ],
      ),
    );
  }

  Future<void> _recalculatePlan(User u) async {
    final db = ref.read(databaseProvider);
    final objetivo = _parseObjetivo(u.objetivo);
    final fase = _parseFase(u.faseCicloActual);
    final today = await db.workoutDao.getTodaySession(u.id);
    final esDiaEntreno = today != null;

    final result = NutritionCalculator.calcMacros(
      pesoKg: u.pesoKg,
      porcentajeGrasa: u.porcentajeGrasa,
      objetivo: objetivo,
      actividad: NivelActividad.moderadamenteActiva,
      faseCiclo: fase,
      esDiaEntreno: esDiaEntreno,
    );

    await db.nutritionDao.insertPlan(NutritionPlansCompanion(
      userId: drift.Value(u.id),
      fecha: drift.Value(DateTime.now()),
      caloriasObjetivo: drift.Value(result.calorias),
      proteinasG: drift.Value(result.proteinasG),
      carbosG: drift.Value(result.carbosG),
      grasasG: drift.Value(result.grasasG),
      aguaMl: drift.Value(result.aguaMl),
      esDiaEntreno: drift.Value(esDiaEntreno),
      masaMagraKgRef: drift.Value(result.masaMagraKg),
    ));

    if (mounted) {
      ref.invalidate(todayNutritionPlanProvider);
      ref.invalidate(todayMacroProgressProvider);
    }
  }

  Objetivo _parseObjetivo(String o) {
    switch (o) {
      case 'perdida_grasa': return Objetivo.perdidaGrasa;
      case 'ganancia_muscular': return Objetivo.gananciaMusculo;
      default: return Objetivo.recomposicion;
    }
  }

  FaseCiclo _parseFase(String f) {
    switch (f) {
      case 'menstruacion': return FaseCiclo.menstruacion;
      case 'ovulacion': return FaseCiclo.ovulacion;
      case 'lutea': return FaseCiclo.lutea;
      default: return FaseCiclo.folicular;
    }
  }

  Future<void> _showAddFoodDialog(BuildContext context) async {
    final user = ref.read(userProvider).value;
    if (user == null) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _AddFoodSheet(userId: user.id),
    );
    ref.invalidate(todayMacroProgressProvider);
  }
}

class _MacroSummaryCard extends StatelessWidget {
  final NutritionPlan? plan;
  final Map<String, double> consumed;
  const _MacroSummaryCard({this.plan, required this.consumed});

  @override
  Widget build(BuildContext context) {
    final calC = consumed['calorias'] ?? 0;
    final calT = plan?.caloriasObjetivo ?? 2000;
    final protC = consumed['proteinas'] ?? 0;
    final protT = plan?.proteinasG ?? 150;
    final carbsC = consumed['carbos'] ?? 0;
    final carbsT = plan?.carbosG ?? 200;
    final fatC = consumed['grasas'] ?? 0;
    final fatT = plan?.grasasG ?? 60;

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
              Text('Resumen del día', style: AppTextStyles.headlineMedium),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${calC.round()} kcal', style: AppTextStyles.displaySmall.copyWith(color: AppColors.primary)),
                  Text('objetivo: ${calT.round()} kcal', style: AppTextStyles.bodySmall),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          _MacroRow('Proteína', protC, protT, AppColors.info),
          const SizedBox(height: 8),
          _MacroRow('Carbohidratos', carbsC, carbsT, AppColors.warning),
          const SizedBox(height: 8),
          _MacroRow('Grasas', fatC, fatT, AppColors.primary),
        ],
      ),
    );
  }
}

class _MacroRow extends StatelessWidget {
  final String label;
  final double consumed;
  final double target;
  final Color color;
  const _MacroRow(this.label, this.consumed, this.target, this.color);

  @override
  Widget build(BuildContext context) {
    final pct = (consumed / target).clamp(0.0, 1.0);
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTextStyles.labelLarge),
            Text('${consumed.round()}g / ${target.round()}g',
                style: AppTextStyles.bodySmall.copyWith(color: color)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            backgroundColor: AppColors.surfaceVariant,
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}

class _WaterCard extends ConsumerStatefulWidget {
  final int userId;
  final double targetMl;
  const _WaterCard({required this.userId, required this.targetMl});

  @override
  ConsumerState<_WaterCard> createState() => _WaterCardState();
}

class _WaterCardState extends ConsumerState<_WaterCard> {
  double _currentMl = 0;

  @override
  void initState() {
    super.initState();
    _loadWater();
  }

  Future<void> _loadWater() async {
    final water = await ref.read(databaseProvider).nutritionDao.getTodayWater(widget.userId);
    if (mounted) setState(() => _currentMl = water?.aguaMlTotal ?? 0);
  }

  Future<void> _addWater(double ml) async {
    final newTotal = _currentMl + ml;
    await ref.read(databaseProvider).nutritionDao.upsertWaterLog(
      DailyWaterLogCompanion(
        userId: drift.Value(widget.userId),
        fecha: drift.Value(DateTime.now()),
        aguaMlTotal: drift.Value(newTotal),
      ),
    );
    setState(() => _currentMl = newTotal);
  }

  @override
  Widget build(BuildContext context) {
    final pct = (_currentMl / widget.targetMl).clamp(0.0, 1.0);

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
              Row(
                children: [
                  const Icon(Icons.water_drop, color: AppColors.info, size: 20),
                  const SizedBox(width: 8),
                  Text('Hidratación', style: AppTextStyles.headlineSmall),
                ],
              ),
              Text(
                '${(_currentMl / 1000).toStringAsFixed(1)} / ${(widget.targetMl / 1000).toStringAsFixed(1)} L',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.info),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: AppColors.surfaceVariant,
              valueColor: const AlwaysStoppedAnimation(AppColors.info),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [150, 250, 330, 500].map((ml) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: OutlinedButton(
                  onPressed: () => _addWater(ml.toDouble()),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.info,
                    side: const BorderSide(color: AppColors.info),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text('+${ml}ml', style: AppTextStyles.bodySmall.copyWith(color: AppColors.info)),
                ),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }
}

class _TodayFoodLog extends ConsumerWidget {
  final int userId;
  const _TodayFoodLog({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<List<DailyNutritionLogData>>(
      future: ref.read(databaseProvider).nutritionDao.getTodayLog(userId),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox();
        final logs = snap.data!;
        if (logs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text('Sin alimentos registrados hoy.', style: AppTextStyles.bodyMedium),
            ),
          );
        }
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text('Alimentos registrados', style: AppTextStyles.headlineSmall),
              ),
              ...logs.map((log) => ListTile(
                title: Text(log.alimento, style: AppTextStyles.labelLarge),
                subtitle: Text('${log.cantidadG.round()}g — ${log.calorias.round()} kcal',
                    style: AppTextStyles.bodySmall),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('P: ${log.proteinasG.round()}g',
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.info)),
                    Text('C: ${log.carbosG.round()}g · G: ${log.grasasG.round()}g',
                        style: AppTextStyles.bodySmall),
                  ],
                ),
                onLongPress: () async {
                  await ref.read(databaseProvider).nutritionDao.deleteFoodLog(log.id);
                  ref.invalidate(todayMacroProgressProvider);
                },
              )),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}

class _AddFoodSheet extends ConsumerStatefulWidget {
  final int userId;
  const _AddFoodSheet({required this.userId});

  @override
  ConsumerState<_AddFoodSheet> createState() => _AddFoodSheetState();
}

class _AddFoodSheetState extends ConsumerState<_AddFoodSheet> {
  final _searchCtrl = TextEditingController();
  List<FoodItem> _results = [];
  FoodItem? _selected;
  final _cantidadCtrl = TextEditingController(text: '100');

  @override
  void initState() {
    super.initState();
    _search('');
  }

  Future<void> _search(String q) async {
    final items = await ref.read(databaseProvider).nutritionDao.searchFoods(q);
    if (mounted) setState(() => _results = items);
  }

  Future<void> _addFood() async {
    if (_selected == null) return;
    final cantidad = double.tryParse(_cantidadCtrl.text) ?? 100;
    final factor = cantidad / 100;

    await ref.read(databaseProvider).nutritionDao.insertFoodLog(
      DailyNutritionLogCompanion(
        userId: drift.Value(widget.userId),
        fecha: drift.Value(DateTime.now()),
        alimento: drift.Value(_selected!.nombre),
        cantidadG: drift.Value(cantidad),
        proteinasG: drift.Value(_selected!.proteinasP100g * factor),
        carbosG: drift.Value(_selected!.carbosP100g * factor),
        grasasG: drift.Value(_selected!.grasasP100g * factor),
        calorias: drift.Value(_selected!.caloriasP100g * factor),
        hora: drift.Value(DateFormat('HH:mm').format(DateTime.now())),
      ),
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.of(context).viewInsets;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + insets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Añadir alimento', style: AppTextStyles.headlineMedium),
          const SizedBox(height: 12),
          TextField(
            controller: _searchCtrl,
            onChanged: _search,
            style: AppTextStyles.bodyLarge,
            decoration: InputDecoration(
              hintText: 'Buscar alimento...',
              hintStyle: AppTextStyles.bodyMedium,
              filled: true,
              fillColor: AppColors.surfaceVariant,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              prefixIcon: const Icon(Icons.search, color: AppColors.textDisabled),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 200,
            child: ListView.builder(
              itemCount: _results.length,
              itemBuilder: (ctx, i) {
                final food = _results[i];
                return ListTile(
                  title: Text(food.nombre, style: AppTextStyles.labelLarge),
                  subtitle: Text(
                    '${food.caloriasP100g.round()} kcal · P:${food.proteinasP100g.round()} C:${food.carbosP100g.round()} G:${food.grasasP100g.round()} (por 100g)',
                    style: AppTextStyles.bodySmall,
                  ),
                  selected: _selected?.id == food.id,
                  selectedColor: AppColors.primary,
                  selectedTileColor: AppColors.primary.withOpacity(0.1),
                  onTap: () => setState(() => _selected = food),
                );
              },
            ),
          ),
          if (_selected != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _cantidadCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Cantidad (g)',
                      filled: true,
                      fillColor: AppColors.surfaceVariant,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: _addFood,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Añadir'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2)),
    );
  }
}
