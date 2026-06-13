class CustomerModel {

  final int id;
  final int userId;
  final String name;
  final int points;
  final String username;
  final String email;
  final String? profilePicture;

  CustomerModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.points,
    required this.username,
    required this.email,
    this.profilePicture,
  });

  factory CustomerModel.fromJson(
    Map<String, dynamic> json,
  ) {

    return CustomerModel(
      id: int.parse(json["id"].toString()),
      userId: int.parse(json["user_id"].toString()),
      name: json["name"] ?? "",
      points: int.parse(json["points"].toString()),
      username: json["username"] ?? "",
      email: json["email"] ?? "",
      profilePicture:
          json["profile_picture"],
    );
  }
}
