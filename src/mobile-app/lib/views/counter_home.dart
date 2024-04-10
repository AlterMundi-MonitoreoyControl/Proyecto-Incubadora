import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:incubapp_lite/views/home.dart';
import 'package:incubapp_lite/views/wifi_home.dart';
import 'package:incubapp_lite/views/initial_home.dart';
// import 'package:incubapp_lite/services/api_services.dart';
// import 'package:incubapp_lite/services/counter_home.dart';
import 'package:incubapp_lite/views/graf_home.dart';

class CHome extends StatefulWidget {
  @override
  _CHomeState createState() => _CHomeState();
}

class _CHomeState extends State<CHome> {
  
  int _selectedIndex = 0; 

  List<int> _bandejaSelectedIndexList = [1, 1, 1]; 

  @override
  Widget build(BuildContext context) {
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
                      _showGreenDialog();
                    }
                  });
                  print('BANDEJA 1 pressed!');
                },
                style: ElevatedButton.styleFrom(
                  primary: _bandejaSelectedIndexList[0] == 1 ? const Color.fromARGB(255, 138, 201, 140) : const Color.fromARGB(255, 179, 65, 65),
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
                      _showGreenDialog();
                    }
                  });
                  print('BANDEJA 2 pressed!');
                },
                style: ElevatedButton.styleFrom(
                  primary: _bandejaSelectedIndexList[1] == 1 ? const Color.fromARGB(255, 138, 201, 140) :  const Color.fromARGB(255, 179, 65, 65),
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
                      _showGreenDialog();
                    }
                  });
                  print('BANDEJA 3 pressed!');
                },
                style: ElevatedButton.styleFrom(
                  primary: _bandejaSelectedIndexList[2] == 1 ? const Color.fromARGB(255, 138, 201, 140) : const Color.fromARGB(255, 179, 65, 65),
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

  void _showGreenDialog() {
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
              });
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