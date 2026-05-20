import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/services/mi_band_service.dart';

class MiBandSetupScreen extends ConsumerStatefulWidget {
  const MiBandSetupScreen({super.key});

  @override
  ConsumerState<MiBandSetupScreen> createState() => _MiBandSetupScreenState();
}

class _MiBandSetupScreenState extends ConsumerState<MiBandSetupScreen> {
  List<BluetoothDevice> _found = [];
  bool _scanning = false;
  BluetoothDevice? _connecting;

  Future<void> _scan() async {
    final service = ref.read(miBandServiceProvider);
    setState(() {
      _scanning = true;
      _found = [];
    });
    final devices = await service.scanForMiBand();
    if (mounted) {
      setState(() {
        _found = devices;
        _scanning = false;
      });
    }
  }

  Future<void> _connect(BluetoothDevice device) async {
    setState(() => _connecting = device);
    final service = ref.read(miBandServiceProvider);
    final ok = await service.connect(device);
    if (mounted) {
      setState(() => _connecting = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? 'Mi Band conectada correctamente' : 'No se pudo conectar'),
          backgroundColor: ok ? AppColors.success : AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Configurar Mi Band'),
        titleTextStyle: AppTextStyles.headlineLarge,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.info.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Conexión Bluetooth LE', style: AppTextStyles.headlineSmall.copyWith(color: AppColors.info)),
                  const SizedBox(height: 8),
                  Text(
                    'Activa el Bluetooth en tu teléfono y asegúrate de que tu Mi Band esté cerca y sin emparejamiento activo en otras apps.',
                    style: AppTextStyles.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _scanning ? null : _scan,
              icon: _scanning
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.bluetooth_searching),
              label: Text(_scanning ? 'Buscando...' : 'Buscar dispositivos'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.info,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 16),
            if (_found.isEmpty && !_scanning)
              Center(
                child: Text(
                  'No se encontraron dispositivos Mi Band.\nAsegúrate de que está activa y cerca.',
                  style: AppTextStyles.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ),
            ..._found.map(
              (device) => ListTile(
                leading: const Icon(Icons.watch, color: AppColors.info),
                title: Text(device.platformName.isNotEmpty ? device.platformName : 'Mi Band',
                    style: AppTextStyles.labelLarge),
                subtitle: Text(device.remoteId.str, style: AppTextStyles.bodySmall),
                trailing: _connecting == device
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
                      )
                    : FilledButton(
                        onPressed: () => _connect(device),
                        style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                        child: const Text('Conectar'),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
