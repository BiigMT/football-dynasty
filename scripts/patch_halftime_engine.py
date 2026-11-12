from pathlib import Path

def replace_once(source, old, new, label):
    count = source.count(old)
    if count != 1:
        raise SystemExit(f"Expected one {label} anchor, found {count}")
    return source.replace(old, new, 1)

def main(project):
    root = Path(project)
    path = root / "lib/domain/match_engine.dart"
    source = path.read_text()
    source = replace_once(source, "  final TeamSheet sheet;\n", "  TeamSheet sheet;\n", "mutable side sheet")
    source = replace_once(source, "  void _computeStrength() {\n", "  void applySheet(TeamSheet next) {\n    sheet = next;\n    _computeStrength();\n  }\n\n  void _computeStrength() {\n", "applySheet")
    source = replace_once(source, "    required int seed,\n  }) {", "    required int seed,\n    TeamSheet? homeSecondHalf,\n    TeamSheet? awaySecondHalf,\n  }) {", "second-half parameters")
    source = replace_once(source, "    for (var minute = 1; minute <= lastMinute; minute++) {\n      final sides = [h, a];", "    for (var minute = 1; minute <= lastMinute; minute++) {\n      // Apply manager decisions before simulating minute 46. The seeded RNG\n      // stream is unchanged, preserving the first-half events exactly.\n      if (minute == 46) {\n        if (homeSecondHalf != null) h.applySheet(homeSecondHalf);\n        if (awaySecondHalf != null) a.applySheet(awaySecondHalf);\n      }\n      final sides = [h, a];", "halftime switch")
    source = replace_once(source, "      homeXI: home.xi.map((s) => s.player.id).toList(),\n      awayXI: away.xi.map((s) => s.player.id).toList(),", "      homeXI: h.sheet.xi.map((s) => s.player.id).toList(),\n      awayXI: a.sheet.xi.map((s) => s.player.id).toList(),", "final XI")
    path.write_text(source)

if __name__ == "__main__":
    import sys
    main(sys.argv[1])
