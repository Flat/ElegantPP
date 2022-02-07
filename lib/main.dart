import 'dart:io';

import 'package:flutter/material.dart';
import 'package:window_size/window_size.dart';
import 'package:file_picker/file_picker.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    setWindowTitle("Elegant PP");
    getWindowInfo().then((value) {
      if (value.screen != null) {
        var width = 325.0;
        var height = 300.0;
        var left = ((value.frame.width - width) / 2).roundToDouble();
        var top = ((value.frame.height - height / 2)).roundToDouble();
        Rect windowSize = Offset(left, top) & Size(width, height);
        setWindowFrame(windowSize);
      }
    });
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Elegant PP',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Elegant PP'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class FormModel {
  String? host;
  int? port;
  FormModel({this.host, this.port});
}

class _MyHomePageState extends State<MyHomePage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final model = FormModel();
  var payloadSelected = 'Browse for Payload';
  File? payload;

  void send() {
    if (model.port != null && payload != null) {
      Socket.connect(model.host, model.port!,
              timeout: const Duration(seconds: 30))
          .then((socket) {
        socket.addStream(payload!.openRead()).then((value) async {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payload written to socket.')),
          );
          await socket.flush();
          socket.close();
        }, onError: (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to send payload: $e')),
          );
        });
      }, onError: (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Failed to connect to ${model.host}:${model.port}: $e')),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('Elegant PP')),
        body: ListView(padding: const EdgeInsets.all(8), children: [
          Form(
              key: _formKey,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                          flex: 7,
                          child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: TextFormField(
                                decoration: const InputDecoration(
                                    labelText: 'IP Address/Domain Name',
                                    hintText: "192.168.1.20"),
                                validator: (String? value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter a valid IP or Domain Name';
                                  }
                                  return null;
                                },
                                onSaved: (value) {
                                  model.host = value;
                                },
                              ))),
                      Expanded(
                          flex: 3,
                          child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: TextFormField(
                                decoration: const InputDecoration(
                                    labelText: 'Port', hintText: "9020"),
                                validator: (String? value) {
                                  if (value == null ||
                                      value.isEmpty ||
                                      value.contains(RegExp(r'^\D'))) {
                                    return 'Please enter a valid port';
                                  }
                                  return null;
                                },
                                onSaved: (value) {
                                  if (value != null && value.isNotEmpty) {
                                    model.port = int.parse(value);
                                  }
                                },
                              )))
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                          child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: ElevatedButton(
                                child: Text(payloadSelected),
                                onPressed: () async {
                                  FilePickerResult? result =
                                      await FilePicker.platform.pickFiles();
                                  if (result != null) {
                                    File payloadFile =
                                        File(result.files.single.path!);
                                    setState(() {
                                      payloadSelected = payloadFile.path;
                                      payload = payloadFile;
                                    });
                                  }
                                },
                              )))
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                          child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: ElevatedButton(
                                child: const Text('Send'),
                                onPressed: () {
                                  if (_formKey.currentState!.validate()) {
                                    if (payload == null) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'Please select a Payload.')),
                                      );
                                    } else {
                                      _formKey.currentState?.save();
                                      send();
                                    }
                                  }
                                },
                              )))
                    ],
                  )
                ],
                crossAxisAlignment: CrossAxisAlignment.start,
              ))
        ]));
  }
}
