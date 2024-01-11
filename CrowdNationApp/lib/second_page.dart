import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wifi_scan/wifi_scan.dart';
import 'package:network_info_plus/network_info_plus.dart';

class SecondPage extends StatefulWidget {
  @override
  _SecondPageState createState() => _SecondPageState();
}

class _SecondPageState extends State<SecondPage> {
  Map<String, dynamic>? wifiDetails;
  List<WiFiAccessPoint>? availableNetworks;

  @override
  void initState() {
    super.initState();
    _getWifiDetails();
    _loadAvailableNetworks();
  }

  Future<void> _getWifiDetails() async {
    PermissionStatus statusLocation = await Permission.location.request();
    if (statusLocation.isGranted) {
      NetworkInfo networkInfo = NetworkInfo();
      String? wifiName = await networkInfo.getWifiName();
      String? wifiBSSID = await networkInfo.getWifiBSSID();
      String? wifiIP = await networkInfo.getWifiIP();

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
      List<WiFiAccessPoint> networks = await WiFiScan.instance.getScannedResults();

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
        title: Text('Debugging-Daten'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              _getWifiDetails();
              _loadAvailableNetworks();
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
