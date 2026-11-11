from pathlib import Path
import json, sys, re

root = Path(sys.argv[1])
workspace = Path(sys.argv[2]) if len(sys.argv) > 2 else root
data = json.loads((workspace / 'data/real_world/competitions_2026_27.json').read_text(encoding='utf-8'))
comps = []
for source in data['competitions']:
    if source.get('format') == 'double_round_robin':
        comps.append(source)
    elif source.get('format') == 'two_streams_championship_final':
        for stream in source.get('streams', []):
            clubs = stream.get('clubs', [])
            comps.append({
                'id': stream['id'],
                'name': f"{source['name']} · {stream['name']} (Transitional 2026)",
                'countryCode': source['countryCode'],
                'countryName': source['countryName'],
                'season': source['season'],
                'format': 'double_round_robin',
                'teamCount': len(clubs),
                'matchesPerTeam': stream['matchesPerTeam'],
                'clubs': clubs,
            })
priority = {'ZAM': 0, 'RSA': 1, 'GHA': 2, 'NGA': 3, 'MAR': 4}
comps.sort(key=lambda c: (priority.get(c['countryCode'], 10), c['countryName']))
def q(s): return json.dumps(s, ensure_ascii=False)

lines = [
"// Generated from data/real_world/competitions_2026_27.json. Do not edit by hand.",
"class RealWorldClub { final String id; final String name; const RealWorldClub(this.id, this.name); }",
"class RealWorldCompetition {",
"  final String id, name, countryCode, countryName, season, format;",
"  final int teamCount, matchesPerTeam;",
"  final List<RealWorldClub> clubs;",
"  const RealWorldCompetition({required this.id, required this.name, required this.countryCode, required this.countryName, required this.season, required this.format, required this.teamCount, required this.matchesPerTeam, required this.clubs});",
"}",
"class RealWorldCompetitions {",
"  static const all = <RealWorldCompetition>["
]
for c in comps:
    lines += [
      "    RealWorldCompetition(",
      f"      id: {q(c['id'])}, name: {q(c['name'])}, countryCode: {q(c['countryCode'])}, countryName: {q(c['countryName'])},",
      f"      season: {q(c['season'])}, format: {q(c['format'])}, teamCount: {c['teamCount']}, matchesPerTeam: {c['matchesPerTeam']},",
      "      clubs: <RealWorldClub>["
    ]
    for club in c['clubs']:
        lines.append(f"        RealWorldClub({q(club['id'])}, {q(club['name'])}),")
    lines += ["      ],", "    ),"]
lines += [
"  ];",
"  static RealWorldCompetition? byId(String id) { for (final c in all) { if (c.id == id) return c; } return null; }",
"  static List<RealWorldCompetition> forCountry(String code) => all.where((c) => c.countryCode == code).toList();",
"}"
]
(root / 'lib/data').mkdir(parents=True, exist_ok=True)
(root / 'lib/data/real_world_competitions.dart').write_text('\n'.join(lines) + '\n', encoding='utf-8')

def patch(rel, old, new):
    path = root / rel
    src = path.read_text(encoding='utf-8')
    if new in src: return
    if old not in src: raise SystemExit(f'Expected patch point not found in {rel}: {old[:100]!r}')
    path.write_text(src.replace(old, new, 1), encoding='utf-8')

patch('lib/domain/world_generator.dart', "import 'rng.dart';", "import 'rng.dart';\nimport '../data/real_world_competitions.dart';")
patch('lib/domain/world_generator.dart', "  static int get clubCount => _clubSeeds.length;", """  static int get clubCount => _clubSeeds.length;

  static const _realClubColours = <int>[
    0xFF1E5AA8, 0xFFB71C1C, 0xFF2E7D32, 0xFFFFA000, 0xFF6A1B9A,
    0xFF00838F, 0xFF455A64, 0xFFAD1457, 0xFF5D4037, 0xFF283593,
  ];

  static String _shortName(String name) {
    final words = name.replaceAll(RegExp(r'[^A-Za-z0-9 ]'), ' ')
        .split(RegExp(r'\\s+')).where((w) => w.isNotEmpty).toList();
    if (words.length > 1) return words.take(3).map((w) => w[0]).join().toUpperCase();
    final word = words.isEmpty ? 'CLB' : words.first.toUpperCase();
    return word.length <= 3 ? word : word.substring(0, 3);
  }

  /// Real club identities with temporary generated squads until verified
  /// first-team player packs are available.
  static int generateForCompetition({
    required int seed,
    required RealWorldCompetition competition,
    required Map<String, Club> clubs,
    required Map<String, Player> players,
  }) {
    final rng = SeededRandom(mixSeed(seed, hashString(competition.id)));
    var number = 1;
    for (var i = 0; i < competition.clubs.length; i++) {
      final source = competition.clubs[i];
      final reputation = rng.range(48, 84);
      final club = Club(
        id: source.id,
        name: source.name,
        shortName: _shortName(source.name),
        reputation: reputation,
        balance: reputation * 66000,
        transferBudget: reputation * 176000,
        wageBudget: 0,
        stadiumCapacity: 10000 + reputation * 420,
        colorValue: _realClubColours[i % _realClubColours.length],
        tactics: Tactics(formation: formations.keys.elementAt(rng.nextInt(formations.length))),
      );
      clubs[club.id] = club;
      var bill = 0;
      squadTemplate.forEach((pos, count) {
        for (var k = 0; k < count; k++) {
          final player = generatePlayer(
            rng: rng, number: number++, position: pos,
            level: reputation - 4 - (k * 3), clubId: club.id,
          );
          players[player.id] = player;
          bill += player.wage;
        }
      });
      club.wageBudget = (bill * 1.12 / 1000).round() * 1000;
    }
    return generateFreeAgents(rng: rng, players: players, startNumber: number, count: 40);
  }""")

patch('lib/domain/career.dart', "import 'world_generator.dart';", "import 'world_generator.dart';\nimport '../data/real_world_competitions.dart';")
patch('lib/domain/career.dart', 'static const schemaVersion = 2;', 'static const schemaVersion = 3;')
patch('lib/domain/career.dart', "  String managerName;\n  String userClubId;", "  String managerName;\n  String userClubId;\n  String competitionId;\n  String competitionName;")
patch('lib/domain/career.dart', "    required this.managerName,\n    required this.userClubId,", "    required this.managerName,\n    required this.userClubId,\n    required this.competitionId,\n    required this.competitionName,")
patch('lib/domain/career.dart', """    required int seed,
  }) {
    final clubs = <String, Club>{};
    final players = <String, Player>{};
    final next = WorldGenerator.generate(seed: seed, clubs: clubs, players: players);""", """    required int seed,
    String competitionId = 'fictional-demo',
  }) {
    final clubs = <String, Club>{};
    final players = <String, Player>{};
    final competition = RealWorldCompetitions.byId(competitionId);
    if (competitionId != 'fictional-demo' && competition == null) {
      throw ArgumentError('Unknown or unsupported competition: $competitionId');
    }
    final next = competition == null
        ? WorldGenerator.generate(seed: seed, clubs: clubs, players: players)
        : WorldGenerator.generateForCompetition(seed: seed, competition: competition, clubs: clubs, players: players);""")
patch('lib/domain/career.dart', "      managerName: managerName,\n      userClubId: userClubId,", "      managerName: managerName,\n      userClubId: userClubId,\n      competitionId: competition?.id ?? 'fictional-demo',\n      competitionName: competition?.name ?? 'Dynasty Demo League',")
patch('lib/domain/career.dart', "  int get totalMatchdays => (clubs.length - 1) * 2;", "  int get totalMatchdays => fixtures.where((f) => f.season == season).fold<int>(0, (maxRound, f) => f.matchday > maxRound ? f.matchday : maxRound);\n  bool get usesGeneratedPlayers => competitionId != 'fictional-demo';")
patch('lib/domain/career.dart', "    if (matchday <= 4) return 'Summer';\n    if (matchday >= 16 && matchday <= 18) return 'Winter';", "    if (matchday <= 4) return 'Summer';\n    final winterStart = (totalMatchdays / 2).floor() + 1;\n    if (matchday >= winterStart && matchday <= winterStart + 2) return 'Winter';")
patch('lib/domain/career.dart', "        'manager': managerName,\n        'userClub': userClubId,", "        'manager': managerName,\n        'userClub': userClubId,\n        'competitionId': competitionId,\n        'competitionName': competitionName,")
patch('lib/domain/career.dart', "      managerName: j['manager'] as String,\n      userClubId: j['userClub'] as String,", "      managerName: j['manager'] as String,\n      userClubId: j['userClub'] as String,\n      competitionId: j['competitionId'] as String? ?? 'fictional-demo',\n      competitionName: j['competitionName'] as String? ?? 'Dynasty Demo League',")

patch('lib/state/game_controller.dart', """  Future<void> startCareer(int s, String manager, String clubId, int seed) async {
    career = Career.newGame(managerName: manager, userClubId: clubId, seed: seed);""", """  Future<void> startCareer(int s, String manager, String clubId, int seed, {String competitionId = 'fictional-demo'}) async {
    career = Career.newGame(managerName: manager, userClubId: clubId, seed: seed, competitionId: competitionId);""")

patch('lib/screens/competitions_screen.dart', """          child: ScreenHeader(kicker: 'FICTIONAL LEAGUE', title: 'Premier Division ${c.seasonLabel}'),""", """          child: ScreenHeader(kicker: 'LEAGUE COMPETITION', title: '\${c.competitionName} \${c.seasonLabel}'),""")

patch('lib/screens/dashboard_screen.dart', """            const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('FOOTBALL DYNASTY', style: TextStyle(fontSize: 11, letterSpacing: 2.0, color: AppTheme.green, fontWeight: FontWeight.w900)),
              Text('Manager career', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
            ])),""", """            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('FOOTBALL DYNASTY', style: TextStyle(fontSize: 11, letterSpacing: 2.0, color: AppTheme.green, fontWeight: FontWeight.w900)),
              Text(c.competitionName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
            ])),
""")



patch('test/career_test.dart', "import 'package:football_dynasty/domain/models.dart';", "import 'package:football_dynasty/domain/models.dart';\nimport 'package:football_dynasty/data/real_world_competitions.dart';")
patch('test/career_test.dart', "  test('world generation is deterministic', () {", """  test('real-world competition sizes generate complete independent leagues', () {
    for (final competition in RealWorldCompetitions.all) {
      final c = Career.newGame(managerName: 'Tester', userClubId: competition.clubs.first.id, seed: 20261111, competitionId: competition.id);
      expect(c.competitionName, competition.name);
      expect(c.clubs.length, competition.teamCount);
      expect(c.totalMatchdays, competition.matchesPerTeam);
      expect(c.fixtures.length, competition.teamCount * competition.matchesPerTeam ~/ 2);
      expect(c.table.length, competition.teamCount);
      expect(c.userSquad.length, 24);
      final restored = Career.fromJson(c.toJson());
      expect(restored.competitionId, competition.id);
      expect(restored.competitionName, competition.name);
    }
  });

  test('world generation is deterministic', () {""")

path = root / 'lib/screens/start_screen.dart'
src = path.read_text(encoding='utf-8')
src = re.sub(r"'All clubs, players and competitions are fictional generated data\. '\\s*'No real-world names, crests or kits are used\.'", "'Choose from real-world club and league identities. Player squads and ratings are generated placeholders until verified squad packs are added.'", src)
if "import '../data/real_world_competitions.dart';" not in src:
    src = src.replace("import '../domain/career.dart';", "import '../domain/career.dart';\nimport '../data/real_world_competitions.dart';")
start = src.index('class NewCareerScreen extends StatefulWidget {')
src = src[:start] + r'''class NewCareerScreen extends StatefulWidget {
  final int slot;
  const NewCareerScreen({super.key, required this.slot});
  @override
  State<NewCareerScreen> createState() => _NewCareerScreenState();
}

class _NewCareerScreenState extends State<NewCareerScreen> {
  final nameController = TextEditingController(text: 'Manager');
  late final int seed = DateTime.now().millisecondsSinceEpoch & 0x7FFFFFFF;
  String? countryCode;
  String? competitionId;
  String? selectedClub;
  bool starting = false;

  @override
  void initState() {
    super.initState();
    countryCode = RealWorldCompetitions.all.first.countryCode;
    competitionId = RealWorldCompetitions.all.first.id;
  }
  @override
  void dispose() { nameController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final countries = <String, String>{for (final c in RealWorldCompetitions.all) c.countryCode: c.countryName};
    final countryLeagues = RealWorldCompetitions.forCountry(countryCode ?? RealWorldCompetitions.all.first.countryCode);
    final selectedCompetition = countryLeagues.firstWhere((c) => c.id == competitionId, orElse: () => countryLeagues.first);
    final preview = Career.newGame(managerName: 'preview', userClubId: selectedCompetition.clubs.first.id, seed: seed, competitionId: selectedCompetition.id);
    final clubs = selectedCompetition.clubs;
    return Scaffold(
      appBar: AppBar(title: const Text('New career')),
      body: Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(18, 8, 18, 4), child: TextField(controller: nameController, maxLength: 30, decoration: const InputDecoration(labelText: 'Manager name', border: OutlineInputBorder()))),
        Padding(padding: const EdgeInsets.fromLTRB(18, 0, 18, 8), child: Column(children: [
          DropdownButtonFormField<String>(value: countryCode, isExpanded: true, decoration: const InputDecoration(labelText: '1. Choose country', border: OutlineInputBorder()),
            items: countries.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
            onChanged: (v) { if (v == null) return; setState(() { countryCode = v; competitionId = RealWorldCompetitions.forCountry(v).first.id; selectedClub = null; }); }),
          const SizedBox(height: 9),
          DropdownButtonFormField<String>(value: selectedCompetition.id, isExpanded: true, decoration: const InputDecoration(labelText: '2. Choose league', border: OutlineInputBorder()),
            items: countryLeagues.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
            onChanged: (v) => setState(() { competitionId = v; selectedClub = null; })),
        ])),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 5), child: Row(children: [
          const Expanded(child: Text('3. Choose your club', style: TextStyle(fontWeight: FontWeight.w900))),
          Text('\${clubs.length} CLUBS', style: const TextStyle(color: AppTheme.green, fontSize: 10, fontWeight: FontWeight.w900)),
        ])),
        Expanded(child: ListView.builder(padding: const EdgeInsets.fromLTRB(18, 4, 18, 12), itemCount: clubs.length, itemBuilder: (context, index) {
          final source = clubs[index];
          final club = preview.clubs[source.id]!;
          final average = preview.squad(club.id).take(11).fold<int>(0, (sum, p) => sum + p.rating) / 11;
          return Padding(padding: const EdgeInsets.only(bottom: 7), child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: selectedClub == club.id ? AppTheme.green : Colors.transparent, width: 2)),
            child: ListTile(onTap: () => setState(() => selectedClub = club.id), leading: ClubCrest(club.shortName, club.colorValue),
              title: Text(club.name, style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text('Squad strength \${average.toStringAsFixed(0)} • \${fmtMoney(club.transferBudget)} budget'),
              trailing: selectedClub == club.id ? const Icon(Icons.check_circle, color: AppTheme.green) : const Icon(Icons.circle_outlined, color: Colors.white24)),
          ));
        })),
        Container(padding: const EdgeInsets.fromLTRB(18, 10, 18, 18), decoration: BoxDecoration(color: AppTheme.panel, border: Border(top: BorderSide(color: Colors.white.withOpacity(.08)))), child: Column(children: [
          const Text('Real club identities are included. Player squads and ratings are generated placeholders until verified real-world squad packs are added. Zambia's two transition streams are playable separately; the championship final is not yet simulated.', style: TextStyle(color: Colors.white54, fontSize: 10), textAlign: TextAlign.center),
          const SizedBox(height: 9),
          SizedBox(width: double.infinity, child: FilledButton(onPressed: selectedClub == null || starting ? null : () async {
            setState(() => starting = true);
            final game = GameScope.of(context); final nav = Navigator.of(context);
            final manager = nameController.text.trim().isEmpty ? 'Manager' : nameController.text.trim();
            await game.startCareer(widget.slot, manager, selectedClub!, seed, competitionId: selectedCompetition.id);
            nav.popUntil((r) => r.isFirst);
          }, child: const Text('START CAREER'))),
        ])),
      ]),
    );
  }
}
'''
path.write_text(src, encoding='utf-8')
print(f'Competition engine patch applied: {len(comps)} playable leagues, {sum(c["teamCount"] for c in comps)} clubs.')
