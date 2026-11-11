import 'package:flutter/material.dart';
import '../state/game_controller.dart';
import 'competitions_screen.dart';
import 'dashboard_screen.dart';
import 'squad_screen.dart';
import 'tactics_screen.dart';
import 'transfers_screen.dart';

class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  int selectedIndex = 0;

  static const pages = [
    DashboardScreen(),
    SquadScreen(),
    TransfersScreen(),
    CompetitionsScreen(),
    TacticsScreen(),
  ];

  static const destinations = [
    NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Home'),
    NavigationDestination(icon: Icon(Icons.groups_2_outlined), selectedIcon: Icon(Icons.groups_2_rounded), label: 'Squad'),
    NavigationDestination(icon: Icon(Icons.swap_horiz_rounded), selectedIcon: Icon(Icons.swap_horiz_rounded), label: 'Market'),
    NavigationDestination(icon: Icon(Icons.emoji_events_outlined), selectedIcon: Icon(Icons.emoji_events_rounded), label: 'League'),
    NavigationDestination(icon: Icon(Icons.tune_rounded), selectedIcon: Icon(Icons.tune_rounded), label: 'Tactics'),
  ];

  @override
  Widget build(BuildContext context) {
    GameScope.of(context);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: IndexedStack(index: selectedIndex, children: pages),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        destinations: destinations,
        onDestinationSelected: (value) => setState(() => selectedIndex = value),
      ),
    );
  }
}
