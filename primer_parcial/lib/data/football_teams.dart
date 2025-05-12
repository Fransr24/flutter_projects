import 'package:primer_parcial/domain/models/team.dart';
import 'package:floor/floor.dart';
import 'package:primer_parcial/domain/reporitory/teams_repository.dart';
import 'dart:convert';

import 'package:flutter/services.dart';

final TeamsList = [
  Team(
    id: 0,
    country: "Argentina",
    confederation: "Conmebol",
    worldCups: 3,
    isWorldChampion: true,
    flag:
        "https://upload.wikimedia.org/wikipedia/commons/thumb/1/1a/Flag_of_Argentina.svg/800px-Flag_of_Argentina.svg.png",
  ),
  Team(
    id: 1,
    country: "Brasil",
    confederation: "Conmebol",
    worldCups: 5,
    isWorldChampion: false,
    flag:
        "https://upload.wikimedia.org/wikipedia/commons/thumb/0/05/Flag_of_Brazil.svg/300px-Flag_of_Brazil.svg.png",
  ),
  Team(
    id: 2,
    country: "Uruguay",
    confederation: "Conmebol",
    worldCups: 2,
    isWorldChampion: false,
    flag:
        "https://upload.wikimedia.org/wikipedia/commons/thumb/f/fe/Flag_of_Uruguay.svg/1200px-Flag_of_Uruguay.svg.png",
  ),
  Team(
    id: 3,
    country: "España",
    confederation: "UEFA",
    worldCups: 1,
    isWorldChampion: false,
    flag:
        "https://static.vecteezy.com/system/resources/thumbnails/017/097/991/small/flag-of-spain-on-a-textured-background-conceptual-collage-photo.jpg",
  ),
  Team(
    id: 4,
    country: "Alemania",
    confederation: "UEFA",
    worldCups: 4,
    isWorldChampion: false,
  ),
  Team(
    id: 5,
    country: "Mexico",
    confederation: "Concacaf",
    worldCups: 0,
    isWorldChampion: false,
    flag:
        "https://upload.wikimedia.org/wikipedia/commons/thumb/f/fc/Flag_of_Mexico.svg/2560px-Flag_of_Mexico.svg.png",
  ),
  Team(
    id: 6,
    country: "Boca",
    confederation: "Conmebol",
    worldCups: 3,
    isWorldChampion: false,
    flag:
        "https://upload.wikimedia.org/wikipedia/commons/thumb/4/48/Flag_of_Bolivia.svg/250px-Flag_of_Bolivia.svg.png",
  ),
];

class JsonTeamsRepository implements TeamsRepository {
  @override
  Future<List<Team>> getTeams() {
    return Future.delayed(const Duration(seconds: 2), () async {
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
    return Future.delayed(const Duration(seconds: 2), () => team);
  }

  @override
  Future<void> insertTeam(Team team) {
    return Future.delayed(const Duration(seconds: 2), () => null);
  }

  @override
  Future<void> updateTeam(Team team) {
    return Future.delayed(const Duration(seconds: 2), () => null);
  }
}
