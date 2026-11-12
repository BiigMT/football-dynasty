from pathlib import Path

def main(project):
    path = Path(project) / "test/engine_test.dart"
    source = path.read_text()
    anchor = "    test('events are chronological and score matches goal events', () {"
    test = """    test('half-time team sheet updates the final XI', () {
      final h = _team('H', 70, 1), a = _team('A', 70, 2);
      final replacement = WorldGenerator.generatePlayer(
        rng: SeededRandom(777), number: 777, position: 'ST', level: 90,
        clubId: 'H', fixedAge: 24,
      );
      final changedXi = List<LineupSlot>.from(h.xi);
      final strikerIndex = changedXi.indexWhere((slot) => slot.slot == 'ST');
      expect(strikerIndex >= 0, isTrue);
      changedXi[strikerIndex] = LineupSlot('ST', replacement);
      final secondHalf = TeamSheet(
        h.club, changedXi, Tactics(mentality: 2, pressing: 2, tempo: 2));
      final result = MatchEngine.simulate(
        fixtureId: 'halftime', home: h, away: a, seed: 9123,
        homeSecondHalf: secondHalf,
      );
      expect(result.homeXI, contains(replacement.id));
      expect(result.homeXI, isNot(contains(h.xi[strikerIndex].player.id)));
      expect(result.events.any((event) => event.type == EventType.halftime), isTrue);
      expect(result.events.last.type, EventType.fulltime);
    });

"""
    if source.count(anchor) != 1:
        raise SystemExit("Could not uniquely locate engine test insertion point")
    path.write_text(source.replace(anchor, test + anchor, 1))

if __name__ == "__main__":
    import sys
    main(sys.argv[1])
