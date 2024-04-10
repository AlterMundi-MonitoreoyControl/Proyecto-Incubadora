import 'dart:convert';

Mintemp mintempFromJson(String str) => Mintemp.fromJson(json.decode(str));

String mintempToJson(Mintemp data) => json.encode(data.toJson());

class Mintemp {
  String message;
  double mintemp;

  Mintemp({
    required this.message,
    required this.mintemp,
  });

  factory Mintemp.fromJson(Map<String, dynamic> json) => Mintemp(
        message: json["message"],
        mintemp: json["mintemp"],
      );

  Map<String, dynamic> toJson() => {
        "message": message,
        "mintemp": mintemp,
      };
}
