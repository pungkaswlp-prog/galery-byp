import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../state/gallery_state.dart';
import 'folder_detail_screen.dart'; // Import layar baru

class FoldersScreen extends StatelessWidget {
  const FoldersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GalleryState>();
    if (state.isLoading) return const Center(child: CircularProgressIndicator());

    return ListView.builder(
      itemCount: state.allFolders.length,
      itemBuilder: (context, index) {
        final folder = state.allFolders[index];
        final isHidden = state.hiddenFolders.contains(folder.relativePath);
        
        return ListTile(
          leading: SizedBox(
            width: 50, height: 50,
            child: FutureBuilder<List<AssetEntity>>(
              future: folder.getAssetListPaged(page: 0, size: 1),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  return ClipRRect(borderRadius: BorderRadius.circular(8), child: AssetEntityImage(snapshot.data!.first, isOriginal: false, thumbnailSize: const ThumbnailSize.square(100), fit: BoxFit.cover));
                }
                return const Icon(LucideIcons.folder);
              },
            ),
          ),
          title: Text(folder.name, style: TextStyle(decoration: isHidden ? TextDecoration.lineThrough : null)),
          subtitle: FutureBuilder<int>(future: folder.assetCountAsync, builder: (_, s) => Text('${s.data ?? 0} foto')),
          trailing: IconButton(
            icon: Icon(isHidden ? LucideIcons.eyeOff : LucideIcons.eye),
            onPressed: () => state.toggleHideFolder(folder.relativePath),
          ),
          onTap: () {
            // Navigasi ke layar isi folder
            Navigator.push(context, MaterialPageRoute(builder: (_) => FolderDetailScreen(folder: folder)));
          },
        );
      },
    );
  }
}
