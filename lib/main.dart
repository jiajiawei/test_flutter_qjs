import 'package:flutter/material.dart';
import 'package:testfqjs/js_engine.dart';

void main() {
  runApp(MyApp());
}

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

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var a = 1;
  TextEditingController controller = TextEditingController(text: 'a = a + 1');
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Text('a: $a'),
          Container(
            decoration: BoxDecoration(border: Border.all()),
            child: SizedBox(
                height: 400,
                child: TextField(
                  controller: controller,
                  maxLines: 20,
                )),
          )
        ],
      ),
      floatingActionButton: OutlinedButton(
        child: Text('test'),
        onPressed: () {
          final injectObj = {
            'a': ScriptProperty(() => a, (v) => setState(() => a = v)),
            'print': print,
          };
          print(JsEngine.eval(injectObj, controller.text));
        },
      ),
    );
  }
}
