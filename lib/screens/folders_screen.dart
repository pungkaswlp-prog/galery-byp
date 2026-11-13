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
    final paths = await PhotoManager.getAssetPathList(type: RequestType.image, onlyAll: false);
    if (mounted) {
      setState(() {
        _folders = paths;
        _isLoading = false;
      });
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
            builder: (context, snapshot) => Text('${snapshot.data ?? 0} foto'),
          ),
          onTap: () {},
        );
      },
    );
  }
}
