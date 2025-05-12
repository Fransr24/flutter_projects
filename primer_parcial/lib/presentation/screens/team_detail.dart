import 'package:primer_parcial/data/football_teams.dart';
import 'package:primer_parcial/domain/models/team.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TeamDetail extends StatelessWidget {
  final String country;
  const TeamDetail({super.key, required this.country});

  @override
  Widget build(BuildContext context) {
    final team = TeamsList.firstWhere((t) => t.country == country);
    return Scaffold(
      appBar: AppBar(title: const Text('Team detail')),
      body: _TeamView(team: team),
    );
  }
}

class _TeamView extends StatelessWidget {
  final Team team;

  const _TeamView({super.key, required this.team});

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme;

    return Center(
      child: Column(
        children: [
          Text(team.country),
          Text(team.confederation),
          //Text(team.worldCups),
          //Text(team.isWorldChampion),
        ],
      ),
    );
  }
}
