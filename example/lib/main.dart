import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_mjpeg/flutter_mjpeg.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter MJPEG Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}


class MyHomePage extends HookWidget
{
  Widget build(BuildContext context) {
    var urlList = List.generate(50, (index) {
      var i = index % 5;
      return "http://192.168.1.$i/stream";
    });

    return Scaffold(
      appBar: AppBar(title: Text("Flutter MJPEG Demo")),
      body: Container(
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Text("<---    This is a scrollable list view    --->", style: TextStyle(color: Colors.purple, fontSize: 25))),
            Center(child: Text("You can quickly slide left and right")),
            Padding(padding: EdgeInsets.all(30)),
            Container(
              width: double.infinity,
              height: 160,
              color: Colors.black12,
              child: ListView.builder(
                key: ObjectKey("list view"),
                controller: ScrollController(),
                padding: EdgeInsets.all(20),
                scrollDirection: Axis.horizontal,
                itemCount: urlList.length,
                itemBuilder: (BuildContext context, int index) => Container(
                  margin: EdgeInsets.only(right: 10),
                  width: 214,
                  height: 120,
                  color: Colors.black,
                  child: Mjpeg(
                    stream: urlList[index],
                    isLive: true,
                    fit: BoxFit.fill,
                    error: (_, error) => Center(child: Text(error.toString(), style: TextStyle(color: Colors.red))),
                    loading: (_) => Center(child: CircularProgressIndicator())
                  )
                )
              )
            ),
            Padding(padding: EdgeInsets.all(20)),
            Text("\t\tThis submitted version fixes the following issues: "),
            Text("\t\t>>>>>> Unhandled Exception: A ValueNotifier<dynamic> was used after being disposed.", style: TextStyle(color: Colors.grey)),
            Text("\t\t>>>>>> Unhandled Exception: Looking up a deactivated widget's ancestor is unsafe.", style: TextStyle(color: Colors.grey))
          ]
        )
      )
    );
  }
}
