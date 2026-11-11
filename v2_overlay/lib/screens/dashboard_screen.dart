import 'package:flutter/material.dart';
import '../domain/models.dart';
import '../state/game_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'match_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    final c = game.career!;
    final club = c.userClub;
    final rows = c.table;
    final myRow = rows.firstWhere((r) => r.clubId == c.userClubId);
    final squad = c.userSquad;
    final injured = squad.where((p) => p.injuredMatches > 0).length;
    final suspended = squad.where((p) => p.suspendedMatches > 0).length;
    final expiring = squad.where((p) => p.contractYears <= 1).length;
    final fx = c.nextUserFixture;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 30),
      children: [
        Row(
          children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(color: AppTheme.panelLight, borderRadius: BorderRadius.circular(13)),
              child: const Icon(Icons.sports_soccer, color: AppTheme.green, size: 23),
            ),
            const SizedBox(width: 11),
            const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('FOOTBALL DYNASTY', style: TextStyle(fontSize: 11, letterSpacing: 2.0, color: AppTheme.green, fontWeight: FontWeight.w900)),
              Text('Manager career', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
            ])),
            IconButton(
              tooltip: 'Career menu',
              onPressed: () => _menu(context, game),
              icon: const Icon(Icons.more_horiz, color: Colors.white70),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _ClubHero(
          clubName: club.name,
          shortName: club.shortName,
          colour: club.colorValue,
          manager: c.managerName,
          season: c.seasonLabel.toString(),
          position: c.userPosition.toString(),
          points: myRow.points.toString(),
          balance: fmtMoney(club.balance),
          matchday: c.matchday,
          totalMatchdays: c.totalMatchdays,
        ),
        const SizedBox(height: 22),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('MATCHDAY', style: TextStyle(fontSize: 12, color: AppTheme.green, letterSpacing: 1.6, fontWeight: FontWeight.w900)),
          Text('ROUND ${c.matchday} / ${c.totalMatchdays}', style: const TextStyle(fontSize: 10, color: Colors.white54, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 9),
        if (c.seasonComplete)
          _seasonEnd(context, game)
        else
          _nextFixture(context, game, fx),
        const SizedBox(height: 20),
        const _SectionHeading(title: 'CLUB MANAGEMENT', trailing: 'SEASON OVERVIEW'),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 9,
          crossAxisSpacing: 9,
          childAspectRatio: 1.75,
          children: [
            _InfoTile(icon: Icons.groups_rounded, title: 'First team', value: '${squad.length} players', accent: AppTheme.green),
            _InfoTile(icon: Icons.account_balance_wallet_rounded, title: 'Wage bill', value: fmtMoney(c.wageBill(c.userClubId)), accent: AppTheme.gold),
            _InfoTile(icon: Icons.swap_horiz_rounded, title: 'Transfer funds', value: fmtMoney(club.transferBudget), accent: AppTheme.green),
            _InfoTile(icon: Icons.flag_rounded, title: 'Board target', value: 'Top ${c.objective}', subtitle: 'Trust ${c.boardConfidence}%', accent: AppTheme.gold),
          ],
        ),
        const SizedBox(height: 21),
        _SectionHeading(title: 'LEAGUE POSITION', trailing: '${rows.length} CLUBS'),
        const SizedBox(height: 9),
        Card(
          child: Column(children: [
            for (var i = 0; i < rows.take(5).length; i++)
              _LeagueLine(
                rank: i + 1,
                name: c.clubs[rows[i].clubId]?.name ?? 'Club',
                points: rows[i].points.toString(),
                isUser: rows[i].clubId == c.userClubId,
                isLast: i == rows.take(5).length - 1,
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
              child: Row(children: [
                const Icon(Icons.info_outline, size: 14, color: Colors.white38),
                const SizedBox(width: 7),
                Expanded(child: Text('Your current position: ${c.userPosition}${_ord(c.userPosition)}', style: const TextStyle(color: Colors.white54, fontSize: 11))),
              ]),
            ),
          ]),
        ),
        if (injured + suspended + expiring > 0) ...[
          const SizedBox(height: 20),
          const _SectionHeading(title: 'SQUAD ALERTS', trailing: 'ACTION REQUIRED'),
          const SizedBox(height: 9),
          Card(child: Padding(
            padding: const EdgeInsets.all(13),
            child: Column(children: [
              if (injured > 0) _AlertLine(icon: Icons.healing, text: '$injured player(s) injured'),
              if (suspended > 0) _AlertLine(icon: Icons.do_not_disturb_alt, text: '$suspended player(s) suspended'),
              if (expiring > 0) _AlertLine(icon: Icons.assignment_late_outlined, text: '$expiring contract(s) expiring soon'),
            ]),
          )),
        ],
        const SizedBox(height: 20),
        _SectionHeading(title: 'CLUB NEWS', trailing: 'INBOX'),
        const SizedBox(height: 9),
        Card(child: Column(children: [
          if (c.news.isEmpty)
            const Padding(padding: EdgeInsets.all(18), child: Text('No new messages from the club.', style: TextStyle(color: Colors.white54)))
          else
            for (final n in c.news.take(5))
              ListTile(
                dense: true,
                leading: const CircleAvatar(radius: 15, backgroundColor: AppTheme.panelLight, child: Icon(Icons.article_outlined, size: 15, color: AppTheme.green)),
                title: Text(n.text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                subtitle: Text('MATCHDAY ${n.matchday}', style: const TextStyle(fontSize: 9, color: Colors.white38, letterSpacing: 1)),
              ),
        ])),
        const SizedBox(height: 16),
        const Center(child: Text('FOOTBALL DYNASTY  •  OFFLINE CAREER', style: TextStyle(color: Colors.white30, fontSize: 9, letterSpacing: 1.2))),
      ],
    );
  }

  Widget _nextFixture(BuildContext context, GameController game, Fixture? fx) {
    final c = game.career!;
    if (fx == null) return const SizedBox.shrink();
    final home = c.clubs[fx.homeId]!;
    final away = c.clubs[fx.awayId]!;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF1A3440), Color(0xFF101B2A)]),
        border: Border.all(color: Colors.white.withOpacity(.08)),
      ),
      padding: const EdgeInsets.fromLTRB(14, 15, 14, 13),
      child: Column(children: [
        const Row(children: [
          Icon(Icons.calendar_today_rounded, size: 13, color: AppTheme.green),
          SizedBox(width: 7),
          Text('UPCOMING FIXTURE', style: TextStyle(fontSize: 10, color: AppTheme.green, fontWeight: FontWeight.w900, letterSpacing: 1.3)),
          Spacer(),
          Text('LEAGUE', style: TextStyle(fontSize: 9, color: Colors.white54, letterSpacing: 1)),
        ]),
        const SizedBox(height: 18),
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _MatchTeam(name: home.name, shortName: home.shortName, colour: home.colorValue),
          const Column(children: [
            Text('VS', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900, color: Colors.white)),
            SizedBox(height: 3),
            Text('90 MIN', style: TextStyle(fontSize: 8, color: Colors.white38, letterSpacing: 1)),
          ]),
          _MatchTeam(name: away.name, shortName: away.shortName, colour: away.colorValue),
        ]),
        const SizedBox(height: 12),
        Text(fx.homeId == c.userClubId ? 'HOME MATCH' : 'AWAY MATCH', style: const TextStyle(fontSize: 9, color: Colors.white54, letterSpacing: 1.4)),
        const SizedBox(height: 14),
        SizedBox(width: double.infinity, height: 46, child: FilledButton.icon(
          onPressed: () {
            final result = game.playMatchday();
            if (result != null) {
              Navigator.push(context, MaterialPageRoute(builder: (_) => MatchScreen(result: result)));
            }
          },
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text('KICK OFF', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2)),
        )),
        TextButton(
          onPressed: () async {
            final ok = await confirm(context, 'Simulate season?', 'Plays every remaining matchday using your current tactics and lineup.', action: 'Simulate');
            if (ok) game.simulateSeason();
          },
          child: const Text('Simulate remaining season', style: TextStyle(fontSize: 11)),
        ),
      ]),
    );
  }

  Widget _seasonEnd(BuildContext context, GameController game) {
    final c = game.career!;
    final pos = c.userPosition;
    final champ = c.clubs[c.table.first.clubId]!;
    return Card(child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('FULL TIME — SEASON COMPLETE', style: TextStyle(color: AppTheme.green, fontSize: 10, letterSpacing: 1.3, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Text('Season ${c.seasonLabel}', style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
        Text('Champions: ${champ.name}', style: const TextStyle(color: AppTheme.gold)),
        Text('You finished ${pos}${_ord(pos)} (target: top ${c.objective}).'),
        const SizedBox(height: 14),
        SizedBox(width: double.infinity, child: FilledButton(
          onPressed: () async {
            final ok = await confirm(context, 'Start next season?', 'Players age and develop, contracts expire and retirements happen.', action: 'Continue');
            if (!ok) return;
            final r = game.startNextSeason();
            if (context.mounted) toast(context, r.message);
          },
          child: const Text('START NEXT SEASON'),
        )),
      ]),
    ));
  }

  static String _ord(int n) {
    if (n % 100 >= 11 && n % 100 <= 13) return 'th';
    switch (n % 10) { case 1: return 'st'; case 2: return 'nd'; case 3: return 'rd'; default: return 'th'; }
  }

  void _menu(BuildContext context, GameController game) {
    showModalBottomSheet(context: context, builder: (ctx) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
      ListTile(
        leading: const Icon(Icons.save_outlined),
        title: const Text('Save & return to menu'),
        subtitle: const Text('Progress is also saved automatically.'),
        onTap: () async { Navigator.pop(ctx); await game.exitToMenu(); },
      ),
    ])));
  }
}

class _ClubHero extends StatelessWidget {
  final String clubName, shortName, manager, season, position, points, balance;
  final int colour, matchday, totalMatchdays;
  const _ClubHero({required this.clubName, required this.shortName, required this.colour, required this.manager, required this.season, required this.position, required this.points, required this.balance, required this.matchday, required this.totalMatchdays});

  @override
  Widget build(BuildContext context) {
    final progress = totalMatchdays <= 0 ? 0.0 : (matchday / totalMatchdays).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF24485A), Color(0xFF142437), Color(0xFF101A29)]),
        border: Border.all(color: Colors.white.withOpacity(.09)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(.22), blurRadius: 18, offset: const Offset(0, 9))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          ClubCrest(shortName, colour, radius: 29),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(clubName.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, letterSpacing: .3)),
            Text('MANAGER  •  $manager', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: Colors.white60)),
          ])),
          Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6), decoration: BoxDecoration(color: AppTheme.green.withOpacity(.14), borderRadius: BorderRadius.circular(8)), child: Text('SEASON $season', style: const TextStyle(color: AppTheme.green, fontSize: 9, fontWeight: FontWeight.w900))),
        ]),
        const SizedBox(height: 18),
        Row(children: [
          _HeroStat(label: 'LEAGUE POS.', value: position),
          _HeroStat(label: 'POINTS', value: points),
          _HeroStat(label: 'CLUB BALANCE', value: balance),
        ]),
        const SizedBox(height: 15),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('SEASON PROGRESS', style: TextStyle(fontSize: 8, color: Colors.white54, letterSpacing: 1.2, fontWeight: FontWeight.bold)),
          Text('$matchday / $totalMatchdays MATCHDAYS', style: const TextStyle(fontSize: 8, color: Colors.white70, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 7),
        ClipRRect(borderRadius: BorderRadius.circular(10), child: LinearProgressIndicator(value: progress, minHeight: 5, backgroundColor: Colors.white12, valueColor: const AlwaysStoppedAnimation(AppTheme.green))),
      ]),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final String label, value;
  const _HeroStat({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: const TextStyle(fontSize: 8, color: Colors.white54, letterSpacing: .8)),
    const SizedBox(height: 4),
    Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
  ]));
}

class _SectionHeading extends StatelessWidget {
  final String title, trailing;
  const _SectionHeading({required this.title, required this.trailing});
  @override
  Widget build(BuildContext context) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
    Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
    Text(trailing, style: const TextStyle(fontSize: 8, color: Colors.white38, letterSpacing: .8)),
  ]);
}

class _MatchTeam extends StatelessWidget {
  final String name, shortName;
  final int colour;
  const _MatchTeam({required this.name, required this.shortName, required this.colour});
  @override
  Widget build(BuildContext context) => SizedBox(width: 105, child: Column(children: [
    ClubCrest(shortName, colour, radius: 27),
    const SizedBox(height: 8),
    Text(name, maxLines: 2, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
  ]));
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title, value;
  final String? subtitle;
  final Color accent;
  const _InfoTile({required this.icon, required this.title, required this.value, required this.accent, this.subtitle});
  @override
  Widget build(BuildContext context) => Card(child: Padding(
    padding: const EdgeInsets.all(12),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, color: accent, size: 18),
      const SizedBox(height: 6),
      Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900)),
      Text(subtitle ?? title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 9, color: Colors.white54)),
    ]),
  ));
}

class _LeagueLine extends StatelessWidget {
  final int rank;
  final String name, points;
  final bool isUser, isLast;
  const _LeagueLine({required this.rank, required this.name, required this.points, required this.isUser, required this.isLast});
  @override
  Widget build(BuildContext context) => Container(
    color: isUser ? AppTheme.green.withOpacity(.09) : Colors.transparent,
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
    child: Row(children: [
      SizedBox(width: 25, child: Text(rank.toString().padLeft(2, '0'), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: isUser ? AppTheme.green : Colors.white54))),
      Expanded(child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, fontWeight: isUser ? FontWeight.w900 : FontWeight.w600))),
      Text(points, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: isUser ? AppTheme.green : Colors.white)),
      const SizedBox(width: 5),
      const Text('PTS', style: TextStyle(fontSize: 8, color: Colors.white38)),
    ]),
  );
}

class _AlertLine extends StatelessWidget {
  final IconData icon;
  final String text;
  const _AlertLine({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Row(children: [
    Icon(icon, color: AppTheme.gold, size: 16),
    const SizedBox(width: 9),
    Expanded(child: Text(text, style: const TextStyle(fontSize: 11))),
  ]));
}
