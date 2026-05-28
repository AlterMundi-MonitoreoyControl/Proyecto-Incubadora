import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';


class NtfySubscriptionScreen extends StatefulWidget {
  const NtfySubscriptionScreen({Key? key}) : super(key: key);

  @override
  _NtfySubscriptionScreenState createState() => _NtfySubscriptionScreenState();
}

class _NtfySubscriptionScreenState extends State<NtfySubscriptionScreen> {
  String? incubadoraHash;

  @override
  void initState() {
    super.initState();
    _loadHash();
  }

  Future<void> _loadHash() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      incubadoraHash = prefs.getString('incubadora_hash');
    });
  }

  Widget _buildInstructionStep(int number, String instruction) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(right: 10),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.black87,
              shape: BoxShape.circle,
            ),
            child: Text(
              number.toString(),
              style: GoogleFonts.questrial(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              instruction,
              style: GoogleFonts.questrial(
                color: Colors.black87,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (incubadoraHash == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Notificaciones'),
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        backgroundColor: const Color.fromRGBO(65, 65, 65, 1),
        body: Center(
          child: Text(
            'No se encontró el identificador de la incubadora',
            style: GoogleFonts.questrial(
              color: Colors.white,
              fontSize: 18,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Notificaciones'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: const Color.fromRGBO(65, 65, 65, 1),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: const Color.fromARGB(225, 255, 255, 255),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.chat,
                    color: Colors.black87,
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Configurar Notificaciones',
                    style: GoogleFonts.questrial(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Text(
                'Para recibir notificaciones de tu incubadora:',
                style: GoogleFonts.questrial(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 15),
              _buildInstructionStep(1, 'Instala la aplicación NTFY'),
              _buildInstructionStep(2, 'Abrí la aplicación NTFY'),
              _buildInstructionStep(3, 'Presiona el botón "+" en la esquina inferior derecha'),
              _buildInstructionStep(4, 'En el campo "Tópico", pega este código:'),
              Container(
                margin: const EdgeInsets.symmetric(vertical: 15),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(65, 65, 65, 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: SelectableText(
                        incubadoraHash!,
                        style: GoogleFonts.sourceCodePro(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.copy,
                        color: Colors.black87,
                      ),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: incubadoraHash!));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Código copiado al portapapeles',
                              style: GoogleFonts.questrial(),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              _buildInstructionStep(5, 'Presiona "Suscribir"'),
              _buildInstructionStep(6, 'Listo! Ya podes recibir las notificaciones de tu incubadora incluso cuando estás lejos'),
              const SizedBox(height: 10),
              Text(
                'Nota: El código se copiará al portapapeles cuando presiones el ícono de copiar',
                style: GoogleFonts.questrial(
                  fontStyle: FontStyle.italic,
                  color: Colors.black54,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}