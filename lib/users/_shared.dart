import 'dart:math' as math;
import 'package:flutter/material.dart';

class NetImage extends StatelessWidget {
  final String url; final BoxFit fit; final double? targetWidth;
  const NetImage(this.url,{super.key,this.fit=BoxFit.cover,this.targetWidth});
  @override
  Widget build(BuildContext context){
    final mq=MediaQuery.of(context);
    final px=((targetWidth??mq.size.width)*mq.devicePixelRatio).clamp(300,1600).toInt();
    return Image.network(url,fit:fit,cacheWidth:px,filterQuality:FilterQuality.low,
      loadingBuilder:(c,child,p)=>p==null?child:const ColoredBox(
        color: Color(0xFFF2F4F7),
        child: Center(child:SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2))),
      ),
      errorBuilder:(_,__,___)=>const ColoredBox(
        color: Color(0xFFF2F4F7), child: Center(child: Icon(Icons.broken_image_outlined,color: Colors.black26)),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget{
  final String text; const SectionTitle(this.text,{super.key});
  @override Widget build(BuildContext context)=>Padding(
    padding: const EdgeInsets.fromLTRB(16,14,16,8),
    child: Text(text,style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
  );
}

class PrimaryBtn extends StatelessWidget{
  final String text; final VoidCallback? onTap; const PrimaryBtn({super.key,required this.text,this.onTap});
  @override Widget build(BuildContext context){
    final enabled=onTap!=null;
    return Opacity(
      opacity: enabled?1:.5,
      child: InkWell(
        onTap:onTap,
        child: Container(
          height:48, alignment: Alignment.center,
          decoration: BoxDecoration(color: const Color(0xFF0BA5A7), borderRadius: BorderRadius.circular(12)),
          child: Text(text,style: const TextStyle(color: Colors.white,fontWeight: FontWeight.w800)),
        ),
      ),
    );
  }
}

class StepHeader extends StatelessWidget{
  final int currentIndex; const StepHeader({super.key, required this.currentIndex});
  static const steps = [
    ('Pilih Layanan', Icons.healing_outlined),
    ('Jadwal', Icons.event_available_outlined),
    ('Petugas', Icons.badge_outlined),
    ('Ringkasan', Icons.description_outlined),
    ('Feedback', Icons.star_rate_outlined),
  ];
  @override Widget build(BuildContext context){
    final mq=MediaQuery.of(context);
    final safe=math.min(mq.textScaleFactor,1.15);
    return MediaQuery(
      data: mq.copyWith(textScaleFactor:safe),
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
          boxShadow:[BoxShadow(blurRadius:8,offset: const Offset(0,4),color: Colors.black.withOpacity(.05))]),
        padding: const EdgeInsets.all(14),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: List.generate(steps.length,(i){
            final (label,icon)=steps[i]; final active=i<=currentIndex;
            return Padding(
              padding: const EdgeInsets.only(right:12),
              child: Column(children:[
                Container(height:32,width:32,decoration: BoxDecoration(
                  color: active?const Color(0xFFE6FAFA):const Color(0xFFF1F5F9), shape: BoxShape.circle),
                  child: Icon(icon,color: const Color(0xFF088088),size:18)),
                const SizedBox(height:4),
                SizedBox(width:68,child: Text(label,maxLines:2,overflow: TextOverflow.ellipsis,textAlign: TextAlign.center,
                  style: const TextStyle(fontSize:10.5,fontWeight: FontWeight.w600))),
              ]),
            );
          })),
        ),
      ),
    );
  }
}

class ChipLite extends StatelessWidget{
  final String text; const ChipLite(this.text,{super.key});
  @override Widget build(BuildContext context)=>Container(
    padding: const EdgeInsets.symmetric(horizontal:8,vertical:4),
    decoration: BoxDecoration(color: Colors.white,borderRadius: BorderRadius.circular(14)),
    child: Text(text,style: const TextStyle(fontWeight: FontWeight.w700,fontSize:11)),
  );
}
