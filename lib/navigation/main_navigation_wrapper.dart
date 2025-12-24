import 'package:flutter/material.dart';
import '../screens/genre_selection/genre_selection_screen.dart';
import '../screens/watchlist/watchlist_screen.dart';
import '../screens/stats/stats_screen.dart';
import '../core/constants.dart';

class MainNavigationWrapper extends StatefulWidget {
  const MainNavigationWrapper({super.key});

  @override
  State<MainNavigationWrapper> createState() => _MainNavigationWrapperState();
}

class _MainNavigationWrapperState extends State<MainNavigationWrapper> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const GenreSelectionScreen(),
    const WatchlistScreen(),
    const StatsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 1),
          child: Container(
            height: 70,
            decoration: BoxDecoration(
              color: scaffoldBlack,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: primaryRed.withOpacity(0.25),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavButton(Icons.explore, 0),
                _buildNavButton(Icons.playlist_add, 1),
                _buildNavButton(Icons.bar_chart, 2),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavButton(IconData icon, int index) {
    return IconButton(
      icon: Icon(icon, size: 32),
      color: _selectedIndex == index ? primaryRed : Colors.grey,
      onPressed: () => setState(() => _selectedIndex = index),
    );
  }
}
