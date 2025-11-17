import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:wanderly/domain/repositories/chat_repository.dart';
import 'package:wanderly/domain/entities/chat_message_entity.dart';
import 'package:wanderly/domain/entities/chat_session_entity.dart';

class HistoryPage extends StatefulWidget {
  final ChatRepository chatRepository;
  final String userId;

  const HistoryPage({
    super.key,
    required this.chatRepository,
    required this.userId,
  });

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  // Sesiones y mensajes de Supabase
  List<ChatSessionEntity> _sessions = [];
  List<ChatMessageEntity> _messages = [];
  String? _selectedSessionId;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final sessions = await widget.chatRepository.listChatSessions(
        userId: widget.userId,
      );
      _sessions = sessions;
      if (_sessions.isNotEmpty) {
        _selectedSessionId = _sessions.first.id;
        await _loadMessages(_selectedSessionId!);
      } else {
        _messages = [];
      }
      setState(() {
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error cargando sesiones: $e';
        _loading = false;
      });
    }
  }

  Future<void> _loadMessages(String sessionId) async {
    try {
      final msgs = await widget.chatRepository.getSessionMessages(
        sessionId: sessionId,
        limit: 500,
      );
      setState(() {
        _messages = msgs;
        _selectedSessionId = sessionId;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error cargando mensajes: $e')));
    }
  }

  Future<void> _newConversation() async {
    try {
      final id = await widget.chatRepository.startNewSession(
        userId: widget.userId,
        title: 'Nueva conversación',
      );
      // Devuelve al HomePage para abrir un chat limpio usando la nueva sesión
      if (mounted) {
        Navigator.pop(context, {'newSessionId': id});
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error creando conversación: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial'),
        actions: [
          IconButton(
            onPressed: _newConversation,
            icon: const Icon(Icons.add_comment),
            tooltip: 'Nuevo chat',
          ),
          IconButton(
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Eliminar todo'),
                  content: const Text(
                    'Se eliminarán todas tus conversaciones en la nube (Supabase). Esta acción no se puede deshacer. ¿Deseas continuar?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancelar'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Eliminar todo'),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                try {
                  await widget.chatRepository.deleteAllSessions(
                    userId: widget.userId,
                  );
                  setState(() {
                    _sessions = [];
                    _messages = [];
                    _selectedSessionId = null;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Todas las conversaciones han sido eliminadas')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error eliminando todo: $e')),
                  );
                }
              }
            },
            icon: const Icon(Icons.delete_forever),
            tooltip: 'Eliminar todo',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : (_sessions.isEmpty)
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.chat_bubble_outline,
                    size: 48,
                    color: Colors.blueGrey,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Aún no tienes conversaciones',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Crea tu primer chat para comenzar',
                    style: TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _newConversation,
                    icon: const Icon(Icons.add_comment),
                    label: const Text('Nuevo chat'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Lista horizontal de sesiones
                SizedBox(
                  height: 90,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.all(12),
                    itemCount: _sessions.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, idx) {
                      final s = _sessions[idx];
                      final selected = s.id == _selectedSessionId;
                      final subtitle = s.lastMessageAt != null
                          ? _formatDate(s.lastMessageAt!)
                          : _formatDate(s.createdAt);
                      return GestureDetector(
                        onTap: () => _loadMessages(s.id),
                        child: Stack(
                          children: [
                            Container(
                              width: 220,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: selected
                                    ? Colors.blue.shade600
                                    : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    s.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: selected
                                          ? Colors.white
                                          : Colors.black87,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    subtitle,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: selected
                                          ? Colors.white70
                                          : Colors.black45,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Positioned(
                              right: 4,
                              top: 4,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () async {
                                  final confirmed = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Eliminar conversación'),
                                      content: const Text(
                                        'Se eliminará la conversación seleccionada en la nube (Supabase). ¿Deseas continuar?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx, false),
                                          child: const Text('Cancelar'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () => Navigator.pop(ctx, true),
                                          child: const Text('Eliminar'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirmed == true) {
                                    try {
                                      await widget.chatRepository.deleteSession(
                                        sessionId: s.id,
                                      );
                                      // Refrescar lista de sesiones
                                      await _loadSessions();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Conversación eliminada')),
                                      );
                                    } catch (e) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Error eliminando sesión: $e')),
                                      );
                                    }
                                  }
                                },
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: selected ? Colors.white24 : Colors.black12,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.delete_outline,
                                    size: 18,
                                    color: selected ? Colors.white : Colors.black54,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemBuilder: (context, index) {
                      final m = _messages[index];
                      final isUser = m.isUser;
                      return Align(
                        alignment: isUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 520),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isUser
                                ? Colors.blue.shade600
                                : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (isUser)
                                Text(
                                  m.content,
                                  style: const TextStyle(
                                    color: Colors.white,
                                  ),
                                )
                              else
                                MarkdownBody(
                                  data: m.content,
                                  styleSheet: MarkdownStyleSheet.fromTheme(
                                    Theme.of(context),
                                  ).copyWith(
                                    p: const TextStyle(
                                      color: Colors.black87,
                                      height: 1.35,
                                    ),
                                    strong: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                    h1: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black87,
                                    ),
                                    h2: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black87,
                                    ),
                                    h3: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black87,
                                    ),
                                    listBullet: const TextStyle(
                                      color: Colors.black87,
                                    ),
                                  ),
                                  selectable: false,
                                ),
                              const SizedBox(height: 6),
                              Text(
                                _formatDate(m.timestamp),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isUser
                                      ? Colors.white70
                                      : Colors.black45,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemCount: _messages.length,
                  ),
                ),
              ],
            ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
