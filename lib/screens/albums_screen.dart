import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../state/gallery_state.dart';

class AlbumsScreen extends StatelessWidget {
  const AlbumsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GalleryState>();

    return Scaffold(
      body: state.albums.isEmpty
          ? const Center(child: Text('Belum ada album. Tekan + untuk membuat.'))
          : ListView.builder(
              itemCount: state.albums.length,
              itemBuilder: (context, index) {
                final album = state.albums[index];
                return ListTile(
                  leading: const Icon(LucideIcons.layers),
                  title: Text(album.name),
                  subtitle: Text('${album.photoIds.length} foto'),
                  onTap: () {},
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateAlbumDialog(context),
        child: const Icon(LucideIcons.plus),
      ),
    );
  }

  void _showCreateAlbumDialog(BuildContext context) {
    final state = context.read<GalleryState>();
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Buat Album Baru'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Nama Album'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) state.createAlbum(controller.text.trim());
              Navigator.pop(ctx);
            },
            child: const Text('Buat'),
          ),
        ],
      ),
    );
  }
}
