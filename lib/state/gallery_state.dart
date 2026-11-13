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
  List<AssetPathEntity> allFolders = [];
  
  List<CustomAlbum> albums = [];
  Map<String, List<String>> photoLabels = {};
  Map<String, DateTime> trashedItems = {};
  
  bool isLoading = true;
  bool isAscending = false; // false = Terbaru di atas
  String selectedLabelFilter = '';
  Set<String> hiddenFolders = {};

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
    
    final albumsJson = prefs.getString('albums');
    if (albumsJson != null) {
      albums = (jsonDecode(albumsJson) as List).map((e) => CustomAlbum.fromJson(e)).toList();
    }

    final labelsJson = prefs.getString('labels');
    if (labelsJson != null) {
      photoLabels = Map<String, List<String>>.from((jsonDecode(labelsJson) as Map).map((k, v) => MapEntry(k, List<String>.from(v))));
    }

    final trashJson = prefs.getString('trash');
    if (trashJson != null) {
      Map<String, dynamic> decoded = jsonDecode(trashJson);
      decoded.forEach((k, v) => trashedItems[k] = DateTime.parse(v));
    }

    hiddenFolders = (prefs.getStringList('hiddenFolders') ?? []).toSet();
  }

  Future<void> _saveLocalData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('albums', jsonEncode(albums.map((e) => e.toJson()).toList()));
    await prefs.setString('labels', jsonEncode(photoLabels));
    
    Map<String, String> trashMap = {};
    trashedItems.forEach((k, v) => trashMap[k] = v.toIso8601String());
    await prefs.setString('trash', jsonEncode(trashMap));
    
    await prefs.setStringList('hiddenFolders', hiddenFolders.toList());
  }

  Future<void> _loadMedia() async {
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    if (ps.hasAccess) {
      allFolders = await PhotoManager.getAssetPathList(type: RequestType.image, onlyAll: false);
      final mainPath = await PhotoManager.getAssetPathList(type: RequestType.image, onlyAll: true);
      
      if (mainPath.isNotEmpty) {
        final photos = await mainPath[0].getAssetListPaged(page: 0, size: 5000);
        
        final now = DateTime.now();
        final expiredIds = trashedItems.entries.where((e) => now.difference(e.value).inDays >= 30).map((e) => e.key).toList();
        if (expiredIds.isNotEmpty) {
          await PhotoManager.editor.deleteWithIds(expiredIds);
          for (var id in expiredIds) trashedItems.remove(id);
          await _saveLocalData();
        }

        allPhotos = photos.where((p) => !trashedItems.containsKey(p.id)).toList();
        _sortPhotos();
        _groupPhotos();
      }
    }
  }

  void _sortPhotos() {
    allPhotos.sort((a, b) => isAscending 
        ? a.createDateTime.compareTo(b.createDateTime)
        : b.createDateTime.compareTo(a.createDateTime));
  }

  void toggleSort() {
    isAscending = !isAscending;
    _sortPhotos();
    _groupPhotos();
    notifyListeners();
  }

  void toggleHideFolder(String path) {
    if (hiddenFolders.contains(path)) {
      hiddenFolders.remove(path);
    } else {
      hiddenFolders.add(path);
    }
    _saveLocalData();
    _groupPhotos();
    notifyListeners();
  }

  void setFilterLabel(String label) {
    selectedLabelFilter = label;
    _groupPhotos();
    notifyListeners();
  }

  void _groupPhotos() {
    groupedPhotos.clear();
    final now = DateTime.now();

    for (var photo in allPhotos) {
      if (hiddenFolders.contains(photo.relativePath)) continue;
      
      if (selectedLabelFilter.isNotEmpty) {
        final labels = photoLabels[photo.id] ?? [];
        if (!labels.contains(selectedLabelFilter)) continue;
      }

      final date = photo.createDateTime;
      String key = '${date.day} ${_monthName(date.month)} ${date.year}';
      
      if (date.year == now.year && date.month == now.month && date.day == now.day) key = 'Hari Ini';
      
      groupedPhotos.putIfAbsent(key, () => []).add(photo);
    }
  }

  String _monthName(int month) {
    const m = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    return m[month - 1];
  }

  Future<void> moveToTrash(List<AssetEntity> photos) async {
    for (var p in photos) trashedItems[p.id] = DateTime.now();
    allPhotos.removeWhere((p) => trashedItems.containsKey(p.id));
    _groupPhotos();
    await _saveLocalData();
    notifyListeners();
  }

  void createAlbum(String name) {
    albums.add(CustomAlbum(id: const Uuid().v4(), name: name, photoIds: []));
    _saveLocalData();
    notifyListeners();
  }

  void addToAlbum(String albumId, List<AssetEntity> photos) {
    final album = albums.firstWhere((a) => a.id == albumId);
    for (var p in photos) {
      if (!album.photoIds.contains(p.id)) album.photoIds.add(p.id);
    }
    _saveLocalData();
    notifyListeners();
  }

  void addLabel(List<AssetEntity> photos, String label) {
    for (var p in photos) {
      final current = photoLabels[p.id] ?? [];
      if (!current.contains(label)) {
        current.add(label);
        photoLabels[p.id] = current;
      }
    }
    _saveLocalData();
    notifyListeners();
  }

  List<String> getAllUniqueLabels() {
    final Set<String> unique = {};
    for (var l in photoLabels.values) unique.addAll(l);
    return unique.toList();
  }
}
