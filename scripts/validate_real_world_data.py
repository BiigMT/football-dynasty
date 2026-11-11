#!/usr/bin/env python3
"""Validate the checked-in real-world competition dataset before a mobile build."""
import json
import sys
from pathlib import Path

root = Path(sys.argv[1])
dataset_path = root / "data/real_world/competitions_2026_27.json"
data = json.loads(dataset_path.read_text(encoding="utf-8"))

assert data.get("schemaVersion") == 1, "Unsupported real-world data schema"
assert data.get("season") == "2026/27", "Unexpected dataset season"
competitions = data.get("competitions")
assert isinstance(competitions, list) and competitions, "No competitions defined"

competition_ids = set()
club_ids = set()
for competition in competitions:
    cid = competition["id"]
    assert cid not in competition_ids, f"Duplicate competition ID: {cid}"
    competition_ids.add(cid)
    assert competition.get("name"), f"Competition {cid} has no name"
    assert competition.get("source", "").startswith("https://"), f"Competition {cid} has no source URL"

    groups = competition.get("streams")
    if groups is None:
        groups = [{"clubs": competition.get("clubs", [])}]
    count = 0
    for group in groups:
        for club in group.get("clubs", []):
            club_id = club["id"]
            assert club_id not in club_ids, f"Duplicate club ID: {club_id}"
            club_ids.add(club_id)
            assert club.get("name"), f"Club {club_id} has no name"
            count += 1
    assert count == competition.get("teamCount"), (
        f"{cid}: expected {competition.get('teamCount')} clubs, found {count}"
    )

epl = next((c for c in competitions if c["id"] == "eng-premier-league"), None)
assert epl is not None and len(epl.get("clubs", [])) == 20, "Premier League must contain 20 clubs"
zambia = next((c for c in competitions if c["id"] == "zam-mtn-super-league"), None)
assert zambia is not None, "Zambia MTN Super League is missing"
assert len(zambia.get("streams", [])) == 2, "Zambia transitional season must have two streams"
assert all(len(s.get("clubs", [])) == 10 for s in zambia["streams"]), "Each Zambia stream must contain 10 clubs"
assert all(s.get("matchesPerTeam") == 18 for s in zambia["streams"]), "Each Zambia stream must play 18 matches per team"

expected_leagues = {
    "esp-la-liga": 20,
    "ger-bundesliga": 18,
    "ita-serie-a": 20,
    "fra-ligue-1": 18,
    "rsa-betway-premiership": 16,
    "gha-premier-league": 18,
    "nga-npfl": 20,
    "mar-botola-pro": 16,
}
for league_id, expected_count in expected_leagues.items():
    league = next((c for c in competitions if c["id"] == league_id), None)
    assert league is not None, f"Missing launch league: {league_id}"
    assert len(league.get("clubs", [])) == expected_count, (
        f"{league_id}: expected {expected_count} clubs, found {len(league.get('clubs', []))}"
    )


expected_matches = {
    "eng-premier-league": 38,
    "esp-la-liga": 38,
    "ger-bundesliga": 34,
    "ita-serie-a": 38,
    "fra-ligue-1": 34,
    "rsa-betway-premiership": 30,
    "gha-premier-league": 34,
    "nga-npfl": 38,
    "mar-botola-pro": 30,
}
for league_id, matches in expected_matches.items():
    league = next(c for c in competitions if c["id"] == league_id)
    assert league.get("format") == "double_round_robin", (
        f"{league_id}: unexpected competition format"
    )
    assert league.get("matchesPerTeam") == matches, (
        f"{league_id}: expected {matches} matches per team"
    )

assert data.get("playerSquads", {}).get("status") == "not_yet_added", (
    "Real-player squads must not be marked complete until approved sources are available"
)

print(f"Real-world dataset valid: {len(competitions)} competitions, {len(club_ids)} clubs.")

