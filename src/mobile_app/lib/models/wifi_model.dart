import 'dart:convert';

Wifi wifiFromJson(String str) => Wifi.fromJson(json.decode(str));

String wifiToJson(Wifi data) => json.encode(data.toJson());

class Wifi {
  String message;
  List<Network> networks;

  Wifi({
    required this.message,
    required this.networks,
  });

  factory Wifi.fromJson(Map<String, dynamic> json) => Wifi(
        message: json["message"],
        networks: List<Network>.from(
            json["networks"].map((x) => Network.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "message": message,
        "networks": List<dynamic>.from(networks.map((x) => x.toJson())),
      };
}

class Network {
  String ssid;
  int rssi;

  Network({
    required this.ssid,
    required this.rssi,
  });

  factory Network.fromJson(Map<String, dynamic> json) => Network(
        ssid: json["ssid"],
        rssi: json["rssi"],
      );

  Map<String, dynamic> toJson() => {
        "ssid": ssid,
        "rssi": rssi,
      };
}
