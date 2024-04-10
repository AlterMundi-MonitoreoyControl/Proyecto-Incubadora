import 'package:incubapp_lite/models/wifi_model.dart';
import 'package:incubapp_lite/views/initial_home.dart';
import 'package:incubapp_lite/services/api_services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:android_flutter_wifi/android_flutter_wifi.dart';
import 'package:connectivity/connectivity.dart';
import 'package:incubapp_lite/views/home.dart';
import 'package:incubapp_lite/views/wifi_home.dart';
import 'package:incubapp_lite/views/initial_home.dart';
import 'package:incubapp_lite/services/api_services.dart';
import 'package:incubapp_lite/views/counter_home.dart';
import 'package:incubapp_lite/views/graf_home.dart';

class WHome extends StatefulWidget {
  const WHome({Key? key}) : super(key: key);

  @override
  _WHomeState createState() => _WHomeState();
}

class _WHomeState extends State<WHome> {
  
  int _selectedIndex = 0;

  late Wifi? _wifiModel = null;

  @override
  void initState() {
    super.initState();
    _getData();
  }

  Future<void> _getData() async {
    _wifiModel = (await ApiService().getWifi());
    setState(() {});
  }

  Future<void> _connectToWifi(String ssid, String password) async {
    try {
      if (ssid.isEmpty || password.isEmpty) {
        throw ("SSID and Password can't be empty");
      }

      debugPrint('SSID: $ssid, Password: $password');

      // Return boolean value
      // If true then connection is success
      // If false then connection failed due to authentication
      var result = await AndroidFlutterWifi.connectToNetwork(ssid, password);

      debugPrint('---------Connection result-----------: ${result.toString()}');
    } catch (e) {
      print(e);
    }
  }

  Future<void> _showWifiListDialog() async {
    if (_wifiModel == null || _wifiModel!.networks.isEmpty) {
      print("No hay redes Wi-Fi disponibles");
      return;
    }

    List<String> networkSSIDs = _wifiModel!.networks.map((network) => network.ssid).toList();

    String password = ''; // Variable para almacenar la contraseña ingresada
    String? selectedSSID = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Ingrese la contraseña:'),
          content: Column(
            children: [
              SingleChildScrollView(
                child: ListBody(
                  children: networkSSIDs.map((ssid) {
                    return ListTile(
                      title: Text(ssid),
                      onTap: () {
                        Navigator.pop(context, ssid);
                      },
                    );
                  }).toList(),
                ),
              ),
              TextField(
                onChanged: (value) {
                  password = value;
                },
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Contraseña'
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Cancelar la conexión
              },
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                // Conectar a la red con la contraseña ingresada
                if (password.isNotEmpty) {
                  Navigator.pop(context, password);
                }
              },
              child: Text('Conectar'),
            ),
          ],
        );
      },
    );

    if (selectedSSID != null) {
      // Ahora puedes realizar la conexión con la red seleccionada y la contraseña ingresada
      _connectToWifi(selectedSSID, password);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('REDES DISPONIBLES'),
      ),
      body: _wifiModel == null
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : ListView.builder(
              itemCount: _wifiModel!.networks.length,
              itemBuilder: (context, index) {
                final network = _wifiModel!.networks[index];
                return Card(
                  child: InkWell(
                    onTap: () {
                      // Mostrar el diálogo de selección de red Wi-Fi
                      _showWifiListDialog();
                    },
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Text('SSID:'),
                            Text(network.ssid),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Text('RSSI:'),
                            Text(network.rssi.toString()),
                          ],
                        ),
                        const SizedBox(
                          height: 10.0,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    
    bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: const Color.fromARGB(65, 65, 65, 1),
        selectedItemColor: Colors.grey,
        unselectedItemColor: Colors.black,
        items: [
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
        // Navigator.push(context, MaterialPageRoute(builder: (context) => WHome()));
        break;
      case 2:
        Navigator.push(context, MaterialPageRoute(builder: (context) => Home()));
        break;
      case 3:
        Navigator.push(context, MaterialPageRoute(builder: (context) => CHome()));
        break;
      case 4:
        Navigator.push(context, MaterialPageRoute(builder: (context) => GHome()));
        break;
    }
  }

}