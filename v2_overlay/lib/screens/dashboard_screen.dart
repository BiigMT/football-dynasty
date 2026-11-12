import 'package:flutter/material.dart';
import '../domain/models.dart';
import '../state/game_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'match_screen.dart';
import 'squad_screen.dart';
import 'transfers_screen.dart';
import 'tactics_screen.dart';
import 'competitions_screen.dart';
import 'national_team_screen.dart';

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
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF101D2B), Color(0xFF080E17), Color(0xFF070B12)],
        ),
      ),
      child: ListView(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 28),
      children: [
        Row(children: [
          Container(width: 42, height: 42, decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF00E5FF), Color(0xFF007FAD)]),
            borderRadius: BorderRadius.circular(13)),
            child: const Icon(Icons.sports_soccer, color: Color(0xFF06131D), size: 25)),
          const SizedBox(width: 10),
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('FOOTBALL DYNASTY', style: TextStyle(fontSize: 11, letterSpacing: 2, color: AppTheme.green, fontWeight: FontWeight.w900)),
            Text('MANAGER CAREER', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: .4)),
          ])),
          IconButton(onPressed: () => _menu(context, game), icon: const Icon(Icons.settings_outlined, color: Colors.white70)),
        ]),
        const SizedBox(height: 12),
        _CalendarStrip(matchday: c.matchday, complete: c.seasonComplete),
        const SizedBox(height: 14),
        _ClubHero(clubName: club.name, shortName: club.shortName, colour: club.colorValue,
          manager: c.managerName, season: c.seasonLabel.toString(),
          position: c.userPosition.toString(), points: myRow.points.toString(),
          balance: fmtMoney(club.balance), matchday: c.matchday, totalMatchdays: c.totalMatchdays),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: _BudgetChip(icon: Icons.swap_horiz, label: 'TRANSFER BUDGET', value: fmtMoney(club.transferBudget))),
          const SizedBox(width: 8),
          Expanded(child: _BudgetChip(icon: Icons.payments_outlined, label: 'WAGE BUDGET', value: fmtMoney(club.wageBudget))),
        ]),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            boxShadow: [BoxShadow(color: AppTheme.green.withOpacity(.18), blurRadius: 22, offset: const Offset(0, 5))],
          ),
          child: SizedBox(
            width: double.infinity,
            height: 54,
            child: FilledButton.icon(
              onPressed: c.seasonComplete ? null : () {
                final result = game.playMatchday();
                if (result != null) {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => MatchScreen(result: result)));
                }
              },
              icon: const Icon(Icons.fast_forward_rounded, size: 22),
              label: const Text('FORWARD TIME', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.1)),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.green,
                foregroundColor: const Color(0xFF04131B),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        const _SectionHeading(title: 'MANAGER HUB', trailing: 'CAREER CONTROL'),
        const SizedBox(height: 9),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 9,
          mainAxisSpacing: 9,
          childAspectRatio: 1.48,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _ActionTile(icon: Icons.groups_rounded, title: 'SQUAD', subtitle: 'Players, roles & fitness', onTap: () => _open(context, const SquadScreen())),
            _ActionTile(icon: Icons.tune_rounded, title: 'TACTICS', subtitle: 'Shape & match approach', onTap: () => _open(context, const TacticsScreen())),
            _ActionTile(icon: Icons.storefront_rounded, title: 'TRANSFERS', subtitle: 'Scout, sign & sell players', onTap: () => _open(context, const TransfersScreen())),
            _ActionTile(icon: Icons.business_center_rounded, title: 'MANAGER OFFICE', subtitle: 'Board, money & objectives', onTap: () => _office(context, game)),
            _ActionTile(icon: Icons.emoji_events_rounded, title: 'SEASON', subtitle: 'Table & competitions', onTap: () => _open(context, const CompetitionsScreen())),
            _ActionTile(icon: Icons.flag_rounded, title: 'NATIONAL TEAM', subtitle: 'Call-ups & selection', onTap: () => _open(context, const NationalTeamScreen())),
          ],
        ),
        const SizedBox(height: 19),
        _SectionHeading(title: 'MATCH CENTRE', trailing: 'NEXT EVENT'),
        const SizedBox(height: 9),
        if (c.seasonComplete) _seasonEnd(context, game) else _nextFixture(context, game, fx),
        const SizedBox(height: 20),
        _SectionHeading(title: 'BREAKING CLUB NEWS', trailing: 'LATEST UPDATES'),
        const SizedBox(height: 9),
        _FeaturedNews(news: c.news.isEmpty ? null : c.news.first.text,
          matchday: c.news.isEmpty ? c.matchday : c.news.first.matchday),
        const SizedBox(height: 18),
        _SectionHeading(title: 'FAN ZONE', trailing: 'SOCIAL FEED'),
        const SizedBox(height: 9),
        const _SocialFeed(),
        const SizedBox(height: 18),
        _SectionHeading(title: 'LEAGUE TABLE', trailing: '${rows.length} CLUBS'),
        const SizedBox(height: 9),
        Card(child: Column(children: [
          const Padding(padding: EdgeInsets.fromLTRB(14, 12, 14, 8), child: Row(children: [
            Expanded(child: Text('CLUB', style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.w900))),
            Text('P', style: TextStyle(color: Colors.white54, fontSize: 9)),
            SizedBox(width: 24),
            Text('PTS', style: TextStyle(color: Colors.white54, fontSize: 9)),
          ])),
          for (var i = 0; i < rows.take(7).length; i++)
            _LeagueLine(rank: i + 1, name: c.clubs[rows[i].clubId]?.name ?? 'Club',
              points: rows[i].points.toString(), isUser: rows[i].clubId == c.userClubId, isLast: i == rows.take(7).length - 1),
          Padding(padding: const EdgeInsets.all(12), child: Row(children: [
            const Icon(Icons.info_outline, size: 14, color: Colors.white38),
            const SizedBox(width: 7),
            Expanded(child: Text('You are currently ${c.userPosition}${_ord(c.userPosition)} in the table.',
              style: const TextStyle(color: Colors.white54, fontSize: 10))),
          ])),
        ])),
        if (injured + suspended + expiring > 0) ...[
          const SizedBox(height: 18),
          const _SectionHeading(title: 'SQUAD ALERTS', trailing: 'ACTION REQUIRED'),
          const SizedBox(height: 8),
          Card(child: Padding(padding: const EdgeInsets.all(13), child: Column(children: [
            if (injured > 0) _AlertLine(icon: Icons.healing, text: '$injured player(s) injured'),
            if (suspended > 0) _AlertLine(icon: Icons.do_not_disturb_alt, text: '$suspended player(s) suspended'),
            if (expiring > 0) _AlertLine(icon: Icons.assignment_late_outlined, text: '$expiring contract(s) expiring soon'),
          ]))),
        ],
        const SizedBox(height: 18),
        const Center(child: Text('FOOTBALL DYNASTY  •  BUILD YOUR LEGACY',
          style: TextStyle(color: Colors.white30, fontSize: 9, letterSpacing: 1.2))),
      ],
    ));
  }

  void _open(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  void _office(BuildContext context, GameController game) {
    final c = game.career!;
    showModalBottomSheet(context: context, backgroundColor: const Color(0xFF101C2B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(child: Padding(padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('MANAGER OFFICE', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1)),
          const SizedBox(height: 14),
          _OfficeLine(label: 'BOARD OBJECTIVE', value: 'Finish in the top ${c.objective}'),
          _OfficeLine(label: 'BOARD CONFIDENCE', value: '${c.boardConfidence}%'),
          _OfficeLine(label: 'CLUB BALANCE', value: fmtMoney(c.userClub.balance)),
          _OfficeLine(label: 'WAGE BILL', value: fmtMoney(c.wageBill(c.userClubId))),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: OutlinedButton.icon(
            onPressed: () async { Navigator.pop(ctx); await game.exitToMenu(); },
            icon: const Icon(Icons.logout), label: const Text('SAVE & RETURN TO MENU'))),
        ]))));
  }

  Widget _nextFixture(BuildContext context, GameController game, Fixture? fx) {
    final c = game.career!;
    if (fx == null) return const SizedBox.shrink();
    final home = c.clubs[fx.homeId]!;
    final away = c.clubs[fx.awayId]!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF123B50), Color(0xFF101A29), Color(0xFF0B111B)]),
        border: Border.all(color: AppTheme.green.withOpacity(.25)),
        boxShadow: [BoxShadow(color: AppTheme.green.withOpacity(.06), blurRadius: 24)]),
      child: Column(children: [
        const Row(children: [Icon(Icons.stadium_outlined, size: 15, color: AppTheme.green),
          SizedBox(width: 7), Text('UPCOMING FIXTURE', style: TextStyle(fontSize: 10, color: AppTheme.green, fontWeight: FontWeight.w900, letterSpacing: 1.3)),
          Spacer(), Text('LEAGUE', style: TextStyle(fontSize: 9, color: Colors.white54))]),
        const SizedBox(height: 18),
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _MatchTeam(name: home.name, shortName: home.shortName, colour: home.colorValue),
          const Text('VS', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppTheme.green)),
          _MatchTeam(name: away.name, shortName: away.shortName, colour: away.colorValue),
        ]),
        const SizedBox(height: 10),
        Text(fx.homeId == c.userClubId ? 'HOME MATCH' : 'AWAY MATCH',
          style: const TextStyle(fontSize: 9, color: Colors.white54, letterSpacing: 1.5)),
        const SizedBox(height: 14),
        SizedBox(width: double.infinity, height: 48, child: FilledButton.icon(
          onPressed: () { final result = game.playMatchday(); if (result != null) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => MatchScreen(result: result))); } },
          icon: const Icon(Icons.play_arrow_rounded), label: const Text('KICK OFF', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.3)))),
        TextButton(onPressed: () async {
          final ok = await confirm(context, 'Simulate season?', 'Plays every remaining matchday using your current tactics and lineup.', action: 'Simulate');
          if (ok) game.simulateSeason();
        }, child: const Text('Simulate remaining season', style: TextStyle(fontSize: 11))),
      ]),
    );
  }

  Widget _seasonEnd(BuildContext context, GameController game) {
    final c = game.career!;
    final champ = c.clubs[c.table.first.clubId]!;
    return Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('FULL TIME — SEASON COMPLETE', style: TextStyle(color: AppTheme.green, fontSize: 10, letterSpacing: 1.3, fontWeight: FontWeight.w900)),
      const SizedBox(height: 8), Text('Season ${c.seasonLabel}', style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
      Text('Champions: ${champ.name}', style: const TextStyle(color: AppTheme.gold)),
      Text('You finished ${c.userPosition}${_ord(c.userPosition)} (target: top ${c.objective}).'),
      const SizedBox(height: 14), SizedBox(width: double.infinity, child: FilledButton(
        onPressed: () async { final ok = await confirm(context, 'Start next season?', 'Players age and develop, contracts expire and retirements happen.', action: 'Continue');
          if (!ok) return; final r = game.startNextSeason(); if (context.mounted) toast(context, r.message); },
        child: const Text('START NEXT SEASON'))),
    ])));
  }

  static String _ord(int n) {
    if (n % 100 >= 11 && n % 100 <= 13) return 'th';
    switch (n % 10) { case 1: return 'st'; case 2: return 'nd'; case 3: return 'rd'; default: return 'th'; }
  }

  void _menu(BuildContext context, GameController game) => _office(context, game);
}

class _CalendarStrip extends StatelessWidget {
  final int matchday; final bool complete;
  const _CalendarStrip({required this.matchday, required this.complete});
  @override Widget build(BuildContext context) {
    final days = [
      ('PREP', Icons.bedtime_outlined), ('TRAIN', Icons.fitness_center),
      ('MATCH', Icons.sports_soccer), ('RECOVER', Icons.healing),
    ];
    return Container(padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
      decoration: BoxDecoration(color: const Color(0xCC101B29), borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(.08))),
      child: Row(children: [
        for (var i = 0; i < days.length; i++) Expanded(child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 3), padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
          decoration: BoxDecoration(color: i == 2 && !complete ? AppTheme.green.withOpacity(.14) : Colors.transparent,
            borderRadius: BorderRadius.circular(11), border: i == 2 && !complete ? Border.all(color: AppTheme.green.withOpacity(.5)) : null),
          child: Column(children: [
            Text(i == 2 ? 'ROUND ${matchday.toString().padLeft(2, '0')}' : ['PREP','TRAIN','MATCH','REST'][i],
              style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: i == 2 ? AppTheme.green : Colors.white54)),
            const SizedBox(height: 6), Icon(days[i].$2, size: 18, color: i == 2 ? AppTheme.green : Colors.white70),
            const SizedBox(height: 4), Text(days[i].$1, style: const TextStyle(fontSize: 7, color: Colors.white38, letterSpacing: .6)),
          ]),
        )),
      ]),
    );
  }
}

class _BudgetChip extends StatelessWidget {
  final IconData icon; final String label, value;
  const _BudgetChip({required this.icon, required this.label, required this.value});
  @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: const Color(0xCC111E2D), borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Colors.white.withOpacity(.08))),
    child: Row(children: [Icon(icon, color: AppTheme.green, size: 17), const SizedBox(width: 8),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 7, color: Colors.white54, letterSpacing: .6)),
        const SizedBox(height: 3), Text(value, maxLines: 1, overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
      ]))]));
}

class _ActionTile extends StatelessWidget {
  final IconData icon; final String title, subtitle; final VoidCallback onTap;
  const _ActionTile({required this.icon, required this.title, required this.subtitle, required this.onTap});
  @override Widget build(BuildContext context) => Material(
    color: const Color(0xCC111E2D),
    borderRadius: BorderRadius.circular(17),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(17),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: Colors.white.withOpacity(.08)),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF172A40), Color(0xFF0E1928)],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 35,
                  height: 35,
                  decoration: BoxDecoration(
                    color: AppTheme.green.withOpacity(.13),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(icon, color: AppTheme.green, size: 19),
                ),
                const Icon(Icons.arrow_outward_rounded, color: Colors.white38, size: 15),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: .45)),
                const SizedBox(height: 4),
                Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 8, color: Colors.white54)),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _FeaturedNews extends StatelessWidget {
  final String? news; final int matchday;
  const _FeaturedNews({required this.news, required this.matchday});
  @override Widget build(BuildContext context) => Container(
    height: 174, padding: const EdgeInsets.all(17),
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(20),
      gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors: [Color(0xFF07506A), Color(0xFF102237), Color(0xFF111827)]),
      border: Border.all(color: AppTheme.green.withOpacity(.25))),
    child: Stack(children: [
      const Positioned(right: 4, bottom: -12, child: Icon(Icons.sports_soccer, size: 112, color: Color(0x2238DDF2))),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [Icon(Icons.bolt, color: AppTheme.green, size: 16),
          Text('  BREAKING CLUB NEWS', style: TextStyle(color: AppTheme.green, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.2))]),
        const Spacer(),
        Text(news ?? 'The next chapter starts now.', maxLines: 3, overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 20, height: 1.12, fontWeight: FontWeight.w900)),
        const SizedBox(height: 7),
        Text('CLUB UPDATE  •  MATCHDAY $matchday', style: const TextStyle(color: Colors.white60, fontSize: 8, letterSpacing: 1)),
      ]),
    ]),
  );
}

class _SocialFeed extends StatelessWidget {
  const _SocialFeed();
  @override Widget build(BuildContext context) => Card(child: Column(children: const [
    _FanPost(initial: 'M', name: 'Matchday Central', handle: '@matchdaycentral',
      message: 'The fans are behind the badge. Big things are expected this season.', likes: '2.4K'),
    Divider(height: 1, color: Color(0x22FFFFFF)),
    _FanPost(initial: 'F', name: 'Football Focus', handle: '@footballfocus',
      message: 'Every result matters. The race for the top spots is heating up.', likes: '1.8K'),
    Divider(height: 1, color: Color(0x22FFFFFF)),
    _FanPost(initial: 'D', name: 'Dynasty Supporters', handle: '@dynastysupport',
      message: 'One club. One dream. We go again on matchday!', likes: '986'),
  ]));
}

class _FanPost extends StatelessWidget {
  final String initial, name, handle, message, likes;
  const _FanPost({required this.initial, required this.name, required this.handle, required this.message, required this.likes});
  @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.all(13), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    CircleAvatar(radius: 17, backgroundColor: AppTheme.green.withOpacity(.18),
      child: Text(initial, style: const TextStyle(color: AppTheme.green, fontWeight: FontWeight.w900))),
    const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Flexible(child: Text(name, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900))),
        const SizedBox(width: 5), Expanded(child: Text(handle, maxLines: 1, overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 8, color: Colors.white38)))]),
      const SizedBox(height: 5), Text(message, style: const TextStyle(fontSize: 10, height: 1.35)),
      const SizedBox(height: 7), Row(children: [const Icon(Icons.favorite_border, size: 12, color: Colors.white38),
        const SizedBox(width: 4), Text(likes, style: const TextStyle(fontSize: 8, color: Colors.white38))]),
    ])),
  ]));
}

class _OfficeLine extends StatelessWidget {
  final String label, value;
  const _OfficeLine({required this.label, required this.value});
  @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(children: [Expanded(child: Text(label, style: const TextStyle(fontSize: 9, color: Colors.white54))),
      Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800))]));
}

class _ClubHero extends StatelessWidget {
  final String clubName, shortName, manager, season, position, points, balance;
  final int colour, matchday, totalMatchdays;
  const _ClubHero({required this.clubName, required this.shortName, required this.colour, required this.manager, required this.season, required this.position, required this.points, required this.balance, required this.matchday, required this.totalMatchdays});
  @override Widget build(BuildContext context) {
    final progress = totalMatchdays <= 0 ? 0.0 : (matchday / totalMatchdays).clamp(0.0, 1.0);
    return Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(22),
      gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors: [Color(0xFF16445A), Color(0xFF142437), Color(0xFF0C1522)]),
      border: Border.all(color: AppTheme.green.withOpacity(.28)),
      boxShadow: [BoxShadow(color: AppTheme.green.withOpacity(.06), blurRadius: 22, offset: const Offset(0, 8))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [ClubCrest(shortName, colour, radius: 27), const SizedBox(width: 11),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(clubName.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: .3)),
            Text('MANAGER  •  $manager', maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 9, color: Colors.white60)),
          ])),
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(color: AppTheme.green.withOpacity(.14), borderRadius: BorderRadius.circular(8)),
            child: Text('SEASON $season', style: const TextStyle(color: AppTheme.green, fontSize: 8, fontWeight: FontWeight.w900))),
        ]),
        const SizedBox(height: 16),
        Row(children: [_HeroStat(label: 'POSITION', value: position), _HeroStat(label: 'POINTS', value: points), _HeroStat(label: 'BALANCE', value: balance)]),
        const SizedBox(height: 14),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('SEASON PROGRESS', style: TextStyle(fontSize: 8, color: Colors.white54, letterSpacing: 1.1, fontWeight: FontWeight.bold)),
          Text('$matchday / $totalMatchdays MATCHDAYS', style: const TextStyle(fontSize: 8, color: Colors.white70, fontWeight: FontWeight.bold))]),
        const SizedBox(height: 7), ClipRRect(borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(value: progress, minHeight: 5, backgroundColor: Colors.white12,
            valueColor: const AlwaysStoppedAnimation(AppTheme.green))),
      ]),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final String label, value;
  const _HeroStat({required this.label, required this.value});
  @override Widget build(BuildContext context) => Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: const TextStyle(fontSize: 8, color: Colors.white54, letterSpacing: .7)),
    const SizedBox(height: 4), Text(value, maxLines: 1, overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
  ]));
}

class _SectionHeading extends StatelessWidget {
  final String title, trailing;
  const _SectionHeading({required this.title, required this.trailing});
  @override Widget build(BuildContext context) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
    Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.1)),
    Text(trailing, style: const TextStyle(fontSize: 8, color: Colors.white38, letterSpacing: .8)),
  ]);
}

class _MatchTeam extends StatelessWidget {
  final String name, shortName; final int colour;
  const _MatchTeam({required this.name, required this.shortName, required this.colour});
  @override Widget build(BuildContext context) => SizedBox(width: 105, child: Column(children: [
    ClubCrest(shortName, colour, radius: 26), const SizedBox(height: 7),
    Text(name, maxLines: 2, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800)),
  ]));
}

class _LeagueLine extends StatelessWidget {
  final int rank; final String name, points; final bool isUser, isLast;
  const _LeagueLine({required this.rank, required this.name, required this.points, required this.isUser, required this.isLast});
  @override Widget build(BuildContext context) => Container(
    color: isUser ? AppTheme.green.withOpacity(.14) : Colors.transparent,
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    child: Row(children: [
      SizedBox(width: 24, child: Text(rank.toString().padLeft(2, '0'),
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: isUser ? AppTheme.green : Colors.white54))),
      Expanded(child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 10, fontWeight: isUser ? FontWeight.w900 : FontWeight.w600))),
      const SizedBox(width: 20), const Text('—', style: TextStyle(fontSize: 10, color: Colors.white38)),
      SizedBox(width: 34, child: Text(points, textAlign: TextAlign.end,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: isUser ? AppTheme.green : Colors.white))),
    ]),
  );
}

class _AlertLine extends StatelessWidget {
  final IconData icon; final String text;
  const _AlertLine({required this.icon, required this.text});
  @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(children: [Icon(icon, color: AppTheme.gold, size: 16), const SizedBox(width: 9),
      Expanded(child: Text(text, style: const TextStyle(fontSize: 11)))]));
}
