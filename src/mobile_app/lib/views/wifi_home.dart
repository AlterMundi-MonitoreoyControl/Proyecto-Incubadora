import 'package:incubapp_lite/models/wifi_model.dart';
import 'package:incubapp_lite/models/actual_model.dart';
import 'package:incubapp_lite/models/config_model.dart';
import 'package:incubapp_lite/services/api_services.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart' hide Config;
import 'package:incubapp_lite/views/initial_home.dart';
import 'package:incubapp_lite/views/home.dart';
import 'package:incubapp_lite/views/counter_home.dart';
import 'package:incubapp_lite/views/graf_home.dart';
import 'package:incubapp_lite/views/rotation_home.dart';


class WHome extends StatefulWidget {
  const WHome({Key? key}) : super(key: key);

  @override
  _WHomeState createState() => _WHomeState();
}

class _WHomeState extends State<WHome> {
  int _selectedIndex = 0;
  Wifi? _wifiModel;
  Config? _configModel;
  bool _showConnectionError = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _startConnectionTimer();
  }

  void _startConnectionTimer() {
    Future.delayed(const Duration(seconds: 5), () {
      if (_wifiModel == null && mounted) {
        setState(() {
          _showConnectionError = true;
        });
      }
    });
  }

  Future<void> _loadData() async {
    try {
      _wifiModel = await ApiService().getWifi();
      _configModel = await ApiService().getConfig();
      setState(() {});
    } catch (e) {
      print(e);
    }
  }

  void _retryConnection() {
    setState(() {
      _showConnectionError = false;
    });
    _loadData();
    _startConnectionTimer();
  }

  Future<void> _connectToWifi(String ssid, String password) async {
    try {
      if (ssid.isEmpty) {
        throw ("La SSID no puede estar vacía");
      }

      Map<String, dynamic> updatedConfig = {
        'ssid': ssid,
        'passwd': password,
        'hash': _configModel?.hash,
        'incubator_name': _configModel?.incubatorName,
        'incubation_period': _configModel?.incubationPeriod,
        'max_temperature': _configModel?.maxTemperature,
        'min_temperature': _configModel?.minTemperature,
        'max_hum': _configModel?.maxHum,
        'min_hum': _configModel?.minHum,
        'rotation_duration': _configModel?.rotationDuration,
        'rotation_period': _configModel?.rotationPeriod,
        'tray_one_date': _configModel?.trayOneDate,
        'tray_two_date': _configModel?.trayTwoDate,
        'tray_three_date': _configModel?.trayThreeDate,
      };

      await ApiService().updateConfig(updatedConfig);

      _showLoadingDialog();

      const delayDuration = Duration(seconds: 15);
      await Future.delayed(delayDuration);

      Navigator.pop(context);

      Actual? actualStatus = await ApiService().getActual();
      
      String message;
      if (actualStatus?.wifiStatus == "connected") {
        message = "Contraseña correcta. Conexión exitosa.";
      } else if (actualStatus?.wifiStatus == "disconnected") {
        message = "No se pudo conectar a la red. Verifique las credenciales.";
      } else {
        message = "Verifique la Conexión";
      }

      _showResultDialog("Resultado de la conexión", message);

    } catch (e) {
      print("Error: $e");
      _showResultDialog("Error", "No se pudo conectar: $e");
    }
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color.fromARGB(245, 255, 255, 255),
          title: Text(
            'Conectando...',
            style: GoogleFonts.questrial(
              color: Colors.black,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                color: Colors.black,
              ),
              const SizedBox(height: 20),
              Text(
                'Esperando respuesta del dispositivo.',
                style: GoogleFonts.questrial(
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showResultDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color.fromARGB(245, 255, 255, 255),
        title: Text(
          title,
          style: GoogleFonts.questrial(
            color: Colors.black,
          ),
        ),
        content: Text(
          message,
          style: GoogleFonts.questrial(
            color: Colors.black87,
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black87,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 10,
              ),
            ),
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Aceptar',
              style: GoogleFonts.questrial(),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showPasswordDialog(String ssid) async {
    String password = '';
    bool obscureText = true; 

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder( 
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color.fromARGB(245, 255, 255, 255),
              title: Text(
                'Ingrese la contraseña para $ssid',
                style: GoogleFonts.questrial(
                  color: Colors.black,
                ),
              ),
              content: TextField(
                onChanged: (value) {
                  password = value;
                },
                obscureText: obscureText,
                style: GoogleFonts.questrial(
                  color: Colors.black,
                ),
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  labelStyle: GoogleFonts.questrial(
                    color: const Color.fromRGBO(65, 65, 65, 1),
                  ),
                  enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color:  Color.fromRGBO(65, 65, 65, 1)),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color:  Color.fromRGBO(65, 65, 65, 1)),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscureText ? Icons.visibility : Icons.visibility_off,
                      color: const Color.fromRGBO(65, 65, 65, 1),
                    ),
                    onPressed: () {
                      setState(() {
                        obscureText = !obscureText;
                      });
                    },
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancelar',
                    style: GoogleFonts.questrial(
                      color: const Color.fromRGBO(65, 65, 65, 1),
                    ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black87,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 10,
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    _connectToWifi(ssid, password);
                  },
                  child: Text(
                    'Conectar',
                    style: GoogleFonts.questrial(),
                  ),
                ),
              ],
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('REDES DISPONIBLES'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: const Color.fromRGBO(65, 65, 65, 1),
      body: _wifiModel == null
          ? Center(
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
            )
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: ListView.builder(
                itemCount: _wifiModel!.networks.length,
                itemBuilder: (context, index) {
                  final network = _wifiModel!.networks[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(225, 255, 255, 255),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      title: Text(
                        network.ssid,
                        style: GoogleFonts.questrial(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        'RSSI: ${network.rssi}',
                        style: GoogleFonts.questrial(
                          color: Colors.black54,
                        ),
                      ),
                      leading: const Icon(
                        Icons.wifi,
                        color: Colors.black54,
                      ),
                      onTap: () => _showPasswordDialog(network.ssid),
                    ),
                  );
                },
              ),
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
