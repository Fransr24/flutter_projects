import 'package:primer_parcial/domain/models/user.dart';

abstract class UsersRepository {
  Future<List<User>> getUsers();
  Future<User> getUserById(int id);

  Future<void> insertUser(User user);
  Future<void> updateUser(User user);
  Future<void> deleteUser(User user);
}
