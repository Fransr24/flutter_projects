import 'package:floor/floor.dart';
import 'package:primer_parcial/domain/models/user.dart';
// dao identifica todas las operaciones que voy a hacer sobre los equipos

@dao
abstract class UsersDao {
  @Query('SELECT * FROM User')
  Future<List<User>> findAllUsers();

  @Query('SELECT * FROM Team WHERE id = :id')
  Future<User?> findUserById(int id);

  /* otras maneras de hacer query
@Query('SELECT name FROM Person')
  Stream<List<String>> findAllPeopleName();

  @Query('SELECT * FROM Person WHERE id = :id')
  Stream<Person?> findPersonById(int id);
*/
  @insert
  Future<void> insertUser(User user);

  @update
  Future<void> updateUser(User user);

  @delete
  Future<void> deleteUser(User user);
}
