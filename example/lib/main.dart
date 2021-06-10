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
              child: Mjpeg(
                isLive: isRunning.value,
                error: (context, error, stack) {
                  print(error);
                  print(stack);
                  return Text(error.toString(), style: TextStyle(color: Colors.red));
                },
                stream:
                'http://91.133.85.170:8090/cgi-bin/faststream.jpg?stream=half&fps=15&rand=COUNTER', //'http://192.168.1.37:8081',
              ),
            ),
          ),
          Row(
            children: <Widget>[
              RaisedButton(
                onPressed: () {
                  isRunning.value = !isRunning.value;
                },
                child: Text('Toggle'),
              ),
              RaisedButton(
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => Scaffold(
                            appBar: AppBar(),
                          )));
                },
                child: Text('Push new route'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
