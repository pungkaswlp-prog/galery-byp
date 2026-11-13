import 'dart:io';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:photo_view/photo_view.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:exif/exif.dart';
import 'package:provider/provider.dart';
import '../state/gallery_state.dart';

class PhotoViewerScreen extends StatefulWidget {
  final List<AssetEntity> photos;
  final int initialIndex;

  const PhotoViewerScreen({super.key, required this.photos, required this.initialIndex});

  @override
  State<PhotoViewerScreen> createState() => _PhotoViewerScreenState();
}

class _PhotoViewerScreenState extends State<PhotoViewerScreen> {
  late PageController _pageController;
  late int _currentIndex;
  bool _showUi = true;
  bool _showDetails = false;
  
  Map<String, IfdTag> _exifData = {};
  bool _isLoadingExif = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    _loadExif(widget.photos[_currentIndex]);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadExif(AssetEntity photo) async {
    setState(() { _isLoadingExif = true; _exifData = {}; });
    try {
      final File? file = await photo.file;
      if (file != null) {
        final bytes = await file.readAsBytes();
        final tags = await readExifFromBytes(bytes);
        if (mounted) setState(() { _exifData = tags; _isLoadingExif = false; });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingExif = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentPhoto = widget.photos[_currentIndex];
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          GestureDetector(
            onTap: () => setState(() { _showUi = !_showUi; if (!_showUi) _showDetails = false; }),
            onVerticalDragEnd: (details) {
              if (details.primaryVelocity! < 0) setState(() { _showDetails = true; _showUi = true; });
              else if (details.primaryVelocity! > 0) setState(() => _showDetails = false);
            },
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.photos.length,
              onPageChanged: (index) {
                setState(() => _currentIndex = index);
                _loadExif(widget.photos[index]);
              },
              itemBuilder: (context, index) {
                final photo = widget.photos[index];
                return FutureBuilder<File?>(
                  future: photo.file,
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data != null) {
                      return PhotoView(
                        imageProvider: FileImage(snapshot.data!),
                        minScale: PhotoViewComputedScale.contained,
                        maxScale: PhotoViewComputedScale.covered * 2,
                        filterQuality: FilterQuality.high,
                      );
                    }
                    return const Center(child: CircularProgressIndicator(color: Colors.white));
                  },
                );
              },
            ),
          ),
          
          // UI Elements
          if (_showUi)
            Positioned(
              top: 0, left: 0, right: 0,
              child: Container(
                decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black.withOpacity(0.7), Colors.transparent])),
                child: SafeArea(
                  child: Row(
                    children: [
                      IconButton(icon: const Icon(LucideIcons.arrowLeft, color: Colors.white), onPressed: () => Navigator.pop(context)),
                      const Spacer(),
                      Text('${_currentIndex + 1} / ${widget.photos.length}', style: const TextStyle(color: Colors.white)),
                      const Spacer(),
                      IconButton(icon: const Icon(LucideIcons.maximize, color: Colors.white), onPressed: () {}),
                    ],
                  ),
                ),
              ),
            ),

          if (_showDetails)
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.95), borderRadius: const BorderRadius.vertical(top: Radius.circular(24)), border: Border.all(color: Colors.white12)),
                child: SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Detail & EXIF', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          IconButton(icon: const Icon(LucideIcons.x, color: Colors.white), onPressed: () => setState(() => _showDetails = false)),
                        ],
                      ),
                      const Divider(color: Colors.white24),
                      _buildInfoRow('Nama File', currentPhoto.title ?? 'Tanpa Nama'),
                      _buildInfoRow('Tanggal', DateFormat('EEEE, d MMMM yyyy - HH:mm').format(currentPhoto.modifiedDateTime)),
                      _buildInfoRow('Resolusi', '${currentPhoto.width} x ${currentPhoto.height}'),
                      
                      FutureBuilder<File?>(
                        future: currentPhoto.file,
                        builder: (context, snapshot) {
                          if (snapshot.hasData && snapshot.data != null) {
                            return FutureBuilder<int>(
                              future: snapshot.data!.length(),
                              builder: (context, lengthSnapshot) {
                                if (lengthSnapshot.hasData) {
                                  final mb = (lengthSnapshot.data! / (1024 * 1024)).toStringAsFixed(2);
                                  return _buildInfoRow('Ukuran', '$mb MB');
                                }
                                return _buildInfoRow('Ukuran', 'Menghitung...');
                              }
                            );
                          }
                          return _buildInfoRow('Ukuran', 'Menghitung...');
                        },
                      ),

                      if (_isLoadingExif)
                        const Padding(padding: EdgeInsets.only(top: 16.0), child: Center(child: CircularProgressIndicator()))
                      else if (_exifData.isNotEmpty) ...[
                        const Divider(color: Colors.white24),
                        const Text('Info Kamera', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        if (_exifData.containsKey('Image Model')) _buildInfoRow('Kamera', _exifData['Image Model']!.printable),
                        if (_exifData.containsKey('EXIF FNumber')) _buildInfoRow('F-Stop', 'f/${_exifData['EXIF FNumber']!.printable}'),
                        if (_exifData.containsKey('EXIF ExposureTime')) _buildInfoRow('Kecepatan', '${_exifData['EXIF ExposureTime']!.printable} s'),
                        if (_exifData.containsKey('EXIF ISOSpeedRatings')) _buildInfoRow('ISO', _exifData['EXIF ISOSpeedRatings']!.printable),
                        if (_exifData.containsKey('EXIF FocalLength')) _buildInfoRow('Focal Length', '${_exifData['EXIF FocalLength']!.printable} mm'),
                      ] else ...[
                        const Divider(color: Colors.white24),
                        const Text('Foto ini tidak memiliki data EXIF kamera.', style: TextStyle(color: Colors.white54, fontStyle: FontStyle.italic)),
                      ]
                    ],
                  ),
                ),
              ),
            ),

          if (_showUi && !_showDetails)
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Colors.black.withOpacity(0.7), Colors.transparent])),
                child: SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(DateFormat('EEEE, d MMMM yyyy - HH:mm').format(currentPhoto.modifiedDateTime), style: const TextStyle(color: Colors.white, fontSize: 14)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _actionButton(LucideIcons.trash2, 'Hapus', () {
                            context.read<GalleryState>().moveToTrash([currentPhoto]);
                            Navigator.pop(context);
                          }),
                          _actionButton(LucideIcons.folderPlus, 'Album', () {}),
                          _actionButton(LucideIcons.tag, 'Label', () {}),
                          _actionButton(LucideIcons.share2, 'Share', () {}),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 110, child: Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13))),
          Expanded(child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 13))),
        ],
      ),
    );
  }

  Widget _actionButton(IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            children: [
              Icon(icon, color: Colors.white, size: 24),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}
