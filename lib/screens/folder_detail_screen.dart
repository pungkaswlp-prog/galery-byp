import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'photo_viewer_screen.dart';

class FolderDetailScreen extends StatefulWidget {
  final AssetPathEntity folder;
  const FolderDetailScreen({super.key, required this.folder});

  @override
  State<FolderDetailScreen> createState() => _FolderDetailScreenState();
}

class _FolderDetailScreenState extends State<FolderDetailScreen> {
  List<AssetEntity> _photos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    final photos = await widget.folder.getAssetListPaged(page: 0, size: 1000);
    photos.sort((a, b) => b.createDateTime.compareTo(a.createDateTime));
    if (mounted) {
      setState(() {
        _photos = photos;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.folder.name)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
              padding: const EdgeInsets.all(4),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemCount: _photos.length,
              itemBuilder: (context, index) {
                final photo = _photos[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => PhotoViewerScreen(photos: _photos, initialIndex: index)));
                  },
                  child: Container(
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: AssetEntityImage(
                      photo,
                      isOriginal: false,
                      thumbnailSize: const ThumbnailSize.square(300),
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              },
            ),
    );
  }
}
