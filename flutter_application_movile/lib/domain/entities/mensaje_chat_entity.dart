class ChatMessageEntity {
  final String id;
  final String contenido;
  final bool esUsuario;
  final DateTime timestamp;
  final String? placeType; 

  ChatMessageEntity({
    required this.id,
    required this.contenido,
    required this.esUsuario,
    required this.timestamp,
    this.placeType,
  });
}