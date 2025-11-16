class UserEntity {
  final String id;
  final String email;
  final String? name;
  final String? profilePicture;
  final DateTime createdAt;
  //viva petro
  UserEntity({
    required this.id,
    required this.email,
    this.name,
    this.profilePicture,
    required this.createdAt,
  });
}
