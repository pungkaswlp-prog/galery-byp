import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:photo_view/photo_view.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';

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

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _toggleDetails() {
    setState(() {
      _showDetails = !_showDetails;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentPhoto = widget.photos[_currentIndex];
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Area Foto & Gestur
          GestureDetector(
            onTap: () => setState(() {
              _showUi = !_showUi;
              if (!_showUi) _showDetails = false;
            }),
            onVerticalDragEnd: (details) {
              if (details.primaryVelocity! < 0) {
                // Swipe ke atas
                setState(() {
                  _showDetails = true;
                  _showUi = true;
                });
              } else if (details.primaryVelocity! > 0) {
                // Swipe ke bawah
                setState(() {
                  _showDetails = false;
                });
              }
            },
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.photos.length,
              onPageChanged: (index) {
                setState(() => _currentIndex = index);
              },
              itemBuilder: (context, index) {
                final photo = widget.photos[index];
                return PhotoView(
                  imageProvider: AssetEntityImageProvider(photo, isOriginal: true),
                  minScale: PhotoViewComputedScale.contained,
                  maxScale: PhotoViewComputedScale.covered * 2,
                );
              },
            ),
          ),
          
          // Top Bar (Back & Counter)
          if (_showUi)
            Positioned(
              top: 0, left: 0, right: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                  ),
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                      Text('${_currentIndex + 1} / ${widget.photos.length}', style: const TextStyle(color: Colors.white)),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(LucideIcons.maximize, color: Colors.white),
                        onPressed: () {
                          // Fitur horizontal (bisa ditambahkan nanti)
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Panel EXIF / Detail (Swipe Up)
          if (_showDetails)
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.9),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Detail Foto', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: const Icon(LucideIcons.x, color: Colors.white),
                            onPressed: _toggleDetails,
                          )
                        ],
                      ),
                      const Divider(color: Colors.white24),
                      _buildInfoRow('Nama File', currentPhoto.title ?? 'Tanpa Nama'),
                      _buildInfoRow('Tanggal', DateFormat('EEEE, d MMMM yyyy - HH:mm').format(currentPhoto.modifiedDateTime)),
                      _buildInfoRow('Resolusi', '${currentPhoto.width} x ${currentPhoto.height}'),
                      _buildInfoRow('Ukuran', '${(currentPhoto.size / 1024 / 1024).toStringAsFixed(2)} MB'),
                      // Info EXIF lengkap bisa ditambahkan di sini nanti
                    ],
                  ),
                ),
              ),
            ),

          // Bottom Action Bar (Minimal)
          if (_showUi && !_showDetails)
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter, end: Alignment.topCenter,
                    colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(DateFormat('EEEE, d MMMM yyyy - HH:mm').format(currentPhoto.modifiedDateTime), style: const TextStyle(color: Colors.white, fontSize: 14)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _actionButton(LucideIcons.trash2, 'Hapus', () {}),
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
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(color: Colors.white54))),
          Expanded(child: Text(value, style: const TextStyle(color: Colors.white))),
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
