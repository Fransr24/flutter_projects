import 'package:floor/floor.dart';

@entity
class Team {
  @primaryKey
  final int id;
  final String country;
  final String confederation;
  final int worldCups;
  final bool isWorldChampion;
  String? flag;

  Team({
    required this.id,
    required this.country,
    required this.confederation,
    required this.worldCups,
    required this.isWorldChampion,
    this.flag,
  });

  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      id: json['id'],
      country: json['country'],
      confederation: json['confederation'],
      worldCups: json['worldCups'],
      isWorldChampion: json['isWorldChampion'],
      flag: json['flag'],
    );
  }
}
