import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_mjpeg/flutter_mjpeg.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final isRunning = useState(true);
    return Scaffold(
      appBar: AppBar(
        title: Text('Flutter Demo Home Page'),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: Center(
              child: isRunning.value
                  ? Mjpeg(
                      width: 200,
                      height: 200,
                      stream: 'http://192.168.1.37:8081',
                    )
                  : Container(),
            ),
          ),
          RaisedButton(
            onPressed: () {
              isRunning.value = !isRunning.value;
            },
            child: Text('Toggle'),
          ),
        ],
      ),
    );
  }
}
