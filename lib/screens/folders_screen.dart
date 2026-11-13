import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:lucide_icons/lucide_icons.dart';

class FoldersScreen extends StatefulWidget {
  const FoldersScreen({super.key});
  @override
  State<FoldersScreen> createState() => _FoldersScreenState();
}

class _FoldersScreenState extends State<FoldersScreen> {
  List<AssetPathEntity> _folders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFolders();
  }

  Future<void> _loadFolders() async {
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    if (ps.hasAccess) {
      // onlyAll: false berarti mengambil SEMUA folder, bukan hanya folder utama
      final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
        type: RequestType.image,
        onlyAll: false, 
      );
      if (mounted) {
        setState(() {
          _folders = paths;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    
    return ListView.builder(
      itemCount: _folders.length,
      itemBuilder: (context, index) {
        final folder = _folders[index];
        return ListTile(
          leading: const Icon(LucideIcons.folder),
          title: Text(folder.name),
          subtitle: FutureBuilder<int>(
            future: folder.assetCountAsync,
            builder: (context, snapshot) {
              return Text('${snapshot.data ?? 0} foto');
            },
          ),
          onTap: () {
            // Navigasi ke grid khusus folder ini bisa ditambahkan nanti
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Membuka folder: ${folder.name}')),
            );
          },
        );
      },
    );
  }
}
