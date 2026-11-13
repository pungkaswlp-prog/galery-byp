import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../state/gallery_state.dart';
import 'photo_viewer_screen.dart';

class PhotosScreen extends StatefulWidget {
  const PhotosScreen({super.key});
  @override
  State<PhotosScreen> createState() => _PhotosScreenState();
}

class _PhotosScreenState extends State<PhotosScreen> {
  int _crossAxisCount = 3;
  double _previousScale = 1.0;
  int _pointerCount = 0;
  
  bool _isSelecting = false;
  List<AssetEntity> _selectedPhotos = [];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GalleryState>();
    if (state.isLoading) return const Center(child: CircularProgressIndicator());

    return Column(
      children: [
        if (!_isSelecting && state.getAllUniqueLabels().isNotEmpty)
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                ActionChip(
                  label: const Text('Semua'),
                  onPressed: () => state.setFilterLabel(''),
                  backgroundColor: state.selectedLabelFilter.isEmpty ? Theme.of(context).colorScheme.primaryContainer : null,
                ),
                const SizedBox(width: 8),
                ...state.getAllUniqueLabels().map((label) => Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ActionChip(
                    label: Text(label),
                    onPressed: () => state.setFilterLabel(label),
                    backgroundColor: state.selectedLabelFilter == label ? Theme.of(context).colorScheme.primaryContainer : null,
                  ),
                )),
              ],
            ),
          ),

        if (_isSelecting)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Row(
              children: [
                Text('${_selectedPhotos.length} dipilih', style: const TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(icon: const Icon(LucideIcons.trash2), onPressed: () { state.moveToTrash(_selectedPhotos); setState(() { _isSelecting = false; _selectedPhotos.clear(); }); }),
                IconButton(icon: const Icon(LucideIcons.layers), onPressed: () => _showAlbumDialog(context, _selectedPhotos)),
                IconButton(icon: const Icon(LucideIcons.tag), onPressed: () => _showLabelDialog(context, _selectedPhotos)),
                IconButton(icon: const Icon(LucideIcons.x), onPressed: () => setState(() { _isSelecting = false; _selectedPhotos.clear(); })),
              ],
            ),
          ),

        Expanded(
          child: Listener(
            onPointerDown: (e) { _pointerCount++; if (_pointerCount == 2) setState(() {}); },
            onPointerUp: (e) { _pointerCount--; if (_pointerCount == 0) setState(() {}); },
            child: GestureDetector(
              onScaleStart: (d) => _previousScale = 1.0,
              onScaleEnd: (d) => _previousScale = 1.0,
              onScaleUpdate: (d) {
                if (_pointerCount == 2) {
                  if (d.scale > _previousScale + 0.1 && _crossAxisCount > 2) { setState(() => _crossAxisCount--); _previousScale = d.scale; }
                  else if (d.scale < _previousScale - 0.1 && _crossAxisCount < 6) { setState(() => _crossAxisCount++); _previousScale = d.scale; }
                }
              },
              child: CustomScrollView(
                physics: _pointerCount > 1 ? const NeverScrollableScrollPhysics() : const BouncingScrollPhysics(),
                slivers: state.groupedPhotos.entries.expand((entry) {
                  return [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
                        child: Text(entry.key, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                      ),
                    ),
                    SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: _crossAxisCount, crossAxisSpacing: 4, mainAxisSpacing: 4),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final photo = entry.value[index];
                          final isSelected = _selectedPhotos.contains(photo);
                          return GestureDetector(
                            onTap: () {
                              if (_isSelecting) {
                                setState(() { isSelected ? _selectedPhotos.remove(photo) : _selectedPhotos.add(photo); if (_selectedPhotos.isEmpty) _isSelecting = false; });
                              } else {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => PhotoViewerScreen(photos: state.allPhotos, initialIndex: state.allPhotos.indexOf(photo))));
                              }
                            },
                            onLongPress: () => setState(() { _isSelecting = true; if (!_selectedPhotos.contains(photo)) _selectedPhotos.add(photo); }),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.surfaceVariant,
                                    borderRadius: BorderRadius.circular(8),
                                    border: isSelected ? Border.all(color: Theme.of(context).colorScheme.primary, width: 3) : null,
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: AssetEntityImage(photo, isOriginal: false, thumbnailSize: const ThumbnailSize.square(300), fit: BoxFit.cover),
                                ),
                                if (isSelected) Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Colors.black.withOpacity(0.3)), child: const Center(child: Icon(LucideIcons.checkCircle2, color: Colors.white, size: 32))),
                              ],
                            ),
                          );
                        },
                        childCount: entry.value.length,
                      ),
                    ),
                  ];
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showAlbumDialog(BuildContext context, List<AssetEntity> photos) {
    final state = context.read<GalleryState>();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Tambah ke Album'),
      content: SizedBox(width: double.maxFinite, child: ListView.builder(
        shrinkWrap: true, itemCount: state.albums.length, itemBuilder: (_, i) => ListTile(
          title: Text(state.albums[i].name),
          onTap: () { state.addToAlbum(state.albums[i].id, photos); Navigator.pop(ctx); setState(() { _isSelecting = false; _selectedPhotos.clear(); }); },
        ),
      )),
    ));
  }

  void _showLabelDialog(BuildContext context, List<AssetEntity> photos) {
    final state = context.read<GalleryState>();
    final controller = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Tambah Label'),
      content: TextField(controller: controller, decoration: const InputDecoration(hintText: 'Misal: Kucing')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
        TextButton(onPressed: () { if (controller.text.isNotEmpty) state.addLabel(photos, controller.text.trim()); Navigator.pop(ctx); setState(() { _isSelecting = false; _selectedPhotos.clear(); }); }, child: const Text('Simpan')),
      ],
    ));
  }
}
