import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
//import 'package:wifi_iot/wifi_iot.dart';
import 'package:permission_handler/permission_handler.dart';
import 'second_page.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io' show Platform;
import 'package:battery_plus/battery_plus.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:wifi_scan/wifi_scan.dart';

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
      home: const MyHomePage(title: 'Crowd-Nation Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final String title;

  const MyHomePage({required this.title});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final ssidController = TextEditingController();
  var targetAddress = TextEditingController();
  List<WiFiAccessPoint> _networks = [];

  @override
  void initState() {
    super.initState();
    targetAddress.text = 'http://172.20.10.4:4206/api/position/user';
    _loadAvailableNetworks();
  }

  Future<void> _loadAvailableNetworks() async {
    if (await Permission.location.request().isGranted) {
      await WiFiScan.instance.startScan();

      List<WiFiAccessPoint> networks = await WiFiScan.instance.getScannedResults();
      if (networks.isNotEmpty) {
        networks.sort((a, b) => b.level.compareTo(a.level)); // Sortiere nach Signalstärke
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
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    String deviceName = '';
    String osVersion = '';

    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      deviceName = androidInfo.model;
      osVersion = 'Android ${androidInfo.version.release}';
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      deviceName = iosInfo.name;
      osVersion = 'iOS ${iosInfo.systemVersion}';
    }


    Battery battery = Battery();
    int batteryLevel = await battery.batteryLevel;

    NetworkInfo networkInfo = NetworkInfo();
    String? wifiIP = await networkInfo.getWifiIP();
    String? wifiName = await networkInfo.getWifiName();
    String? wifiBSSID = await networkInfo.getWifiBSSID();
    int? wifiFrequency = _networks.firstWhere((network) => network.bssid!.toLowerCase() == wifiBSSID!.toLowerCase())!.frequency ?? null;
    String frequencyType = "Unknown";
    if (wifiFrequency != null) {
      frequencyType = _getFrequencyBand(wifiFrequency);
    }

    var url = Uri.parse(targetAddress.text);
    var response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: json.encode({
        "device": {
          "name": deviceName,
          //"mac": "NOT POSSIBLE?",
          "userId": "WIP",
          "ipAddress": wifiIP ?? "Unknown",
          "os": osVersion,
          "batteryLevel": batteryLevel,
          "connectedAP": {
            //"ipAddress": wifiIP ?? '',
            "mac": wifiBSSID ?? '',
            "network": wifiName ?? '',
            "frequency": frequencyType
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
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadAvailableNetworks();
            },
          ),
          IconButton(
            icon: const Icon(Icons.navigate_next),
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
            decoration: const InputDecoration(
              labelText: 'Target Address',
            ),
          ),
          TextField(
            controller: ssidController,
            decoration: const InputDecoration(
              labelText: 'SSID Filter',
            ),
          ),
          ElevatedButton(
            onPressed: () => _filterNetworks(),
            child: const Text('Filter SSID'),
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
            child: const Text('Send Data'),
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
