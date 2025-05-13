import 'package:floor/floor.dart';
import 'package:primer_parcial/domain/explain_interface.dart';

@entity
class User implements ExplainInterface {
  @PrimaryKey(autoGenerate: true)
  final int? id;
  String user;
  String password;
  String age;
  String teamFan;
  String? profilePicture;

  User({
    this.id,
    required this.user,
    required this.password,
    required this.age,
    required this.teamFan,
    this.profilePicture,
  });
  @override
  String explain() {
    return "Se debe indicar un usuario o contraseña que se encuentre dentro del registro";
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      user: json['user'],
      password: json['password'],
      age: json['age'],
      teamFan: json['teamFan'],
      profilePicture: json['profilePicture'],
    );
  }
}
