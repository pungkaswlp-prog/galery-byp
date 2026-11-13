import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'state/gallery_state.dart';
import 'screens/photos_screen.dart';
import 'screens/folders_screen.dart';
import 'screens/albums_screen.dart';

void main() {
  runApp(ChangeNotifierProvider(create: (_) => GalleryState(), child: const GaleriApp()));
}

class GaleriApp extends StatelessWidget {
  const GaleriApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Galeri',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, surface: const Color(0xFFF8FAFC)),
        textTheme: GoogleFonts.interTextTheme(),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.grey, brightness: Brightness.dark, surface: Colors.black),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        scaffoldBackgroundColor: Colors.black,
      ),
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

  final List<Widget> _screens = const [PhotosScreen(), FoldersScreen(), AlbumsScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(['Photos', 'Folders', 'Albums'][_currentIndex], style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          if (_currentIndex == 0)
            IconButton(
              icon: const Icon(LucideIcons.arrowUpDown),
              onPressed: () => context.read<GalleryState>().toggleSort(),
            ),
        ],
      ),
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(LucideIcons.image), label: 'Photos'),
          NavigationDestination(icon: Icon(LucideIcons.folder), label: 'Folders'),
          NavigationDestination(icon: Icon(LucideIcons.layers), label: 'Albums'),
        ],
      ),
    );
  }
}
