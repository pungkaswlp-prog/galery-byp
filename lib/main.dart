import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'theme.dart';
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
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
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
      appBar: AppBar(
        title: Text(
          ['Photos', 'Folders', 'Albums'][_currentIndex],
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (int index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(icon: Icon(LucideIcons.image), label: 'Photos'),
          NavigationDestination(icon: Icon(LucideIcons.folder), label: 'Folders'),
          NavigationDestination(icon: Icon(LucideIcons.layers), label: 'Albums'),
        ],
      ),
    );
  }
}
