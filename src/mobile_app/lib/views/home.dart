import 'package:flutter/widgets.dart';
import 'package:incubapp_lite/services/api_services.dart';
import 'package:flutter/material.dart';
import 'package:incubapp_lite/views/initial_home.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:incubapp_lite/views/wifi_home.dart';
import 'package:incubapp_lite/views/counter_home.dart';
import 'package:incubapp_lite/views/graf_home.dart';
import 'package:incubapp_lite/models/config_model.dart';
import 'package:incubapp_lite/views/rotation_home.dart';


class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
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
      if (_configModel == null && mounted) {
        setState(() {
          _showConnectionError = true;
        });
      }
    });
  }

  Future<void> _getData() async {
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

    // Estado de carga o error de conexión

    if (_configModel == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Configuraciones'),
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

    final incubator_name = _configModel!.incubatorName;
    final hash = _configModel!.hash;
    final incubation_period = _configModel!.incubationPeriod;
    final maxtemp = _configModel!.maxTemperature;
    final mintemp = _configModel!.minTemperature;
    final maxhum = _configModel!.maxHum;
    final minhum = _configModel!.minHum;
    final password = _configModel!.passwd;
    final rotation_duration = _configModel!.rotationDuration;
    final rotation_period = _configModel!.rotationPeriod;
    final ssid = _configModel!.ssid;
    final tray_one_date = _configModel!.trayOneDate;
    final tray_two_date = _configModel!.trayTwoDate;
    final tray_three_date = _configModel!.trayThreeDate;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuraciones'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            ListTile(
              title: const Text('NOMBRE DE LA INCUBADORA'),
              subtitle: Row(
                children: [
                  Text(incubator_name),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: () => _showInputDialog(
                      context,
                      'NOMBRE DE LA INCUBADORA',
                      incubator_name,
                      (newName) {
                        if (newName != null && newName.isNotEmpty) {
                          setState(() {
                            _configModel?.incubatorName = newName;
                          });
                          ApiService().updateConfig({
                            'incubator_name': newName,
                            'hash': hash,
                            'incubation_period': incubation_period,
                            'max_temperature': maxtemp,
                            'min_temperature': mintemp,
                            'max_hum': maxhum,
                            'min_hum': minhum,
                            'passwd': password,
                            'rotation_duration': rotation_duration,
                            'rotation_period': rotation_period,
                            'ssid': ssid,
                            'tray_one_date': tray_one_date,
                            'tray_three_date': tray_three_date,
                            'tray_two_date': tray_two_date
                          });
                        }
                      },
                    ),
                    icon: const Icon(Icons.edit),
                  ),
                ],
              ),
            ),
            ListTile(
                title: Text('TEMPERATURA MÁXIMA'),
                subtitle: Row(
                  children: [
                    Text(
                        '${_configModel?.maxTemperature ?? 0}'), // Utiliza _configModel?.maxTemperature (el valor directamente del json)
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
                                  _configModel?.maxTemperature =
                                      newMaxTemp; // Actualiza _configModel?.maxTemperature en lugar de una variable que luego es enviada
                                });
                                // Llama a la función para enviar los datos actualizados a la API
                                ApiService().updateConfig({
                                  'incubator_name': _configModel?.incubatorName,
                                  'hash': _configModel?.hash,
                                  'incubation_period':
                                      _configModel?.incubationPeriod,
                                  'max_temperature': newMaxTemp,
                                  'min_temperature': _configModel?.minTemperature,
                                  'max_hum': _configModel?.maxHum,
                                  'min_hum': _configModel?.minHum,
                                  'passwd': password,
                                  'rotation_duration': rotation_duration,
                                  'rotation_period': _configModel?.rotationPeriod,
                                  'ssid': ssid,
                                  'tray_one_date': tray_one_date,
                                  'tray_three_date': tray_three_date,
                                  'tray_two_date': tray_two_date
                                });
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
                                ApiService().updateConfig({
                                  'incubator_name': _configModel?.incubatorName,
                                  'hash': _configModel?.hash,
                                  'incubation_period':
                                      _configModel?.incubationPeriod,
                                  'max_temperature': _configModel?.maxTemperature,
                                  'min_temperature': newMinTemp,
                                  'max_hum': _configModel?.maxHum,
                                  'min_hum': _configModel?.minHum,
                                  'passwd': password,
                                  'rotation_duration': rotation_duration,
                                  'rotation_period': _configModel?.rotationPeriod,
                                  'ssid': ssid,
                                  'tray_one_date': tray_one_date,
                                  'tray_three_date': tray_three_date,
                                  'tray_two_date': tray_two_date
                                });
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
                                ApiService().updateConfig({
                                  'incubator_name': _configModel?.incubatorName,
                                  'hash': _configModel?.hash,
                                  'incubation_period':
                                      _configModel?.incubationPeriod,
                                  'max_temperature': _configModel?.maxTemperature,
                                  'min_temperature': _configModel?.minTemperature,
                                  'max_hum': newMaxHum,
                                  'min_hum': _configModel?.minHum,
                                  'passwd': password,
                                  'rotation_duration': rotation_duration,
                                  'rotation_period': _configModel?.rotationPeriod,
                                  'ssid': ssid,
                                  'tray_one_date': tray_one_date,
                                  'tray_three_date': tray_three_date,
                                  'tray_two_date': tray_two_date
                                });
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
                                ApiService().updateConfig({
                                  'incubator_name': _configModel?.incubatorName,
                                  'hash': _configModel?.hash,
                                  'incubation_period':
                                      _configModel?.incubationPeriod,
                                  'max_temperature': _configModel?.maxTemperature,
                                  'min_temperature': _configModel?.minTemperature,
                                  'max_hum': _configModel?.maxHum,
                                  'min_hum': newMinHum,
                                  'passwd': password,
                                  'rotation_duration': rotation_duration,
                                  'rotation_period': _configModel?.rotationPeriod,
                                  'ssid': ssid,
                                  'tray_one_date': tray_one_date,
                                  'tray_three_date': tray_three_date,
                                  'tray_two_date': tray_two_date
                                });
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
                                ApiService().updateConfig({
                                  'incubator_name': _configModel?.incubatorName,
                                  'hash': _configModel?.hash,
                                  'incubation_period': newIncPeriod,
                                  'max_temperature': _configModel?.maxTemperature,
                                  'min_temperature': _configModel?.minTemperature,
                                  'max_hum': _configModel?.maxHum,
                                  'min_hum': _configModel?.minHum,
                                  'passwd': password,
                                  'rotation_duration': rotation_duration,
                                  'rotation_period': _configModel?.rotationPeriod,
                                  'ssid': ssid,
                                  'tray_one_date': tray_one_date,
                                  'tray_three_date': tray_three_date,
                                  'tray_two_date': tray_two_date
                                });
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
                title: Text('ROTACIÓN (MINUTOS)'),
                subtitle: Row(
                  children: [
                    Text('${(_configModel?.rotationPeriod ?? 0) / 60000}'),
                    SizedBox(width: 12),
                    IconButton(
                      onPressed: () {
                        _showInputDialog(
                          context,
                          'INTERVALO DE ROTACIÓN (en minutos)',
                          ((_configModel?.rotationPeriod ?? 0) / 60000).toString(),
                          (newValue) {
                            if (newValue != null && newValue.isNotEmpty) {
                              int? newRotPeriod = int.tryParse(newValue);

                              if (newRotPeriod != null) {
                                int newRotPeriodMs = newRotPeriod * 60000;
                                setState(() {
                                  _configModel?.rotationPeriod = newRotPeriodMs;
                                });
                                ApiService().updateConfig({
                                  'incubator_name': _configModel?.incubatorName,
                                  'hash': _configModel?.hash,
                                  'incubation_period': _configModel?.incubationPeriod,
                                  'max_temperature': _configModel?.maxTemperature,
                                  'min_temperature': _configModel?.minTemperature,
                                  'max_hum': _configModel?.maxHum,
                                  'min_hum': _configModel?.minHum,
                                  'passwd': password,
                                  'rotation_duration': rotation_duration,
                                  'rotation_period': newRotPeriodMs,
                                  'ssid': ssid,
                                  'tray_one_date': tray_one_date,
                                  'tray_three_date': tray_three_date,
                                  'tray_two_date': tray_two_date
                                });
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
                subtitle: Text('${_configModel?.hash ?? 0}')
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
        Navigator.push(context, MaterialPageRoute(builder: (context) => IHome()));
        break;
      case 1:
        Navigator.push(context, MaterialPageRoute(builder: (context) => WHome()));
        break;
      case 2:
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
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Aceptar'),
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
