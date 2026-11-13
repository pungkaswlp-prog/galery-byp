import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class CustomAlbum {
  final String id;
  final String name;
  final List<String> photoIds;

  CustomAlbum({required this.id, required this.name, required this.photoIds});

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'photoIds': photoIds};
  factory CustomAlbum.fromJson(Map<String, dynamic> json) => CustomAlbum(
        id: json['id'],
        name: json['name'],
        photoIds: List<String>.from(json['photoIds']),
      );
}

class GalleryState extends ChangeNotifier {
  List<AssetEntity> allPhotos = [];
  Map<String, List<AssetEntity>> groupedPhotos = {};
  List<CustomAlbum> albums = [];
  Map<String, List<String>> labels = {}; // ID Foto -> List Label
  List<String> trashedPhotoIds = [];
  bool isLoading = true;
  String selectedLabelFilter = '';

  GalleryState() {
    initGallery();
  }

  Future<void> initGallery() async {
    isLoading = true;
    notifyListeners();

    await _loadLocalData();
    await _loadMedia();

    isLoading = false;
    notifyListeners();
  }

  Future<void> _loadLocalData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load Albums
    final albumsJson = prefs.getString('albums');
    if (albumsJson != null) {
      final List decoded = jsonDecode(albumsJson);
      albums = decoded.map((e) => CustomAlbum.fromJson(e)).toList();
    }

    // Load Labels
    final labelsJson = prefs.getString('labels');
    if (labelsJson != null) {
      labels = Map<String, List<String>>.from(
        (jsonDecode(labelsJson) as Map).map((k, v) => MapEntry(k, List<String>.from(v))),
      );
    }

    // Load Trash
    trashedPhotoIds = prefs.getStringList('trash') ?? [];
  }

  Future<void> _saveLocalData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('albums', jsonEncode(albums.map((e) => e.toJson()).toList()));
    await prefs.setString('labels', jsonEncode(labels));
    await prefs.setStringList('trash', trashedPhotoIds);
  }

  Future<void> _loadMedia() async {
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    if (ps.hasAccess) {
      final paths = await PhotoManager.getAssetPathList(type: RequestType.image, onlyAll: true);
      if (paths.isNotEmpty) {
        final photos = await paths[0].getAssetListPaged(page: 0, size: 3000);
        
        // Filter yang ada di sampah
        allPhotos = photos.where((p) => !trashedPhotoIds.contains(p.id)).toList();
        allPhotos.sort((a, b) => b.modifiedDateTime.compareTo(a.modifiedDateTime));
        
        _groupPhotos();
      }
    }
  }

  void _groupPhotos() {
    groupedPhotos.clear();
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));

    for (var photo in allPhotos) {
      // Filter Label
      if (selectedLabelFilter.isNotEmpty) {
        final photoLabels = labels[photo.id] ?? [];
        if (!photoLabels.contains(selectedLabelFilter)) continue;
      }

      final date = photo.modifiedDateTime;
      String key;
      if (date.year == now.year && date.month == now.month && date.day == now.day) {
        key = 'Hari Ini';
      } else if (date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day) {
        key = 'Kemarin';
      } else {
        key = '${date.day} ${_monthName(date.month)} ${date.year}';
      }
      groupedPhotos.putIfAbsent(key, () => []).add(photo);
    }
  }

  String _monthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    return months[month - 1];
  }

  // FITUR: Hapus (Masuk Sampah)
  Future<void> moveToTrash(List<AssetEntity> photos) async {
    for (var p in photos) {
      if (!trashedPhotoIds.contains(p.id)) trashedPhotoIds.add(p.id);
    }
    allPhotos.removeWhere((p) => trashedPhotoIds.contains(p.id));
    _groupPhotos();
    await _saveLocalData();
    notifyListeners();
  }

  // FITUR: Buat Album
  void createAlbum(String name) {
    albums.add(CustomAlbum(id: const Uuid().v4(), name: name, photoIds: []));
    _saveLocalData();
    notifyListeners();
  }

  // FITUR: Tambah ke Album
  void addToAlbum(String albumId, List<AssetEntity> photos) {
    final album = albums.firstWhere((a) => a.id == albumId);
    for (var p in photos) {
      if (!album.photoIds.contains(p.id)) album.photoIds.add(p.id);
    }
    _saveLocalData();
    notifyListeners();
  }

  // FITUR: Tambah Label
  void addLabel(List<AssetEntity> photos, String label) {
    for (var p in photos) {
      final currentLabels = labels[p.id] ?? [];
      if (!currentLabels.contains(label)) {
        currentLabels.add(label);
        labels[p.id] = currentLabels;
      }
    }
    _saveLocalData();
    notifyListeners();
  }

  // FITUR: Ambil Semua Label Unik
  List<String> getAllUniqueLabels() {
    final Set<String> unique = {};
    for (var l in labels.values) {
      unique.addAll(l);
    }
    return unique.toList();
  }

  // FITUR: Set Filter Label
  void setFilterLabel(String label) {
    selectedLabelFilter = label;
    _groupPhotos();
    notifyListeners();
  }
}
