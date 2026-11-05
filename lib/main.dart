import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:adhan/adhan.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

void main(){ runApp(SukoonApp()); }

class SukoonApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) => MaterialApp(debugShowCheckedModeBanner: false, home: HomeScreen());
}

class HomeScreen extends StatefulWidget { @override _HomeScreenState createState() => _HomeScreenState(); }
class _HomeScreenState extends State<HomeScreen> {
  int _index=2;
  final screens=[TasksPage(), QuranPage(), PrayerPage()];
  @override Widget build(BuildContext context){
    return Scaffold(
      body: screens[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index, onTap: (i){ setState((){ _index=i; }); },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.check), label: 'مهامي'),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: 'القرآن'),
          BottomNavigationBarItem(icon: Icon(Icons.mosque), label: 'الصلاة'),
        ]),
    );
  }
}

class TasksPage extends StatefulWidget { @override _TasksPageState createState() => _TasksPageState(); }
class _TasksPageState extends State<TasksPage> {
  List tasks=[]; var c=TextEditingController();
  @override void initState(){ super.initState(); load(); }
  load() async { var p=await SharedPreferences.getInstance(); setState((){ tasks=jsonDecode(p.getString('tasks')??'[]'); }); }
  save() async { var p=await SharedPreferences.getInstance(); p.setString('tasks', jsonEncode(tasks)); }
  @override Widget build(BuildContext context){
    return Scaffold(appBar: AppBar(title: Text('مهامي')), body: Column(children:[ Row(children:[Expanded(child: TextField(controller:c)), ElevatedButton(onPressed: (){ if(c.text.isNotEmpty){ setState((){ tasks.add({'title':c.text,'done':false}); }); c.clear(); save(); } }, child: Text('اضافة'))]), Expanded(child: ListView.builder(itemCount: tasks.length, itemBuilder: (ctx,i)=> CheckboxListTile(value: tasks[i]['done'], title: Text(tasks[i]['title']), onChanged: (v){ setState((){ tasks[i]['done']=v; }); save(); })))]));
  }
}

class QuranPage extends StatelessWidget {
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text('القرآن')), body: Center(child: Text('المصحف هيضاف بعد اول بناء ناجح')));
}

class PrayerPage extends StatefulWidget { @override _PrayerPageState createState() => _PrayerPageState(); }
class _PrayerPageState extends State<PrayerPage> {
  PrayerTimes? times; String status='جاري التحديد...';
  @override void initState(){ super.initState(); getTimes(); }
  getTimes() async {
    try{
      await Geolocator.requestPermission();
      Position pos=await Geolocator.getCurrentPosition();
      final coords=Coordinates(pos.latitude, pos.longitude);
      final params=CalculationMethod.egyptian.getParameters();
      final t=PrayerTimes(coords, DateComponents.from(DateTime.now()), params);
      setState((){ times=t; status='درين - نبروه'; });
    }catch(e){ setState((){ status='$e'; }); }
  }
  @override Widget build(BuildContext context){
    if(times==null) return Scaffold(appBar: AppBar(title: Text('الصلاة')), body: Center(child: Text(status)));
    return Scaffold(appBar: AppBar(title: Text('الصلاة - $status')), body: ListView(children:[ ListTile(title: Text('الفجر'), trailing: Text(DateFormat.jm().format(times!.fajr))), ListTile(title: Text('الظهر'), trailing: Text(DateFormat.jm().format(times!.dhuhr))), ListTile(title: Text('العصر'), trailing: Text(DateFormat.jm().format(times!.asr))), ListTile(title: Text('المغرب'), trailing: Text(DateFormat.jm().format(times!.maghrib))), ListTile(title: Text('العشاء'), trailing: Text(DateFormat.jm().format(times!.isha))) ]));
  }
}