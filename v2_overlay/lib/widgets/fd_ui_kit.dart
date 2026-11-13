import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Compact rating badge shared by squad, player and scouting screens.
class FdRatingBadge extends StatelessWidget {
  const FdRatingBadge(this.rating, {super.key});
  final int rating;

  @override
  Widget build(BuildContext context) {
    final color = rating >= 80
        ? AppTheme.gold
        : rating >= 65
            ? AppTheme.green
            : const Color(0xFFFF8A80);
    return Semantics(
      label: 'Player rating $rating',
      child: Container(
        constraints: const BoxConstraints(minWidth: 43, minHeight: 45),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: color.withValues(alpha: .7)),
        ),
        child: Text('$rating', style: TextStyle(
          color: color, fontSize: 18, fontWeight: FontWeight.w900,
        )),
      ),
    );
  }
}

/// Reusable dark surface for future Football Dynasty screens.
class FdSurfaceCard extends StatelessWidget {
  const FdSurfaceCard({super.key, required this.child, this.padding = const EdgeInsets.all(14), this.onTap});
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: AppTheme.panel,
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(color: Colors.white.withValues(alpha: .07)),
    ),
    child: InkWell(onTap: onTap, child: Padding(padding: padding, child: child)),
  );
}

/// Small uppercase section heading with an optional trailing action.
class FdSectionHeader extends StatelessWidget {
  const FdSectionHeader(this.title, {super.key, this.trailing});
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Row(children: [
    Expanded(child: Text(title.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis,
      style: const TextStyle(color: AppTheme.muted, fontSize: 10, letterSpacing: 1.3, fontWeight: FontWeight.w900))),
    if (trailing != null) trailing!,
  ]);
}

/// Three-across statistic tile that safely scales long values on small phones.
class FdStatTile extends StatelessWidget {
  const FdStatTile({super.key, required this.label, required this.value, this.valueColor});
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) => FdSurfaceCard(
    padding: const EdgeInsets.all(11),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: AppTheme.muted, fontSize: 9, fontWeight: FontWeight.w800)),
      const SizedBox(height: 5),
      FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft,
        child: Text(value, style: TextStyle(color: valueColor ?? Colors.white, fontSize: 20, fontWeight: FontWeight.w900))),
    ]),
  );
}

enum FdFormResult { win, draw, loss }

/// Accessible W/D/L form strip.
class FdFormGuide extends StatelessWidget {
  const FdFormGuide({super.key, required this.results});
  final List<FdFormResult> results;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Recent form: ${results.map((r) => switch (r) { FdFormResult.win => 'win', FdFormResult.draw => 'draw', FdFormResult.loss => 'loss' }).join(', ')}',
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        for (var i = 0; i < results.length; i++) ...[
          if (i > 0) const SizedBox(width: 5),
          Builder(builder: (context) {
            final r = results[i];
            final color = switch (r) {
              FdFormResult.win => const Color(0xFF42D99A),
              FdFormResult.draw => AppTheme.gold,
              FdFormResult.loss => const Color(0xFFFF8A80),
            };
            final letter = switch (r) { FdFormResult.win => 'W', FdFormResult.draw => 'D', FdFormResult.loss => 'L' };
            return Container(width: 25, height: 25, alignment: Alignment.center,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(7)),
              child: Text(letter, style: const TextStyle(color: Color(0xFF07111B), fontSize: 11, fontWeight: FontWeight.w900)));
          }),
        ],
      ]),
    );
  }
}
