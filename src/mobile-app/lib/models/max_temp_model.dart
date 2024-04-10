import 'dart:convert';

Maxtemp maxtempFromJson(String str) => Maxtemp.fromJson(json.decode(str));

String maxtempToJson(Maxtemp data) => json.encode(data.toJson());

class Maxtemp {
  String message;
  int maxtemp;

  Maxtemp({
    required this.message,
    required this.maxtemp,
  });

  factory Maxtemp.fromJson(Map<String, dynamic> json) => Maxtemp(
        message: json["message"],
        maxtemp: json["maxtemp"],
      );

  Map<String, dynamic> toJson() => {
        "message": message,
        "maxtemp": maxtemp,
      };
}
