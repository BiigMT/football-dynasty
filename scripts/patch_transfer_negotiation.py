from pathlib import Path
import sys
root=Path(sys.argv[1])
def patch(rel,old,new):
 p=root/rel; s=p.read_text(encoding='utf-8')
 if new in s:return
 if old not in s:raise SystemExit(f'Expected transfer negotiation patch point not found in {rel}: {old[:100]!r}')
 p.write_text(s.replace(old,new,1),encoding='utf-8')

patch('lib/domain/career.dart', '''  void rejectOffer(String offerId) => offers.removeWhere((o) => o.id == offerId);
''', '''  ActionResult counterTransferOffer(String offerId, int requestedFee) {
    final index = offers.indexWhere((o) => o.id == offerId);
    if (index < 0) return const ActionResult(false, 'That offer has expired.');
    final offer = offers[index];
    final player = players[offer.playerId];
    final buyer = clubs[offer.fromClubId];
    if (player == null || player.clubId != userClubId || buyer == null) {
      return const ActionResult(false, 'The transfer is no longer available.');
    }
    if (!isWindowOpen) return const ActionResult(false, 'The transfer window is closed.');
    if (requestedFee <= offer.fee) {
      return const ActionResult(false, 'Your counter-offer must be higher than their bid.');
    }
    if (userSquad.length <= Economy.minSquad) {
      return const ActionResult(false, 'Your squad is too small to sell this player.');
    }
    final buyerLimit = math.min(buyer.balance, buyer.transferBudget);
    if (requestedFee > buyerLimit) {
      return const ActionResult(false, 'The buying club cannot afford that fee.');
    }
    final fairCeiling = math.max(offer.fee, (player.value * 1.28).round());
    if (requestedFee <= fairCeiling) {
      _moveToClub(player, buyer.id, requestedFee, selling: true);
      offers.removeWhere((o) => o.playerId == player.id);
      _addNews('${buyer.name} accepted your counter-offer for ${player.name}: ${_money(requestedFee)}.');
      return ActionResult(true, '${buyer.name} accepted. ${player.name} has been sold for ${_money(requestedFee)}.');
    }
    if (requestedFee <= (fairCeiling * 1.18).round()) {
      final counter = TransferOffer(
        id: offer.id, playerId: offer.playerId, fromClubId: offer.fromClubId,
        fee: fairCeiling, expiresMatchday: offer.expiresMatchday, season: offer.season,
      );
      offers[index] = counter;
      _addNews('${buyer.name} rejected your demand but improved their offer for ${player.name} to ${_money(fairCeiling)}.');
      return ActionResult(true, 'They countered at ${_money(fairCeiling)}. Review the updated offer.');
    }
    return const ActionResult(false, 'The club rejected your counter-offer. You can still accept their original bid.');
  }

  void rejectOffer(String offerId) => offers.removeWhere((o) => o.id == offerId);
''')
patch('lib/state/game_controller.dart', '''  ActionResult acceptOffer(String id) => run((c) => c.acceptOffer(id));
''', '''  ActionResult acceptOffer(String id) => run((c) => c.acceptOffer(id));
  ActionResult counterTransferOffer(String id, int fee) => run((c) => c.counterTransferOffer(id, fee));
''')
patch('lib/screens/transfers_screen.dart', '''  Widget _offers(BuildContext context, GameController game) {
''', '''  Future<void> _counterDialog(BuildContext context, GameController game, TransferOffer offer, Player player) async {
    final controller = TextEditingController(text: (player.value * 1.15).round().toString());
    final fee = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Counter ${fmtMoney(offer.fee)} offer'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Their bid: ${fmtMoney(offer.fee)} • Player value: ${fmtMoney(player.value)}', style: const TextStyle(color: Colors.white60, fontSize: 12)),
          const SizedBox(height: 12),
          TextField(controller: controller, keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Your requested fee (€)', border: OutlineInputBorder())),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, int.tryParse(controller.text.trim())), child: const Text('SEND COUNTER')),
        ],
      ),
    );
    controller.dispose();
    if (fee == null || fee <= 0 || !context.mounted) return;
    final result = game.counterTransferOffer(offer.id, fee);
    if (context.mounted) toast(context, result.message);
  }

  Widget _offers(BuildContext context, GameController game) {
''')
patch('lib/screens/transfers_screen.dart', '''                Row(children: [
                  Expanded(
                    child: FilledButton(
''', '''                Row(children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _counterDialog(context, game, o, p),
                      child: const Text('NEGOTIATE'),
                    ),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: FilledButton(
''')
patch('test/career_test.dart', '''    test('a high bid is accepted and money moves', () {
''', '''    test('manager can negotiate an incoming transfer offer', () {
      final c = _new();
      final player = c.userSquad.firstWhere((p) => p.position == 'ST');
      expect(c.offerPlayerToClubs(player.id).ok, isTrue);
      final offer = c.offers.firstWhere((o) => o.playerId == player.id);
      final buyer = c.clubs[offer.fromClubId]!;
      buyer.balance = 1000000000;
      buyer.transferBudget = 1000000000;
      final result = c.counterTransferOffer(offer.id, (player.value * 1.10).round());
      expect(result.ok, isTrue);
      expect(player.clubId == c.userClubId, isFalse);
      expect(c.offers.where((o) => o.playerId == player.id), isEmpty);
    });

    test('a high bid is accepted and money moves', () {
''')
print('Transfer negotiation patch applied.')
