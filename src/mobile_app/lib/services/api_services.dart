import 'dart:async';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:incubapp_lite/models/actual_model.dart';
import 'package:incubapp_lite/utils/constants.dart';
import 'package:incubapp_lite/models/max_temp_model.dart';
import 'package:incubapp_lite/models/min_temp_model.dart';
import 'package:incubapp_lite/models/version_model.dart';
import 'package:incubapp_lite/models/rotation_model.dart';
import 'package:incubapp_lite/models/wifi_model.dart';
import 'package:incubapp_lite/models/config_model.dart';

// logica para consumo de datos en la api

class ApiService {
  Future<Maxtemp?> getMaxtemp() async {
    try {
      var url = Uri.parse(ApiConstants.baseUrl + ApiConstants.maxTempEndPoint);
      var response = await http.get(url);
      if (response.statusCode == 200) {
        Maxtemp model = maxtempFromJson(response.body);
        return model;
      }
    } catch (e) {
      log(e.toString());
    }
    return null;
  }

  Future<Mintemp?> getMintemp() async {
    try {
      var url = Uri.parse(ApiConstants.baseUrl + ApiConstants.minTempEndPoint);
      var response = await http.get(url);
      if (response.statusCode == 200) {
        Mintemp model = mintempFromJson(response.body);
        return model;
      }
    } catch (e) {
      log(e.toString());
    }
    return null;
  }

  Future<Wifi?> getWifi() async {
    try {
      var url = Uri.parse(ApiConstants.baseUrl + ApiConstants.wifiEndPoint);
      var response = await http.get(url);
      if (response.statusCode == 200) {
        Wifi model = wifiFromJson(response.body);
        return model;
      }
    } catch (e) {
      log(e.toString());
    }
    return null;
  }

  Future<Rotation?> getRotation() async {
    try {
      var url = Uri.parse(ApiConstants.baseUrl + ApiConstants.rotationEndPoint);
      var response = await http.get(url);
      if (response.statusCode == 200) {
        Rotation model = rotationFromJson(response.body);
        return model;
      }
    } catch (e) {
      log(e.toString());
    }
    return null;
  }

  Future<Version?> getVersion() async {
    try {
      var url = Uri.parse(ApiConstants.baseUrl + ApiConstants.versionEndPoint);
      var response = await http.get(url);
      if (response.statusCode == 200) {
        Version model = versionFromJson(response.body);
        return model;
      }
    } catch (e) {
      log(e.toString());
    }
    return null;
  }

  Future<Actual?> getActual() async {
    try {
      var url = Uri.parse(ApiConstants.baseUrl + ApiConstants.actualEndPoint);
      print('URL de la API: $url');
      var response = await http.get(url);
      if (response.statusCode == 200) {
        Actual model = actualFromJson(response.body);
        return model;
      } else {
        print('Respuesta de la API no exitosa: ${response.statusCode}');
      }
    } catch (e) {
      print('Error en la llamada a la API: $e');
      log(e.toString());
    }
    return null;
  }

  Future<Config?> getConfig() async {
    try {
      var url = Uri.parse(ApiConstants.baseUrl + ApiConstants.configEndPoint);
      print('URL de la API: $url');
      var response = await http.get(url);
      if (response.statusCode == 200) {
        Config model = configFromJson(response.body);
        return model;
      } else {
        print('Respuesta de la API no exitosa: ${response.statusCode}');
      }
    } catch (e) {
      print('Error en la llamada a la API: $e');
      log(e.toString());
    }
    return null;
  }

}
