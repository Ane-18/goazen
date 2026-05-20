import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Servicios UUID conocidos del Mi Band 3 (protocolo público Xiaomi)
class MiBandUUIDs {
  static const String serviceHeartRate = '0000180d-0000-1000-8000-00805f9b34fb';
  static const String characteristicHrMeasurement = '00002a37-0000-1000-8000-00805f9b34fb';
  static const String serviceActivity = '0000fee0-0000-1000-8000-00805f9b34fb';
  static const String characteristicActivity = '00000007-0000-3512-2118-0009af100700';
}

class MiBandData {
  final double? fcReposo;
  final double? fcActual;
  final int? pasos;
  final double? caloriasActivas;
  final double? horasSuenio;

  const MiBandData({
    this.fcReposo,
    this.fcActual,
    this.pasos,
    this.caloriasActivas,
    this.horasSuenio,
  });
}

class MiBandService {
  BluetoothDevice? _device;
  StreamSubscription<BluetoothConnectionState>? _connectionSub;
  final _hrController = StreamController<double>.broadcast();
  bool _connected = false;

  Stream<double> get heartRateStream => _hrController.stream;
  bool get isConnected => _connected;

  Future<List<BluetoothDevice>> scanForMiBand({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final results = <BluetoothDevice>[];
    try {
      await FlutterBluePlus.startScan(timeout: timeout);
      await for (final result in FlutterBluePlus.scanResults) {
        for (final r in result) {
          if (r.device.platformName.contains('Mi Band') ||
              r.device.platformName.contains('Xiaomi')) {
            results.add(r.device);
          }
        }
      }
    } catch (_) {}
    return results;
  }

  Future<bool> connect(BluetoothDevice device) async {
    try {
      await device.connect(timeout: const Duration(seconds: 15));
      _device = device;
      _connected = true;

      _connectionSub = device.connectionState.listen((state) {
        _connected = state == BluetoothConnectionState.connected;
      });

      await _subscribeHeartRate(device);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _subscribeHeartRate(BluetoothDevice device) async {
    try {
      final services = await device.discoverServices();
      for (final service in services) {
        if (service.uuid.toString().contains('180d')) {
          for (final char in service.characteristics) {
            if (char.uuid.toString().contains('2a37')) {
              await char.setNotifyValue(true);
              char.onValueReceived.listen((data) {
                if (data.length >= 2) {
                  final hr = data[1].toDouble();
                  if (hr > 0) _hrController.add(hr);
                }
              });
            }
          }
        }
      }
    } catch (_) {}
  }

  Future<MiBandData?> fetchDailySummary() async {
    if (_device == null || !_connected) return null;
    // En una implementación real, se leerían los datos del wearable
    // Por ahora retorna null para que la app use entrada manual
    return null;
  }

  Future<void> disconnect() async {
    await _connectionSub?.cancel();
    await _device?.disconnect();
    _device = null;
    _connected = false;
  }

  void dispose() {
    _hrController.close();
    disconnect();
  }
}

// Provider global del servicio
final miBandServiceProvider = Provider<MiBandService>((ref) {
  final service = MiBandService();
  ref.onDispose(service.dispose);
  return service;
});

final miBandHrProvider = StreamProvider<double>((ref) {
  final service = ref.watch(miBandServiceProvider);
  return service.heartRateStream;
});
