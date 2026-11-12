from pathlib import Path
import sys
root = Path(sys.argv[1])

def write(path, content):
    target = root / path
    target.parent.mkdir(parents=True, exist_ok=True)
    if target.exists():
        if target.read_text(encoding='utf-8') == content:
            return
        raise SystemExit(f'Refusing to overwrite existing {path}')
    target.write_text(content, encoding='utf-8')

def replace(path, old, new):
    target = root / path
    source = target.read_text(encoding='utf-8')
    if new in source: return
    if old not in source: raise SystemExit(f'Patch anchor missing in {path}')
    target.write_text(source.replace(old, new, 1), encoding='utf-8')

pubspec = root / 'pubspec.yaml'
pubspec_text = pubspec.read_text(encoding='utf-8')
if 'shared_preferences:' not in pubspec_text:
    if '\ndependencies:\n' not in pubspec_text:
        raise SystemExit('Could not find dependencies section in pubspec.yaml')
    pubspec_text = pubspec_text.replace('\ndependencies:\n', '\ndependencies:\n  shared_preferences: ^2.5.3\n', 1)
    pubspec.write_text(pubspec_text, encoding='utf-8')

write('lib/domain/player_career.dart', r"""class PlayerCareer {
  String name, nationality, position, club;
  int age, overall, appearances, goals, assists, trainingPoints;
  double lastRating;
  Map<String, int> attributes, focus;
  List<double> recentRatings;

  PlayerCareer({required this.name, required this.nationality, required this.position,
    this.club = 'Kafue FC', this.age = 18, this.overall = 60, this.appearances = 0,
    this.goals = 0, this.assists = 0, this.trainingPoints = 2, this.lastRating = 6.0,
    Map<String,int>? attributes, Map<String,int>? focus, List<double>? recentRatings})
    : attributes = attributes ?? {'Shooting':60,'Passing':58,'Dribbling':61,'Defense':35,'Speed':64,'Stamina':59},
      focus = focus ?? {'Shooting':0,'Passing':0,'Dribbling':0,'Defense':0,'Speed':0,'Stamina':0},
      recentRatings = recentRatings ?? [];

  Map<String,dynamic> toJson() => {'name':name,'nationality':nationality,'position':position,
    'club':club,'age':age,'overall':overall,'appearances':appearances,'goals':goals,
    'assists':assists,'trainingPoints':trainingPoints,'lastRating':lastRating,
    'attributes':attributes,'focus':focus,'recentRatings':recentRatings};

  factory PlayerCareer.fromJson(Map<String,dynamic> j) => PlayerCareer(
    name:j['name'] as String? ?? 'New Player', nationality:j['nationality'] as String? ?? 'Zambia',
    position:j['position'] as String? ?? 'ST', club:j['club'] as String? ?? 'Kafue FC',
    age:j['age'] as int? ?? 18, overall:j['overall'] as int? ?? 60,
    appearances:j['appearances'] as int? ?? 0, goals:j['goals'] as int? ?? 0,
    assists:j['assists'] as int? ?? 0, trainingPoints:j['trainingPoints'] as int? ?? 2,
    lastRating:(j['lastRating'] as num?)?.toDouble() ?? 6.0,
    attributes:Map<String,int>.from(j['attributes'] as Map? ?? const {}),
    focus:Map<String,int>.from(j['focus'] as Map? ?? const {}),
    recentRatings:(j['recentRatings'] as List? ?? const []).map((v)=>(v as num).toDouble()).toList());
}
""")

write('lib/domain/player_simulation_engine.dart', r"""import 'dart:math';
import 'dart:isolate';

/// Runs matchday calculations in a worker isolate, keeping the UI isolate responsive.
class PlayerSimulationEngine {
  Future<Map<String,dynamic>> simulate(Map<String,dynamic> player) =>
      Isolate.run(() => _simulate(Map<String,dynamic>.from(player)));
}

Map<String,dynamic> _simulate(Map<String,dynamic> data) {
  final stats = Map<String,int>.from(data['attributes'] as Map);
  final focus = Map<String,int>.from(data['focus'] as Map);
  final rng = Random(DateTime.now().microsecondsSinceEpoch);
  final pos = data['position'] as String? ?? 'ST';
  final shooting = stats['Shooting'] ?? 60;
  final passing = stats['Passing'] ?? 58;
  final rating = (5.8 + rng.nextDouble()*1.8 +
    ((pos == 'ST' || pos == 'CF') ? (shooting-60)/100 : (passing-60)/120)).clamp(4.0,10.0).toDouble();
  final goals = (pos == 'ST' || pos == 'CF') && rng.nextDouble() < shooting/180 ? 1 : 0;
  final assists = rng.nextDouble() < passing/240 ? 1 : 0;
  for (final item in focus.entries) {
    final value = stats[item.key] ?? 50;
    if (item.value > 0 && value < 99 && rng.nextDouble() < item.value*.18) stats[item.key] = value+1;
  }
  final history = (data['recentRatings'] as List? ?? const []).map((v)=>(v as num).toDouble()).toList();
  history.add(double.parse(rating.toStringAsFixed(1)));
  if (history.length > 5) history.removeAt(0);
  final vals = stats.values.toList();
  data['attributes'] = stats;
  data['overall'] = (vals.reduce((a,b)=>a+b)/vals.length).round();
  data['lastRating'] = double.parse(rating.toStringAsFixed(1));
  data['recentRatings'] = history;
  data['appearances'] = (data['appearances'] as int? ?? 0)+1;
  data['goals'] = (data['goals'] as int? ?? 0)+goals;
  data['assists'] = (data['assists'] as int? ?? 0)+assists;
  data['trainingPoints'] = (data['trainingPoints'] as int? ?? 0)+1;
  data['lastMatchGoals'] = goals;
  data['lastMatchAssists'] = assists;
  return data;
}
""")

write('lib/screens/become_legend_screen.dart', r"""import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/player_career.dart';
import '../domain/player_simulation_engine.dart';

class BecomeLegendScreen extends StatefulWidget {
  const BecomeLegendScreen({super.key});
  @override State<BecomeLegendScreen> createState()=>_BecomeLegendScreenState();
}
class _BecomeLegendScreenState extends State<BecomeLegendScreen> {
  static const saveKey='football_dynasty_bal_save_v1';
  static const cyan=Color(0xFF00F0FF);
  final engine=PlayerSimulationEngine();
  final name=TextEditingController();
  PlayerCareer? player;
  bool loading=true, busy=false;
  String position='ST', nationality='Zambia', report='';

  @override void initState(){super.initState();load();}
  @override void dispose(){name.dispose();super.dispose();}
  Future<void> load() async {
    final prefs=await SharedPreferences.getInstance();
    final raw=prefs.getString(saveKey);
    if(raw!=null){try{player=PlayerCareer.fromJson(jsonDecode(raw) as Map<String,dynamic>);}catch(_){await prefs.remove(saveKey);}}
    if(mounted)setState(()=>loading=false);
  }
  Future<void> save() async {
    if(player==null)return;
    final prefs=await SharedPreferences.getInstance();
    await prefs.setString(saveKey,jsonEncode(player!.toJson()));
  }
  Future<void> createPlayer() async {
    if(name.text.trim().isEmpty)return;
    setState(()=>player=PlayerCareer(name:name.text.trim(),nationality:nationality,position:position));
    await save();
  }
  void adjust(String key,int delta){
    final p=player!, current=p.focus[key]??0;
    if(delta>0 && p.trainingPoints>0 && current<4){p.focus[key]=current+1;p.trainingPoints--;}
    if(delta<0 && current>0){p.focus[key]=current-1;p.trainingPoints++;}
    setState((){});save();
  }
  Future<void> playMatch() async {
    if(player==null||busy)return;
    setState(()=>busy=true);
    try{
      final result=await engine.simulate(player!.toJson());
      final goals=result['lastMatchGoals'] as int? ?? 0;
      final assists=result['lastMatchAssists'] as int? ?? 0;
      setState((){
        player=PlayerCareer.fromJson(result);
        report='FULL TIME  •  RATING §{player!.lastRating.toStringAsFixed(1)}  •  §{goals} GOALS  •  §{assists} ASSISTS';
      });
      await save();
    }catch(e){setState(()=>report='Simulation error: $e');}
    finally{if(mounted)setState(()=>busy=false);}
  }
  @override Widget build(BuildContext context)=>Scaffold(
    backgroundColor:const Color(0xFF090B0E),
    appBar:AppBar(backgroundColor:const Color(0xFF090B0E),title:const Text('BECOME A LEGEND',style:TextStyle(fontWeight:FontWeight.w900))),
    body:loading?const Center(child:CircularProgressIndicator(color:cyan)):player==null?createView():careerView());

  Widget createView()=>ListView(padding:const EdgeInsets.all(18),children:[
    const Icon(Icons.stadium,size:60,color:cyan),
    const Text('CREATE YOUR PLAYER',textAlign:TextAlign.center,style:TextStyle(fontSize:21,fontWeight:FontWeight.w900)),
    const SizedBox(height:18),
    TextField(controller:name,decoration:const InputDecoration(labelText:'Player name',border:OutlineInputBorder())),
    const SizedBox(height:12),
    DropdownButtonFormField<String>(value:nationality,decoration:const InputDecoration(labelText:'Nationality'),
      items:const ['Zambia','South Africa','Nigeria','Ghana','England','France','Brazil','Argentina'].map((v)=>DropdownMenuItem(value:v,child:Text(v))).toList(),
      onChanged:(v)=>setState(()=>nationality=v??'Zambia')),
    const SizedBox(height:12),
    DropdownButtonFormField<String>(value:position,decoration:const InputDecoration(labelText:'Position'),
      items:const ['ST','CF','CAM','CM','CDM','LW','RW','CB','LB','RB','GK'].map((v)=>DropdownMenuItem(value:v,child:Text(v))).toList(),
      onChanged:(v)=>setState(()=>position=v??'ST')),
    const SizedBox(height:20),
    FilledButton(onPressed:createPlayer,style:FilledButton.styleFrom(backgroundColor:cyan,foregroundColor:Colors.black),
      child:const Text('START PLAYER CAREER')),
  ]);

  Widget careerView(){
    final p=player!;
    return ListView(padding:const EdgeInsets.all(15),children:[
      Container(padding:const EdgeInsets.all(17),decoration:BoxDecoration(
        gradient:const LinearGradient(colors:[Color(0xFF173B49),Color(0xFF111923)]),
        border:Border.all(color:cyan.withOpacity(.4)),borderRadius:BorderRadius.circular(15)),
        child:Row(children:[
          const CircleAvatar(radius:27,backgroundColor:cyan,child:Icon(Icons.person,color:Colors.black,size:30)),
          const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Text(p.name.toUpperCase(),style:const TextStyle(fontSize:18,fontWeight:FontWeight.w900)),
            Text('§{p.club} • §{p.position} • §{p.age} yrs',style:const TextStyle(color:Colors.white70,fontSize:11)),
            Text(p.nationality,style:const TextStyle(color:cyan,fontSize:10)),
          ])),
          Column(children:[const Text('OVR',style:TextStyle(color:Colors.white54,fontSize:10)),
            Text('§{p.overall}',style:const TextStyle(color:cyan,fontSize:29,fontWeight:FontWeight.w900))]),
        ])),
      const SizedBox(height:12),
      Row(children:[metric('APPS','§{p.appearances}'),metric('GOALS','§{p.goals}'),metric('ASSISTS','§{p.assists}'),metric('RATING',p.lastRating.toStringAsFixed(1))]),
      const SizedBox(height:18),heading('PLAYER ATTRIBUTES'),
      for(final item in p.attributes.entries) Padding(padding:const EdgeInsets.symmetric(vertical:5),child:Row(children:[
        SizedBox(width:85,child:Text(item.key,style:const TextStyle(fontSize:11,color:Colors.white70))),
        Expanded(child:LinearProgressIndicator(value:item.value/99,minHeight:6,backgroundColor:Colors.white10,color:colorFor(item.value))),
        const SizedBox(width:8),Text('§{item.value}',style:TextStyle(color:colorFor(item.value),fontWeight:FontWeight.bold)),
      ])),
      const SizedBox(height:17),heading('TRAINING FOCUS  •  §{p.trainingPoints} POINTS AVAILABLE'),
      for(final item in p.focus.entries) Padding(padding:const EdgeInsets.symmetric(vertical:3),child:Row(children:[
        Expanded(child:Text(item.key,style:const TextStyle(fontSize:12))),
        for(var i=0;i<4;i++)Container(width:11,height:11,margin:const EdgeInsets.only(right:3),decoration:BoxDecoration(
          color:i<item.value?cyan:Colors.white10,borderRadius:BorderRadius.circular(2))),
        IconButton(visualDensity:VisualDensity.compact,onPressed:item.value>0?()=>adjust(item.key,-1):null,icon:const Icon(Icons.remove_circle_outline,size:18)),
        Text('§{item.value}'),
        IconButton(visualDensity:VisualDensity.compact,onPressed:p.trainingPoints>0&&item.value<4?()=>adjust(item.key,1):null,
          icon:const Icon(Icons.add_circle_outline,size:18,color:cyan)),
      ])),
      const SizedBox(height:17),heading('RECENT FORM  •  LAST 5 MATCHES'),
      Wrap(spacing:7,children:p.recentRatings.map((v)=>Chip(label:Text(v.toStringAsFixed(1)),backgroundColor:cyan.withOpacity(.12))).toList()),
      if(report.isNotEmpty)Padding(padding:const EdgeInsets.symmetric(vertical:12),child:Text(report,style:const TextStyle(color:cyan,fontWeight:FontWeight.bold))),
      SizedBox(height:50,child:FilledButton.icon(onPressed:busy?null:playMatch,
        style:FilledButton.styleFrom(backgroundColor:cyan,foregroundColor:Colors.black),
        icon:busy?const SizedBox(width:16,height:16,child:CircularProgressIndicator(strokeWidth:2,color:Colors.black)):const Icon(Icons.sports_soccer),
        label:Text(busy?'SIMULATING…':'PLAY NEXT MATCHDAY'))),
      const SizedBox(height:8),
      const Text('This is a separate player-career save. Manager Career progress is not changed.',textAlign:TextAlign.center,
        style:TextStyle(color:Colors.white38,fontSize:10)),
    ]);
  }
  Widget metric(String label,String value)=>Expanded(child:Container(margin:const EdgeInsets.only(right:5),padding:const EdgeInsets.all(10),
    decoration:BoxDecoration(color:Colors.white.withOpacity(.05),borderRadius:BorderRadius.circular(9)),
    child:Column(children:[Text(value,style:const TextStyle(color:cyan,fontSize:17,fontWeight:FontWeight.w900)),
      Text(label,style:const TextStyle(color:Colors.white54,fontSize:8))])));
  Widget heading(String title)=>Text(title,style:const TextStyle(fontSize:12,fontWeight:FontWeight.w900,letterSpacing:.6));
  Color colorFor(int v)=>v>=85?Colors.redAccent:v>=80?Colors.orange:v>=75?Colors.amber:v>=70?Colors.lightGreen:cyan;
}
""".replace('§{','${'))

replace('lib/screens/dashboard_screen.dart',
  "import 'national_team_screen.dart';",
  "import 'national_team_screen.dart';\nimport 'become_legend_screen.dart';")
replace('lib/screens/dashboard_screen.dart',
  "            _ActionTile(icon: Icons.flag_rounded, title: 'NATIONAL TEAM', subtitle: 'Call-ups & selection', onTap: () => _open(context, const NationalTeamScreen())),",
  "            _ActionTile(icon: Icons.flag_rounded, title: 'NATIONAL TEAM', subtitle: 'Call-ups & selection', onTap: () => _open(context, const NationalTeamScreen())),\n            _ActionTile(icon: Icons.person_pin_circle_rounded, title: 'BECOME A LEGEND', subtitle: 'Separate player career — create your own football journey', onTap: () => _open(context, const BecomeLegendScreen())),")
print('Separate Become a Legend mode patch applied.')
