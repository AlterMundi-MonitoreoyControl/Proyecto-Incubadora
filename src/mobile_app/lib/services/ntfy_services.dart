import 'dart:convert';
import 'package:http/http.dart' as http;

class NtfyService {
  final String _baseUrl = "https://ntfy.sh";

  // Enviar notificaciones
  Future<void> sendNotification(String topic, String title, String message) async {
    try {
      var url = Uri.parse("$_baseUrl/$topic");
      var response = await http.post(
        url,
        headers: {"Title": title},
        body: message,
      );

      if (response.statusCode == 200) {
        print("Notificación enviada con éxito.");
      } else {
        print("Error al enviar la notificación: ${response.statusCode}");
      }
    } catch (e) {
      print("Excepción al enviar notificación: $e");
    }
  }

  // Suscribirse a un tema y recibir notificaciones
  Future<void> subscribeToTopic(String topic) async {
    try {
      var url = Uri.parse("$_baseUrl/$topic");
      var request = http.Request("GET", url);
      var response = await request.send();

      if (response.statusCode == 200) {
        response.stream
            .transform(utf8.decoder)
            .listen((data) {
          print("Notificación recibida: $data");
        });
      } else {
        print("Error al suscribirse: ${response.statusCode}");
      }
    } catch (e) {
      print("Excepción al suscribirse: $e");
    }
  }

  void subscribeToNtfyChannelFromConfig(String hash) {}
}
