import 'package:flutter/material.dart';
import 'package:flutter_application_movile/domain/entities/mensaje_chat_entity.dart';

class MensajeChatWidget extends StatelessWidget {
  final MensajeChatEntity mensaje;

  const MensajeChatWidget({super.key, required this.mensaje});

  @override
  Widget build(BuildContext context) {
    final isUser = mensaje.esUsuario;
    final bubbleColor = isUser ? Colors.white : Theme.of(context).colorScheme.primary.withOpacity(0.10);
    final labelColor = isUser ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.primary;

    final bubble = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 600),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(16),
          border: isUser ? Border.all(color: Colors.grey.shade200) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (mensaje.tipoLugar != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: labelColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  mensaje.tipoLugar!,
                  style: TextStyle(
                    color: labelColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            Text(
              mensaje.contenido,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );

    final avatar = CircleAvatar(
      backgroundColor: isUser ? Colors.grey.shade300 : Theme.of(context).colorScheme.primary,
      child: Icon(isUser ? Icons.person : Icons.smart_toy, color: isUser ? Colors.white : Colors.white),
    );

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: isUser
            ? [
                Expanded(child: Align(alignment: Alignment.centerRight, child: bubble)),
                const SizedBox(width: 12),
                avatar,
              ]
            : [
                avatar,
                const SizedBox(width: 12),
                Expanded(child: bubble),
              ],
      ),
    );
  }
}