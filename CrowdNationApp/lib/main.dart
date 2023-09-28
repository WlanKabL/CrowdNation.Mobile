import 'package:flutter/material.dart';
import 'package:wifi_info_flutter/wifi_info_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Crowd-Nation',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: MyHomePage(title: 'Crowd-Nation Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final String title;
  MyHomePage({required this.title});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Future<String?>? _wifiNameFuture;

  @override
  void initState() {
    super.initState();
    _wifiNameFuture = _getWifiName();
  }

  Future<String?> _getWifiName() async {
    PermissionStatus status = await Permission.location.request();
    if (status.isGranted) {
      return await WifiInfo().getWifiName();
    } else {
      return "Permission not granted";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: FutureBuilder<String?>(
          future: _wifiNameFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              if (snapshot.hasError) {
                // Dies gibt den Fehler aus, falls einer auftritt.
                return Text("Error: ${snapshot.error}");
              } else if (snapshot.hasData) {
                return Text("Wifi Name: ${snapshot.data}");
              } else {
                return Text("Data is null. ${_getWifiName()}");
              }
            } else {
              return CircularProgressIndicator();
            }
          },
        ),
      ),
    );
  }
}
