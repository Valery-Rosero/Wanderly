class UsuarioEntity {
  final String id;
  final String email;
  final String? nombre;
  final String? fotoPerfil;
  final DateTime createdAt;
//viva petro
  UsuarioEntity({
    required this.id,
    required this.email,
    this.nombre,
    this.fotoPerfil,
    required this.createdAt,
  });
}
