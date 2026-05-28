import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart' hide Config;
import 'package:incubapp_lite/views/home.dart';
import 'package:incubapp_lite/views/wifi_home.dart';
import 'package:incubapp_lite/views/initial_home.dart';
import 'package:incubapp_lite/services/api_services.dart';
import 'package:incubapp_lite/views/graf_home.dart';
import 'package:incubapp_lite/models/config_model.dart';
import 'package:incubapp_lite/views/rotation_home.dart';


class CHome extends StatefulWidget {
  @override
  _CHomeState createState() => _CHomeState();
}

class _CHomeState extends State<CHome> {
  Config? _configModel;
  int _selectedIndex = 0;
  bool _showConnectionError = false;
  List<int> _bandejaSelectedIndexList = [1, 1, 1];
  List<int?> _bandejaTimestamps = [0, 0, 0];

  @override
  void initState() {
    super.initState();
    _getData();
    _startConnectionTimer();
  }

  void _startConnectionTimer() {
    Future.delayed(const Duration(seconds: 5), () {
      if (_configModel == null && mounted) {
        setState(() {
          _showConnectionError = true;
        });
      }
    });
  }

  Future<void> _getData() async {
    _configModel = await ApiService().getConfig();
    if (mounted) {
      setState(() {
        _initializeBandejaColors();
      });
    }
  }

  void _retryConnection() {
    setState(() {
      _showConnectionError = false;
    });
    _getData();
    _startConnectionTimer();
  }

  void _initializeBandejaColors() {
    _bandejaSelectedIndexList[0] = _configModel?.trayOneDate == 0 ? 1 : 0;
    _bandejaSelectedIndexList[1] = _configModel?.trayTwoDate == 0 ? 1 : 0;
    _bandejaSelectedIndexList[2] = _configModel?.trayThreeDate == 0 ? 1 : 0;
  }

  @override
  Widget build(BuildContext context) {
    if (_configModel == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Contador de Días'),
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contador de Días'),
      ),
      backgroundColor: const Color.fromRGBO(65, 65, 65, 1),
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
                      ApiService().updateConfig({
                        'incubator_name': _configModel?.incubatorName,
                        'hash': _configModel?.hash,
                        'incubation_period': _configModel?.incubationPeriod,
                        'max_temperature': _configModel?.maxTemperature,
                        'min_temperature': _configModel?.minTemperature,
                        'max_hum': _configModel?.maxHum,
                        'min_hum': _configModel?.minHum,
                        'passwd': _configModel?.passwd,
                        'rotation_duration': _configModel?.rotationDuration,
                        'rotation_period': _configModel?.rotationPeriod,
                        'ssid': _configModel?.ssid,
                        'tray_one_date': newTrayOneDate,
                        'tray_three_date': _configModel?.trayThreeDate,
                        'tray_two_date': _configModel?.trayTwoDate
                      });
                    }
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _bandejaSelectedIndexList[0] == 1
                      ? const Color.fromARGB(255, 138, 201, 140)
                      : const Color.fromARGB(255, 179, 65, 65),
                ),
                child: const Text(
                  'BANDEJA 1',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 20),
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
                      ApiService().updateConfig({
                        'incubator_name': _configModel?.incubatorName,
                        'hash': _configModel?.hash,
                        'incubation_period': _configModel?.incubationPeriod,
                        'max_temperature': _configModel?.maxTemperature,
                        'min_temperature': _configModel?.minTemperature,
                        'max_hum': _configModel?.maxHum,
                        'min_hum': _configModel?.minHum,
                        'passwd': _configModel?.passwd,
                        'rotation_duration': _configModel?.rotationDuration,
                        'rotation_period': _configModel?.rotationPeriod,
                        'ssid': _configModel?.ssid,
                        'tray_one_date': _configModel?.trayOneDate,
                        'tray_three_date': _configModel?.trayThreeDate,
                        'tray_two_date': newTrayTwoDate
                      });
                    }
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _bandejaSelectedIndexList[1] == 1
                      ? const Color.fromARGB(255, 138, 201, 140)
                      : const Color.fromARGB(255, 179, 65, 65),
                ),
                child: const Text(
                  'BANDEJA 2',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 20),
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
                      ApiService().updateConfig({
                        'incubator_name': _configModel?.incubatorName,
                        'hash': _configModel?.hash,
                        'incubation_period': _configModel?.incubationPeriod,
                        'max_temperature': _configModel?.maxTemperature,
                        'min_temperature': _configModel?.minTemperature,
                        'max_hum': _configModel?.maxHum,
                        'min_hum': _configModel?.minHum,
                        'passwd': _configModel?.passwd,
                        'rotation_duration': _configModel?.rotationDuration,
                        'rotation_period': _configModel?.rotationPeriod,
                        'ssid': _configModel?.ssid,
                        'tray_one_date': _configModel?.trayOneDate,
                        'tray_three_date': newTrayThreeDate,
                        'tray_two_date': _configModel?.trayTwoDate
                      });
                    }
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _bandejaSelectedIndexList[2] == 1
                      ? const Color.fromARGB(255, 138, 201, 140)
                      : const Color.fromARGB(255, 179, 65, 65),
                ),
                child: const Text(
                  'BANDEJA 3',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildNavigationBar(),
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
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => IHome()));
        break;
      case 1:
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => WHome()));
        break;
      case 2:
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => Home()));
        break;
      case 3:
        break;
      case 4:
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => RHome()));
        break;
      case 5:
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => GHome()));
      break;
    }
  }

  void _showGreenDialog(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
              'La bandeja ha comenzado un nuevo ciclo, los huevos deberán ser movidos a nacedora en 18 días'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Aceptar'),
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
          title: const Text(
              'El ciclo todavía no terminó. ¿Está seguro de que desea cambiar el estado de la bandeja?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _bandejaSelectedIndexList[index] = 1;
                  _bandejaTimestamps[index] = 0;
                });

                switch (index) {
                  case 0:
                    _configModel?.trayOneDate = _bandejaTimestamps[index]!;
                    break;
                  case 1:
                    _configModel?.trayTwoDate = _bandejaTimestamps[index]!;
                    break;
                  case 2:
                    _configModel?.trayThreeDate = _bandejaTimestamps[index]!;
                    break;
                }

                ApiService().updateConfig({
                  'incubator_name': _configModel?.incubatorName,
                  'hash': _configModel?.hash,
                  'incubation_period': _configModel?.incubationPeriod,
                  'max_temperature': _configModel?.maxTemperature,
                  'min_temperature': _configModel?.minTemperature,
                  'max_hum': _configModel?.maxHum,
                  'min_hum': _configModel?.minHum,
                  'passwd': _configModel?.passwd,
                  'rotation_duration': _configModel?.rotationDuration,
                  'rotation_period': _configModel?.rotationPeriod,
                  'ssid': _configModel?.ssid,
                  'tray_one_date': _configModel?.trayOneDate,
                  'tray_three_date': _configModel?.trayThreeDate,
                  'tray_two_date': _configModel?.trayTwoDate
                });

                Navigator.of(context).pop();
              },
              child: const Text('Aceptar'),
            ),
          ],
        );
      },
    );
  }
}