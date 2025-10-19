import 'package:flutter/material.dart';

class InputChatWidget extends StatefulWidget {
  final Function(String) onEnviarMensaje;
  final bool estaCargando;

  const InputChatWidget({
    super.key,
    required this.onEnviarMensaje,
    required this.estaCargando,
  });

  @override
  State<InputChatWidget> createState() => _InputChatWidgetState();
}

class _InputChatWidgetState extends State<InputChatWidget> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Pregunta sobre lugares...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onSubmitted: (_) => _enviarMensaje(),
            ),
          ),
          const SizedBox(width: 8),
          widget.estaCargando
              ? const CircularProgressIndicator()
              : IconButton(
                  icon: const Icon(Icons.send, color: Colors.blue),
                  onPressed: _enviarMensaje,
                ),
        ],
      ),
    );
  }

  void _enviarMensaje() {
    if (_controller.text.trim().isNotEmpty) {
      widget.onEnviarMensaje(_controller.text);
      _controller.clear();
    }
  }
}