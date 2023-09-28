import 'package:flutter/material.dart';
import 'package:wifi_info_flutter/wifi_info_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wifi_iot/wifi_iot.dart';

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
  Map<String, dynamic>? wifiDetails;
  List<WifiNetwork>? availableNetworks;

  @override
  void initState() {
    super.initState();
    _getWifiDetails();
    _loadAvailableNetworks();
  }

  Future<void> _getWifiDetails() async {
    PermissionStatus statusLocation = await Permission.location.request();
    if (statusLocation.isGranted) {
      String? wifiName = await WifiInfo().getWifiName();
      String? wifiBSSID = await WifiInfo().getWifiBSSID();
      String? wifiIP = await WifiInfo().getWifiIP();

      setState(() {
        wifiDetails = {
          'Name': wifiName,
          'BSSID': wifiBSSID,
          'IP': wifiIP,
        };
      });
    } else {
      print("Erforderliche Berechtigungen wurden nicht erteilt.");
    }
  }

  Future<void> _loadAvailableNetworks() async {
    if (await Permission.location.request().isGranted) {
      List<WifiNetwork> networks = await WiFiForIoTPlugin.loadWifiList();
      setState(() {
        availableNetworks = networks;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: ListView(
        children: [
          if (wifiDetails != null)
            ...wifiDetails!.entries.map((entry) {
              return ListTile(
                title: Text("${entry.key}: ${entry.value}"),
              );
            }).toList(),
          if (availableNetworks != null)
            ...availableNetworks!.map((network) {
              return ListTile(
                title: Text("SSID: ${network.ssid}"),
                subtitle: Text('Signalstärke (RSSI): ${network.level} dBm'),
              );
            }).toList(),
        ],
      ),
    );
  }
}
