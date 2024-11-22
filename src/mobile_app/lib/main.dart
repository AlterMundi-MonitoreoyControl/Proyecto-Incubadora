import 'package:flutter/material.dart';
import 'package:incubapp_lite/services/api_services.dart';
import 'package:incubapp_lite/services/ntfy_services.dart';
import 'views/splashscreen.dart';
import 'package:incubapp_lite/models/config_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Crear instancia del servicio de Ntfy
  NtfyService ntfyService = NtfyService();

  Config? config = await ApiService().getConfig();

  if (config != null) {
    String topic = config.hash;

    ntfyService.subscribeToTopic(topic);

    ntfyService.sendNotification(
      topic,
      "Prueba",
      "Hola desde Flutter!",
    );
  } else {
    print("No se pudo obtener la configuración desde la API.");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Incuapp Lite',
      home: SplashScreen(),
    );
  }
}
