import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'photo_viewer_screen.dart'; // Import file baru

class PhotosScreen extends StatefulWidget {
  const PhotosScreen({super.key});
  @override
  State<PhotosScreen> createState() => _PhotosScreenState();
}

class _PhotosScreenState extends State<PhotosScreen> {
  List<AssetEntity> _photos = [];
  Map<String, List<AssetEntity>> _groupedPhotos = {};
  bool _isLoading = true;
  String _error = '';
  int _crossAxisCount = 3;
  
  double _previousScale = 1.0;
  int _pointerCount = 0; 

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    if (kIsWeb) {
      if (mounted) {
        setState(() {
          _error = 'Web Preview tidak mendukung akses galeri. Silakan cek di APK.';
          _isLoading = false;
        });
      }
      return;
    }

    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    
    if (ps.hasAccess) {
      final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
        type: RequestType.image,
        onlyAll: true, 
        filterOption: FilterOptionGroup(
          orders: [
            const OrderOption(type: OrderOptionType.createDate, asc: false),
          ],
        ),
      );
      
      if (paths.isNotEmpty) {
        final List<AssetEntity> photos = await paths[0].getAssetListPaged(page: 0, size: 1000);
        
        photos.sort((a, b) => b.modifiedDateTime.compareTo(a.modifiedDateTime));
        
        _groupPhotos(photos);
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
          _error = 'Izin Ditolak';
          _isLoading = false;
        });
      }
    }
  }

  void _groupPhotos(List<AssetEntity> photos) {
    final Map<String, List<AssetEntity>> grouped = {};
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));

    for (var photo in photos) {
      final date = photo.modifiedDateTime;
      String key;
      
      if (date.year == now.year && date.month == now.month && date.day == now.day) {
        key = 'Hari Ini';
      } else if (date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day) {
        key = 'Kemarin';
      } else {
        key = DateFormat('d MMMM yyyy').format(date);
      }

      if (!grouped.containsKey(key)) {
        grouped[key] = [];
      }
      grouped[key]!.add(photo);
    }
    
    _groupedPhotos = grouped;
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
            Text(_error, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
          ],
        ),
      );
    }

    if (_photos.isEmpty) {
      return const Center(child: Text('Galeri kosong'));
    }

    return Listener(
      onPointerDown: (event) {
        _pointerCount++;
        if (_pointerCount == 2) setState(() {}); 
      },
      onPointerUp: (event) {
        _pointerCount--;
        if (_pointerCount == 0) setState(() {}); 
      },
      child: GestureDetector(
        onScaleStart: (details) {
          _previousScale = 1.0;
        },
        onScaleEnd: (details) {
          _previousScale = 1.0;
        },
        onScaleUpdate: (details) {
          if (_pointerCount == 2) {
            if (details.scale > _previousScale + 0.1) {
              if (_crossAxisCount > 2) {
                setState(() => _crossAxisCount--);
                _previousScale = details.scale;
              }
            } else if (details.scale < _previousScale - 0.1) {
              if (_crossAxisCount < 6) {
                setState(() => _crossAxisCount++);
                _previousScale = details.scale;
              }
            }
          }
        },
        child: CustomScrollView(
          physics: _pointerCount > 1 ? const NeverScrollableScrollPhysics() : const BouncingScrollPhysics(),
          slivers: _groupedPhotos.entries.expand((entry) {
            return [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 8.0),
                  child: Text(
                    entry.key,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
              SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: _crossAxisCount,
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 4,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final photo = entry.value[index];
                    return GestureDetector(
                      onTap: () {
                        // Navigasi ke Viewer
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PhotoViewerScreen(
                              photos: _photos,
                              initialIndex: _photos.indexOf(photo),
                            ),
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: AssetEntityImage(
                          photo,
                          isOriginal: false,
                          thumbnailSize: const ThumbnailSize.square(300),
                          fit: BoxFit.cover,
                        ),
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
    );
  }
}
