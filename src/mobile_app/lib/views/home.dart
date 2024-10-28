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

  late Config? _configModel = Config(incubatorName: "Nombre", ssid: "SSID", minHum: 50, maxHum: 70, minTemperature: 37, maxTemperature: 39, rotationPeriod: 3600000, rotationDuration: 5000, passwd: "12345678", hash: "1234", incubationPeriod: 18, trayOneDate: 10000, trayTwoDate: 5000, trayThreeDate: 0);
  
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
    String incubator_name = _configModel?.incubatorName ?? "";
    String hash = _configModel?.hash ?? "";
    int incubation_period = _configModel?.incubationPeriod ?? 0;
    double maxtemp = _configModel?.maxTemperature ?? 0;
    double mintemp = _configModel?.minTemperature ?? 0;
    int maxhum = _configModel?.maxHum ?? 0;
    int minhum = _configModel?.minHum ?? 0;
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
                  Text('${_configModel?.incubatorName ?? 0}'),
                  SizedBox(width: 12),
                  IconButton(
                    onPressed: () {
                      _showInputDialog(
                        context,
                        'NOMBRE DE LA INCUBADORA',
                        incubator_name.toString(),
                        (newName) {
                          if (newName != null && newName.isNotEmpty) {                            
                            incubator_name = newName;

                            if (newName != null) { 
                              setState(() {
                                _configModel?.incubatorName = newName; 
                              });
                              ApiService().updateConfig({'incubator_name': newName, 'hash': _configModel?.hash,'incubation_period': _configModel?.incubationPeriod,'max_temperature': _configModel?.maxTemperature,'min_temperature': _configModel?.minTemperature, 'max_humidity': _configModel?.maxHum, 'min_humidity': _configModel?.minHum, 'passwd': password,'rotation_duration': rotation_duration,'rotation_period': rotation_period,'ssid': ssid,'tray_one_date': tray_one_date,'tray_three_date': tray_three_date,'tray_two_date': tray_two_date}); 
                            } else {
                              print('Nombre no válido');
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
                          double? newMaxTemp = double.tryParse(newValue);

                          if (newMaxTemp != null) {
                            setState(() {
                              _configModel?.maxTemperature = newMaxTemp; // Actualiza _configModel?.maxTemperature en lugar de una variable que luego es enviada
                            });
                            // Llama a la función para enviar los datos actualizados a la API
                            ApiService().updateConfig({'incubator_name': _configModel?.incubatorName, 'hash': _configModel?.hash,'incubation_period': _configModel?.incubationPeriod,'max_temperature': newMaxTemp, 'min_temperature': _configModel?.minTemperature,'max_humidity': _configModel?.maxHum, 'min_humidity': _configModel?.minHum, 'passwd': password,'rotation_duration': rotation_duration,'rotation_period': rotation_period,'ssid': ssid,'tray_one_date': tray_one_date,'tray_three_date': tray_three_date,'tray_two_date': tray_two_date});
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
                            double? newMinTemp = double.tryParse(newValue);

                            if (newMinTemp != null) { 
                              setState(() {
                                _configModel?.minTemperature = newMinTemp; 
                              });
                              ApiService().updateConfig({'incubator_name': _configModel?.incubatorName, 'hash': _configModel?.hash,'incubation_period': _configModel?.incubationPeriod,'max_temperature': _configModel?.maxTemperature,'min_temperature': newMinTemp, 'max_humidity': _configModel?.maxHum, 'min_humidity': _configModel?.minHum, 'passwd': password,'rotation_duration': rotation_duration,'rotation_period': rotation_period,'ssid': ssid,'tray_one_date': tray_one_date,'tray_three_date': tray_three_date,'tray_two_date': tray_two_date}); 
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
              title: Text('HUMEDAD MÁXIMA'),
              subtitle: Row(
                children: [
                  Text('${_configModel?.maxHum ?? 0}'),
                  SizedBox(width: 12),
                  IconButton(
                    onPressed: () {
                    _showInputDialog(
                      context,
                      'HUMEDAD MÁXIMA',
                      (_configModel?.maxHum ?? 0).toString(),
                      (newValue) {
                        if (newValue != null && newValue.isNotEmpty) {
                          int? newMaxHum = int.tryParse(newValue);

                          if (newMaxHum != null) {
                            setState(() {
                              _configModel?.maxHum = newMaxHum;
                            });
                            // Llama a la función para enviar los datos actualizados a la API
                            ApiService().updateConfig({'incubator_name': _configModel?.incubatorName, 'hash': _configModel?.hash,'incubation_period': _configModel?.incubationPeriod,'max_temperature': _configModel?.maxTemperature,'min_temperature': _configModel?.minTemperature, 'max_humidity': newMaxHum, 'min_humidity': _configModel?.minHum, 'passwd': password,'rotation_duration': rotation_duration,'rotation_period': rotation_period,'ssid': ssid,'tray_one_date': tray_one_date,'tray_three_date': tray_three_date,'tray_two_date': tray_two_date});
                          } else {
                            // Maneja el caso en el que la conversión a int falla
                            print('Valor de humedad no válido');
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
              title: Text('HUMEDAD MÍNIMA'),
              subtitle: Row(
                children: [
                  Text('${_configModel?.minHum ?? 0}'),
                  SizedBox(width: 12),
                  IconButton(
                    onPressed: () {
                      _showInputDialog(
                        context,
                        'HUMEDAD MÍNIMA',
                        (_configModel?.minHum ?? 0).toString(),
                        (newValue) {
                          if (newValue != null && newValue.isNotEmpty) {
                            int? newMinHum = int.tryParse(newValue);

                            if (newMinHum != null) { 
                              setState(() {
                                _configModel?.minHum = newMinHum; 
                              });
                              ApiService().updateConfig({'incubator_name': _configModel?.incubatorName, 'hash': _configModel?.hash,'incubation_period': _configModel?.incubationPeriod,'max_temperature': _configModel?.maxTemperature,'min_temperature': _configModel?.minTemperature, 'max_humidity': _configModel?.maxHum, 'min_humidity': newMinHum, 'passwd': password,'rotation_duration': rotation_duration,'rotation_period': rotation_period,'ssid': ssid,'tray_one_date': tray_one_date,'tray_three_date': tray_three_date,'tray_two_date': tray_two_date}); 
                            } else {
                              print('Valor de humedad no válido');
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
                              ApiService().updateConfig({'incubator_name': _configModel?.incubatorName, 'hash': _configModel?.hash,'incubation_period': newIncPeriod,'max_temperature': _configModel?.maxTemperature,'min_temperature': _configModel?.minTemperature, 'max_humidity': _configModel?.maxHum, 'min_humidity': _configModel?.minHum, 'passwd': password,'rotation_duration': rotation_duration,'rotation_period': rotation_period,'ssid': ssid,'tray_one_date': tray_one_date,'tray_three_date': tray_three_date,'tray_two_date': tray_two_date}); 
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
                        hash.toString(),
                        (newHash) {
                          if (newHash != null && newHash.isNotEmpty) {                            
                            incubator_name = newHash;

                            if (newHash != null) { 
                              setState(() {
                                _configModel?.incubatorName = newHash; 
                              });
                              ApiService().updateConfig({'incubator_name': _configModel?.incubatorName, 'hash': newHash,'incubation_period': _configModel?.incubationPeriod,'max_temperature': _configModel?.maxTemperature,'min_temperature': _configModel?.minTemperature, 'max_humidity': _configModel?.maxHum, 'min_humidity': _configModel?.minHum, 'passwd': password,'rotation_duration': rotation_duration,'rotation_period': rotation_period,'ssid': ssid,'tray_one_date': tray_one_date,'tray_three_date': tray_three_date,'tray_two_date': tray_two_date}); 
                            } else {
                              print('Hash no válido');
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