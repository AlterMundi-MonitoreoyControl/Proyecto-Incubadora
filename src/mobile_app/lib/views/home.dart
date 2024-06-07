import 'package:flutter/widgets.dart';
import 'package:incubapp_lite/services/api_services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/material.dart';
import 'package:incubapp_lite/views/initial_home.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:incubapp_lite/views/home.dart';
import 'package:incubapp_lite/views/wifi_home.dart';
import 'package:incubapp_lite/views/counter_home.dart';
import 'package:incubapp_lite/views/graf_home.dart';
import 'package:incubapp_lite/models/config_model.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  
  int _selectedIndex = 0; 
  String incubator_name = 'Incu 1';

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

  String calculateElapsedTime(int epochTime) {
    if (epochTime == 0) {
      return "LA BANDEJA ESTÁ VACÍA";
    }
    
    int nowEpoch = DateTime.now().millisecondsSinceEpoch;
    int difference = nowEpoch - epochTime;

    Duration duration = Duration(milliseconds: difference);
    int days = duration.inDays;
    int hours = duration.inHours % 24;
    int minutes = duration.inMinutes % 60;

    return '$days días, $hours horas y $minutes minutos';
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
        title: Text('Configuraciones'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ListTile(
              title: Text('NOMBRE DE LA INCUBADORA'),
              subtitle: Row(
                children: [
                  Text(incubator_name),
                  SizedBox(width: 12),
                  IconButton(
                    onPressed: () {
                      _showInputDialog(
                        context,
                        'NOMBRE DE LA INCUBADORA',
                        incubator_name.toString(),
                        (newValue) {
                          if (newValue != null && newValue.isNotEmpty) {
                            setState(() {
                              incubator_name = newValue;
                            });
                          }
                        },
                      );
                    },
                    icon: Icon(Icons.edit),
                  ),
                ],
              ),
            ),
            ListTile(
              title: Text('TEMPERATURA MÁXIMA'),
              subtitle: Row(
                children: [
                  Text('${_configModel?.maxTemperature ?? 0}'), // Utiliza _configModel?.maxTemperature (el valor directamente del json)
                  SizedBox(width: 12),
                  IconButton(
                    onPressed: () {
                    _showInputDialog(
                      context,
                      'TEMPERATURA MÁXIMA',
                      (_configModel?.maxTemperature ?? 0).toString(),
                      (newValue) {
                        if (newValue != null && newValue.isNotEmpty) {
                          int? newMaxTemp = int.tryParse(newValue);

                          if (newMaxTemp != null) {
                            setState(() {
                              _configModel?.maxTemperature = newMaxTemp; // Actualiza _configModel?.maxTemperature en lugar de una variable que luego es enviada
                            });
                            // Llama a la función para enviar los datos actualizados a la API
                            ApiService().updateConfig({'hash': _configModel?.hash,'incubation_period': _configModel?.incubationPeriod,'max_temperature': newMaxTemp,'min_temperature': _configModel?.minTemperature,'passwd': password,'rotation_duration': rotation_duration,'rotation_period': rotation_period,'ssid': ssid,'tray_one_date': tray_one_date,'tray_three_date': tray_three_date,'tray_two_date': tray_two_date});
                          } else {
                            // Maneja el caso en el que la conversión a int falla
                            print('Valor de temperatura no válido');
                          }
                        }
                      },
                    );
                  },
                    icon: Icon(Icons.edit),
                  ),
                ],
              ),
            ),
            ListTile(
              title: Text('TEMPERATURA MÍNIMA'),
              subtitle: Row(
                children: [
                  Text('${_configModel?.minTemperature ?? 0}'),
                  SizedBox(width: 12),
                  IconButton(
                    onPressed: () {
                      _showInputDialog(
                        context,
                        'TEMPERATURA MÍNIMA',
                        (_configModel?.minTemperature ?? 0).toString(),
                        (newValue) {
                          if (newValue != null && newValue.isNotEmpty) {
                            int? newMinTemp = int.tryParse(newValue);

                            if (newMinTemp != null) { 
                              setState(() {
                                _configModel?.minTemperature = newMinTemp; 
                              });
                              ApiService().updateConfig({'hash': _configModel?.hash,'incubation_period': _configModel?.incubationPeriod,'max_temperature': _configModel?.maxTemperature,'min_temperature': newMinTemp,'passwd': password,'rotation_duration': rotation_duration,'rotation_period': rotation_period,'ssid': ssid,'tray_one_date': tray_one_date,'tray_three_date': tray_three_date,'tray_two_date': tray_two_date}); 
                            } else {
                              print('Valor de temperatura no válido');
                            }
                          }
                        },
                      );
                    },
                    icon: Icon(Icons.edit),
                  ),
                ],
              ),
            ),
            ListTile(
              title: Text('DIAS DE INCUBACION B. 1'),
              subtitle: Text(calculateElapsedTime(tray_one_date)),
            ),
            ListTile(
              title: Text('DIAS DE INCUBACION B. 2'),
              subtitle: Text(calculateElapsedTime(tray_two_date)),
            ),
            ListTile(
              title: Text('DIAS DE INCUBACION B. 3'),
              subtitle: Text(calculateElapsedTime(tray_three_date)),
            ),
            ListTile(
              title: Text('DÍAS DEL PROCESO'),
              subtitle: Row(
                children: [
                  Text('${_configModel?.incubationPeriod ?? 0}'),
                  SizedBox(width: 12),
                  IconButton(
                    onPressed: () {
                      _showInputDialog(
                        context,
                        'DÍAS DEL PROCESO',
                        (_configModel?.incubationPeriod ?? 0).toString(),
                        (newValue) {
                          if (newValue != null && newValue.isNotEmpty) {
                            int? newIncPeriod = int.tryParse(newValue);

                            if (newIncPeriod != null) { 
                              setState(() {
                                _configModel?.incubationPeriod = newIncPeriod; 
                              });
                              ApiService().updateConfig({'hash': _configModel?.hash,'incubation_period': newIncPeriod,'max_temperature': _configModel?.maxTemperature,'min_temperature': _configModel?.minTemperature,'passwd': password,'rotation_duration': rotation_duration,'rotation_period': rotation_period,'ssid': ssid,'tray_one_date': tray_one_date,'tray_three_date': tray_three_date,'tray_two_date': tray_two_date}); 
                            } else {
                              print('Valor de temperatura no válido');
                            }
                          }
                        },
                      );
                    },
                    icon: Icon(Icons.edit),
                  ),
                ],
              ),
            ),
            ListTile(
              title: Text('HASH NOTIFY'),
              subtitle: Row(
                children: [
                  Text('${_configModel?.hash ?? 0}'),
                  SizedBox(width: 12),
                  IconButton(
                    onPressed: () {
                      _showInputDialog(
                        context,
                        'HASH NOTIFY',
                        (_configModel?.hash ?? 0).toString(),
                        (newValue) {
                          if (newValue != null && newValue.isNotEmpty) {
                            int? newHash = int.tryParse(newValue);

                            if (newHash != null) { 
                              setState(() {
                                _configModel?.hash = newHash; 
                              });
                              ApiService().updateConfig({'hash': newHash,'incubation_period': _configModel?.incubationPeriod,'max_temperature': _configModel?.maxTemperature,'min_temperature': _configModel?.minTemperature,'passwd': password,'rotation_duration': rotation_duration,'rotation_period': rotation_period,'ssid': ssid,'tray_one_date': tray_one_date,'tray_three_date': tray_three_date,'tray_two_date': tray_two_date}); 
                            } else {
                              print('Valor de temperatura no válido');
                            }
                          }
                        },
                      );
                    },
                    icon: Icon(Icons.edit),
                  ),
                ],
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
        // Navigator.push(context, MaterialPageRoute(builder: (context) => Home()));
        break;
      case 3:
        Navigator.push(context, MaterialPageRoute(builder: (context) => CHome()));
        break;
      case 4:
        Navigator.push(context, MaterialPageRoute(builder: (context) => GHome()));
        break;
    }
  }

  void _showInputDialog(BuildContext context, String title, String currentValue, Function(String?) onSubmit) {
    TextEditingController controller = TextEditingController(text: currentValue);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Ingrese el nuevo valor de $title'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(hintText: 'Nuevo valor'),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Aceptar'),
              onPressed: () {
                onSubmit(controller.text);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}