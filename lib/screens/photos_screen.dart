import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

class PhotosScreen extends StatefulWidget {
  const PhotosScreen({super.key});
  @override
  State<PhotosScreen> createState() => _PhotosScreenState();
}

class _PhotosScreenState extends State<PhotosScreen> {
  String _status = 'Meminta izin...';
  int _photoCount = 0;

  @override
  void initState() {
    super.initState();
    _requestPermission();
  }

  Future<void> _requestPermission() async {
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    if (ps.isAuth) {
      final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
        type: RequestType.image, // Hanya foto, tidak termasuk video
      );
      if (paths.isNotEmpty) {
        final int count = await paths[0].assetCountAsync;
        setState(() {
          _status = 'Izin Diberikan';
          _photoCount = count;
        });
      }
    } else {
      setState(() => _status = 'Izin Ditolak / Web Preview tidak mendukung galeri');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo_library, size: 64, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 16),
          Text(_status, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text('Total: $_photoCount foto', style: Theme.of(context).textTheme.headlineSmall),
        ],
      ),
    );
  }
}
