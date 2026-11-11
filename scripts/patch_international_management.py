from pathlib import Path
import sys

root = Path(sys.argv[1])

def patch(rel, old, new):
    path = root / rel
    source = path.read_text()
    if new in source:
        return
    if old not in source:
        raise SystemExit(f'Expected international patch point not found in {rel}')
    path.write_text(source.replace(old, new, 1))

patch('lib/domain/models.dart', """  String? clubId; // null = free agent
  int injuredMatches;
""", """  String? clubId; // null = free agent
  String nationality;
  int injuredMatches;
""")
patch('lib/domain/models.dart', """    this.clubId,
    this.injuredMatches = 0,
""", """    this.clubId,
    this.nationality = 'ZAM',
    this.injuredMatches = 0,
""")
patch('lib/domain/models.dart', """        'club': clubId,
        'inj': injuredMatches,
""", """        'club': clubId,
        'nat': nationality,
        'inj': injuredMatches,
""")
patch('lib/domain/models.dart', """        clubId: j['club'] as String?,
        injuredMatches: j['inj'] as int,
""", """        clubId: j['club'] as String?,
        nationality: j['nat'] as String? ?? 'ZAM',
        injuredMatches: j['inj'] as int,
""")

patch('lib/domain/world_generator.dart', """class WorldGenerator {
  static const _clubSeeds = <List<Object>>[
""", """class WorldGenerator {
  static const nationalityCodes = <String>[
    'ZAM', 'RSA', 'NGA', 'GHA', 'SEN', 'MAR', 'EGY', 'CMR',
    'CIV', 'COD', 'ENG', 'FRA', 'ESP', 'GER', 'BRA', 'ARG',
  ];

  static const _clubSeeds = <List<Object>>[
""")
patch('lib/domain/world_generator.dart', """      contractYears: rng.range(1, 5),
      clubId: clubId,
""", """      contractYears: rng.range(1, 5),
      clubId: clubId,
      nationality: rng.pick(nationalityCodes),
""")

patch('lib/domain/career.dart', """class Career {
  static const schemaVersion = 1;
""", """class Career {
  static const schemaVersion = 2;
""")
patch('lib/domain/career.dart', """  List<SeasonRecord> history;

  Career._({
""", """  List<SeasonRecord> history;
  String? nationalTeamCode;
  Set<String> nationalCallups;
  Set<String> nationalStartingXi;
  String? nationalCaptainId;

  Career._({
""")
patch('lib/domain/career.dart', """    required this.history,
  });
""", """    required this.history,
    required this.nationalTeamCode,
    required this.nationalCallups,
    required this.nationalStartingXi,
    required this.nationalCaptainId,
  });
""")
patch('lib/domain/career.dart', """      history: [],
    );
""", """      history: [],
      nationalTeamCode: null,
      nationalCallups: <String>{},
      nationalStartingXi: <String>{},
      nationalCaptainId: null,
    );
""")
patch('lib/domain/career.dart', """  List<Player> get freeAgents => players.values.where((p) => p.clubId == null).toList();
  int wageBill(String clubId) => squad(clubId).fold<int>(0, (a, p) => a + p.wage);
""", """  List<Player> get freeAgents => players.values.where((p) => p.clubId == null).toList();
  int wageBill(String clubId) => squad(clubId).fold<int>(0, (a, p) => a + p.wage);

  static const nationalTeams = <String, String>{
    'ZAM': 'Zambia', 'RSA': 'South Africa', 'NGA': 'Nigeria',
    'GHA': 'Ghana', 'SEN': 'Senegal', 'MAR': 'Morocco',
    'EGY': 'Egypt', 'CMR': 'Cameroon', 'CIV': 'Ivory Coast',
    'COD': 'DR Congo', 'ENG': 'England', 'FRA': 'France',
    'ESP': 'Spain', 'GER': 'Germany', 'BRA': 'Brazil', 'ARG': 'Argentina',
  };

  List<Player> get eligibleNationalPlayers {
    final code = nationalTeamCode;
    if (code == null) return <Player>[];
    return players.values.where((p) => p.nationality == code).toList()
      ..sort((a, b) {
        final rating = b.rating.compareTo(a.rating);
        return rating != 0 ? rating : a.age.compareTo(b.age);
      });
  }

  ActionResult appointNationalTeam(String code) {
    if (nationalTeamCode != null) {
      return const ActionResult(false, 'You already manage a national team.');
    }
    if (!nationalTeams.containsKey(code)) {
      return const ActionResult(false, 'That national team is unavailable.');
    }
    nationalTeamCode = code;
    final pool = eligibleNationalPlayers;
    nationalCallups = pool.take(23).map((p) => p.id).toSet();
    nationalStartingXi = pool.take(11).map((p) => p.id).toSet();
    nationalCaptainId = pool.isEmpty ? null : pool.first.id;
    _addNews('You have been appointed head coach of ${nationalTeams[code]}.');
    return ActionResult(true, 'You are now the manager of ${nationalTeams[code]}.');
  }

  ActionResult callUpPlayer(String playerId) {
    final player = players[playerId];
    if (nationalTeamCode == null) {
      return const ActionResult(false, 'Accept a national team job first.');
    }
    if (player == null || player.nationality != nationalTeamCode) {
      return const ActionResult(false, 'This player is not eligible for your national team.');
    }
    if (nationalCallups.contains(playerId)) {
      return const ActionResult(false, 'This player is already in the squad.');
    }
    if (nationalCallups.length >= 26) {
      return const ActionResult(false, 'The national squad is full (26 players).');
    }
    nationalCallups.add(playerId);
    _addNews('${player.name} has been called up for ${nationalTeams[nationalTeamCode]}.');
    return ActionResult(true, '${player.name} called up.');
  }

  ActionResult dropNationalPlayer(String playerId) {
    if (!nationalCallups.remove(playerId)) {
      return const ActionResult(false, 'That player is not in your national squad.');
    }
    nationalStartingXi.remove(playerId);
    if (nationalCaptainId == playerId) {
      nationalCaptainId = nationalCallups.isEmpty ? null : nationalCallups.first;
    }
    final player = players[playerId];
    return ActionResult(true, '${player?.name ?? 'Player'} removed from the squad.');
  }

  ActionResult toggleNationalStarter(String playerId) {
    if (!nationalCallups.contains(playerId)) {
      return const ActionResult(false, 'Call up the player before selecting the starting XI.');
    }
    if (nationalStartingXi.remove(playerId)) {
      return const ActionResult(true, 'Player removed from the starting XI.');
    }
    if (nationalStartingXi.length >= 11) {
      return const ActionResult(false, 'The starting XI already has 11 players.');
    }
    nationalStartingXi.add(playerId);
    return const ActionResult(true, 'Player added to the starting XI.');
  }

  ActionResult setNationalCaptain(String playerId) {
    if (!nationalCallups.contains(playerId)) {
      return const ActionResult(false, 'The captain must be in your national squad.');
    }
    nationalCaptainId = playerId;
    return ActionResult(true, '${players[playerId]!.name} is now captain.');
  }
""")
patch('lib/domain/career.dart', """        'history': history.map((h) => h.toJson()).toList(),
      };
""", """        'history': history.map((h) => h.toJson()).toList(),
        'nationalTeam': nationalTeamCode,
        'nationalCallups': nationalCallups.toList(),
        'nationalStartingXi': nationalStartingXi.toList(),
        'nationalCaptain': nationalCaptainId,
      };
""")
patch('lib/domain/career.dart', """      history: list('history', SeasonRecord.fromJson),
    );
""", """      history: list('history', SeasonRecord.fromJson),
      nationalTeamCode: j['nationalTeam'] as String?,
      nationalCallups: ((j['nationalCallups'] as List?) ?? const <dynamic>[]).cast<String>().toSet(),
      nationalStartingXi: ((j['nationalStartingXi'] as List?) ?? const <dynamic>[]).cast<String>().toSet(),
      nationalCaptainId: j['nationalCaptain'] as String?,
    );
""")

patch('lib/state/game_controller.dart', """  ActionResult offerToClubs(String id) => run((c) => c.offerPlayerToClubs(id));
""", """  ActionResult offerToClubs(String id) => run((c) => c.offerPlayerToClubs(id));
  ActionResult appointNationalTeam(String code) => run((c) => c.appointNationalTeam(code));
  ActionResult callUpPlayer(String id) => run((c) => c.callUpPlayer(id));
  ActionResult dropNationalPlayer(String id) => run((c) => c.dropNationalPlayer(id));
  ActionResult toggleNationalStarter(String id) => run((c) => c.toggleNationalStarter(id));
  ActionResult setNationalCaptain(String id) => run((c) => c.setNationalCaptain(id));
""")

patch('test/career_test.dart', """  test('a full season plays out with a consistent table', () {
""", """  test('national manager can appoint a team, call up players and save selection', () {
    final c = _new();
    final appointment = c.appointNationalTeam('ZAM');
    expect(appointment.ok, isTrue);
    expect(c.nationalTeamCode, 'ZAM');
    expect(c.nationalCallups.length, lessThanOrEqualTo(23));
    expect(c.nationalStartingXi.length, lessThanOrEqualTo(11));

    final eligible = c.eligibleNationalPlayers
        .where((p) => !c.nationalCallups.contains(p.id))
        .toList();
    if (eligible.isNotEmpty && c.nationalCallups.length < 26) {
      expect(c.callUpPlayer(eligible.first.id).ok, isTrue);
    }
    final selected = c.nationalCallups.first;
    expect(c.setNationalCaptain(selected).ok, isTrue);
    final restored = Career.fromJson(c.toJson());
    expect(restored.nationalTeamCode, 'ZAM');
    expect(restored.nationalCallups, c.nationalCallups);
    expect(restored.nationalCaptainId, c.nationalCaptainId);
  });

  test('a full season plays out with a consistent table', () {
""")
print('International management domain patch applied.')
