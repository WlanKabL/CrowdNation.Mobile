import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:wifi_iot/wifi_iot.dart';
import 'package:permission_handler/permission_handler.dart';
import 'second_page.dart';

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
  final ssidController = TextEditingController();
  final targetAddress = TextEditingController();
  List<WifiNetwork> _networks = [];

  @override
  void initState() {
    super.initState();
    targetAddress.text = 'http://192.168.178.85:4206/api/position/user';
    _loadAvailableNetworks();
  }

  Future<void> _loadAvailableNetworks() async {
    if (await Permission.location.request().isGranted) {
      List<WifiNetwork> networks = await WiFiForIoTPlugin.loadWifiList();

      if (networks != null) {
        networks.sort((a, b) =>
            (a.level ?? 0).compareTo(b.level ?? 0)); // Sortiere nach Signalstärke
      }

      setState(() {
        _networks = networks;
        _filterNetworks();
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

  Future<void> _sendData() async {
    var url = Uri.parse(targetAddress.text);
    var response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: json.encode({
        "device": {
          "name": "WlankabL iPhone",
          "mac": "00:1A:2B:3C:4D:5E",
          "userId": "1",
          "ipAddress": "192.168.0.102",
          "os": "iOS 17.2",
          "batteryLevel": "85%",
          "connectedAP": {
            "mac": "A1:F7:0E:2C:5D:9B",
            "apId": "550e8400-e29b-41d4-a716-446655440000",
            "frequency": "5GHz"
          }
        },
        "apList": _networks.map((network) => {
          "ssid": network.ssid,
          "mac": network.bssid, // Annahme, dass bssid verfügbar ist
          "strength": network.level,
          "frequencyBand": _getFrequencyBand(network.frequency)
        }).toList(),
      }),
    );
    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');
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
              _loadAvailableNetworks();
            },
          ),
          IconButton(
            icon: Icon(Icons.navigate_next),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SecondPage()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          TextField(
            controller: targetAddress,
            decoration: InputDecoration(
              labelText: 'Target Address',
            ),
          ),
          TextField(
            controller: ssidController,
            decoration: InputDecoration(
              labelText: 'SSID Filter',
            ),
          ),
          ElevatedButton(
            onPressed: () => _filterNetworks(),
            child: Text('Filter SSID'),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _networks.length,
              itemBuilder: (context, index) {
                final frequencyBand = _getFrequencyBand(_networks[index].frequency);
                return ListTile(
                  title: Text(_networks[index].ssid.toString()),
                  subtitle: Text(
                      'Signalstärke: ${_networks[index].level} dBm\nFrequenzband: $frequencyBand'
                  ),
                );
              },
            ),
          ),
          ElevatedButton(
            onPressed: _sendData,
            child: Text('Send Data'),
          ),
        ],
      ),
    );
  }

  void _filterNetworks() {
    setState(() {
      if (ssidController.text.isNotEmpty) {
        _networks = _networks
            .where((network) => network.ssid!.toLowerCase().contains(ssidController.text))
            .toList();
      } else {
        // Hier rufst du _loadAvailableNetworks() auf, wenn das Textfeld leer ist
        _loadAvailableNetworks();
      }
    });
  }

}
