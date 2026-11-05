import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:just_audio/just_audio.dart';
import 'package:adhan/adhan.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;
import 'dart:convert';

final FlutterLocalNotificationsPlugin notificationsPlugin = FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tzdata.initializeTimeZones();
  const androidInit = AndroidInitializationSettings('@mipmap/launcher_icon');
  await notificationsPlugin.initialize(const InitializationSettings(android: androidInit));
  runApp(SukoonApp());
}

Future<void> schedulePrayerNotification(DateTime time, String name, int id) async {
  if (time.isBefore(DateTime.now())) return;
  await notificationsPlugin.zonedSchedule(
    id,
    'حان وقت $name 🕌',
    'قومي لصلاة $name',
    tz.TZDateTime.from(time, tz.local),
    const NotificationDetails(android: AndroidNotificationDetails('prayer_channel', 'مواقيت الصلاة', importance: Importance.max, priority: Priority.high)),
    androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
  );
}

class SukoonApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) => MaterialApp(debugShowCheckedModeBanner: false, home: HomeScreen());
}

class HomeScreen extends StatefulWidget { @override _HomeScreenState createState() => _HomeScreenState(); }
class _HomeScreenState extends State<HomeScreen> {
  int _index=0;
  final screens=[TasksPage(), QuranPage(), PrayerPage(), AzkarPage(), SalatGuidePage()];
  @override Widget build(BuildContext context){
    return Scaffold(
      body: screens[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index, onTap: (i){ setState((){ _index=i; }); },
        type: BottomNavigationBarType.fixed, selectedItemColor: const Color(0xFF4A6741),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.check_circle), label: 'مهامي'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'القرآن'),
          BottomNavigationBarItem(icon: Icon(Icons.mosque), label: 'الصلاة'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'أذكاري'),
          BottomNavigationBarItem(icon: Icon(Icons.school), label: 'تعلمي'),
        ]),
    );
  }
}

class TasksPage extends StatefulWidget { @override _TasksPageState createState() => _TasksPageState(); }
class _TasksPageState extends State<TasksPage> {
  List tasks=[]; TextEditingController c=TextEditingController();
  @override void initState(){ super.initState(); load(); }
  load() async { var p=await SharedPreferences.getInstance(); setState((){ tasks=jsonDecode(p.getString('tasks')??'[]'); }); }
  save() async { var p=await SharedPreferences.getInstance(); p.setString('tasks', jsonEncode(tasks)); }
  @override Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(title: const Text('اكتبي مهامك'), backgroundColor: const Color(0xFF4A6741)),
      body: Column(children:[
        Padding(padding: const EdgeInsets.all(12), child: Row(children:[Expanded(child: TextField(controller:c, decoration: const InputDecoration(hintText:'مهمة جديدة...', border: OutlineInputBorder()))), const SizedBox(width:8), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4A6741)), onPressed: (){ if(c.text.isNotEmpty){ setState((){ tasks.add({'title':c.text,'done':false}); }); c.clear(); save(); } }, child: const Text('اضافة'))])),
        Expanded(child: ListView.builder(itemCount: tasks.length, itemBuilder: (ctx,i)=> Card(child: CheckboxListTile(value: tasks[i]['done'], title: Text(tasks[i]['title']), onChanged: (v){ setState((){ tasks[i]['done']=v; }); save(); }, secondary: IconButton(icon: const Icon(Icons.delete), onPressed: (){ setState((){ tasks.removeAt(i); }); save(); }))))
      ]),
    );
  }
}

class QuranPage extends StatefulWidget { @override _QuranPageState createState() => _QuranPageState(); }
class _QuranPageState extends State<QuranPage> {
  final player=AudioPlayer(); int? playing; String selectedReciter='mishaari_raashid_al-afasy';
  final reciters={'mishaari_raashid_al-afasy':'مشاري العفاسي','maher_al_muaiqly':'ماهر المعيقلي','abdurrahmaan_as_sudais':'السديس','sa3d_al-ghaamidi':'سعد الغامدي'};
  final surahs=[{'id':'001','name':'الفاتحة'},{'id':'002','name':'البقرة'},{'id':'018','name':'الكهف'},{'id':'036','name':'يس'},{'id':'055','name':'الرحمن'},{'id':'056','name':'الواقعة'},{'id':'067','name':'الملك'},{'id':'112','name':'الإخلاص'},{'id':'113','name':'الفلق'},{'id':'114','name':'الناس'}];
  @override Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(title: const Text('القرآن - 4 شيوخ'), backgroundColor: const Color(0xFF4A6741)),
      body: Column(children:[
        Padding(padding: const EdgeInsets.all(8), child: DropdownButtonFormField<String>(value: selectedReciter, decoration: const InputDecoration(labelText:'اختاري القارئ', border: OutlineInputBorder()), items: reciters.entries.map((e)=> DropdownMenuItem(value:e.key, child: Text(e.value))).toList(), onChanged: (v){ setState((){ selectedReciter=v!; }); player.stop(); playing=null; })),
        Expanded(child: ListView.builder(itemCount: surahs.length, itemBuilder: (ctx,i){
          bool isPlay=playing==i;
          return Card(child: ListTile(leading: CircleAvatar(backgroundColor: const Color(0xFF4A6741), child: Text(surahs[i]['id']!, style: const TextStyle(color:Colors.white, fontSize:10))), title: Text(surahs[i]['name']!, style: const TextStyle(fontWeight: FontWeight.bold)), trailing: Icon(isPlay?Icons.stop_circle:Icons.play_circle_fill, size:38, color: const Color(0xFF4A6741)),
            onTap: () async { try{ if(isPlay){ await player.stop(); setState((){ playing=null; }); } else{ String url='https://download.quranicaudio.com/quran/$selectedReciter/${surahs[i]['id']}.mp3'; await player.setUrl(url); await player.play(); setState((){ playing=i; }); } }catch(e){ ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('شغلي النت'))); } }));
        }))
      ]),
    );
  }
}

class PrayerPage extends StatefulWidget { @override _PrayerPageState createState() => _PrayerPageState(); }
class _PrayerPageState extends State<PrayerPage> {
  PrayerTimes? times; String status='جاري التحديد...'; String next='';
  @override void initState(){ super.initState(); getTimes(); }
  getTimes() async {
    try{
      LocationPermission perm = await Geolocator.requestPermission();
      Position pos=await Geolocator.getCurrentPosition();
      final coords=Coordinates(pos.latitude, pos.longitude);
      final params=CalculationMethod.egyptian.getParameters(); params.madhab=Madhab.shafi;
      final t=PrayerTimes(coords, DateComponents.from(DateTime.now()), params);
      await notificationsPlugin.cancelAll();
      await schedulePrayerNotification(t.fajr, 'الفجر', 1);
      await schedulePrayerNotification(t.dhuhr, 'الظهر', 2);
      await schedulePrayerNotification(t.asr, 'العصر', 3);
      await schedulePrayerNotification(t.maghrib, 'المغرب', 4);
      await schedulePrayerNotification(t.isha, 'العشاء', 5);
      DateTime now=DateTime.now();
      String n='القادمة';
      if(now.isBefore(t.fajr)) n='القادمة: الفجر';
      else if(now.isBefore(t.dhuhr)) n='القادمة: الظهر';
      else if(now.isBefore(t.asr)) n='القادمة: العصر';
      else if(now.isBefore(t.maghrib)) n='القادمة: المغرب';
      else if(now.isBefore(t.isha)) n='القادمة: العشاء';
      else n='القادمة: فجر الغد';
      setState((){ times=t; status='درين - نبروه 📍 تم تفعيل الإشعارات'; next=n; });
    }catch(e){ setState((){ status='شغلي الـ GPS والنت: $e'; }); }
  }
  @override Widget build(BuildContext context){
    if(times==null) return Scaffold(appBar: AppBar(title: const Text('الصلاة'), backgroundColor: const Color(0xFF4A6741)), body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children:[const CircularProgressIndicator(), const SizedBox(height:12), Text(status, textAlign: TextAlign.center), ElevatedButton(onPressed: getTimes, child: const Text('إعادة المحاولة'))])));
    return Scaffold(appBar: AppBar(title: const Text('مواقيت الصلاة'), backgroundColor: const Color(0xFF4A6741), actions:[IconButton(icon:const Icon(Icons.refresh), onPressed: getTimes)]),
      body: Padding(padding: const EdgeInsets.all(16), child: Column(children:[
        Card(color: const Color(0xFF4A6741), child: Padding(padding: const EdgeInsets.all(16), child: Column(children:[Text(status, style: const TextStyle(color:Colors.white)), const SizedBox(height:8), Text(next, style: const TextStyle(color:Colors.white, fontSize:20, fontWeight: FontWeight.bold)), const SizedBox(height:8), const Text('سيصلك إشعار عند كل صلاة', style: TextStyle(color:Colors.white70))]))),
        const SizedBox(height:12),
        Expanded(child: ListView(children:[for(var e in [['الفجر', times!.fajr], ['الظهر', times!.dhuhr], ['العصر', times!.asr], ['المغرب', times!.maghrib], ['العشاء', times!.isha]]) Card(child: ListTile(title: Text(e[0] as String, style: const TextStyle(fontWeight: FontWeight.bold)), trailing: Text(DateFormat.jm().format(e[1] as DateTime), style: const TextStyle(fontSize:18))))]))
      ])),
    );
  }
}

class AzkarPage extends StatefulWidget { @override _AzkarPageState createState() => _AzkarPageState(); }
class _AzkarPageState extends State<AzkarPage> {
  int cat=0; final cats=['الصباح','المساء','النوم','بعد الصلاة'];
  final data={
    'الصباح':[{'text':'آية الكرسي','count':1},{'text':'أصبحنا وأصبح الملك لله','count':1}],
    'المساء':[{'text':'آية الكرسي','count':1},{'text':'أمسينا وأمسى الملك لله','count':1}],
    'النوم':[{'text':'باسمك ربي وضعت جنبي','count':1}],
    'بعد الصلاة':[{'text':'أستغفر الله 3','count':1}]
  };
  Map<String,int> counters={};
  @override Widget build(BuildContext context){
    String current=cats[cat]; var list=data[current]!;
    return Scaffold(appBar: AppBar(title: const Text('الأذكار'), backgroundColor: const Color(0xFF4A6741)),
      body: Column(children:[
        SizedBox(height:50, child: ListView.builder(scrollDirection: Axis.horizontal, itemCount: cats.length, itemBuilder: (ctx,i)=> Padding(padding: const EdgeInsets.all(6), child: ChoiceChip(label: Text(cats[i]), selected: cat==i, onSelected: (v){ setState((){ cat=i; }); })))),
        Expanded(child: ListView.builder(itemCount: list.length, itemBuilder: (ctx,i){
          String key='$current-$i'; int c=counters[key]??0; int target=list[i]['count'];
          return Card(margin: const EdgeInsets.all(8), child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[Text(list[i]['text'], style: const TextStyle(fontSize:17)), const SizedBox(height:10), Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children:[Text('$c / $target'), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4A6741)), onPressed: (){ setState((){ counters[key]=c+1; }); }, child: const Text('تسبيح'))])])));
        }))
      ]),
    );
  }
}

class SalatGuidePage extends StatelessWidget {
  @override Widget build(BuildContext context){
    return Scaffold(appBar: AppBar(title: const Text('تعلمي الصلاة'), backgroundColor: const Color(0xFF4A6741)),
      body: ListView(children: const [
        ExpansionTile(title: Text('الوضوء'), children:[ListTile(title: Text('النية - بسم الله - غسل الكفين 3 - المضمضة 3 - الاستنشاق 3 - الوجه 3 - اليدين للمرفقين - مسح الرأس - الأذنين - الرجلين للكعبين'))]),
        ExpansionTile(title: Text('الصلاة'), children:[ListTile(title: Text('الله أكبر - الفاتحة - سورة - سبحان ربي العظيم 3 - سمع الله لمن حمده - سبحان ربي الأعلى 3 - التشهد - التسليم'))]),
      ]),
    );
  }
}