import 'package:flutter/material.dart';

/// A deterministic illustrated portrait seeded by the player's name.
class ProceduralPlayerAvatar extends StatelessWidget {
  final String playerName;
  final Color jerseyColor;
  final double size;
  const ProceduralPlayerAvatar({super.key, required this.playerName, this.jerseyColor = const Color(0xFF00E5FF), this.size = 56});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size, height: size,
    child: CustomPaint(painter: _PortraitPainter(_hash(playerName), jerseyColor)),
  );

  static int _hash(String value) {
    var hash = 0x811c9dc5;
    for (final unit in value.toLowerCase().codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash;
  }
}

class _PortraitPainter extends CustomPainter {
  final int seed;
  final Color jersey;
  _PortraitPainter(this.seed, this.jersey);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height, cx = size.width / 2;
    final rng = _PortraitRandom(seed);
    final skin = [const Color(0xFF8D563B), const Color(0xFFB87955), const Color(0xFFD49A73), const Color(0xFF6D402F), const Color(0xFFA96C4B)][rng.next(5)];
    final hair = [const Color(0xFF171311), const Color(0xFF302018), const Color(0xFF4A3022), const Color(0xFF171B20)][rng.next(4)];
    final bounds = Offset.zero & size;
    canvas.drawRRect(RRect.fromRectAndRadius(bounds, Radius.circular(w * .2)),
      Paint()..shader = const LinearGradient(colors: [Color(0xFF263D4C), Color(0xFF101820)], begin: Alignment.topLeft, end: Alignment.bottomRight).createShader(bounds));
    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(bounds, Radius.circular(w * .2)));
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, h*.70), width: w*.22, height: h*.30), Radius.circular(w*.06)), Paint()..color=skin);
    final shirt = Path()..moveTo(w*.04,h)..lineTo(w*.12,h*.79)..quadraticBezierTo(cx,h*.67,w*.88,h*.79)..lineTo(w*.98,h)..close();
    canvas.drawPath(shirt, Paint()..color=jersey);
    canvas.drawPath(shirt, Paint()..style=PaintingStyle.stroke..strokeWidth=1..color=Colors.white.withValues(alpha:.24));
    final ear = Paint()..color=skin;
    canvas.drawOval(Rect.fromCenter(center:Offset(w*.25,h*.45),width:w*.13,height:h*.19),ear);
    canvas.drawOval(Rect.fromCenter(center:Offset(w*.75,h*.45),width:w*.13,height:h*.19),ear);
    canvas.drawOval(Rect.fromCenter(center:Offset(cx,h*.43),width:w*.47,height:h*.51),Paint()..color=skin);
    final hairPath=Path()..moveTo(w*.265,h*.39)..quadraticBezierTo(w*.20,h*.08,cx,h*.12)..quadraticBezierTo(w*.82,h*.08,w*.735,h*.40)..quadraticBezierTo(cx,h*.27,w*.265,h*.39)..close();
    canvas.drawPath(hairPath,Paint()..color=hair);
    for(var i=0;i<3;i++){final x=w*(.35+i*.15);canvas.drawCircle(Offset(x,h*(.18+rng.next(5)*.008)),w*.055,Paint()..color=hair);}
    final eye=Paint()..color=const Color(0xFF171717);
    final brow=Paint()..color=hair..strokeWidth=w*.035..strokeCap=StrokeCap.round;
    for(final x in [w*.40,w*.60]){
      canvas.drawLine(Offset(x-w*.055,h*.365),Offset(x+w*.045,h*.35),brow);
      canvas.drawOval(Rect.fromCenter(center:Offset(x,h*.405),width:w*.055,height:h*.027),eye);
      canvas.drawCircle(Offset(x+w*.008,h*.398),w*.008,Paint()..color=Colors.white);
    }
    final nose=Paint()..color=skin.withValues(alpha:.72)..strokeWidth=w*.025..strokeCap=StrokeCap.round;
    canvas.drawLine(Offset(cx,h*.42),Offset(cx-w*.025,h*.52),nose);
    canvas.drawLine(Offset(cx-w*.025,h*.52),Offset(cx+w*.025,h*.52),nose);
    canvas.drawLine(Offset(w*.445,h*.585),Offset(w*.555,h*.585),Paint()..color=const Color(0xFF5C2925)..strokeWidth=w*.025..strokeCap=StrokeCap.round);
    canvas.drawCircle(Offset(w*.18,h*.17),w*.045,Paint()..color=Colors.white.withValues(alpha:.08));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _PortraitPainter old) => old.seed != seed || old.jersey != jersey;
}

class _PortraitRandom {
  int state;
  _PortraitRandom(this.state);
  int next(int max) { state=(1664525*state+1013904223)&0x7fffffff; return state%max; }
}
