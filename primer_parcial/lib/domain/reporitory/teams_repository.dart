import 'package:primer_parcial/domain/models/team.dart';

abstract class TeamsRepository {
  Future<List<Team>> getTeams();
  Future<Team> getTeamById(int id);

  Future<void> insertTeam(Team team);
  Future<void> updateTeam(Team team);
  Future<void> deleteTeam(Team team);
}
