import 'package:incubapp_lite/models/max_temp_model.dart';
import 'package:incubapp_lite/models/min_temp_model.dart';
import 'package:incubapp_lite/models/version_model.dart';
import 'package:incubapp_lite/models/rotation_model.dart';
import 'package:incubapp_lite/services/api_services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/material.dart';
import 'package:incubapp_lite/views/initial_home.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:incubapp_lite/views/home.dart';
import 'package:incubapp_lite/views/wifi_home.dart';
import 'package:incubapp_lite/views/initial_home.dart';
import 'package:incubapp_lite/services/api_services.dart';
import 'package:incubapp_lite/views/counter_home.dart';
import 'package:incubapp_lite/views/graf_home.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  
  int _selectedIndex = 0;

  late Maxtemp? _maxModel = Maxtemp(message: "", maxtemp: 0);
  late Mintemp? _minModel = Mintemp(message: "", mintemp: 0);
  late Version? _verModel = Version(message: "", version: "");
  late Rotation? _rotModel = Rotation(message: "", rotation: 0);
  late TextEditingController _newMaxTempController;
  late TextEditingController _newMinTempController;

  var _newMaxTemp;
  var _newMinTemp;

  @override
  void initState() {
    super.initState();
    _newMaxTempController = TextEditingController();
    _newMinTempController = TextEditingController();

    _getData();

    _newMaxTempController.addListener(_updateTemp);
  }

  void _updateTemp() {
    setState(() {
      _newMaxTemp = _newMaxTempController.text;
      _newMinTemp = _newMinTempController.text;
    });
  }

  void _getData() async {
    _maxModel = (await ApiService().getMaxtemp());
    _minModel = (await ApiService().getMintemp());
    _verModel = (await ApiService().getVersion());
    _rotModel = (await ApiService().getRotation());

    Future.delayed(const Duration(seconds: 1)).then((value) => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: null,
      body: Stack(
        children: [
          ListView.builder(
            itemCount: 1,
            itemBuilder: (context, index) {
              return Card(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          child: Text(
                            "Temperatura Maxima",
                            style: GoogleFonts.questrial(),
                          ),
                        ),
                        Text(
                          '${_maxModel!.maxtemp} °C',
                          style: GoogleFonts.questrial(),
                        ),
                        //Text(_maxModel!.message.toString()),
                        Flexible(
                            child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 10,
                          ),
                          child: TextField(
                            controller: _newMaxTempController,
                            decoration: const InputDecoration(
                                border: UnderlineInputBorder(),
                                hintText: 'nueva temperatura maxima'),
                          ),
                        )),
                        ElevatedButton(
                          onPressed: () => print(
                              'La temperatura maxima elegida es: ${_newMaxTempController.text}'),
                          style: ElevatedButton.styleFrom(
                            shape: const CircleBorder(),
                            padding: const EdgeInsets.all(20),
                          ),
                          child: const Icon(
                            FontAwesomeIcons.arrowsRotate,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 15, vertical: 20),
                          child: Text("Temperatura Minima",
                              style: GoogleFonts.questrial()),
                        ),
                        Text('${_minModel!.mintemp} °C',
                            style: GoogleFonts.questrial()),
                        //Text(_maxModel!.message.toString()),
                        Flexible(
                            child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          child: TextField(
                            controller: _newMinTempController,
                            decoration: const InputDecoration(
                                border: UnderlineInputBorder(),
                                hintText: 'nueva temperatura minima'),
                          ),
                        )),
                        ElevatedButton(
                          onPressed: () => print(
                              'La temperatura minima elegida es: ${_newMinTempController.text}'),
                          style: ElevatedButton.styleFrom(
                            shape: const CircleBorder(),
                            padding: const EdgeInsets.all(20),
                          ),
                          child: const Icon(FontAwesomeIcons.arrowsRotate,
                              size: 20),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 15, vertical: 20),
                          child: Text("Tiempo de Rotación",
                              style: GoogleFonts.questrial()),
                        ),
                        Text('${_rotModel!.rotation / 1000} s',
                            style: GoogleFonts.questrial()),
                        const Flexible(
                            child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 10,
                          ),
                          child: TextField(
                            decoration: InputDecoration(
                                border: UnderlineInputBorder(),
                                hintText: 'nuevo tiempo'),
                          ),
                        )),
                        ElevatedButton(
                          onPressed: () => print('blabla'),
                          style: ElevatedButton.styleFrom(
                              shape: const CircleBorder(),
                              padding: const EdgeInsets.all(20)),
                          child: const Icon(FontAwesomeIcons.arrowsRotate,
                              size: 20),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 300),
                          child: Text('Version: ${_verModel!.version}'),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 100,
                    )
                  ],
                ),
              );
            },
          ),
        ], // children
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
}
