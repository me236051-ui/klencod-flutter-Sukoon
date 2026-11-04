import 'package:flutter/material.dart';

void main() {
  runApp(SukoonApp());
}

class SukoonApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'سُكُون',
      theme: ThemeData(
        primaryColor: Color(0xFF8FA99B),
        scaffoldBackgroundColor: Color(0xFFFAF6F0),
        fontFamily: 'Cairo',
      ),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  final List<Map<String, String>> azkar = [
    {"title": "أذكار الصباح", "count": "24 ذكر"},
    {"title": "أذكار المساء", "count": "20 ذكر"},
    {"title": "أذكار النوم", "count": "12 ذكر"},
    {"title": "تسبيح", "count": "سبحان الله"},
  ];

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
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Color(0xFF8FA99B),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(Icons.play_circle_fill, color: Colors.white, size: 50),
                  SizedBox(width: 15),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('استمع الآن', style: TextStyle(color: Colors.white, fontSize: 16)),
                      Text('سورة البقرة - بصوت عذب', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                    ],
                  )
                ],
              ),
            ),
            SizedBox(height: 25),
            Expanded(
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 15, mainAxisSpacing: 15),
                itemCount: azkar.length,
                itemBuilder: (context, index) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.menu_book_rounded, color: Color(0xFF8FA99B), size: 40),
                        SizedBox(height: 10),
                        Text(azkar[index]['title']!, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(azkar[index]['count']!, style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}