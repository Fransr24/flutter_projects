import 'package:floor/floor.dart';
import 'package:primer_parcial/domain/models/team.dart';
// dao identifica todas las operaciones que voy a hacer sobre los equipos

@dao
abstract class TeamsDao {
  @Query('SELECT * FROM Team')
  Future<List<Team>> findAllTeams();

  @Query('SELECT * FROM Movie WHERE id = :id')
  Future<Team?> findTeamById(int id);

  /* otras maneras de hacer query
@Query('SELECT name FROM Person')
  Stream<List<String>> findAllPeopleName();

  @Query('SELECT * FROM Person WHERE id = :id')
  Stream<Person?> findPersonById(int id);
*/
  @insert
  Future<void> insertTeam(Team team);

  @update
  Future<void> updateTeam(Team team);

  @delete
  Future<void> deleteTeam(Team team);
}
