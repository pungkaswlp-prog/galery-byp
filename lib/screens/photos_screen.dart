import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:lucide_icons/lucide_icons.dart';

class PhotosScreen extends StatefulWidget {
  const PhotosScreen({super.key});
  @override
  State<PhotosScreen> createState() => _PhotosScreenState();
}

class _PhotosScreenState extends State<PhotosScreen> {
  List<AssetEntity> _photos = [];
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    
    if (ps.hasAccess) {
      final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
        type: RequestType.image,
        onlyAll: true, // Hanya ambil wadah utama (Semua Foto)
      );
      
      if (paths.isNotEmpty) {
        // Ambil maksimal 1000 foto dulu untuk performa
        final List<AssetEntity> photos = await paths[0].getAssetListPaged(page: 0, size: 1000);
        if (mounted) {
          setState(() {
            _photos = photos;
            _isLoading = false;
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _error = 'Izin Ditolak / Web Preview tidak mendukung galeri';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_error.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.camera, size: 64),
            const SizedBox(height: 16),
            Text(_error),
          ],
        ),
      );
    }

    if (_photos.isEmpty) {
      return const Center(child: Text('Galeri kosong'));
    }

    // Tampilan Grid Foto
    return GridView.builder(
      padding: const EdgeInsets.all(4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, // 3 Kolom
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: _photos.length,
      itemBuilder: (context, index) {
        final photo = _photos[index];
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant, // Warna placeholder
            borderRadius: BorderRadius.circular(8),
          ),
          clipBehavior: Clip.antiAlias,
          child: AssetEntityImage(
            photo,
            isOriginal: false,
            thumbnailSize: const ThumbnailSize.square(300), // Resolusi thumbnail
            fit: BoxFit.cover,
          ),
        );
      },
    );
  }
}
