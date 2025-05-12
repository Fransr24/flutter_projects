import 'package:primer_parcial/domain/explain_interface.dart';

class User implements ExplainInterface {
  String user;
  String password;
  String? profilePicture;

  User({required this.user, required this.password, this.profilePicture});
  @override
  String explain() {
    return "Se debe indicar un usuario o contraseña que se encuentre dentro del registro";
  }
}
