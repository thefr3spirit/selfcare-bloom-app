import 'package:flutter/material.dart';

import 'home_screen.dart';
import 'insights_screen.dart';
import 'settings_screen.dart';

/// Main navigation screen with bottom navigation bar
/// Modern Material Design 3 layout - 3 tabs only
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  final GlobalKey<HomeScreenState> _homeScreenKey = GlobalKey();
  final GlobalKey<InsightsScreenState> _insightsScreenKey = GlobalKey();

  // Navigation screens
  List<Widget> get _screens => [
        HomeScreen(key: _homeScreenKey),
        InsightsScreen(key: _insightsScreenKey),
        const SettingsScreen(),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
          // Refresh screens when navigating to them
          if (index == 0) {
            _homeScreenKey.currentState?.refresh();
          } else if (index == 1) {
            _insightsScreenKey.currentState?.refresh();
          }
        },
        elevation: 3,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined, size: 26),
            selectedIcon: Icon(Icons.home, size: 28),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined, size: 26),
            selectedIcon: Icon(Icons.bar_chart, size: 28),
            label: 'Insights',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined, size: 26),
            selectedIcon: Icon(Icons.settings, size: 28),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
