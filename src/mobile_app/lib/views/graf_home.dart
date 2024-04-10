import 'dart:io';                     
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
//import 'package:incubapp_lite/models/actual_model.dart';
import 'package:incubapp_lite/views/home.dart';
//import 'package:incubapp_lite/views/login.dart';
import 'package:incubapp_lite/views/wifi_home.dart';
import 'package:incubapp_lite/views/initial_home.dart';
//import 'package:incubapp_lite/services/api_services.dart';
//import 'package:incubapp_lite/services/counter_home.dart';
import 'package:incubapp_lite/views/counter_home.dart';
// import 'package:webview_flutter/webview_flutter.dart';
import 'package:incubapp_lite/utils/constants.dart';




class GHome extends StatefulWidget {
  const GHome({Key? key}) : super(key: key);

  @override
  _GHomeState createState() => _GHomeState();
}

class _GHomeState extends State<GHome> {

  int _selectedIndex = 0; 

  @override
  
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Visualizador Grafana'),
      ),
      body: Center(
        child: Text(
          'mimimi',
          style: TextStyle(
            fontSize: 24.0,
            fontWeight: FontWeight.bold,
          ),
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
        Navigator.push(context, MaterialPageRoute(builder: (context) => CHome()));
        break;
      case 4:
        // Navigator.push(context, MaterialPageRoute(builder: (context) => GHome()));
        break;
    }
  }

}