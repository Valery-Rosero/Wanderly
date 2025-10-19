class MensajeChatEntity {
  final String id;
  final String contenido;
  final bool esUsuario;
  final DateTime timestamp;
  final String? tipoLugar; // 'cafeteria', 'museo', etc.

  MensajeChatEntity({
    required this.id,
    required this.contenido,
    required this.esUsuario,
    required this.timestamp,
    this.tipoLugar,
  });
}