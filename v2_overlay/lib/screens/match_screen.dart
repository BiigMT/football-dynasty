import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:ui' show FontFeature;
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
  bool halftimePaused = false;
  bool halfTimeManagerShown = false;
  List<String> activeHomeXI = [];
  List<String> activeAwayXI = [];
  String? selectedOutgoingId;
  String? selectedIncomingId;
  int substitutionsUsed = 0;
  bool teamTalkGiven = false;
  final List<String> halftimeNotes = [];
  List<MatchEvent> get events => widget.result.events;
  bool get finished => shown >= events.length;
  @override
  void initState() { super.initState(); activeHomeXI = List<String>.from(widget.result.homeXI); activeAwayXI = List<String>.from(widget.result.awayXI); _tick(); }
  void _tick() {
    timer?.cancel();
    timer = Timer.periodic(Duration(milliseconds: fast ? 180 : 800), (_) {
      if (!mounted) return;
      if (finished) { timer?.cancel(); return; }
      setState(() => shown++);
      if (shown > 0 && events[shown - 1].type == EventType.halftime) {
        timer?.cancel();
        if (mounted) { setState(() => halftimePaused = true); if (!halfTimeManagerShown) { halfTimeManagerShown = true; WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) _openHalftimeManager(); }); } }
      }
    });
  }

  void _giveTeamTalk(String talk) {
    final controller = GameScope.of(context);
    final career = controller.career!;
    final ids = widget.result.homeId == career.userClubId ? activeHomeXI : activeAwayXI;
    final boost = talk == 'Demand more' ? 2 : talk == 'Calm down' ? 3 : 4;
    controller.run((c) {
      for (final id in ids) {
        final player = c.players[id];
        if (player != null) player.morale = (player.morale + boost).clamp(0, 100).toInt();
      }
    });
    setState(() { teamTalkGiven = true; halftimeNotes.add('Team talk: ' + talk + ' — squad morale increased'); });
  }

  void _makeHalftimeSubstitution() {
    if (selectedOutgoingId == null || selectedIncomingId == null || substitutionsUsed >= 5) return;
    final controller = GameScope.of(context);
    final career = controller.career!;
    final ids = widget.result.homeId == career.userClubId ? activeHomeXI : activeAwayXI;
    final outIndex = ids.indexOf(selectedOutgoingId!);
    final incoming = career.players[selectedIncomingId!];
    if (outIndex < 0 || incoming == null || !incoming.isAvailable || ids.contains(incoming.id)) return;
    final outgoing = career.players[selectedOutgoingId!];
    setState(() {
      ids[outIndex] = incoming.id;
      substitutionsUsed++;
      halftimeNotes.add('Substitution: ' + (outgoing?.name ?? 'Player') + ' off, ' + incoming.name + ' on');
      selectedOutgoingId = null;
      selectedIncomingId = null;
    });
    controller.setTactics(career.userClub.tactics.copy()..lineup = List<String>.from(ids));
  }

  void _openHalftimeManager() {
    if (!mounted || !halftimePaused) return;
    final controller = GameScope.of(context);
    final career = controller.career!;
    final isHome = widget.result.homeId == career.userClubId;
    final activeIds = isHome ? activeHomeXI : activeAwayXI;
    final squad = career.userSquad;
    final bench = squad.where((p) => p.isAvailable && !activeIds.contains(p.id)).toList()
      ..sort((a, b) => b.rating.compareTo(a.rating));
    final activePlayers = activeIds.map((id) => career.players[id]).whereType<Player>().toList();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF101F31),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (sheetContext) => StatefulBuilder(builder: (sheetContext, refreshSheet) {
        final tactics = career.userClub.tactics;
        final currentBench = bench.where((p) => !activeIds.contains(p.id)).toList();
        return SafeArea(child: Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(sheetContext).viewInsets.bottom + 18),
          child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Center(child: Container(width: 42, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(4)))),
            const SizedBox(height: 16),
            const Text('HALF-TIME TEAM TALK', style: TextStyle(color: AppTheme.green, fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
            const SizedBox(height: 12),
            const Text('TEAM TALK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11)),
            Wrap(spacing: 8, children: [
              for (final talk in ['Encourage', 'Demand more', 'Calm down'])
                ChoiceChip(label: Text(talk), selected: teamTalkGiven && halftimeNotes.any((n) => n.contains(talk)),
                  onSelected: teamTalkGiven ? null : (_) { _giveTeamTalk(talk); refreshSheet(() {}); }),
            ]),
            const SizedBox(height: 14),
            const Text('TACTICAL ADJUSTMENTS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11)),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: _tacticDropdown<String>(label: 'Formation', value: tactics.formation, values: formations.keys.toList(),
                onChanged: (v) { if (v != null) controller.setTactics(tactics.copy()..formation = v); refreshSheet(() {}); })),
              const SizedBox(width: 8),
              Expanded(child: _tacticDropdown<int>(label: 'Mentality', value: tactics.mentality, values: const [0, 1, 2], labels: mentalityLabels,
                onChanged: (v) { if (v != null) controller.setTactics(tactics.copy()..mentality = v); refreshSheet(() {}); })),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: _tacticDropdown<int>(label: 'Pressing', value: tactics.pressing, values: const [0, 1, 2], labels: pressingLabels,
                onChanged: (v) { if (v != null) controller.setTactics(tactics.copy()..pressing = v); refreshSheet(() {}); })),
              const SizedBox(width: 8),
              Expanded(child: _tacticDropdown<int>(label: 'Tempo', value: tactics.tempo, values: const [0, 1, 2], labels: tempoLabels,
                onChanged: (v) { if (v != null) controller.setTactics(tactics.copy()..tempo = v); refreshSheet(() {}); })),
            ]),
            const SizedBox(height: 14),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('SUBSTITUTIONS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11)),
              Text(substitutionsUsed.toString() + ' / 5 used', style: const TextStyle(color: AppTheme.green, fontSize: 10, fontWeight: FontWeight.w800)),
            ]),
            const SizedBox(height: 8),
            _tacticDropdown<String>(label: 'Player coming off', value: selectedOutgoingId,
              values: activePlayers.map((p) => p.id).toList(), labels: activePlayers.map((p) => p.name + ' · ' + p.position).toList(),
              onChanged: (v) { setState(() => selectedOutgoingId = v); refreshSheet(() {}); }),
            const SizedBox(height: 8),
            _tacticDropdown<String>(label: 'Player coming on', value: selectedIncomingId,
              values: currentBench.map((p) => p.id).toList(), labels: currentBench.map((p) => p.name + ' · ' + p.position + ' · ' + p.rating.toString() + ' OVR').toList(),
              onChanged: (v) { setState(() => selectedIncomingId = v); refreshSheet(() {}); }),
            const SizedBox(height: 8),
            SizedBox(width: double.infinity, child: FilledButton.icon(
              onPressed: substitutionsUsed >= 5 || selectedOutgoingId == null || selectedIncomingId == null ? null : () { _makeHalftimeSubstitution(); refreshSheet(() {}); },
              icon: const Icon(Icons.swap_horiz), label: const Text('CONFIRM SUBSTITUTION'))),
            if (halftimeNotes.isNotEmpty) ...[
              const SizedBox(height: 10),
              for (final note in halftimeNotes) Padding(padding: const EdgeInsets.only(bottom: 3),
                child: Text('• ' + note, style: const TextStyle(color: Colors.white60, fontSize: 10))),
            ],
            const SizedBox(height: 10),
            const Text('Important: the current match result is already calculated before this screen opens. Team talks, tactics and lineup changes are saved to your career, but do not recalculate this match’s second-half events yet.', style: TextStyle(color: Colors.white38, fontSize: 10, height: 1.4)),
          ])),
        ));
      }),
    );
  }

  Widget _tacticDropdown<T>({required String label, required T? value, required List<T> values, List<String>? labels, required ValueChanged<T?> onChanged}) {
    final safeValue = values.contains(value) ? value : null;
    return DropdownButtonFormField<T>(
      value: safeValue, isExpanded: true,
      decoration: InputDecoration(labelText: label, labelStyle: const TextStyle(color: Colors.white54, fontSize: 10),
        filled: true, fillColor: Colors.white.withOpacity(.05), contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
      dropdownColor: const Color(0xFF203D52), style: const TextStyle(color: Colors.white, fontSize: 11),
      items: List<DropdownMenuItem<T>>.generate(values.length, (i) => DropdownMenuItem<T>(value: values[i],
        child: Text(labels != null && i < labels.length ? labels[i] : values[i].toString(), overflow: TextOverflow.ellipsis))),
      onChanged: onChanged,
    );
  }

  void _resumeSecondHalf() {
    if (!mounted) return;
    setState(() => halftimePaused = false);
    _tick();
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
    final homeAttacking = visible.isEmpty || visible.last.clubId == r.homeId;
    final ballLane = visible.isEmpty ? 0.0 : (homeAttacking ? .34 : -.34);
    final ballDepth = ((minute * 13) % 70) / 100 - .35;
    return Scaffold(
      appBar: AppBar(title: const Text('MATCH CENTRE'), actions: [
        if (!finished) IconButton(onPressed: () { setState(() => fast = !fast); _tick(); }, icon: Icon(fast ? Icons.speed : Icons.fast_forward)),
        if (!finished) IconButton(onPressed: () { timer?.cancel(); setState(() => shown = events.length); }, icon: const Icon(Icons.skip_next)),
      ]),
      body: Column(children: [
        Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [Color(0xFF203D52), Color(0xFF101F31), Color(0xFF091522)],
            ),
            border: Border(bottom: BorderSide(color: AppTheme.green.withOpacity(.25))),
            boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 16, offset: Offset(0, 5))],
          ),
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(width: 6, height: 6, decoration: BoxDecoration(
                color: finished ? AppTheme.gold : AppTheme.green, shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: (finished ? AppTheme.gold : AppTheme.green).withOpacity(.65), blurRadius: 7)],
              )),
              const SizedBox(width: 7),
              Text(finished ? 'FULL TIME' : halftimePaused ? 'HALF TIME' : minute == 0 ? 'PRE-MATCH' : minute > 45 ? 'SECOND HALF' : 'FIRST HALF',
                style: const TextStyle(color: AppTheme.green, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2)),
              const SizedBox(width: 7),
              const Text('•  FOOTBALL DYNASTY', style: TextStyle(color: Colors.white38, fontSize: 8, letterSpacing: .8)),
            ]),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, crossAxisAlignment: CrossAxisAlignment.center, children: [
              _Team(club: home),
              Column(mainAxisSize: MainAxisSize.min, children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                  child: Text('$hg  -  $ag', key: ValueKey('$hg-$ag'),
                    style: const TextStyle(fontSize: 35, height: 1, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                ),
                const SizedBox(height: 7),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(.08), borderRadius: BorderRadius.circular(20)),
                  child: Text(finished ? '90:00' : minute == 0 ? '00:00' : "$minute:00",
                    style: const TextStyle(color: AppTheme.green, fontSize: 10, fontWeight: FontWeight.w900, fontFeatures: [FontFeature.tabularFigures()])),
                ),
              ]),
              _Team(club: away),
            ]),
            const SizedBox(height: 13),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: finished ? 1 : (minute / 90).clamp(0.0, 1.0).toDouble(),
                minHeight: 4,
                backgroundColor: Colors.white.withOpacity(.12),
                valueColor: const AlwaysStoppedAnimation(AppTheme.green),
              ),
            ),
            const SizedBox(height: 5),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: const [
              Text('1ST HALF', style: TextStyle(color: Colors.white38, fontSize: 7, letterSpacing: .8)),
              Text('HALF TIME', style: TextStyle(color: Colors.white38, fontSize: 7, letterSpacing: .8)),
              Text('FULL TIME', style: TextStyle(color: Colors.white38, fontSize: 7, letterSpacing: .8)),
            ]),
          ]),
        ),
        Padding(padding: const EdgeInsets.all(12), child: AspectRatio(aspectRatio: halftimePaused ? 1.12 : 0.88,
          child: ClipRRect(borderRadius: BorderRadius.circular(14), child: CustomPaint(
            painter: _PitchPainter(),
            child: Stack(children: [
              for (var i = 0; i < activeHomeXI.length && i < 11; i++)
                _PlayerDot(index: i, home: true, minute: minute,
                  playerName: c.players[activeHomeXI[i]]?.name ?? 'Home player'),
              for (var i = 0; i < activeAwayXI.length && i < 11; i++)
                _PlayerDot(index: i, home: false, minute: minute,
                  playerName: c.players[activeAwayXI[i]]?.name ?? 'Away player'),
              AnimatedAlign(
                duration: const Duration(milliseconds: 650),
                curve: Curves.easeInOutCubic,
                alignment: Alignment(
                  ballLane + ((minute * 7) % 15) / 100 - .07,
                  ballDepth,
                ),
                child: Container(
                  width: 13, height: 13,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(colors: [Colors.white, Color(0xFFB9C5D1), Color(0xFF596777)]),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(.55), blurRadius: 7, offset: const Offset(2, 3))],
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                ),
              ),
              if (visible.isNotEmpty && visible.last.type == EventType.goal)
                const Align(alignment: Alignment.bottomCenter, child: Padding(padding: EdgeInsets.all(8), child: Text('⚽  GOAL!', style: TextStyle(color: Colors.white, fontSize: 16, letterSpacing: 2, fontWeight: FontWeight.w900, shadows: [Shadow(color: Colors.black, blurRadius: 8)])))),
              if (halftimePaused || (visible.isNotEmpty && (visible.last.type == EventType.halftime || visible.last.type == EventType.fulltime)))
                Center(child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                  decoration: BoxDecoration(color: const Color(0xE6091522), borderRadius: BorderRadius.circular(14), border: Border.all(color: AppTheme.green.withOpacity(.6))),
                  child: Text(halftimePaused || visible.last.type == EventType.halftime ? 'HALF TIME' : 'FULL TIME',
                    style: const TextStyle(color: AppTheme.green, fontSize: 17, letterSpacing: 2, fontWeight: FontWeight.w900)),
                )),
            ]),
          )),
        )),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF142438),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(.07)),
            ),
            child: Row(children: [
              const Icon(Icons.graphic_eq_rounded, color: AppTheme.green, size: 17),
              const SizedBox(width: 9),
              Expanded(child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Text(
                  visible.isEmpty ? 'The teams are ready. Waiting for kick-off…' : visible.last.detail,
                  key: ValueKey(visible.isEmpty ? 'kickoff' : '${visible.last.minute}-${visible.last.detail}'),
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w600),
                ),
              )),
              const SizedBox(width: 8),
              Text(minute == 0 ? '00’' : "$minute’",
                style: const TextStyle(color: AppTheme.green, fontSize: 12, fontWeight: FontWeight.w900)),
            ]),
          ),
        ),
        Expanded(child: ListView(padding: const EdgeInsets.all(14), children: [
          const Text('MATCH TIMELINE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
          const SizedBox(height: 8),
          for (final note in halftimeNotes) Card(child: ListTile(dense: true, leading: const Icon(Icons.swap_horiz, color: AppTheme.green), title: Text(note, style: const TextStyle(fontSize: 10)))),
          for (final e in visible.reversed) _EventTile(event: e, career: c),
          if (finished) ...[
            const SizedBox(height: 12),
            const Text('MATCH STATISTICS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
            _Stats(result: r),
          ],
        ])),
        if (halftimePaused) Padding(padding: const EdgeInsets.fromLTRB(14, 6, 14, 4), child: Row(children: [
          Expanded(child: OutlinedButton.icon(onPressed: _openHalftimeManager, icon: const Icon(Icons.tune_rounded, size: 17), label: const Text('TEAM TALK & CHANGES'))),
          const SizedBox(width: 8),
          Expanded(child: FilledButton.icon(onPressed: _resumeSecondHalf, icon: const Icon(Icons.play_arrow_rounded), label: const Text('START SECOND HALF'))),
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
  final int index; final bool home; final int minute; final String playerName;
  const _PlayerDot({required this.index, required this.home, required this.minute, required this.playerName});
  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return (index + 1).toString();
    if (parts.length == 1) return parts.first.substring(0, parts.first.length > 1 ? 2 : 1).toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
  @override
  Widget build(BuildContext context) {
    final row = index == 0 ? 0 : index <= 4 ? 1 : index <= 7 ? 2 : 3;
    final start = row == 0 ? 0 : row == 1 ? 1 : row == 2 ? 5 : 8;
    final count = row == 0 ? 1 : row == 1 ? 4 : 3;
    final x = count == 1 ? .5 : .12 + .76 * (index - start) / (count - 1);
    final y = row / 3;
    final phase = (minute ~/ 3 + index * 7) % 9;
    final driftX = minute == 0 ? 0.0 : (phase - 4) * .008;
    final driftY = minute == 0 ? 0.0 : ((index + minute ~/ 5) % 5 - 2) * .009;
    final left = (home ? x + driftX : 1 - x - driftX).clamp(.06, .94).toDouble();
    final top = (home ? .13 + y * .70 + driftY : .13 + (1 - y) * .70 - driftY).clamp(.08, .92).toDouble();
    return LayoutBuilder(builder: (context, constraints) {
      const size = 23.0;
      final dx = (constraints.maxWidth * left - size / 2).clamp(0.0, constraints.maxWidth - size).toDouble();
      final dy = (constraints.maxHeight * top - size / 2).clamp(0.0, constraints.maxHeight - size).toDouble();
      return Stack(children: [
        AnimatedPositioned(duration: const Duration(milliseconds: 700), curve: Curves.easeInOut, left: dx, top: dy, child: Container(
          width: size, height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: home ? [const Color(0xFFE3FFB4), AppTheme.green, const Color(0xFF639C2B)] : [const Color(0xFFFFE6A3), AppTheme.gold, const Color(0xFFB87916)],),
            border: Border.all(color: Colors.white, width: 1.5),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(.35), blurRadius: 5, offset: const Offset(0, 2))],
          ),
          alignment: Alignment.center,
          child: Text(_initials(playerName), style: const TextStyle(color: Color(0xFF08111D), fontSize: 7, fontWeight: FontWeight.w900)),
        )),
      ]);
    });
  }
}
class _PitchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..shader = const LinearGradient(
      begin: Alignment.topCenter, end: Alignment.bottomCenter,
      colors: [Color(0xFF071B19), Color(0xFF102E25), Color(0xFF071B19)],
    ).createShader(rect));
    final pitch = Path()
      ..moveTo(size.width * .18, size.height * .035)
      ..lineTo(size.width * .82, size.height * .035)
      ..lineTo(size.width * .98, size.height * .97)
      ..lineTo(size.width * .02, size.height * .97)
      ..close();
    canvas.drawPath(pitch, Paint()..shader = const LinearGradient(
      colors: [Color(0xFF258354), Color(0xFF12613E), Color(0xFF0B4A31)],
    ).createShader(rect));
    final stripe = Paint()..color = Colors.white.withOpacity(.045);
    for (var i = 0; i < 8; i++) {
      if (i.isEven) {
        final x = size.width * (.18 + i * .08);
        canvas.drawPath(Path()..moveTo(x, size.height * .04)
          ..lineTo(x + size.width * .075, size.height * .04)
          ..lineTo(size.width * .98 - i * 2, size.height * .97)
          ..lineTo(size.width * .02 + i * 2, size.height * .97)..close(), stripe);
      }
    }
    final p = Paint()..color = Colors.white.withOpacity(.78)
      ..style = PaintingStyle.stroke..strokeWidth = 1.15;
    final left = size.width * .18, right = size.width * .82;
    final top = size.height * .035, bottom = size.height * .97;
    canvas.drawPath(Path()..moveTo(left, top)..lineTo(right, top)
      ..lineTo(size.width * .98, bottom)..lineTo(size.width * .02, bottom)..close(), p);
    canvas.drawLine(Offset(size.width * .5, top), Offset(size.width * .5, bottom), p);
    canvas.drawOval(Rect.fromCenter(center: Offset(size.width * .5, size.height * .5),
      width: size.width * .27, height: size.height * .18), p);
    canvas.drawRect(Rect.fromLTRB(size.width * .35, top, size.width * .65, size.height * .19), p);
    canvas.drawRect(Rect.fromLTRB(size.width * .35, size.height * .81, size.width * .65, bottom), p);
    canvas.drawRect(Rect.fromLTRB(size.width * .43, top, size.width * .57, size.height * .10), p);
    canvas.drawRect(Rect.fromLTRB(size.width * .43, size.height * .90, size.width * .57, bottom), p);
    final glow = Paint()..shader = RadialGradient(colors: [Colors.white.withOpacity(.12), Colors.transparent])
      .createShader(Rect.fromCircle(center: Offset(size.width * .5, size.height * .1), radius: size.width * .7));
    canvas.drawRect(rect, glow);
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
