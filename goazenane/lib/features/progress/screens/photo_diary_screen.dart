import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:drift/drift.dart' as drift;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/database/app_database.dart';
import '../../../core/services/database_provider.dart';
import '../../home/providers/home_provider.dart';

class PhotoDiaryScreen extends ConsumerStatefulWidget {
  const PhotoDiaryScreen({super.key});

  @override
  ConsumerState<PhotoDiaryScreen> createState() => _PhotoDiaryScreenState();
}

class _PhotoDiaryScreenState extends ConsumerState<PhotoDiaryScreen> {
  final _picker = ImagePicker();

  Future<void> _takePhoto() async {
    final user = ref.read(userProvider).value;
    if (user == null) return;

    final photo = await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (photo == null) return;

    final dir = await getApplicationDocumentsDirectory();
    final filename = 'progress_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final localPath = path.join(dir.path, 'photos', filename);
    final localFile = File(localPath);
    await localFile.parent.create(recursive: true);
    await File(photo.path).copy(localPath);

    final latest = await ref.read(databaseProvider).userDao.getLatestBodyMetric(user.id);
    if (latest != null) {
      await ref.read(databaseProvider).userDao.insertBodyMetric(
        BodyMetricsCompanion(
          userId: drift.Value(user.id),
          fecha: drift.Value(DateTime.now()),
          pesoKg: drift.Value(latest.pesoKg),
          fotoPath: drift.Value(localPath),
        ),
      );
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider).value;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Foto progreso'),
        titleTextStyle: AppTextStyles.headlineLarge,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _takePhoto,
        icon: const Icon(Icons.camera_alt),
        label: const Text('Nueva foto'),
        backgroundColor: AppColors.primary,
      ),
      body: user == null
          ? const SizedBox()
          : FutureBuilder<List<BodyMetric>>(
              future: ref.read(databaseProvider).userDao.getBodyMetrics(user.id),
              builder: (context, snap) {
                final metrics = (snap.data ?? []).where((m) => m.fotoPath.isNotEmpty).toList();
                if (metrics.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.photo_camera, size: 64, color: AppColors.textDisabled),
                        const SizedBox(height: 16),
                        Text('Sin fotos aún', style: AppTextStyles.headlineMedium),
                        const SizedBox(height: 8),
                        Text(
                          'Las fotos se guardan 100% en tu dispositivo.\nNadie más tiene acceso.',
                          style: AppTextStyles.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }
                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: metrics.length,
                  itemBuilder: (ctx, i) {
                    final m = metrics[i];
                    return GestureDetector(
                      onTap: () => _viewPhoto(context, m),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.file(File(m.fotoPath), fit: BoxFit.cover),
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [Colors.transparent, Colors.black87],
                                  ),
                                ),
                                child: Text(
                                  '${m.fecha.day}/${m.fecha.month}/${m.fecha.year}',
                                  style: AppTextStyles.bodySmall.copyWith(color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  void _viewPhoto(BuildContext context, BodyMetric m) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(File(m.fotoPath)),
        ),
      ),
    );
  }
}
