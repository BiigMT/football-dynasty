from pathlib import Path
import sys

root = Path(sys.argv[1])

def patch(rel, old, new):
    path = root / rel
    source = path.read_text()
    if new in source:
        return
    if old not in source:
        raise SystemExit(f'Expected patch point not found in {rel}')
    path.write_text(source.replace(old, new, 1))

patch('lib/domain/career.dart', """    final buyers = clubs.values.where((c) => c.id != userClubId).toList();
    final buyer = rng.pick(buyers);""", """    final buyers = clubs.values.where((c) =>
        c.id != userClubId && c.transferBudget >= target.value && c.balance >= target.value).toList();
    if (buyers.isEmpty) return;
    final buyer = rng.pick(buyers);""")

patch('lib/domain/career.dart', '''  ActionResult acceptOffer(String offerId) {
''', '''  /// Ask interested AI clubs to make bids for one of our players.
  ActionResult offerPlayerToClubs(String playerId) {
    final p = players[playerId];
    if (p == null || p.clubId != userClubId) {
      return const ActionResult(false, 'That player is not in your squad.');
    }
    if (!isWindowOpen) {
      return const ActionResult(false, 'The transfer window is closed.');
    }
    if (userSquad.length <= Economy.minSquad) {
      return ActionResult(false,
          'You need at least ${Economy.minSquad} players. Sign a replacement first.');
    }
    if (offers.any((o) => o.playerId == playerId)) {
      return const ActionResult(false, 'This player already has an active offer.');
    }

    final rng = SeededRandom(mixSeed(seed, hashString(playerId) + season * 31 + matchday));
    final buyers = clubs.values
        .where((club) => club.id != userClubId &&
            club.transferBudget >= p.value &&
            club.balance >= p.value)
        .toList()
      ..sort((a, b) => b.reputation.compareTo(a.reputation));
    if (buyers.isEmpty) {
      return const ActionResult(false, 'No clubs can afford this player right now.');
    }
    rng.shuffle(buyers);
    final interested = buyers.take(buyers.length < 3 ? buyers.length : 3).toList();
    for (final buyer in interested) {
      final fee = math.max(10000,
          ((p.value * (0.78 + rng.nextDouble() * 0.18)) / 10000).round() * 10000).toInt();
      offers.add(TransferOffer(
        id: 'o${offerCounter++}',
        playerId: p.id,
        fromClubId: buyer.id,
        fee: fee,
        expiresMatchday: matchday + 3,
        season: season,
      ));
      _addNews('${buyer.name} are interested in ${p.name} and have submitted an offer.');
    }
    return ActionResult(true,
        '${interested.length} club(s) have made offers for ${p.name}. Check the Offers tab.');
  }

  ActionResult acceptOffer(String offerId) {
''')

patch('lib/domain/career.dart', '''    } else {
      userClub.balance += fee;
      userClub.transferBudget += fee;
    }
''', '''    } else {
      userClub.balance += fee;
      userClub.transferBudget += fee;
      final buyer = clubs[toClubId];
      if (buyer != null) {
        buyer.balance = buyer.balance >= fee ? buyer.balance - fee : 0;
        buyer.transferBudget = buyer.transferBudget >= fee ? buyer.transferBudget - fee : 0;
      }
    }
''')

patch('lib/domain/career.dart', '''    offers.removeAt(idx);
    _addNews('${p.name} sold to ${clubs[o.fromClubId]!.name} for ${_money(o.fee)}.');
''', '''    offers.removeWhere((other) => other.playerId == p.id);
    _addNews('${p.name} sold to ${clubs[o.fromClubId]!.name} for ${_money(o.fee)}.');
''')

patch('lib/domain/career.dart', '''    if (userSquad.length <= Economy.minSquad) {
      return ActionResult(false,
          'You need at least ${Economy.minSquad} players. Sign a replacement first.');
    }
    _moveToClub(p, o.fromClubId, o.fee, selling: true);''', '''    if (userSquad.length <= Economy.minSquad) {
      return ActionResult(false,
          'You need at least ${Economy.minSquad} players. Sign a replacement first.');
    }
    final buyer = clubs[o.fromClubId];
    if (buyer == null || buyer.balance < o.fee || buyer.transferBudget < o.fee) {
      return const ActionResult(false, 'The buying club can no longer afford this offer.');
    }
    _moveToClub(p, o.fromClubId, o.fee, selling: true);''')

patch('lib/state/game_controller.dart', '''  BidResponse bid(String id, int fee) => run((c) => c.bid(id, fee));
''', '''  BidResponse bid(String id, int fee) => run((c) => c.bid(id, fee));
  ActionResult offerToClubs(String id) => run((c) => c.offerPlayerToClubs(id));
''')

patch('lib/screens/player_screen.dart', '''  List<Widget> _ownActions(BuildContext context, GameController game, Player p) {
    return [
      SizedBox(
''', '''  List<Widget> _ownActions(BuildContext context, GameController game, Player p) {
    final c = game.career!;
    final alreadyListed = c.offers.any((offer) => offer.playerId == p.id);
    return [
      if (c.isWindowOpen && !alreadyListed)
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            icon: const Icon(Icons.outbound_rounded),
            onPressed: () async {
              final ok = await confirm(
                context,
                'Offer ${p.name} to clubs?',
                'Interested clubs will submit transfer bids. You can review and accept or reject them in Transfers → Offers.',
                action: 'Offer player',
              );
              if (!ok) return;
              final result = game.offerToClubs(p.id);
              if (context.mounted) toast(context, result.message);
            },
            label: const Text('OFFER TO CLUBS'),
          ),
        )
      else if (alreadyListed)
        const Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: Text('This player has active offers. Review them in Transfers → Offers.',
              style: TextStyle(color: AppTheme.green, fontSize: 12)),
        ),
      SizedBox(
''')

patch('test/career_test.dart', '''    test('a high bid is accepted and money moves', () {
''', '''    test('manager can offer a player to clubs and receive bids', () {
      final c = _new();
      final player = c.userSquad.firstWhere((p) => p.position == 'ST');
      final beforeBalance = c.userClub.balance;

      final result = c.offerPlayerToClubs(player.id);

      expect(result.ok, isTrue);
      expect(c.offers.where((o) => o.playerId == player.id).isNotEmpty, isTrue);
      final offer = c.offers.firstWhere((o) => o.playerId == player.id);
      final accepted = c.acceptOffer(offer.id);

      expect(accepted.ok, isTrue);
      expect(player.clubId, offer.fromClubId);
      expect(c.userClub.balance, greaterThan(beforeBalance));
      expect(c.offers.where((o) => o.playerId == player.id), isEmpty);
    });

    test('a high bid is accepted and money moves', () {
''')
print('Transfer-listing patch applied.')
