import 'dart:convert';

Rotation rotationFromJson(String str) => Rotation.fromJson(json.decode(str));

String rotationToJson(Rotation data) => json.encode(data.toJson());

class Rotation {
    String message;
    int rotation;

    Rotation({
        required this.message,
        required this.rotation,
    });

    factory Rotation.fromJson(Map<String, dynamic> json) => Rotation(
        message: json["message"],
        rotation: json["rotation"],
    );

    Map<String, dynamic> toJson() => {
        "message": message,
        "rotation": rotation,
    };
}
