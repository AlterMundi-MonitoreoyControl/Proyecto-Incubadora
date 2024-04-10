import 'dart:convert';

Config configFromJson(String str) => Config.fromJson(json.decode(str));

String configToJson(Config data) => json.encode(data.toJson());

class Config {
    int minTemperature;
    int maxTemperature;
    int rotationDuration;
    int rotationPeriod;

    Config({
        required this.minTemperature,
        required this.maxTemperature,
        required this.rotationDuration,
        required this.rotationPeriod,
    });

    factory Config.fromJson(Map<String, dynamic> json) => Config(
        minTemperature: json["min_temperature"],
        maxTemperature: json["max_temperature"],
        rotationDuration: json["rotation_duration"],
        rotationPeriod: json["rotation_period"],
    );

    Map<String, dynamic> toJson() => {
        "min_temperature": minTemperature,
        "max_temperature": maxTemperature,
        "rotation_duration": rotationDuration,
        "rotation_period": rotationPeriod,
    };
}
