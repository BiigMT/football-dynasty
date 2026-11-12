import 'package:flutter/material.dart';
import '../domain/models.dart';
import '../state/game_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/player_avatar_painter.dart';
import '../widgets/common.dart';
import 'player_screen.dart';

class SquadScreen extends StatefulWidget {
  const SquadScreen({super.key});
  @override State<SquadScreen> createState()=>_SquadScreenState();
}

class _SquadScreenState extends State<SquadScreen> {
  PositionGroup? filter;
  String sort='Rating';

  @override
  Widget build(BuildContext context) {
    final controller=GameScope.of(context);
    final career=controller.career!;
    final tactics=career.userClub.tactics;
    var players=career.userSquad.where((p)=>filter==null||p.group==filter).toList();
    switch(sort){
      case 'Age': players.sort((a,b)=>a.age.compareTo(b.age)); break;
      case 'Position': players.sort((a,b)=>allPositions.indexOf(a.position).compareTo(allPositions.indexOf(b.position))); break;
      case 'Fitness': players.sort((a,b)=>b.fitness.compareTo(a.fitness)); break;
      default: players.sort((a,b)=>b.rating.compareTo(a.rating));
    }

    return Scaffold(
      backgroundColor:AppTheme.navy,
      appBar:AppBar(
        title:const Text('SQUAD & TACTICS',style:TextStyle(fontSize:16,letterSpacing:1.1,fontWeight:FontWeight.w900)),
        actions:[Padding(padding:const EdgeInsets.only(right:10),child:DropdownButtonHideUnderline(
          child:DropdownButton<int>(
            value:tactics.mentality.clamp(0,2).toInt(),dropdownColor:AppTheme.panel,
            icon:const Icon(Icons.keyboard_arrow_down,color:AppTheme.green),
            style:const TextStyle(color:AppTheme.green,fontWeight:FontWeight.w800,fontSize:11),
            items:const [
              DropdownMenuItem(value:0,child:Text('DEFENSIVE')),
              DropdownMenuItem(value:1,child:Text('BALANCED')),
              DropdownMenuItem(value:2,child:Text('ATTACKING')),
            ],
            onChanged:(value){if(value!=null){controller.setTactics(tactics.copy()..mentality=value);}},
          ),
        ))],
      ),
      body:Column(children:[
        Padding(padding:const EdgeInsets.fromLTRB(14,8,14,8),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          const Text('FIRST TEAM',style:TextStyle(color:AppTheme.green,fontSize:10,fontWeight:FontWeight.w900,letterSpacing:1.8)),
          const SizedBox(height:4),
          Text('${career.userSquad.length} PLAYERS  •  ${fmtMoney(career.wageBill(career.userClubId))}/WK WAGES',style:const TextStyle(color:Colors.white60,fontSize:11,fontWeight:FontWeight.w600)),
          const SizedBox(height:11),
          SingleChildScrollView(scrollDirection:Axis.horizontal,child:Row(children:[
            _chip('ALL',filter==null,()=>setState(()=>filter=null)),
            _chip('GK',filter==PositionGroup.gk,()=>setState(()=>filter=PositionGroup.gk)),
            _chip('DEF',filter==PositionGroup.def,()=>setState(()=>filter=PositionGroup.def)),
            _chip('MID',filter==PositionGroup.mid,()=>setState(()=>filter=PositionGroup.mid)),
            _chip('ATT',filter==PositionGroup.att,()=>setState(()=>filter=PositionGroup.att)),
          ])),
          const SizedBox(height:7),
          SingleChildScrollView(scrollDirection:Axis.horizontal,child:Row(children:[
            const Padding(padding:EdgeInsets.only(right:7),child:Text('SORT',style:TextStyle(color:Colors.white38,fontSize:9,fontWeight:FontWeight.w900))),
            for(final value in ['Rating','Age','Position','Fitness']) _chip(value.toUpperCase(),sort==value,()=>setState(()=>sort=value)),
          ])),
        ])),
        Expanded(child:players.isEmpty
          ? const Center(child:Text('No players in this group',style:TextStyle(color:Colors.white54)))
          : ListView.separated(
            padding:const EdgeInsets.fromLTRB(14,3,14,18),itemCount:players.length,
            separatorBuilder:(_,__)=>const SizedBox(height:9),
            itemBuilder:(context,index){
              final p=players[index];
              final ratingColor=p.rating>=80?AppTheme.gold:AppTheme.green;
              final fitness=p.fitness.clamp(0,100);
              final status=p.injuredMatches>0?'INJURED • ${p.injuredMatches} MATCHES':p.suspendedMatches>0?'SUSPENDED':p.contractYears<=1?'CONTRACT ENDING':'AVAILABLE';
              return Material(color:Colors.transparent,child:InkWell(
                borderRadius:BorderRadius.circular(14),
                onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>PlayerScreen(playerId:p.id))),
                child:Ink(
                  padding:const EdgeInsets.all(11),
                  decoration:BoxDecoration(
                    gradient:const LinearGradient(begin:Alignment.topLeft,end:Alignment.bottomRight,colors:[Color(0xFF1B2837),Color(0xFF101923)]),
                    borderRadius:BorderRadius.circular(14),border:Border.all(color:Colors.white.withValues(alpha:.075)),
                  ),
                  child:Row(children:[
                    ProceduralPlayerAvatar(playerName:p.name,jerseyColor:Color(career.userClub.colorValue),size:58),
                    const SizedBox(width:11),
                    Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                      Row(children:[
                        Container(padding:const EdgeInsets.symmetric(horizontal:6,vertical:3),decoration:BoxDecoration(color:AppTheme.green.withValues(alpha:.13),borderRadius:BorderRadius.circular(4)),
                          child:Text(p.position,style:const TextStyle(color:AppTheme.green,fontSize:10,fontWeight:FontWeight.w900))),
                        const SizedBox(width:7),
                        Expanded(child:Text(p.name,maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w900,fontSize:13))),
                      ]),
                      const SizedBox(height:6),
                      Text('AGE ${p.age}  •  POT ${p.potential}',style:const TextStyle(color:Colors.white54,fontSize:9,letterSpacing:.5,fontWeight:FontWeight.w700)),
                      const SizedBox(height:7),
                      ClipRRect(borderRadius:BorderRadius.circular(5),child:LinearProgressIndicator(value:fitness/100,minHeight:5,backgroundColor:Colors.white10,color:fitness>=70?const Color(0xFF42D99A):AppTheme.gold)),
                      const SizedBox(height:4),
                      Row(children:[
                        Text('FITNESS $fitness%',style:const TextStyle(color:Colors.white54,fontSize:9)),
                        const Spacer(),
                        Text(status,style:TextStyle(color:p.isAvailable?Colors.white38:const Color(0xFFFF8A80),fontSize:8,fontWeight:FontWeight.w800)),
                      ]),
                    ])),
                    const SizedBox(width:10),
                    Container(width:43,height:45,alignment:Alignment.center,decoration:BoxDecoration(color:ratingColor.withValues(alpha:.12),borderRadius:BorderRadius.circular(9),border:Border.all(color:ratingColor.withValues(alpha:.7))),
                      child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[
                        Text('${p.rating}',style:TextStyle(color:ratingColor,fontSize:18,fontWeight:FontWeight.w900,height:1)),
                        const SizedBox(height:3),
                        const Text('OVR',style:TextStyle(color:Colors.white54,fontSize:7,fontWeight:FontWeight.w900)),
                      ])),
                  ]),
                ),
              ));
            },
          )),
      ]),
    );
  }

  Widget _chip(String label,bool selected,VoidCallback onTap)=>Padding(
    padding:const EdgeInsets.only(right:6),
    child:ChoiceChip(
      label:Text(label,style:const TextStyle(fontSize:9,fontWeight:FontWeight.w800)),
      selected:selected,onSelected:(_)=>onTap(),visualDensity:VisualDensity.compact,
      padding:const EdgeInsets.symmetric(horizontal:5),
      selectedColor:AppTheme.green.withValues(alpha:.18),backgroundColor:AppTheme.panel,
      side:BorderSide(color:selected?AppTheme.green.withValues(alpha:.55):Colors.white12),
      labelStyle:TextStyle(color:selected?AppTheme.green:Colors.white60),
    ),
  );
}
