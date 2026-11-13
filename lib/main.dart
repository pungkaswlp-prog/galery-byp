import 'package:flutter/material.dart';
import 'screens/photos_screen.dart';
import 'screens/folders_screen.dart';
import 'screens/albums_screen.dart';

void main() => runApp(const GaleriApp());

class GaleriApp extends StatelessWidget {
  const GaleriApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Galeri',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system, // Otomatis ikut HP
      home: const MainNavigation(),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});
  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    PhotosScreen(),
    FoldersScreen(),
    AlbumsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Galeri')),
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (int index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.photo), label: 'Photos'),
          NavigationDestination(icon: Icon(Icons.folder), label: 'Folders'),
          NavigationDestination(icon: Icon(Icons.collections_bookmark), label: 'Albums'),
        ],
      ),
    );
  }
}
