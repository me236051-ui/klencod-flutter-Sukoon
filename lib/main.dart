import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:just_audio/just_audio.dart';
import 'package:adhan/adhan.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

void main() => runApp(SukoonApp());

class SukoonApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'سكون',
      theme: ThemeData(
        primaryColor: Color(0xFF4A6741),
        scaffoldBackgroundColor: Color(0xFFFAF8F5),
      ),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override _HomeScreenState createState() => _HomeScreenState();
}
class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;
  final screens = [TasksPage(), QuranPage(), PrayerPage(), AzkarPage()];
  @override Widget build(BuildContext context) {
    return Scaffold(
      body: screens[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Color(0xFF4A6741),
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.task_alt), label: 'مهامي'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book_rounded), label: 'القرآن'),
          BottomNavigationBarItem(icon: Icon(Icons.mosque), label: 'الصلاة'),
          BottomNavigationBarItem(icon: Icon(Icons.self_improvement), label: 'أذكاري'),
        ],
      ),
    );
  }
}

// مهام
class TasksPage extends StatefulWidget { @override _TasksPageState createState() => _TasksPageState(); }
class _TasksPageState extends State<TasksPage> {
  List tasks = []; TextEditingController c = TextEditingController();
  @override void initState(){ super.initState(); load(); }
  load() async { var p=await SharedPreferences.getInstance(); setState(()=> tasks=jsonDecode(p.getString('tasks')??'[]')); }
  save() async { var p=await SharedPreferences.getInstance(); p.setString('tasks', jsonEncode(tasks)); }
  @override Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(title: Text('سكون - مهامي'), backgroundColor: Color(0xFF4A6741)),
      body: Column(children:[
        Padding(padding: EdgeInsets.all(12), child: Row(children:[
          Expanded(child: TextField(controller:c, decoration: InputDecoration(hintText:'اكتبي مهمة جديدة...', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))))),
          SizedBox(width:8),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF4A6741)), onPressed: (){ if(c.text.isNotEmpty){ setState(()=> tasks.add({'title':c.text,'done':false})); c.clear(); save(); } }, child: Icon(Icons.add))
        ])),
        Expanded(child: ListView.builder(itemCount: tasks.length, itemBuilder: (ctx,i)=> Card(child: CheckboxListTile(value: tasks[i]['done'], title: Text(tasks[i]['title']), onChanged: (v){ setState(()=> tasks[i]['done']=v); save(); }))))
      ]),
    );
  }
}

// قرآن - بصوت مشاري العفاسي العذب
class QuranPage extends StatefulWidget { @override _QuranPageState createState() => _QuranPageState(); }
class _QuranPageState extends State<QuranPage> {
  final player = AudioPlayer();
  int? playing; bool loading=false;
  final surahs = [
    {'id':'001','name':'الفاتحة'}, {'id':'002','name':'البقرة'}, {'id':'003','name':'آل عمران'},
    {'id':'036','name':'يس'}, {'id':'055','name':'الرحمن'}, {'id':'056','name':'الواقعة'},
    {'id':'067','name':'الملك'}, {'id':'018','name':'الكهف'}, {'id':'019','name':'مريم'},
    {'id':'020','name':'طه'}, {'id':'044','name':'الدخان'}, {'id':'078','name':'النبأ'},
    {'id':'112','name':'الإخلاص'}, {'id':'113','name':'الفلق'}, {'id':'114','name':'الناس'},
  ];
  play(String id, int index) async {
    setState(()=> loading=true);
    try{
      String url = 'https://server8.mp3quran.net/afs/$id.mp3';
      await player.setUrl(url);
      await player.play();
      setState(()=> playing=index);
    }catch(e){ ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ في التشغيل'))); }
    setState(()=> loading=false);
  }
  @override void dispose(){ player.dispose(); super.dispose(); }
  @override Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(title: Text('القرآن - مشاري العفاسي'), backgroundColor: Color(0xFF4A6741)),
      body: Column(children:[
        Container(padding: EdgeInsets.all(12), color: Color(0xFFE8F5E9), child: Row(children:[Icon(Icons.info, color: Colors.green), SizedBox(width:8), Expanded(child: Text('اضغطي على السورة للاستماع بصوت عذب', style: TextStyle(fontSize:13)))])),
        Expanded(child: ListView.builder(itemCount: surahs.length, itemBuilder: (ctx,i){
          bool isPlay = playing==i;
          return Card(margin: EdgeInsets.symmetric(horizontal:12, vertical:4), child: ListTile(
            leading: CircleAvatar(backgroundColor: Color(0xFF4A6741), child: Text(surahs[i]['id']!, style: TextStyle(color:Colors.white, fontSize:12))),
            title: Text(surahs[i]['name']!, style: TextStyle(fontSize:18, fontWeight: FontWeight.bold)),
            subtitle: Text(isPlay? 'يتم التشغيل الآن...' : 'العفاسي - صوت عذب خاشع'),
            trailing: loading && !isPlay ? CircularProgressIndicator() : Icon(isPlay? Icons.stop_circle : Icons.play_circle_fill, color: Color(0xFF4A6741), size:36),
            onTap: () async {
              if(isPlay){ await player.stop(); setState(()=> playing=null); }
              else{ await play(surahs[i]['id']!, i); }
            },
          ));
        }))
      ]),
    );
  }
}

// صلاة - بالتوقيت الحالي
class PrayerPage extends StatefulWidget { @override _PrayerPageState createState() => _PrayerPageState(); }
class _PrayerPageState extends State<PrayerPage> {
  PrayerTimes? times; String status='جاري تحديد موقع بدر، البحيرة...'; String nextPrayer='';
  @override void initState(){ super.initState(); getTimes(); }
  getTimes() async {
    try{
      LocationPermission perm = await Geolocator.checkPermission();
      if(perm==LocationPermission.denied) perm = await Geolocator.requestPermission();
      if(perm==LocationPermission.deniedForever){ setState(()=> status='فعلي الموقع من الإعدادات'); return; }
      Position pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      final coords = Coordinates(pos.latitude, pos.longitude);
      final params = CalculationMethod.egyptian.getParameters();
      params.madhab = Madhab.shafi;
      final date = DateComponents.from(DateTime.now());
      final t = PrayerTimes(coords, date, params);
      String next = '';
      DateTime now = DateTime.now();
      if(now.isBefore(t.fajr)) next='القادمة: الفجر'; else if(now.isBefore(t.dhuhr)) next='القادمة: الظهر'; else if(now.isBefore(t.asr)) next='القادمة: العصر'; else if(now.isBefore(t.maghrib)) next='القادمة: المغرب'; else if(now.isBefore(t.isha)) next='القادمة: العشاء'; else next='القادمة: الفجر غداً';
      setState(()=> {times=t, status='بدر - البحيرة 📍', nextPrayer=next});
    }catch(e){ setState(()=> status='خطأ: $e'); }
  }
  @override Widget build(BuildContext context){
    if(times==null) return Scaffold(appBar: AppBar(title: Text('مواقيت الصلاة'), backgroundColor: Color(0xFF4A6741)), body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children:[CircularProgressIndicator(), SizedBox(height:12), Text(status)])));
    return Scaffold(
      appBar: AppBar(title: Text('مواقيت الصلاة'), backgroundColor: Color(0xFF4A6741), actions:[IconButton(icon:Icon(Icons.refresh), onPressed: getTimes)]),
      body: Padding(padding: EdgeInsets.all(16), child: Column(children:[
        Card(color: Color(0xFF4A6741), child: Padding(padding: EdgeInsets.all(16), child: Column(children:[Text(status, style: TextStyle(color:Colors.white)), SizedBox(height:8), Text(nextPrayer, style: TextStyle(color:Colors.white70, fontSize:20, fontWeight: FontWeight.bold)), Text(DateFormat('EEEE - d MMMM yyyy','ar').format(DateTime.now()), style: TextStyle(color:Colors.white60))]))),
        SizedBox(height:12),
        Expanded(child: ListView(children:[
          for(var e in [['الفجر', times!.fajr, Icons.nights_stay], ['الشروق', times!.sunrise, Icons.wb_sunny], ['الظهر', times!.dhuhr, Icons.light_mode], ['العصر', times!.asr, Icons.wb_twilight], ['المغرب', times!.maghrib, Icons.nightlight], ['العشاء', times!.isha, Icons.dark_mode]])
            Card(child: ListTile(leading: Icon(e[2] as IconData, color: Color(0xFF4A6741)), title: Text(e[0] as String, style: TextStyle(fontWeight: FontWeight.bold)), trailing: Text(DateFormat.jm().format(e[1] as DateTime), style: TextStyle(fontSize:18, fontWeight: FontWeight.bold)))),
        ]))
      ])),
    );
  }
}

// اذكار كاملة صحيحة
class AzkarPage extends StatefulWidget { @override _AzkarPageState createState() => _AzkarPageState(); }
class _AzkarPageState extends State<AzkarPage> {
  int cat = 0;
  final cats = ['الصباح','المساء','النوم','بعد الصلاة'];
  final Map<String, List<Map<String,dynamic>>> data = {
    'الصباح': [
      {'text':'أعوذ بالله من الشيطان الرجيم {الله لا إله إلا هو الحي القيوم}','count':1},
      {'text':'بسم الله الرحمن الرحيم {قل هو الله أحد} - {قل أعوذ برب الفلق} - {قل أعوذ برب الناس} (3 مرات)','count':3},
      {'text':'أصبحنا وأصبح الملك لله والحمد لله','count':1},
      {'text':'اللهم بك أصبحنا وبك أمسينا وبك نحيا وبك نموت وإليك النشور','count':1},
      {'text':'اللهم أنت ربي لا إله إلا أنت خلقتني وأنا عبدك','count':1},
      {'text':'سبحان الله وبحمده (100 مرة)','count':100},
    ],
    'المساء': [
      {'text':'أمسينا وأمسى الملك لله والحمد لله','count':1},
      {'text':'اللهم بك أمسينا وبك أصبحنا وبك نحيا وبك نموت وإليك المصير','count':1},
      {'text':'أعوذ بكلمات الله التامات من شر ما خلق (3 مرات)','count':3},
      {'text':'بسم الله الذي لا يضر مع اسمه شيء في الأرض ولا في السماء (3 مرات)','count':3},
      {'text':'رضيت بالله ربا وبالإسلام دينا وبمحمد ﷺ نبيا (3 مرات)','count':3},
    ],
    'النوم': [
      {'text':'باسمك ربي وضعت جنبي وبك أرفعه','count':1},
      {'text':'اللهم قني عذابك يوم تبعث عبادك (3 مرات)','count':3},
      {'text':'سبحان الله 33 - الحمد لله 33 - الله أكبر 34','count':1},
      {'text':'آية الكرسي','count':1},
    ],
    'بعد الصلاة': [
      {'text':'أستغفر الله (3 مرات)','count':3},
      {'text':'اللهم أنت السلام ومنك السلام تباركت يا ذا الجلال والإكرام','count':1},
      {'text':'لا إله إلا الله وحده لا شريك له له الملك وله الحمد وهو على كل شيء قدير','count':1},
      {'text':'سبحان الله 33، الحمد لله 33، الله أكبر 33، ثم تمام المائة: لا إله إلا الله','count':1},
    ]
  };
  Map<String,int> counters={};
  @override Widget build(BuildContext context){
    String currentCat = cats[cat];
    var list = data[currentCat]!;
    return Scaffold(
      appBar: AppBar(title: Text('أذكاري الصحيحة'), backgroundColor: Color(0xFF4A6741)),
      body: Column(children:[
        Container(height:50, child: ListView.builder(scrollDirection: Axis.horizontal, itemCount: cats.length, itemBuilder: (ctx,i)=> Padding(padding: EdgeInsets.all(6), child: ChoiceChip(label: Text(cats[i]), selected: cat==i, onSelected: (v)=> setState(()=> cat=i))))),
        Expanded(child: ListView.builder(itemCount: list.length, itemBuilder: (ctx,i){
          String key = '$currentCat-$i';
          int c = counters[key] ?? 0;
          int target = list[i]['count'];
          double prog = target>0 ? (c/target).clamp(0,1) : 0;
          return Card(margin: EdgeInsets.all(8), child: Padding(padding: EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
            Text(list[i]['text'], style: TextStyle(fontSize:18, height:1.6)),
            SizedBox(height:10),
            LinearProgressIndicator(value: prog.toDouble(), backgroundColor: Colors.grey[200], color: Color(0xFF4A6741)),
            SizedBox(height:8),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children:[
              Text('$c / $target', style: TextStyle(fontWeight: FontWeight.bold)),
              ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF4A6741)), onPressed: (){ setState(()=> counters[key]=c+1); if(c+1>=target) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('أحسنتي! ✅'))); }, child: Text('تسبيح'))
            ])
          ])));
        }))
      ]),
    );
  }
}