import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:adhan/adhan.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

void main() { runApp(const SukoonApp()); }

class SukoonApp extends StatelessWidget {
  const SukoonApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primaryColor: const Color(0xFF4A6741)),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget { const HomeScreen({super.key}); @override State<HomeScreen> createState() => _HomeScreenState(); }
class _HomeScreenState extends State<HomeScreen> {
  int _index = 2;
  final List<Widget> screens = [const TasksPage(), const QuranPage(), const PrayerPage()];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: screens[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        selectedItemColor: const Color(0xFF4A6741),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.check_circle), label: 'مهامي'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'القرآن'),
          BottomNavigationBarItem(icon: Icon(Icons.mosque), label: 'الصلاة'),
        ],
      ),
    );
  }
}

class TasksPage extends StatefulWidget { const TasksPage({super.key}); @override State<TasksPage> createState() => _TasksPageState(); }
class _TasksPageState extends State<TasksPage> {
  List tasks = []; final c = TextEditingController();
  @override void initState() { super.initState(); load(); }
  load() async { var p = await SharedPreferences.getInstance(); setState(() { tasks = jsonDecode(p.getString('tasks') ?? '[]'); }); }
  save() async { var p = await SharedPreferences.getInstance(); p.setString('tasks', jsonEncode(tasks)); }
  @override Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('مهامي'), backgroundColor: const Color(0xFF4A6741)),
      body: Column(children: [
        Padding(padding: const EdgeInsets.all(12), child: Row(children: [Expanded(child: TextField(controller: c, decoration: const InputDecoration(hintText: 'مهمة جديدة...', border: OutlineInputBorder()))), const SizedBox(width: 8), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4A6741)), onPressed: () { if (c.text.isNotEmpty) { setState(() { tasks.add({'title': c.text, 'done': false}); }); c.clear(); save(); } }, child: const Text('إضافة'))])),
        Expanded(child: ListView.builder(itemCount: tasks.length, itemBuilder: (ctx, i) => Card(child: CheckboxListTile(value: tasks[i]['done'], title: Text(tasks[i]['title']), onChanged: (v) { setState(() { tasks[i]['done'] = v; }); save(); }))))
      ]),
    );
  }
}

class QuranPage extends StatelessWidget {
  const QuranPage({super.key});
  @override Widget build(BuildContext context) {
    final surahs = ['الفاتحة', 'البقرة', 'الكهف', 'يس', 'الرحمن', 'الواقعة', 'الملك', 'الإخلاص', 'الفلق', 'الناس'];
    return Scaffold(appBar: AppBar(title: const Text('القرآن الكريم'), backgroundColor: const Color(0xFF4A6741)), body: ListView.builder(itemCount: surahs.length, itemBuilder: (ctx, i) => Card(child: ListTile(title: Text(surahs[i]), leading: const Icon(Icons.book)))));
  }
}

class PrayerPage extends StatefulWidget { const PrayerPage({super.key}); @override State<PrayerPage> createState() => _PrayerPageState(); }
class _PrayerPageState extends State<PrayerPage> {
  PrayerTimes? times; String status = 'جاري تحديد موقعك...';
  @override void initState() { super.initState(); getTimes(); }
  getTimes() async {
    try {
      await Geolocator.requestPermission();
      Position pos = await Geolocator.getCurrentPosition();
      final coords = Coordinates(pos.latitude, pos.longitude);
      final params = CalculationMethod.egyptian.getParameters();
      final t = PrayerTimes(coords, DateComponents.from(DateTime.now()), params);
      setState(() { times = t; status = 'درين - نبروه 📍'; });
    } catch (e) { setState(() { status = 'شغلي الـ GPS: $e'; }); }
  }
  @override Widget build(BuildContext context) {
    if (times == null) return Scaffold(appBar: AppBar(title: const Text('الصلاة'), backgroundColor: const Color(0xFF4A6741)), body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const CircularProgressIndicator(), const SizedBox(height: 12), Text(status), ElevatedButton(onPressed: getTimes, child: const Text('إعادة المحاولة'))])));
    return Scaffold(appBar: AppBar(title: Text('الصلاة - $status'), backgroundColor: const Color(0xFF4A6741), actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: getTimes)]), body: ListView(children: [ListTile(title: const Text('الفجر'), trailing: Text(DateFormat.jm().format(times!.fajr))), ListTile(title: const Text('الظهر'), trailing: Text(DateFormat.jm().format(times!.dhuhr))), ListTile(title: const Text('العصر'), trailing: Text(DateFormat.jm().format(times!.asr))), ListTile(title: const Text('المغرب'), trailing: Text(DateFormat.jm().format(times!.maghrib))), ListTile(title: const Text('العشاء'), trailing: Text(DateFormat.jm().format(times!.isha)))]));
  }
}