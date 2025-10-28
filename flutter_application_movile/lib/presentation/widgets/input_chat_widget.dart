import 'package:flutter/material.dart';
import 'package:flutter_application_movile/core/theme/app_theme.dart';

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
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Pregunta a Wanderly sobre lugares cercanos…',
                      prefixIcon: Icon(Icons.chat_bubble_outline),
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _enviarMensaje(),
                  ),
                ),
                const SizedBox(width: 10),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: widget.estaCargando
                      ? const SizedBox(
                          width: 40,
                          height: 40,
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : InkWell(
                          onTap: _enviarMensaje,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              gradient: AppTheme.accentGradient,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.send_rounded, color: Colors.white),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
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