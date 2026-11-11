import 'package:flutter/material.dart';
import '../domain/career.dart';
import '../domain/models.dart';
import '../state/game_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class NationalTeamScreen extends StatefulWidget {
  const NationalTeamScreen({super.key});

  @override
  State<NationalTeamScreen> createState() => _NationalTeamScreenState();
}

class _NationalTeamScreenState extends State<NationalTeamScreen> {
  String? selectedCode;
  String playerSearch = '';
  String rosterFilter = 'ALL';

  void _showResult(BuildContext context, ActionResult result) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    final career = game.career!;
    final code = career.nationalTeamCode;

    if (code == null) return _jobMarket(context, game);

    final teamName = Career.nationalTeams[code] ?? code;
    final called = career.nationalCallups;
    final allPlayers = career.eligibleNationalPlayers;
    final players = allPlayers.where((player) {
      final matchesSearch = player.name.toLowerCase().contains(playerSearch.trim().toLowerCase()) ||
          player.position.toLowerCase().contains(playerSearch.trim().toLowerCase());
      final matchesFilter = rosterFilter == 'ALL' ||
          (rosterFilter == 'CALLED' && called.contains(player.id)) ||
          (rosterFilter == 'AVAILABLE' && !called.contains(player.id));
      return matchesSearch && matchesFilter;
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ScreenHeader(kicker: 'INTERNATIONAL MANAGEMENT', title: 'National team'),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF123B36), Color(0xFF102536)],
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppTheme.green.withValues(alpha: .16),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(code, style: const TextStyle(fontWeight: FontWeight.w900)),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(teamName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                          const Text('NATIONAL TEAM HEAD COACH', style: TextStyle(color: Colors.white60, fontSize: 10, letterSpacing: 1)),
                        ],
                      ),
                    ),
                    const Icon(Icons.flag_rounded, color: AppTheme.gold, size: 28),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _metric('CALLED UP', '${called.length}/26'),
                  const SizedBox(width: 8),
                  _metric('STARTING XI', '${career.nationalStartingXi.length}/11'),
                  const SizedBox(width: 8),
                  _metric('ELIGIBLE', '${players.length}'),
                ],
              ),
              const SizedBox(height: 12),
              const Text('PLAYER POOL', style: TextStyle(color: AppTheme.green, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1)),
              const SizedBox(height: 4),
              const Text('Select players from every club. Build your squad, choose your starting XI and appoint a captain.', style: TextStyle(color: Colors.white60, fontSize: 12)),
              const SizedBox(height: 12),
              TextField(
                onChanged: (value) => setState(() => playerSearch = value),
                decoration: InputDecoration(
                  hintText: 'Search player or position…',
                  prefixIcon: const Icon(Icons.search_rounded, size: 19),
                  suffixIcon: playerSearch.isEmpty ? null : IconButton(
                    onPressed: () => setState(() => playerSearch = ''),
                    icon: const Icon(Icons.close_rounded, size: 17),
                  ),
                  isDense: true,
                  filled: true,
                  fillColor: AppTheme.panel,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(spacing: 7, children: [
                for (final filter in const ['ALL', 'CALLED', 'AVAILABLE'])
                  ChoiceChip(
                    label: Text(filter == 'ALL' ? 'ALL PLAYERS' : filter == 'CALLED' ? 'CALLED UP' : 'AVAILABLE'),
                    selected: rosterFilter == filter,
                    onSelected: (_) => setState(() => rosterFilter = filter),
                    visualDensity: VisualDensity.compact,
                  ),
              ]),
            ],
          ),
        ),
        Expanded(
          child: players.isEmpty
              ? Center(child: Text(playerSearch.isNotEmpty || rosterFilter != 'ALL' ? 'No players match this filter.' : 'No eligible players are currently available.'))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
                  itemCount: players.length,
                  itemBuilder: (context, index) {
                    final player = players[index];
                    final isCalled = called.contains(player.id);
                    final isStarter = career.nationalStartingXi.contains(player.id);
                    final isCaptain = career.nationalCaptainId == player.id;
                    final club = player.clubId == null
                        ? 'Free agent'
                        : career.clubs[player.clubId!]?.name ?? 'Unattached';
                    return Card(
                      margin: const EdgeInsets.only(bottom: 7),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(color: AppTheme.panelLight, borderRadius: BorderRadius.circular(11)),
                                  child: Text(player.position, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(child: Text(player.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800))),
                                          if (isCaptain) ...[
                                            const SizedBox(width: 5),
                                            const Icon(Icons.shield, size: 14, color: AppTheme.gold),
                                          ],
                                        ],
                                      ),
                                      Text('$club • Age ${player.age}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                                    ],
                                  ),
                                ),
                                RatingBadge(player.rating),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                if (isCalled) ...[
                                  _tag(isStarter ? 'STARTING XI' : 'SQUAD', isStarter ? AppTheme.green : Colors.white54),
                                  const Spacer(),
                                  IconButton(
                                    visualDensity: VisualDensity.compact,
                                    tooltip: isStarter ? 'Remove from starting XI' : 'Add to starting XI',
                                    onPressed: () => _showResult(context, game.toggleNationalStarter(player.id)),
                                    icon: Icon(isStarter ? Icons.star_rounded : Icons.star_border_rounded, color: isStarter ? AppTheme.gold : Colors.white60),
                                  ),
                                  IconButton(
                                    visualDensity: VisualDensity.compact,
                                    tooltip: 'Make captain',
                                    onPressed: isCaptain ? null : () => _showResult(context, game.setNationalCaptain(player.id)),
                                    icon: Icon(Icons.shield_outlined, color: isCaptain ? AppTheme.gold : Colors.white60),
                                  ),
                                  TextButton(
                                    onPressed: () => _showResult(context, game.dropNationalPlayer(player.id)),
                                    child: const Text('DROP', style: TextStyle(fontSize: 10)),
                                  ),
                                ] else ...[
                                  const Spacer(),
                                  FilledButton.tonalIcon(
                                    onPressed: called.length >= 26 ? null : () => _showResult(context, game.callUpPlayer(player.id)),
                                    icon: const Icon(Icons.add, size: 16),
                                    label: const Text('CALL UP', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900)),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _jobMarket(BuildContext context, GameController game) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 24),
      children: [
        const ScreenHeader(kicker: 'INTERNATIONAL MANAGEMENT', title: 'National team jobs'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: AppTheme.panel, borderRadius: BorderRadius.circular(18)),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.public_rounded, color: AppTheme.gold, size: 34),
              SizedBox(height: 12),
              Text('Take your country to the top.', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              SizedBox(height: 6),
              Text('Accept an international management role and select players from clubs across the football world.', style: TextStyle(color: Colors.white60, height: 1.4)),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text('AVAILABLE NATIONAL TEAMS', style: TextStyle(color: AppTheme.green, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: selectedCode,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Choose a national team', border: OutlineInputBorder()),
          items: Career.nationalTeams.entries.map((entry) => DropdownMenuItem(
            value: entry.key,
            child: Text('${entry.value}  (${entry.key})'),
          )).toList(),
          onChanged: (value) => setState(() => selectedCode = value),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: selectedCode == null
              ? null
              : () {
                  final result = game.appointNationalTeam(selectedCode!);
                  _showResult(context, result);
                },
          icon: const Icon(Icons.handshake_rounded),
          label: const Text('ACCEPT NATIONAL TEAM JOB'),
        ),
        const SizedBox(height: 12),
        const Text('The current player database uses generated fictional players with assigned nationalities. Real player identities and international fixtures will be connected as the licensed-data and competition systems are added.', style: TextStyle(color: Colors.white38, fontSize: 11, height: 1.4)),
      ],
    );
  }

  Widget _metric(String label, String value) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(color: AppTheme.panel, borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
              const SizedBox(height: 3),
              Text(label, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white54, fontSize: 8, fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      );

  Widget _tag(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: color.withValues(alpha: .12), borderRadius: BorderRadius.circular(7)),
        child: Text(text, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w900)),
      );
}
