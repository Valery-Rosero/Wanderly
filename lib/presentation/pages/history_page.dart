import 'package:flutter/material.dart';
import 'package:flutter_application_movile/domain/repositories/chat_repository.dart';
import 'package:flutter_application_movile/domain/entities/chat_message_entity.dart';

class HistoryPage extends StatefulWidget {
  final ChatRepository chatRepository;
  final String usuarioId;

  const HistoryPage({
    super.key,
    required this.chatRepository,
    required this.usuarioId,
  });

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<ChatMessageEntity> _history = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await widget.chatRepository.getChatHistory(
        userId: widget.usuarioId,
        limit: 500,
      );
      setState(() {
        _history = data;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error cargando historial: $e';
        _loading = false;
      });
    }
  }

  Future<void> _clearHistory() async {
    try {
      await widget.chatRepository.clearChatHistory(userId: widget.usuarioId);
      await _loadHistory();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Historial borrado')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error borrando historial: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial'),
        actions: [
          IconButton(
            onPressed: _clearHistory,
            icon: const Icon(Icons.delete),
            tooltip: 'Borrar historial',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final m = _history[index];
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
                        Text(
                          m.content,
                          style: TextStyle(
                            color: isUser ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _formatDate(m.timestamp),
                          style: TextStyle(
                            fontSize: 11,
                            color: isUser ? Colors.white70 : Colors.black45,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemCount: _history.length,
            ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
