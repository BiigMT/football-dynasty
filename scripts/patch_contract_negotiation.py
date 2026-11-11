from pathlib import Path
import re, sys
root = Path(sys.argv[1])

def patch(rel, old, new):
    path = root / rel
    source = path.read_text(encoding='utf-8')
    if new in source:
        return
    if old not in source:
        raise SystemExit('Expected contract negotiation patch point not found in ' + rel)
    path.write_text(source.replace(old, new, 1), encoding='utf-8')

patch('lib/domain/career.dart', '''  ActionResult renewContract(String playerId) {
''', '''  ActionResult negotiateContract(String playerId, int offeredWage, int years) {
    final p = players[playerId];
    if (p == null || p.clubId != userClubId) {
      return const ActionResult(false, 'Player not found in your squad.');
    }
    if (years < 1 || years > 5 || offeredWage <= 0) {
      return const ActionResult(false, 'Enter a valid wage and contract length.');
    }
    final demand = Economy.renewalWage(p);
    if (offeredWage < (demand * 0.90).round()) {
      return ActionResult(false, p.name + ' rejected the offer and wants at least ' + _money((demand * 0.90).round()) + '/week.');
    }
    if (p.age < 31 && years < 2) {
      return ActionResult(false, p.name + ' wants a contract of at least two years.');
    }
    if (wageBill(userClubId) - p.wage + offeredWage > userClub.wageBudget) {
      return const ActionResult(false, 'This would exceed your wage budget.');
    }
    if (offeredWage < demand && p.morale < 75) {
      return ActionResult(false, p.name + ' rejected the offer. Their wage demand is ' + _money(demand) + '/week.');
    }
    p.wage = offeredWage;
    p.contractYears = years;
    p.morale = math.min(100, p.morale + 5);
    _addNews(p.name + ' agreed a new ' + years.toString() + '-year contract on ' + _money(offeredWage) + '/week.');
    return ActionResult(true, p.name + ' signed a new ' + years.toString() + '-year deal.');
  }

  ActionResult renewContract(String playerId) {
''')
patch('lib/state/game_controller.dart', '''  ActionResult renew(String id) => run((c) => c.renewContract(id));
''', '''  ActionResult renew(String id) => run((c) => c.renewContract(id));
  ActionResult negotiateContract(String id, int wage, int years) => run((c) => c.negotiateContract(id, wage, years));
''')

contract_dialog = '''  Future<void> _contractDialog(BuildContext context, GameController game, Player p) async {
    final wage = TextEditingController(text: Economy.renewalWage(p).toString());
    var years = Economy.renewalYears(p);
    final result = await showDialog<(int, int)>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setDialogState) => AlertDialog(
        title: Text('Contract offer for ' + p.name),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Player demand: ' + fmtWage(Economy.renewalWage(p)), style: const TextStyle(color: Colors.white60, fontSize: 12)),
          const SizedBox(height: 12),
          TextField(controller: wage, keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Weekly wage (€)', border: OutlineInputBorder())),
          const SizedBox(height: 10),
          DropdownButtonFormField<int>(
            value: years,
            decoration: const InputDecoration(labelText: 'Contract length'),
            items: [1, 2, 3, 4, 5].map((v) => DropdownMenuItem(value: v, child: Text(v.toString() + ' years'))).toList(),
            onChanged: (v) { if (v != null) setDialogState(() => years = v); },
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () {
            final amount = int.tryParse(wage.text.trim());
            if (amount != null && amount > 0) Navigator.pop(ctx, (amount, years));
          }, child: const Text('SUBMIT OFFER')),
        ],
      )),
    );
    wage.dispose();
    if (result == null || !context.mounted) return;
    final response = game.negotiateContract(p.id, result.$1, result.$2);
    if (context.mounted) toast(context, response.message);
  }

'''
patch('lib/screens/player_screen.dart', '''  List<Widget> _ownActions(BuildContext context, GameController game, Player p) {
''', contract_dialog + '''  List<Widget> _ownActions(BuildContext context, GameController game, Player p) {
''')

player_path = root / 'lib/screens/player_screen.dart'
player_source = player_path.read_text(encoding='utf-8')
pattern = r"onPressed: \(\) async \{\s*final wage = Economy\.renewalWage\(p\);.*?child: const Text\('RENEW CONTRACT'\),"
replacement = "onPressed: () => _contractDialog(context, game, p),\n          child: const Text('NEGOTIATE CONTRACT'),"
player_source, count = re.subn(pattern, replacement, player_source, count=1, flags=re.S)
if count != 1:
    raise SystemExit('Could not replace the existing renew-contract button.')
player_path.write_text(player_source, encoding='utf-8')

patch('test/career_test.dart', '''    test('a high bid is accepted and money moves', () {
''', '''    test('manager can negotiate a player contract within the wage budget', () {
      final c = _new();
      final player = c.userSquad.first;
      final demand = Economy.renewalWage(player);
      c.userClub.wageBudget = c.wageBill(c.userClubId) + demand * 2;
      final result = c.negotiateContract(player.id, demand, 3);
      expect(result.ok, isTrue);
      expect(player.wage, demand);
      expect(player.contractYears, 3);
    });

    test('a high bid is accepted and money moves', () {
''')
print('Contract negotiation patch applied.')
