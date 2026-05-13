import 'package:flutter/material.dart';
//import 'package:incubapp_lite/models/actual_model.dart';
import 'package:incubapp_lite/views/home.dart';
import 'package:incubapp_lite/views/wifi_home.dart';
import 'package:incubapp_lite/views/initial_home.dart';
import 'package:incubapp_lite/services/api_services.dart';
import 'package:incubapp_lite/views/counter_home.dart';
import 'package:incubapp_lite/utils/constants.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:incubapp_lite/views/rotation_home.dart';


class GHome extends StatefulWidget {
  const GHome({Key? key}) : super(key: key);

  @override
  _GHomeState createState() => _GHomeState();
}

class _GHomeState extends State<GHome> {
  final ApiService _apiService = ApiService();
  String? incubadoraId;
  int _selectedIndex = 0;
  InAppWebViewController? webViewController;

  @override
  void initState() {
    super.initState();
    _loadIncubatorHash();
  }

  Future<void> _loadIncubatorHash() async {
    final hash = await _apiService.getIncubatorHash();
    setState(() {
      incubadoraId = hash;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (incubadoraId == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Visualizador Grafana'),
      ),
      body: InAppWebView(
        initialUrlRequest: URLRequest(
          url: WebUri(ApiConstants.getGrafanaUrl(incubadoraId!)),
        ),
        onWebViewCreated: (controller) {
          webViewController = controller;
        },
        onLoadStart: (controller, url) {
          print('Page started loading: $url');
        },
        onLoadStop: (controller, url) async {
          print('Page finished loading: $url');
        },
        onLoadError: (controller, url, code, message) {
          print('Page load error: $code, $message');
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: const Color.fromARGB(65, 65, 65, 1),
        selectedItemColor: Colors.grey,
        unselectedItemColor: Colors.black,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.wifi),
            label: 'Conexion',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Configuraciones',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.egg),
            label: 'Contador',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_backup_restore),
            label: 'Rotación',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.monitor_heart),
            label: 'Grafana',
          ),
        ],
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.push(context, MaterialPageRoute(builder: (context) => IHome()));
        break;
      case 1:
        Navigator.push(context, MaterialPageRoute(builder: (context) => WHome()));
        break;
      case 2:
        Navigator.push(context, MaterialPageRoute(builder: (context) => Home()));
        break;
      case 3:
        Navigator.push(context, MaterialPageRoute(builder: (context) => CHome()));
        break;
      case 4:
        Navigator.push(context, MaterialPageRoute(builder: (context) => RHome()));
        break;
      case 5:
        // GHome
        break;
    }
  }
}