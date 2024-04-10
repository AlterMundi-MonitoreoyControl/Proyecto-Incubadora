import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:incubapp_lite/models/actual_model.dart';
import 'package:incubapp_lite/views/home.dart';
//import 'package:incubapp_lite/views/login.dart';
import 'package:incubapp_lite/views/wifi_home.dart';
import 'package:incubapp_lite/services/api_services.dart';
import 'package:incubapp_lite/views/counter_home.dart';
import 'package:incubapp_lite/views/graf_home.dart';

void main() => runApp(MaterialApp(
      debugShowCheckedModeBanner: false,
      home: IHome(),
    ));

class IHome extends StatefulWidget {
  @override
  _IHomeState createState() => _IHomeState();
}
class _IHomeState extends State<IHome> {
  late Actual? _actualModel = Actual(aHumidity: 60, aTemperature: 37.5);
  int _selectedIndex = 0;
  @override
  void initState() {
    super.initState();
    _getData();
  }
  Future<void> _getData() async {
    _actualModel = await ApiService().getActual();
    setState(() {});
  }
  @override
  Widget build(BuildContext context) {
    double temperature = _actualModel?.aTemperature ?? 0.0;
    double humidity = _actualModel?.aHumidity ?? 0.0;
    Size size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.grey,
      body: _buildBody(size, temperature, humidity),
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
  Widget _buildBody(Size size, double temperature, double humidity) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color.fromRGBO(65, 65, 65, 1), Color.fromRGBO(65, 65, 65, 1)])),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  FontAwesomeIcons.temperatureHalf,
                  color: Color.fromARGB(255, 255, 255, 255),
                  size: 40.0,
                ),
                SizedBox(
                  height: size.height * 0.03,
                ),
                temperatureTitle(size),
                const SizedBox(
                  height: 30.0,
                ),
                temperatureValue(size, temperature),
                const SizedBox(
                  height: 30.0,
                ),
                const Icon(
                  FontAwesomeIcons.droplet,
                  color: Color.fromARGB(255, 255, 255, 255),
                  size: 40.0,
                ),
                const SizedBox(
                  height: 10.0,
                ),
                humidityTitle(size),
                SizedBox(
                  height: size.height * 0.05,
                ),
                humidityValue(size, humidity),
              ],
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomRight,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
            ),
          ),
        )
      ],
    );
  }
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    switch (index) {
      case 0:
        // Navegar a la pantalla de inicio
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
        Navigator.push(context, MaterialPageRoute(builder: (context) => GHome()));
        break;
    }
  }
}
Widget temperatureTitle(size) {
  return Text("Temperatura:",
      style: GoogleFonts.questrial(
          color: Color.fromARGB(255, 255, 255, 255), fontSize: size.height * 0.05));
}
Widget temperatureValue(size, temperature) {
  return Text(
    '$temperature˚C', //max temperature
    style: GoogleFonts.questrial(
      color: Tcolor(temperature),
      fontSize: size.height * 0.13,
    ),
  );
}
Color Tcolor(temperature) {
  if (temperature <= 0) {
    return Colors.yellow; // -= 0: Verde
  } else if (temperature <= 38 && temperature >= 36.5) {
    return Colors.lightGreenAccent; // -= 37.5: Verde
  } else {
    return Colors.red; // > 37.5: Rojo
  }
}
Color Hcolor(humidity) {
  if (humidity <= 0) {
    return Colors.red; // -= 0: Verde
  } else if (humidity <= 70.0 && humidity >= 55.0) {
    return Colors.lightGreenAccent; // -= 37.5: Verde
  } else {
    return Colors.red; // > 37.5: Rojo
  }
}
Widget humidityTitle(size) {
  return Text("Humedad:",
      style: GoogleFonts.questrial(
          color: Color.fromARGB(255, 255, 255, 255), fontSize: size.height * 0.05));
}
Widget humidityValue(size, humidity) {
  return Text(
    '$humidity %', //max temperature
    style: GoogleFonts.questrial(
      color: Hcolor(humidity),
      fontSize: size.height * 0.13,
    ),
  );
}
