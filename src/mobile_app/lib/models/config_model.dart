import 'dart:convert';

Config configFromJson(String str) => Config.fromJson(json.decode(str));

String configToJson(Config data) => json.encode(data.toJson());

class Config {
    String hash;
    double minTemperature;
    int minHum;
    String incubatorName;
    int maxHum;
    int rotationDuration;
    int trayThreeDate;
    double maxTemperature;
    int rotationPeriod;
    int trayTwoDate;
    int trayOneDate;
    int incubationPeriod;
    String? passwd;
    String? ssid;

    Config({
        required this.hash,
        required this.minTemperature,
        required this.minHum,
        required this.incubatorName,
        required this.maxHum,
        required this.rotationDuration,
        required this.trayThreeDate,
        required this.maxTemperature,
        required this.rotationPeriod,
        required this.trayTwoDate,
        required this.trayOneDate,
        required this.incubationPeriod,
        this.passwd,
        this.ssid,
    });

    factory Config.fromJson(Map<String, dynamic> json) => Config(
        hash: json["hash"],
        minTemperature: json["min_temperature"].toDouble(),
        minHum: json["min_hum"],
        incubatorName: json["incubator_name"],
        maxHum: json["max_hum"],
        rotationDuration: json["rotation_duration"],
        trayThreeDate: json["tray_three_date"],
        maxTemperature: json["max_temperature"].toDouble(),
        rotationPeriod: json["rotation_period"],
        trayTwoDate: json["tray_two_date"],
        trayOneDate: json["tray_one_date"],
        incubationPeriod: json["incubation_period"],
        passwd: json["passwd"],
        ssid: json["ssid"],
    );

    Map<String, dynamic> toJson() => {
        "hash": hash,
        "min_temperature": minTemperature,
        "min_hum": minHum,
        "incubator_name": incubatorName,
        "max_hum": maxHum,
        "rotation_duration": rotationDuration,
        "tray_three_date": trayThreeDate,
        "max_temperature": maxTemperature,
        "rotation_period": rotationPeriod,
        "tray_two_date": trayTwoDate,
        "tray_one_date": trayOneDate,
        "incubation_period": incubationPeriod,
        "passwd": passwd,
        "ssid": ssid,
    };
}