import 'package:flutter/material.dart';
import 'package:wifi_info_flutter/wifi_info_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wifi_iot/wifi_iot.dart';
import 'second_page.dart'; // Importiere die SecondPage

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

      if (networks != null) {
        networks.sort((a, b) =>
            (a.level ?? 0).compareTo(b.level ?? 0)); // Sortiere nach Signalstärke
      }

      setState(() {
        availableNetworks = networks;
      });
    }
  }

  String _getFrequencyBand(int? frequency) {
    if (frequency != null) {
      if (frequency >= 2400 && frequency <= 2500) {
        return '2.4 GHz';
      } else if (frequency >= 4900 && frequency <= 5900) {
        return '5 GHz';
      }
    }
    return 'Unbekannt';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              _getWifiDetails();
              _loadAvailableNetworks();
            },
          ),
          IconButton(
            icon: Icon(Icons.navigate_next), // Hinzugefügter Button
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SecondPage()), // Navigiere zur SecondPage
              );
            },
          ),
        ],
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
              final frequencyBand = _getFrequencyBand(network.frequency);

              return ListTile(
                title: Text("SSID: ${network.ssid}"),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Signalstärke (RSSI): ${network.level} dBm'),
                    Text('Frequenzband: $frequencyBand'),
                  ],
                ),
              );
            }).toList(),
        ],
      ),
    );
  }
}
