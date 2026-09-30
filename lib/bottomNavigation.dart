import 'package:flutter/material.dart';
import 'util.dart';

class ModernBottomNavigation extends StatelessWidget {
  const ModernBottomNavigation({super.key, required this.currentIndex, required this.onChanged, required this.onSettings});
  final int currentIndex; final ValueChanged<int> onChanged; final VoidCallback onSettings;
  @override Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BottomAppBar(height: 88, color: theme.scaffoldBackgroundColor, elevation: 18, shadowColor: Colors.black26, notchMargin: 10, shape: const CircularNotchedRectangle(), child: SafeArea(top:false, minimum: const EdgeInsets.only(bottom:5), child: Row(children: [
      Expanded(child: _NavItem(icon: Icons.home_rounded, label: tr('Home'), selected: currentIndex==0, onTap:()=>onChanged(0))),
      Expanded(child: _NavItem(icon: Icons.checklist_rounded, label: tr('Tasks'), selected: currentIndex==1, onTap:()=>onChanged(1))),
      const SizedBox(width:72),
      Expanded(child: _NavItem(icon: Icons.sticky_note_2_rounded, label: tr('Notes'), selected: currentIndex==2, onTap:()=>onChanged(2))),
      Expanded(child: _NavItem(icon: Icons.settings_rounded, label: tr('Settings'), selected:false, onTap:onSettings)),
    ])));
  }
}
class _NavItem extends StatelessWidget { const _NavItem({required this.icon,required this.label,required this.selected,required this.onTap}); final IconData icon; final String label; final bool selected; final VoidCallback onTap; @override Widget build(BuildContext context){final color=selected?CustomColors.primary:CustomColors.muted; return InkWell(onTap:onTap,borderRadius:BorderRadius.circular(18),child:Padding(padding:const EdgeInsets.symmetric(horizontal:3,vertical:5),child:Column(mainAxisSize:MainAxisSize.min,children:[AnimatedContainer(duration:const Duration(milliseconds:180),width:38,height:30,decoration:BoxDecoration(color:selected?CustomColors.primary.withOpacity(.10):Colors.transparent,borderRadius:BorderRadius.circular(11)),child:Icon(icon,size:21,color:color)),const SizedBox(height:1),Text(label,maxLines:1,overflow:TextOverflow.ellipsis,style:TextStyle(fontSize:9,fontWeight:FontWeight.w800,color:color))])));}}
