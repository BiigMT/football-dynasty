import 'dart:async';
import 'package:flutter/material.dart';
import '../domain/career.dart';
import '../domain/models.dart';
import '../state/game_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class MatchScreen extends StatefulWidget {
  final MatchResult result;
  const MatchScreen({super.key, required this.result});
  @override
  State<MatchScreen> createState() => _MatchScreenState();
}
class _MatchScreenState extends State<MatchScreen> {
  Timer? timer;
  int shown = 0;
  bool fast = false;
  List<MatchEvent> get events => widget.result.events;
  bool get finished => shown >= events.length;
  @override
  void initState() { super.initState(); _tick(); }
  void _tick() {
    timer?.cancel();
    timer = Timer.periodic(Duration(milliseconds: fast ? 180 : 800), (_) {
      if (!mounted) return;
      if (finished) { timer?.cancel(); return; }
      setState(() => shown++);
    });
  }
  @override
  void dispose() { timer?.cancel(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final c = GameScope.of(context).career!;
    final r = widget.result;
    final home = c.clubs[r.homeId]!;
    final away = c.clubs[r.awayId]!;
    final visible = events.take(shown).toList();
    var hg = 0, ag = 0;
    for (final e in visible) {
      if (e.type == EventType.goal) {
        if (e.clubId == r.homeId) { hg++; } else { ag++; }
      }
    }
    final minute = visible.isEmpty ? 0 : visible.last.minute;
    return Scaffold(
      appBar: AppBar(title: const Text('MATCH CENTRE'), actions: [
        if (!finished) IconButton(onPressed: () { setState(() => fast = !fast); _tick(); }, icon: Icon(fast ? Icons.speed : Icons.fast_forward)),
        if (!finished) IconButton(onPressed: () { timer?.cancel(); setState(() => shown = events.length); }, icon: const Icon(Icons.skip_next)),
      ]),
      body: Column(children: [
        Container(padding: const EdgeInsets.all(14), decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFF19364A), Color(0xFF0B1725)], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
          child: Column(children: [
            Text(finished ? 'FULL TIME' : minute == 0 ? 'PRE-MATCH' : 'LEAGUE · LIVE',
              style: const TextStyle(color: AppTheme.green, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2)),
            const SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              _Team(club: home),
              Column(children: [Text('$hg - $ag', style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900)), Text(finished ? '90 MIN' : '$minute MIN', style: const TextStyle(color: Colors.white54, fontSize: 9))]),
              _Team(club: away),
            ]),
          ]),
        ),
        Padding(padding: const EdgeInsets.all(12), child: AspectRatio(aspectRatio: 1.5,
          child: ClipRRect(borderRadius: BorderRadius.circular(14), child: CustomPaint(
            painter: _PitchPainter(),
            child: Stack(children: [
              for (var i = 0; i < r.homeXI.length && i < 11; i++) _PlayerDot(index: i, home: true),
              for (var i = 0; i < r.awayXI.length && i < 11; i++) _PlayerDot(index: i, home: false),
              if (visible.isNotEmpty && visible.last.type == EventType.goal)
                const Align(alignment: Alignment.bottomCenter, child: Padding(padding: EdgeInsets.all(8), child: Text('⚽ GOAL!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)))),
            ]),
          )),
        )),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Row(children: [
          const Icon(Icons.sensors, color: AppTheme.green, size: 15), const SizedBox(width: 7),
          Expanded(child: Text(visible.isEmpty ? 'Teams are preparing for kick-off' : visible.last.detail, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: Colors.white70))),
          Text('$minute’', style: const TextStyle(color: AppTheme.green, fontWeight: FontWeight.w900)),
        ])),
        Expanded(child: ListView(padding: const EdgeInsets.all(14), children: [
          const Text('MATCH TIMELINE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
          const SizedBox(height: 8),
          for (final e in visible.reversed) _EventTile(event: e, career: c),
          if (finished) ...[
            const SizedBox(height: 12),
            const Text('MATCH STATISTICS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
            _Stats(result: r),
          ],
        ])),
        if (finished) Padding(padding: const EdgeInsets.all(14), child: SizedBox(width: double.infinity, child: FilledButton(onPressed: () => Navigator.pop(context), child: const Text('CONTINUE')))),
      ]),
    );
  }
}
class _Team extends StatelessWidget {
  final Club club;
  const _Team({required this.club});
  @override
  Widget build(BuildContext context) => SizedBox(width: 100, child: Column(children: [
    ClubCrest(club.shortName, club.colorValue, radius: 25), const SizedBox(height: 6),
    Text(club.name, maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
  ]));
}
class _PlayerDot extends StatelessWidget {
  final int index; final bool home;
  const _PlayerDot({required this.index, required this.home});
  @override
  Widget build(BuildContext context) {
    final row = index == 0 ? 0 : index <= 4 ? 1 : index <= 7 ? 2 : 3;
    final start = row == 0 ? 0 : row == 1 ? 1 : row == 2 ? 5 : 8;
    final count = row == 0 ? 1 : row == 1 ? 4 : 3;
    final x = count == 1 ? .5 : .12 + .76 * (index - start) / (count - 1);
    final y = row / 3;
    final left = home ? x : 1 - x;
    final top = home ? .13 + y * .70 : .13 + (1 - y) * .70;
    return Positioned(left: MediaQuery.of(context).size.width * .70 * left - 10,
      top: 12 + MediaQuery.of(context).size.width * .70 * top * .38,
      child: Container(width: 21, height: 21, decoration: BoxDecoration(
        color: home ? AppTheme.green : AppTheme.gold, shape: BoxShape.circle, border: Border.all(color: Colors.white)),
        alignment: Alignment.center, child: Text((index + 1).toString(), style: const TextStyle(color: Color(0xFF08111D), fontSize: 8, fontWeight: FontWeight.w900))));
  }
}
class _PitchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..shader = const LinearGradient(colors: [Color(0xFF17613F), Color(0xFF0F5035), Color(0xFF17613F)]).createShader(rect));
    final stripe = Paint()..color = Colors.white.withOpacity(.035);
    for (var i = 0; i < 8; i++) { if (i.isEven) canvas.drawRect(Rect.fromLTWH(i * size.width / 8, 0, size.width / 8, size.height), stripe); }
    final p = Paint()..color = Colors.white.withOpacity(.75)..style = PaintingStyle.stroke..strokeWidth = 1.1;
    const pad = 9.0;
    canvas.drawRect(Rect.fromLTWH(pad, pad, size.width - 2 * pad, size.height - 2 * pad), p);
    canvas.drawLine(Offset(size.width / 2, pad), Offset(size.width / 2, size.height - pad), p);
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), size.height * .13, p);
    canvas.drawRect(Rect.fromLTWH(pad, size.height * .25, size.width * .16, size.height * .5), p);
    canvas.drawRect(Rect.fromLTWH(size.width - pad - size.width * .16, size.height * .25, size.width * .16, size.height * .5), p);
    canvas.drawRect(Rect.fromLTWH(pad, size.height * .37, size.width * .06, size.height * .26), p);
    canvas.drawRect(Rect.fromLTWH(size.width - pad - size.width * .06, size.height * .37, size.width * .06, size.height * .26), p);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
class _EventTile extends StatelessWidget {
  final MatchEvent event; final Career career;
  const _EventTile({required this.event, required this.career});
  @override
  Widget build(BuildContext context) {
    IconData icon = Icons.sports; Color color = Colors.white60;
    switch (event.type) {
      case EventType.goal: icon = Icons.sports_soccer; color = AppTheme.green; break;
      case EventType.yellow: icon = Icons.square; color = AppTheme.gold; break;
      case EventType.red: icon = Icons.square; color = Colors.redAccent; break;
      case EventType.injury: icon = Icons.healing; color = Colors.orangeAccent; break;
      case EventType.save: icon = Icons.back_hand_outlined; break;
      case EventType.shotOff: icon = Icons.call_made; break;
      case EventType.halftime: icon = Icons.pause_circle_outline; color = AppTheme.gold; break;
      case EventType.fulltime: icon = Icons.flag; color = AppTheme.green; break;
      default: icon = Icons.sports;
    }
    final text = event.playerName == null ? event.detail : event.playerName! + ' ' + event.detail;
    final club = event.clubId == null ? '' : ' · ' + (career.clubs[event.clubId]?.shortName ?? '');
    return Card(child: ListTile(dense: true, leading: SizedBox(width: 48, child: Row(children: [
      Text(event.minuteLabel, style: const TextStyle(color: Colors.white54, fontSize: 11)), const Spacer(), Icon(icon, color: color, size: 17),
    ])), title: Text(text + club, style: TextStyle(fontSize: 11, fontWeight: event.type == EventType.goal ? FontWeight.w900 : FontWeight.w500))));
  }
}
class _Stats extends StatelessWidget {
  final MatchResult result;
  const _Stats({required this.result});
  @override
  Widget build(BuildContext context) {
    final s = result.stats;
    Widget row(String label, int h, int a) => Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Row(children: [
      SizedBox(width: 30, child: Text('$h', style: const TextStyle(fontWeight: FontWeight.w900))),
      Expanded(child: Text(label, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white60, fontSize: 10))),
      SizedBox(width: 30, child: Text('$a', textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w900))),
    ]));
    return Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(children: [
      row('Possession %', s.homePossession, 100 - s.homePossession),
      row('Shots', s.homeShots, s.awayShots), row('On target', s.homeOnTarget, s.awayOnTarget),
      row('Yellow cards', s.homeYellows, s.awayYellows), row('Red cards', s.homeReds, s.awayReds),
    ])));
  }
}
