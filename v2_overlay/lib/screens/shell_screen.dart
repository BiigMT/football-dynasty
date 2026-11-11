import 'package:flutter/material.dart';
import '../state/game_controller.dart';
import '../theme/app_theme.dart';
import 'competitions_screen.dart';
import 'dashboard_screen.dart';
import 'national_team_screen.dart';
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
    NationalTeamScreen(),
  ];

  static const labels = ['HOME', 'SQUAD', 'MARKET', 'LEAGUE', 'TACTICS', 'NATION'];
  static const icons = [
    Icons.home_rounded,
    Icons.groups_rounded,
    Icons.swap_horiz_rounded,
    Icons.emoji_events_rounded,
    Icons.tune_rounded,
    Icons.flag_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    GameScope.of(context);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: IndexedStack(index: selectedIndex, children: pages),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF091522),
          border: Border(top: BorderSide(color: Colors.white.withOpacity(.08))),
          boxShadow: const [
            BoxShadow(color: Colors.black38, blurRadius: 18, offset: Offset(0, -5)),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 66,
            child: Row(
              children: List.generate(labels.length, (index) {
                final selected = selectedIndex == index;
                return Expanded(
                  child: InkWell(
                    onTap: () => setState(() => selectedIndex = index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.fromLTRB(3, 7, 3, 5),
                      decoration: BoxDecoration(
                        color: selected ? AppTheme.green.withOpacity(.12) : Colors.transparent,
                        borderRadius: BorderRadius.circular(13),
                        border: selected
                            ? Border.all(color: AppTheme.green.withOpacity(.22))
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            icons[index],
                            size: 20,
                            color: selected ? AppTheme.green : AppTheme.muted,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            labels[index],
                            maxLines: 1,
                            style: TextStyle(
                              fontSize: 7,
                              letterSpacing: .4,
                              fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
                              color: selected ? AppTheme.green : AppTheme.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
