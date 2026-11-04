import 'package:flutter/material.dart';

void main() => runApp(SukoonApp());

class SukoonApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'سُكُون',
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFAF6F0),
      appBar: AppBar(
        backgroundColor: Color(0xFFFAF6F0),
        elevation: 0,
        title: Text('سُكُون', style: TextStyle(color: Color(0xFF5A6E64), fontWeight: FontWeight.bold, fontSize: 26)),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: ()=> Navigator.push(context, MaterialPageRoute(builder: (_)=> QuranScreen())),
              child: Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(color: Color(0xFF8FA99B), borderRadius: BorderRadius.circular(20)),
                child: Row(children: [
                  Icon(Icons.play_circle_fill, color: Colors.white, size: 50),
                  SizedBox(width: 12),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('استمع الآن', style: TextStyle(color: Colors.white70)),
                    Text('سورة البقرة - بصوت عذب', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ])
                ]),
              ),
            ),
            SizedBox(height: 20),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2, crossAxisSpacing: 15, mainAxisSpacing: 15,
                children: [
                  azkarCard(context, 'أذكار الصباح', '24 ذكر'),
                  azkarCard(context, 'أذكار المساء', '20 ذكر'),
                  azkarCard(context, 'أذكار النوم', '12 ذكر'),
                  tasbihCard(context),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget azkarCard(BuildContext ctx, String title, String count) {
    return GestureDetector(
      onTap: ()=> Navigator.push(ctx, MaterialPageRoute(builder: (_)=> AzkarDetail(title: title))),
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.menu_book_rounded, color: Color(0xFF8FA99B), size: 40),
          SizedBox(height: 8),
          Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
          Text(count, style: TextStyle(color: Colors.grey)),
        ]),
      ),
    );
  }

  Widget tasbihCard(BuildContext ctx) {
    return GestureDetector(
      onTap: ()=> Navigator.push(ctx, MaterialPageRoute(builder: (_)=> TasbihScreen())),
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.menu_book_rounded, color: Color(0xFF8FA99B), size: 40),
          SizedBox(height: 8),
          Text('تسبيح', style: TextStyle(fontWeight: FontWeight.bold)),
          Text('سبحان الله', style: TextStyle(color: Colors.grey)),
        ]),
      ),
    );
  }
}

class AzkarDetail extends StatelessWidget {
  final String title;
  AzkarDetail({required this.title});
  final List<String> azkar = [
    'اللهم بك أصبحنا وبك أمسينا وبك نحيا وبك نموت وإليك النشور',
    'أعوذ بكلمات الله التامات من شر ما خلق',
    'سبحان الله وبحمده 100 مرة',
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), backgroundColor: Color(0xFF8FA99B)),
      body: ListView.builder(
        padding: EdgeInsets.all(15),
        itemCount: azkar.length,
        itemBuilder: (_, i) => Card(
          child: Padding(padding: EdgeInsets.all(15), child: Text(azkar[i], style: TextStyle(fontSize: 18), textAlign: TextAlign.center)),
        ),
      ),
    );
  }
}

class TasbihScreen extends StatefulWidget {
  @override
  _TasbihScreenState createState() => _TasbihScreenState();
}
class _TasbihScreenState extends State<TasbihScreen> {
  int count = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('تسبيح'), backgroundColor: Color(0xFF8FA99B)),
      body: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('$count', style: TextStyle(fontSize: 80, fontWeight: FontWeight.bold, color: Color(0xFF5A6E64))),
          SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF8FA99B), padding: EdgeInsets.symmetric(horizontal: 60, vertical: 20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
            onPressed: ()=> setState(()=> count++),
            child: Text('سبحان الله', style: TextStyle(fontSize: 22)),
          ),
          TextButton(onPressed: ()=> setState(()=> count=0), child: Text('إعادة')),
        ]),
      ),
    );
  }
}

class QuranScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('القرآن الكريم'), backgroundColor: Color(0xFF8FA99B)),
      body: Center(child: Text('هنا هنضيف أصوات المشايخ قريباً 🎧', style: TextStyle(fontSize: 18))),
    );
  }
}