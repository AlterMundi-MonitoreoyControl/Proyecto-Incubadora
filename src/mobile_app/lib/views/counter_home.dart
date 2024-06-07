import 'package:flutter/material.dart';
import 'dart:collection'; 
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:incubapp_lite/views/home.dart';
import 'package:incubapp_lite/views/wifi_home.dart';
import 'package:incubapp_lite/views/initial_home.dart';
import 'package:incubapp_lite/services/api_services.dart';
// import 'package:incubapp_lite/services/counter_home.dart';
import 'package:incubapp_lite/views/graf_home.dart';
import 'package:incubapp_lite/models/config_model.dart';


class CHome extends StatefulWidget {
  @override
  _CHomeState createState() => _CHomeState();
}

class _CHomeState extends State<CHome> {
  
  int _selectedIndex = 0; 

  List<int> _bandejaSelectedIndexList = [1, 1, 1]; 

  List<int?> _bandejaTimestamps = [0, 0, 0];

  late Config? _configModel = Config(ssid: "SSID", minTemperature: 37, maxTemperature: 39, rotationPeriod: 3600000, rotationDuration: 5000, passwd: "12345678", hash: 1234, incubationPeriod: 18, trayOneDate: 10000, trayTwoDate: 5000, trayThreeDate: 0);

  @override
  void initState() {
    super.initState();
    _getData();
  }
  Future<void> _getData() async {
    _configModel = await ApiService().getConfig();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    
    int hash = _configModel?.hash ?? 0;
    int incubation_period = _configModel?.incubationPeriod ?? 0;
    int maxtemp = _configModel?.maxTemperature ?? 0;
    int mintemp = _configModel?.minTemperature ?? 0;
    String password = _configModel?.passwd ?? "";
    int rotation_duration = _configModel?.rotationDuration ?? 0;
    int rotation_period =_configModel?.rotationPeriod ?? 0;
    String ssid = _configModel?.ssid ?? "";
    int tray_one_date = _configModel?.trayOneDate ?? 0;
    int tray_two_date = _configModel?.trayTwoDate ?? 0;
    int tray_three_date = _configModel?.trayThreeDate ?? 0;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Contador de Días'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 200,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    if (_bandejaSelectedIndexList[0] == 0) {
                      _showRedDialog(0);
                    } else {
                      _bandejaSelectedIndexList[0] = 0;
                      _showGreenDialog(0);
                      _bandejaTimestamps[0] = DateTime.now().millisecondsSinceEpoch;
                      int? newTrayOneDate = _bandejaTimestamps[0];
                      setState(() {
                                _configModel?.trayOneDate = newTrayOneDate!;
                              });
                              ApiService().updateConfig({'hash': _configModel?.hash,'incubation_period': _configModel?.incubationPeriod,'max_temperature': _configModel?.maxTemperature,'min_temperature': _configModel?.minTemperature,'passwd': password,'rotation_duration': rotation_duration,'rotation_period': rotation_period,'ssid': ssid,'tray_one_date': newTrayOneDate,'tray_three_date': _configModel?.trayThreeDate,'tray_two_date': _configModel?.trayTwoDate});
                      print('Timestamp: ${_bandejaTimestamps[0]}');
                    }
                  });
                  print('BANDEJA 1 pressed!');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _bandejaSelectedIndexList[0] == 1 ? const Color.fromARGB(255, 138, 201, 140) : const Color.fromARGB(255, 179, 65, 65),
                ),
                child: Text(
                  'BANDEJA 1',
                  style: TextStyle(color: Colors.white), 
                  ),
              ),
            ),
            SizedBox(height: 20), 
            SizedBox(
              width: 200,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    if (_bandejaSelectedIndexList[1] == 0) {
                      _showRedDialog(1);
                    } else {
                      _bandejaSelectedIndexList[1] = 0;
                      _showGreenDialog(1);
                      _bandejaTimestamps[1] = DateTime.now().millisecondsSinceEpoch;
                      int? newTrayTwoDate = _bandejaTimestamps[1];
                      setState(() {
                                _configModel?.trayTwoDate = newTrayTwoDate!;
                              });
                              ApiService().updateConfig({'hash': _configModel?.hash,'incubation_period': _configModel?.incubationPeriod,'max_temperature': _configModel?.maxTemperature,'min_temperature': _configModel?.minTemperature,'passwd': password,'rotation_duration': rotation_duration,'rotation_period': rotation_period,'ssid': ssid,'tray_one_date': _configModel?.trayOneDate,'tray_three_date': _configModel?.trayThreeDate,'tray_two_date': newTrayTwoDate});
                      print('Timestamp: ${_bandejaTimestamps[1]}');
                    }
                  });
                  print('BANDEJA 2 pressed!');                  
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _bandejaSelectedIndexList[1] == 1 ? const Color.fromARGB(255, 138, 201, 140) :  const Color.fromARGB(255, 179, 65, 65),
                ),
                child: Text(
                  'BANDEJA 2',
                  style: TextStyle(color: Colors.white), 
                  ),
              ),
            ),
            SizedBox(height: 20),
            SizedBox(
              width: 200, 
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    if (_bandejaSelectedIndexList[2] == 0) {
                      _showRedDialog(2);
                    } else {
                      _bandejaSelectedIndexList[2] = 0;
                      _showGreenDialog(2);
                      _bandejaTimestamps[2] = DateTime.now().millisecondsSinceEpoch;
                      int? newTrayThreeDate = _bandejaTimestamps[2];
                      setState(() {
                                _configModel?.trayThreeDate = newTrayThreeDate!;
                              });
                              ApiService().updateConfig({'hash': _configModel?.hash,'incubation_period': _configModel?.incubationPeriod,'max_temperature': _configModel?.maxTemperature,'min_temperature': _configModel?.minTemperature,'passwd': password,'rotation_duration': rotation_duration,'rotation_period': rotation_period,'ssid': ssid,'tray_one_date': _configModel?.trayOneDate,'tray_three_date': newTrayThreeDate,'tray_two_date': _configModel?.trayTwoDate});
                      print('Timestamp: ${_bandejaTimestamps[2]}');
                    }
                  });
                  print('BANDEJA 3 pressed!');                  
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _bandejaSelectedIndexList[2] == 1 ? const Color.fromARGB(255, 138, 201, 140) : const Color.fromARGB(255, 179, 65, 65),
                ),
                child: Text(
                  'BANDEJA 3',
                  style: TextStyle(color: Colors.white), 
                  ),
              ),
            ),
          ],
        ),
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
        Navigator.push(context, MaterialPageRoute(builder: (context) => WHome()));
        break;
      case 2:
        Navigator.push(context, MaterialPageRoute(builder: (context) => Home()));
        break;
      case 3:
        // Navigator.push(context, MaterialPageRoute(builder: (context) => CHome()));
        break;
      case 4:
        Navigator.push(context, MaterialPageRoute(builder: (context) => GHome()));
        break;
    }
  }

  void _showGreenDialog(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('La bandeja ha comenzado un nuevo ciclo, los huevos deberán ser movidos a nacedora en 18 días'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Aceptar'),
            ),
          ],
        );
      },
    );
  }

  void _showRedDialog(int index) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('El ciclo todavía no terminó. ¿Está seguro de que desea cambiar el estado de la bandeja?'),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Cerrar el diálogo sin cambiar el color del botón
            },
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _bandejaSelectedIndexList[index] = 1; // Cambiar el color del botón
                _bandejaTimestamps[index] = 0;
                print('Timestamp: ${_bandejaTimestamps[index]}');
              });

              switch (index) {
                case 0:
                  _configModel?.trayOneDate = _bandejaTimestamps[index]!;
                  ApiService().updateConfig({'hash': _configModel?.hash,'incubation_period': _configModel?.incubationPeriod,'max_temperature': _configModel?.maxTemperature,'min_temperature': _configModel?.minTemperature,'passwd': _configModel?.passwd,'rotation_duration': _configModel?.rotationDuration,'rotation_period': _configModel?.rotationPeriod,'ssid': _configModel?.ssid,'tray_one_date': _configModel?.trayOneDate,'tray_three_date': _configModel?.trayThreeDate,'tray_two_date': _configModel?.trayTwoDate});
                  break;
                case 1:
                  _configModel?.trayTwoDate = _bandejaTimestamps[index]!;
                  ApiService().updateConfig({'hash': _configModel?.hash,'incubation_period': _configModel?.incubationPeriod,'max_temperature': _configModel?.maxTemperature,'min_temperature': _configModel?.minTemperature,'passwd': _configModel?.passwd,'rotation_duration': _configModel?.rotationDuration,'rotation_period': _configModel?.rotationPeriod,'ssid': _configModel?.ssid,'tray_one_date': _configModel?.trayOneDate,'tray_three_date': _configModel?.trayThreeDate,'tray_two_date': _configModel?.trayTwoDate});
                  break;
                case 2:
                  _configModel?.trayThreeDate = _bandejaTimestamps[index]!;
                  ApiService().updateConfig({'hash': _configModel?.hash,'incubation_period': _configModel?.incubationPeriod,'max_temperature': _configModel?.maxTemperature,'min_temperature': _configModel?.minTemperature,'passwd': _configModel?.passwd,'rotation_duration': _configModel?.rotationDuration,'rotation_period': _configModel?.rotationPeriod,'ssid': _configModel?.ssid,'tray_one_date': _configModel?.trayOneDate,'tray_three_date': _configModel?.trayThreeDate,'tray_two_date': _configModel?.trayTwoDate});
                  break;
              }

              Navigator.of(context).pop(); // Cerrar el diálogo
            },
            child: Text('Aceptar'),
          ),
        ],
      );
    },
  );
}


}