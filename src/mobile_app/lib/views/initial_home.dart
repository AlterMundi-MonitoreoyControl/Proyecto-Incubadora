import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart' hide Config;
import 'package:incubapp_lite/models/actual_model.dart';
import 'package:incubapp_lite/models/config_model.dart';
import 'package:incubapp_lite/views/home.dart';
import 'package:incubapp_lite/views/wifi_home.dart';
import 'package:incubapp_lite/services/api_services.dart';
import 'package:incubapp_lite/views/counter_home.dart';
import 'package:incubapp_lite/views/graf_home.dart';
import 'package:incubapp_lite/views/notif_home.dart';
import 'package:incubapp_lite/views/rotation_home.dart';
import 'package:incubapp_lite/views/ntfy_home.dart';


void main() => runApp(MaterialApp(
      debugShowCheckedModeBanner: false,
      home: IHome(),
    ));

class IHome extends StatefulWidget {
  @override
  _IHomeState createState() => _IHomeState();
}

class _IHomeState extends State<IHome> {
  Actual? _actualModel;
  Config? _configModel;
  int _selectedIndex = 0;
  bool _showConnectionError = false;
  
  @override
  void initState() {
    super.initState();
    _getData();
    _startConnectionTimer();
  }

  void _startConnectionTimer() {
    Future.delayed(const Duration(seconds: 5), () {
      if (_actualModel == null && mounted) {
        setState(() {
          _showConnectionError = true;
        });
      }
    });
  }
  
  Future<void> _getData() async {
    _actualModel = await ApiService().getActual();
    _configModel = await ApiService().getConfig();
    setState(() {});
  }

  void _retryConnection() {
    setState(() {
      _showConnectionError = false;
    });
    _getData();
    _startConnectionTimer();
  }

  Widget buildStatusIndicator(String title, String status, Color statusColor, Size size) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "$title: ",
            style: GoogleFonts.questrial(
              color: Colors.white,
              fontSize: size.height * 0.025,
            ),
          ),
          Text(
            status,
            style: GoogleFonts.questrial(
              color: statusColor,
              fontSize: size.height * 0.025,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildValueIndicator({
    required IconData icon,
    required String title,
    required String value,
    required Color valueColor,
    required Size size,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 30,
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: GoogleFonts.questrial(
              color: Colors.white,
              fontSize: size.height * 0.03,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.questrial(
              color: valueColor,
              fontSize: size.height * 0.05,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    if (_actualModel == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          actions: [            
            IconButton(
              iconSize: 30.0,
              icon: const Icon(Icons.chat, color: Colors.black),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => NtfySubscriptionScreen()),
                );
              },
            ),
            IconButton(
              iconSize: 30.0,
              icon: const Icon(Icons.notifications, color: Colors.black),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => NHome()),
                );
              },
            ),
          ],
        ),
        backgroundColor: const Color.fromRGBO(65, 65, 65, 1),
        body: Center(
          child: _showConnectionError 
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Verifique conexión con incubadora',
                    style: GoogleFonts.questrial(
                      color: Colors.white,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _retryConnection,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 15,
                      ),
                    ),
                    child: const Text('Reintentar'),
                  ),
                ],
              )
            : const CircularProgressIndicator(
                color: Colors.white,
              ),
        ),
        bottomNavigationBar: _buildNavigationBar(),
      );
    }

    final temperature = _actualModel!.aTemperature;
    final humidity = _actualModel!.aHumidity;
    final wifiStatus = _actualModel!.wifiStatus;
    final rotation = _actualModel!.rotation;
    
    final maxtemp = _configModel!.maxTemperature;
    final mintemp = _configModel!.minTemperature;
    final maxhum = _configModel!.maxHum;
    final minhum = _configModel!.minHum;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
              iconSize: 30.0,
              icon: const Icon(Icons.chat, color: Colors.black),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => NtfySubscriptionScreen()),
                );
              },
            ),
          IconButton(
            iconSize: 30.0,
            icon: const Icon(Icons.notifications, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => NHome()),
              );
            },
          ),          
        ],
      ),
      backgroundColor: const Color.fromRGBO(65, 65, 65, 1),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color.fromRGBO(65, 65, 65, 1), Color.fromRGBO(65, 65, 65, 1)]
          )
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Estado del sistema
                  Container(
                    padding: const EdgeInsets.all(15),
                    margin: const EdgeInsets.all(20),
                    width: size.width * 0.9,
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      children: [
                        buildWifiStatus(context, wifiStatus, size),
                        const SizedBox(height: 15),
                        buildRotStatus(context, rotation, size),
                      ],
                    ),
                  ),
                  
                  // Indicadores principales
                  SizedBox(
                    width: size.width * 0.9,
                    child: buildValueIndicator(
                      icon: FontAwesomeIcons.temperatureHalf,
                      title: "Temperatura",
                      value: "$temperature˚C",
                      valueColor: Tcolor(temperature, maxtemp, mintemp),
                      size: size,
                    ),
                  ),
                  SizedBox(
                    width: size.width * 0.9,
                    child: buildValueIndicator(
                      icon: FontAwesomeIcons.droplet,
                      title: "Humedad",
                      value: "$humidity%",
                      valueColor: Hcolor(humidity, maxhum, minhum),
                      size: size,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildNavigationBar(),
    );
  }

  Widget buildWifiStatus(BuildContext context, String wifiStatus, Size size) {
    late final Color statusColor;
    late final String displayText;
    
    switch (wifiStatus) {
      case "connected":
        statusColor = Colors.lightGreenAccent;
        displayText = "Conectado";
        break;
      case "disconnected":
        statusColor = Colors.red;
        displayText = "Desconectado";
        break;
      default:
        statusColor = Colors.orange;
        displayText = "Verificando";
        
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Future.delayed(const Duration(seconds: 4), () {
            if (context.mounted && 
                wifiStatus != "connected" && 
                wifiStatus != "disconnected") {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Estado de Conexión'),
                    content: const Text('No se ha podido establecer conexión con la incubadora.'),
                    actions: <Widget>[
                      TextButton(
                        child: const Text('Aceptar'),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  );
                },
              );
            }
          });
        });
    }

    return buildStatusIndicator("WiFi", displayText, statusColor, size);
  }

  Widget buildRotStatus(BuildContext context, bool rotation, Size size) {
    return buildStatusIndicator(
      "Estado de Rotación",
      rotation ? "Activa" : "Error",
      rotation ? Colors.lightGreenAccent : Colors.red,
      size
    );
  }

  Widget _buildNavigationBar() {
    return BottomNavigationBar(
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
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    switch (index) {
      case 0:
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
        Navigator.push(context, MaterialPageRoute(builder: (context) => GHome()));
        break;
    }
  }
}

Color Tcolor(temperature, double maxTemp, double minTemp) {
  if (temperature <= 0) {
    return Colors.red;
  } else if (temperature <= maxTemp && temperature >= minTemp) {
    return Colors.lightGreenAccent;
  } else {
    return Colors.red;
  }
}

Color Hcolor(humidity, int maxHum, int minHum) {
  if (humidity <= 0) {
    return Colors.red;
  } else if (humidity <= maxHum && humidity >= minHum) {
    return Colors.lightGreenAccent;
  } else {
    return Colors.red;
  }
}