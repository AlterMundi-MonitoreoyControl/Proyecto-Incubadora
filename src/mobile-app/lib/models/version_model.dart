import 'dart:convert';

Version versionFromJson(String str) => Version.fromJson(json.decode(str));

String versionToJson(Version data) => json.encode(data.toJson());

class Version {
  String message;
  String version;

  Version({
    required this.message,
    required this.version,
  });

  factory Version.fromJson(Map<String, dynamic> json) => Version(
        message: json["message"],
        version: json["version"],
      );

  Map<String, dynamic> toJson() => {
        "message": message,
        "version": version,
      };
}
