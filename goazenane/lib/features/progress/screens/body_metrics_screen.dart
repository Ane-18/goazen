import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/database/app_database.dart';
import '../../../core/services/database_provider.dart';
import '../../home/providers/home_provider.dart';

class BodyMetricsScreen extends ConsumerStatefulWidget {
  const BodyMetricsScreen({super.key});

  @override
  ConsumerState<BodyMetricsScreen> createState() => _BodyMetricsScreenState();
}

class _BodyMetricsScreenState extends ConsumerState<BodyMetricsScreen> {
  final _pesoCtrl = TextEditingController();
  final _cinturaCtrl = TextEditingController();
  final _caderaCtrl = TextEditingController();
  final _pechoCtrl = TextEditingController();
  final _brazoCtrl = TextEditingController();
  final _musloCtrl = TextEditingController();

  Future<void> _save() async {
    final user = ref.read(userProvider).value;
    if (user == null) return;
    await ref.read(databaseProvider).userDao.insertBodyMetric(
      BodyMetricsCompanion(
        userId: drift.Value(user.id),
        fecha: drift.Value(DateTime.now()),
        pesoKg: drift.Value(double.tryParse(_pesoCtrl.text) ?? user.pesoKg),
        cinturaCm: drift.Value(double.tryParse(_cinturaCtrl.text)),
        caderaCm: drift.Value(double.tryParse(_caderaCtrl.text)),
        pechoCm: drift.Value(double.tryParse(_pechoCtrl.text)),
        brazoCm: drift.Value(double.tryParse(_brazoCtrl.text)),
        musloCm: drift.Value(double.tryParse(_musloCtrl.text)),
      ),
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Medidas corporales'),
        titleTextStyle: AppTextStyles.headlineLarge,
        actions: [
          TextButton(
            onPressed: _save,
            child: Text('Guardar', style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _field(_pesoCtrl, 'Peso', 'kg', Icons.monitor_weight_outlined),
            const SizedBox(height: 12),
            _field(_cinturaCtrl, 'Cintura', 'cm', Icons.straighten),
            const SizedBox(height: 12),
            _field(_caderaCtrl, 'Cadera', 'cm', Icons.straighten),
            const SizedBox(height: 12),
            _field(_pechoCtrl, 'Pecho / Busto', 'cm', Icons.straighten),
            const SizedBox(height: 12),
            _field(_brazoCtrl, 'Brazo', 'cm', Icons.straighten),
            const SizedBox(height: 12),
            _field(_musloCtrl, 'Muslo', 'cm', Icons.straighten),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, String unit, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: AppTextStyles.labelLarge)),
          SizedBox(
            width: 100,
            child: TextField(
              controller: ctrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.end,
              style: AppTextStyles.headlineSmall.copyWith(color: AppColors.primary),
              decoration: InputDecoration(
                hintText: '---',
                suffixText: unit,
                border: InputBorder.none,
                hintStyle: AppTextStyles.bodyMedium,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
