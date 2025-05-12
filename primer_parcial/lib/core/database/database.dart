import 'dart:async';
import 'package:floor/floor.dart';
import 'package:primer_parcial/data/football_teams_repository.dart';
import 'package:primer_parcial/domain/reporitory/teams_repository.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

import '../../data/dao/teams_dao.dart';
import '../../domain/models/team.dart';

part 'database.g.dart'; // the generated code will be there

@Database(version: 1, entities: [Team])
abstract class AppDatabase extends FloorDatabase {
  TeamsDao get teamsDao;

  static Future<AppDatabase> create(String name) {
    return $FloorAppDatabase
        .databaseBuilder(name)
        .addCallback(
          Callback(
            onCreate: (database, version) async {
              await _prepopulateDb(database);
            },
          ),
        )
        .build();
  }

  static Future<void> _prepopulateDb(sqflite.DatabaseExecutor database) async {
    final repository = JsonTeamsRepository();
    final teams = await repository.getTeams();

    for (final team in teams) {
      await InsertionAdapter(
        database,
        'Team',
        (Team item) => <String, Object?>{
          'id': item.id,
          'country': item.country,
          'confederation': item.confederation,
          'worldCups': item.worldCups,
          'isWorldChampion': item.isWorldChampion,
          'flag': item.flag,
        },
      ).insert(team, OnConflictStrategy.replace);
    }
  }
}
