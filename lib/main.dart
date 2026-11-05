import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:just_audio/just_audio.dart';
import 'package:adhan/adhan.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';

final FlutterLocalNotificationsPlugin notificationsPlugin = FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tzdata.initializeTimeZones();
  const androidInit = AndroidInitializationSettings('@mipmap/launcher_icon');
  await notificationsPlugin.initialize(InitializationSettings(android: androidInit));
  runApp(SukoonApp());
}

Future<void> schedulePrayerNotification(DateTime time, String name, int id) async {
  if (time.isBefore(DateTime.now())) return;
  await notificationsPlugin.zonedSchedule(
    id,
    'حان وقت $name 🕌',
    'قومي لصلاة $name - درين - نبروه',
    tz.TZDateTime.from(time, tz.local),
    NotificationDetails(android: AndroidNotificationDetails('prayer_channel', 'مواقيت الصلاة', importance: Importance.max, priority: Priority.high)),
    androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
  );
}

class SukoonApp extends StatelessWidget {
  @override Widget build(BuildContext context) => MaterialApp(debugShowCheckedModeBanner: false, home: HomeScreen());
}

class HomeScreen extends StatefulWidget { @override _HomeScreenState createState() => _HomeScreenState(); }
class _HomeScreenState extends State<HomeScreen> {
  int _index=0;
  final screens=[TasksPage(), QuranPage(), PrayerPage(), AzkarPage(), SalatGuidePage()];
  @override Widget build(BuildContext context){
    return Scaffold(
      body: screens[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index, onTap: (i)=> setState(()=> _index=i),
        type: BottomNavigationBarType.fixed, selectedItemColor: Color(0xFF4A6741),
        items:[
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
  load() async { var p=await SharedPreferences.getInstance(); setState(()=> tasks=jsonDecode(p.getString('tasks')??'[]')); }
  save() async { var p=await SharedPreferences.getInstance(); p.setString('tasks', jsonEncode(tasks)); }
  @override Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(title: Text('اكتبي مهامك'), backgroundColor: Color(0xFF4A6741)),
      body: Column(children:[
        Padding(padding: EdgeInsets.all(12), child: Row(children:[Expanded(child: TextField(controller:c, decoration: InputDecoration(hintText:'مهمة جديدة...', border: OutlineInputBorder()))), SizedBox(width:8), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF4A6741)), onPressed: (){ if(c.text.isNotEmpty){ setState(()=> tasks.add({'title':c.text,'done':false})); c.clear(); save(); } }, child: Text('اضافة'))])),
        Expanded(child: ListView.builder(itemCount: tasks.length, itemBuilder: (ctx,i)=> Card(child: CheckboxListTile(value: tasks[i]['done'], title: Text(tasks[i]['title']), onChanged: (v){ setState(()=> tasks[i]['done']=v); save(); }, secondary: IconButton(icon: Icon(Icons.delete), onPressed: (){ setState(()=> tasks.removeAt(i)); save(); }))))
      ]),
    );
  }
}

class QuranPage extends StatefulWidget { @override _QuranPageState createState() => _QuranPageState(); }
class _QuranPageState extends State<QuranPage> {
  final player=AudioPlayer(); int? playing; String selectedReciter='mishaari_raashid_al-afasy';
  final reciters={'mishaari_raashid_al-afasy':'مشاري العفاسي - عذب','maher_al_muaiqly':'ماهر المعيقلي - خاشع','abdurrahmaan_as_sudais':'السديس - مريح','sa3d_al-ghaamidi':'سعد الغامدي - جميل'};
  final surahs=[{'id':'001','name':'الفاتحة'},{'id':'002','name':'البقرة'},{'id':'018','name':'الكهف'},{'id':'036','name':'يس'},{'id':'055','name':'الرحمن'},{'id':'056','name':'الواقعة'},{'id':'067','name':'الملك'},{'id':'112','name':'الإخلاص'},{'id':'113','name':'الفلق'},{'id':'114','name':'الناس'}];
  @override Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(title: Text('القرآن - 4 شيوخ عذبة'), backgroundColor: Color(0xFF4A6741)),
      body: Column(children:[
        Padding(padding: EdgeInsets.all(8), child: DropdownButtonFormField<String>(value: selectedReciter, decoration: InputDecoration(labelText:'اختاري القارئ', border: OutlineInputBorder()), items: reciters.entries.map((e)=> DropdownMenuItem(value:e.key, child: Text(e.value))).toList(), onChanged: (v){ setState(()=> selectedReciter=v!); player.stop(); playing=null; })),
        Expanded(child: ListView.builder(itemCount: surahs.length, itemBuilder: (ctx,i){
          bool isPlay=playing==i;
          return Card(child: ListTile(leading: CircleAvatar(backgroundColor: Color(0xFF4A6741), child: Text(surahs[i]['id']!, style:TextStyle(color:Colors.white, fontSize:10))), title: Text(surahs[i]['name']!, style: TextStyle(fontWeight: FontWeight.bold)), subtitle: Text(reciters[selectedReciter]!), trailing: Icon(isPlay?Icons.stop_circle:Icons.play_circle_fill, size:38, color: Color(0xFF4A6741)),
            onTap: () async { try{ if(isPlay){ await player.stop(); setState(()=> playing=null); } else{ String url='https://download.quranicaudio.com/quran/$selectedReciter/${surahs[i]['id']}.mp3'; await player.setUrl(url); await player.play(); setState(()=> playing=i); } }catch(e){ ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('شغلي النت'))); } }));
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
      await Permission.notification.request();
      await Permission.location.request();
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
      DateTime now=DateTime.now(); String n= now.isBefore(t.fajr)?'القادمة: الفجر': now.isBefore(t.dhuhr)?'القادمة: الظهر': now.isBefore(t.asr)?'القادمة: العصر': now.isBefore(t.maghrib)?'القادمة: المغرب': now.isBefore(t.isha)?'القادمة: العشاء':'القادمة: فجر الغد';
      setState(()=> {times=t, status='درين - نبروه 📍 تم تفعيل الإشعارات', next=n});
    }catch(e){ setState(()=> status='شغلي الـ GPS والنت: $e'); }
  }
  @override Widget build(BuildContext context){
    if(times==null) return Scaffold(appBar: AppBar(title: Text('الصلاة'), backgroundColor: Color(0xFF4A6741)), body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children:[CircularProgressIndicator(), SizedBox(height:12), Text(status, textAlign: TextAlign.center), ElevatedButton(onPressed: getTimes, child: Text('إعادة المحاولة'))])));
    return Scaffold(appBar: AppBar(title: Text('مواقيت الصلاة'), backgroundColor: Color(0xFF4A6741), actions:[IconButton(icon:Icon(Icons.refresh), onPressed: getTimes)]),
      body: Padding(padding: EdgeInsets.all(16), child: Column(children:[
        Card(color: Color(0xFF4A6741), child: Padding(padding: EdgeInsets.all(16), child: Column(children:[Text(status, style: TextStyle(color:Colors.white)), SizedBox(height:8), Text(next, style: TextStyle(color:Colors.white, fontSize:20, fontWeight: FontWeight.bold)), SizedBox(height:8), Text('سيصلك إشعار عند كل صلاة', style: TextStyle(color:Colors.white70))]))),
        SizedBox(height:12),
        Expanded(child: ListView(children:[for(var e in [['الفجر', times!.fajr], ['الظهر', times!.dhuhr], ['العصر', times!.asr], ['المغرب', times!.maghrib], ['العشاء', times!.isha]]) Card(child: ListTile(title: Text(e[0] as String, style: TextStyle(fontWeight: FontWeight.bold)), trailing: Text(DateFormat.jm().format(e[1] as DateTime), style: TextStyle(fontSize:18))))]))
      ])),
    );
  }
}

class AzkarPage extends StatefulWidget { @override _AzkarPageState createState() => _AzkarPageState(); }
class _AzkarPageState extends State<AzkarPage> {
  int cat=0; final cats=['الصباح','المساء','النوم','بعد الصلاة'];
  final data={
    'الصباح':[
      {'text':'اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ ۚ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ ۚ لَّهُ مَا فِي السَّمَاوَاتِ وَمَا فِي الْأَرْضِ ۗ مَن ذَا الَّذِي يَشْفَعُ عِندَهُ إِلَّا بِإِذْنِهِ ۚ يَعْلَمُ مَا بَيْنَ أَيْدِيهِمْ وَمَا خَلْفَهُمْ ۖ وَلَا يُحِيطُونَ بِشَيْءٍ مِّنْ عِلْمِهِ إِلَّا بِمَا شَاءَ ۚ وَسِعَ كُرْسِيُّهُ السَّمَاوَاتِ وَالْأَرْضَ ۖ وَلَا يَئُودُهُ حِفْظُهُمَا ۚ وَهُوَ الْعَلِيُّ الْعَظِيمُ (آية الكرسي كاملة)','count':1},
      {'text':'أصبحنا وأصبح الملك لله والحمد لله لا إله إلا الله وحده لا شريك له','count':1},
      {'text':'سيد الاستغفار: اللهم أنت ربي لا إله إلا أنت خلقتني وأنا عبدك وأنا على عهدك ووعدك ما استطعت أعوذ بك من شر ما صنعت أبوء لك بنعمتك علي وأبوء بذنبي فاغفر لي','count':1},
      {'text':'بسم الله الذي لا يضر مع اسمه شيء في الأرض ولا في السماء وهو السميع العليم (3 مرات)','count':3},
    ],
    'المساء':[
      {'text':'آية الكرسي كاملة: اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ ... إلى العلي العظيم','count':1},
      {'text':'أمسينا وأمسى الملك لله','count':1},
      {'text':'أعوذ بكلمات الله التامات من شر ما خلق (3)','count':3},
      {'text':'حسبي الله لا إله إلا هو عليه توكلت وهو رب العرش العظيم (7)','count':7},
    ],
    'النوم':[
      {'text':'باسمك ربي وضعت جنبي وبك أرفعه','count':1},
      {'text':'باسمك اللهم أموت وأحيا','count':1},
      {'text':'آية الكرسي كاملة قبل النوم','count':1},
      {'text':'سبحان الله 33 الحمد لله 33 الله أكبر 34','count':1},
    ],
    'بعد الصلاة':[
      {'text':'أستغفر الله 3 - اللهم أنت السلام ومنك السلام','count':1},
      {'text':'آية الكرسي بعد كل صلاة','count':1},
      {'text':'سبحان الله 33 الحمد لله 33 الله أكبر 33 وتختم لا إله إلا الله وحده لا شريك له','count':1},
    ]
  };
  Map<String,int> counters={};
  @override Widget build(BuildContext context){
    String current=cats[cat]; var list=data[current]!;
    return Scaffold(
      appBar: AppBar(title: Text('الأذكار كاملة'), backgroundColor: Color(0xFF4A6741)),
      body: Column(children:[
        Container(height:50, child: ListView.builder(scrollDirection: Axis.horizontal, itemCount: cats.length, itemBuilder: (ctx,i)=> Padding(padding: EdgeInsets.all(6), child: ChoiceChip(label: Text(cats[i]), selected: cat==i, onSelected: (v)=> setState(()=> cat=i))))),
        Expanded(child: ListView.builder(itemCount: list.length, itemBuilder: (ctx,i){
          String key='$current-$i'; int c=counters[key]??0; int target=list[i]['count'];
          return Card(margin: EdgeInsets.all(8), child: Padding(padding: EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[Text(list[i]['text'], style: TextStyle(fontSize:17, height:1.8)), SizedBox(height:10), Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children:[Text('$c / $target'), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF4A6741)), onPressed: (){ setState(()=> counters[key]=c+1); }, child: Text('تسبيح'))])])));
        }))
      ]),
    );
  }
}

class SalatGuidePage extends StatelessWidget {
  @override Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(title: Text('تعلمي الصلاة والوضوء'), backgroundColor: Color(0xFF4A6741)),
      body: ListView(children:[
        ExpansionTile(title: Text('الوضوء خطوة بخطوة', style: TextStyle(fontWeight: FontWeight.bold)), children:[ListTile(title: Text('1- النية 2- بسم الله 3- غسل الكفين 3 مرات 4- المضمضة 3 5- الاستنشاق 3 6- غسل الوجه 3 7- اليدين للمرفقين 3 8- مسح الرأس 9- مسح الأذنين 10- غسل الرجلين للكعبين 3\nالدعاء: أشهد أن لا إله إلا الله وأشهد أن محمد عبده ورسوله اللهم اجعلني من التوابين', style: TextStyle(height:1.6)))]),
        ExpansionTile(title: Text('ما يقال في الصلاة', style: TextStyle(fontWeight: FontWeight.bold)), children:[ListTile(title: Text('تكبيرة الإحرام: الله أكبر\nدعاء الاستفتاح: سبحانك اللهم وبحمدك\nالفاتحة + سورة قصيرة\nالركوع: سبحان ربي العظيم 3\nسمع الله لمن حمده ربنا ولك الحمد\nالسجود: سبحان ربي الأعلى 3\nبين السجدتين: رب اغفر لي\nالتشهد + الصلاة الإبراهيمية + التسليم', style: TextStyle(height:1.7)))]),
        ExpansionTile(title: Text('الفروض والسنن', style: TextStyle(fontWeight: FontWeight.bold)), children:[ListTile(title: Text('الفجر 2 - الظهر 4 - العصر 4 - المغرب 3 - العشاء 4\nالسنن: 2 قبل الفجر - 4 قبل الظهر و2 بعده - 2 بعد المغرب - 2 بعد العشاء - الوتر 1 أو 3', style: TextStyle(height:1.6)))]),
      ]),
    );
  }
}