import 'package:primer_parcial/data/dao/teams_dao.dart';
import 'package:primer_parcial/domain/models/team.dart';
import 'package:floor/floor.dart';
import 'package:primer_parcial/domain/reporitory/teams_repository.dart';
import 'dart:convert';
import 'dao/teams_dao.dart';
import 'package:flutter/services.dart';
import 'package:primer_parcial/core/database/database.dart';
import '../main.dart';

class JsonTeamsRepository implements TeamsRepository {
  @override
  Future<List<Team>> getTeams() {
    return Future.delayed(const Duration(seconds: 0), () async {
      final jsonString = await rootBundle.loadString('assets/teams.json');
      final jsonList = json.decode(jsonString) as List;
      final teams = jsonList.map((json) => Team.fromJson(json)).toList();

      return teams;
    });
  }

  @override
  Future<Team> getTeamById(int id) async {
    final teams = await getTeams();
    final team = teams.firstWhere((m) => m.id == id);
    return Future.delayed(const Duration(seconds: 0), () => team);
  }

  @override
  Future<void> insertTeam(Team team) {
    return Future.delayed(const Duration(seconds: 0), () => null);
  }

  @override
  Future<void> updateTeam(Team team) {
    return Future.delayed(const Duration(seconds: 0), () => null);
  }

  @override
  Future<void> deleteTeam(Team team) {
    return Future.delayed(const Duration(seconds: 0), () => null);
  }
}

class LocalTeamsRepository implements TeamsRepository {
  final TeamsDao _teamsDao = database.teamsDao;

  @override
  Future<List<Team>> getTeams() {
    return _teamsDao.findAllTeams();
  }

  @override
  Future<Team> getTeamById(int id) async {
    final teams = await getTeams();
    final team = teams.firstWhere((m) => m.id == id);
    return Future.delayed(const Duration(seconds: 0), () => team);
  }

  @override
  Future<void> insertTeam(Team team) async {
    await _teamsDao.insertTeam(team);
  }

  @override
  Future<void> updateTeam(Team team) async {
    await _teamsDao.updateTeam(team);
  }

  @override
  Future<void> deleteTeam(Team team) async {
    await _teamsDao.deleteTeam(team);
  }
}
