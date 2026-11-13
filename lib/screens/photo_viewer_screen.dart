import 'dart:io';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
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
  bool _isHorizontal = false;
  
  Map<String, IfdTag> _exifData = {};
  bool _isLoadingExif = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    _loadExif(widget.photos[_currentIndex]);
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
            onVerticalDragEnd: (d) {
              if (d.primaryVelocity! < 0) setState(() { _showDetails = true; _showUi = true; });
              else if (d.primaryVelocity! > 0) setState(() => _showDetails = false);
            },
            child: PageView.builder(
              controller: _pageController,
              scrollDirection: _isHorizontal ? Axis.horizontal : Axis.vertical,
              itemCount: widget.photos.length,
              onPageChanged: (i) { setState(() => _currentIndex = i); _loadExif(widget.photos[i]); },
              itemBuilder: (context, index) {
                return FutureBuilder<File?>(
                  future: widget.photos[index].file,
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
                      IconButton(icon: Icon(_isHorizontal ? LucideIcons.minimize : LucideIcons.maximize, color: Colors.white), onPressed: () => setState(() => _isHorizontal = !_isHorizontal)),
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
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.95), borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
                child: SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        const Text('Detail & EXIF', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        IconButton(icon: const Icon(LucideIcons.x, color: Colors.white), onPressed: () => setState(() => _showDetails = false)),
                      ]),
                      const Divider(color: Colors.white24),
                      _buildInfoRow('Nama File', currentPhoto.title ?? 'Tanpa Nama'),
                      _buildInfoRow('Tanggal', DateFormat('EEEE, d MMMM yyyy - HH:mm').format(currentPhoto.modifiedDateTime)),
                      _buildInfoRow('Resolusi', '${currentPhoto.width} x ${currentPhoto.height}'),
                      
                      if (_isLoadingExif) const Center(child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator()))
                      else if (_exifData.isNotEmpty) ...[
                        const Divider(color: Colors.white24),
                        if (_exifData.containsKey('Image Model')) _buildInfoRow('Kamera', _exifData['Image Model']!.printable),
                        if (_exifData.containsKey('EXIF FNumber')) _buildInfoRow('F-Stop', 'f/${_exifData['EXIF FNumber']!.printable}'),
                        if (_exifData.containsKey('EXIF ExposureTime')) _buildInfoRow('Kecepatan', '${_exifData['EXIF ExposureTime']!.printable} s'),
                        if (_exifData.containsKey('EXIF ISOSpeedRatings')) _buildInfoRow('ISO', _exifData['EXIF ISOSpeedRatings']!.printable),
                        if (_exifData.containsKey('EXIF FocalLength')) _buildInfoRow('Focal Length', '${_exifData['EXIF FocalLength']!.printable} mm'),
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
                  child: Row(
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
      child: Row(children: [
        SizedBox(width: 110, child: Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13))),
        Expanded(child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 13))),
      ]),
    );
  }

  Widget _actionButton(IconData icon, String label, VoidCallback onTap) {
    return Expanded(child: InkWell(onTap: onTap, child: Column(children: [
      Icon(icon, color: Colors.white, size: 24),
      const SizedBox(height: 4),
      Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
    ])));
  }
}
