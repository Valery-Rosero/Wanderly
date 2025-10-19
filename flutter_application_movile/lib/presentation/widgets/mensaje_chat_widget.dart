import 'package:flutter/material.dart';
import 'package:flutter_application_movile/domain/entities/mensaje_chat_entity.dart';

class MensajeChatWidget extends StatelessWidget {
  final MensajeChatEntity mensaje;

  const MensajeChatWidget({super.key, required this.mensaje});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!mensaje.esUsuario)
            CircleAvatar(
              backgroundColor: Colors.blue,
              child: Icon(Icons.smart_toy, color: Colors.white),
            )
          else
            CircleAvatar(
              backgroundColor: Colors.green,
              child: Icon(Icons.person, color: Colors.white),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mensaje.esUsuario ? 'Tú' : 'TravelBot',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: mensaje.esUsuario ? Colors.green : Colors.blue,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: mensaje.esUsuario
                        ? Colors.green.shade50
                        : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    mensaje.contenido,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}