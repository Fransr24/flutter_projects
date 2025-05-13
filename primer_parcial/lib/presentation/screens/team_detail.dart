import 'package:primer_parcial/data/football_teams_repository.dart';
import 'package:primer_parcial/domain/models/team.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:primer_parcial/domain/reporitory/teams_repository.dart';

class TeamDetail extends StatefulWidget {
  final String id;
  String userId;
  TeamDetail({super.key, required this.id, required this.userId});

  @override
  State<TeamDetail> createState() => _TeamDetailState();
}

class _TeamDetailState extends State<TeamDetail> {
  late final Future<Team> teamFuture;
  final TeamsRepository _repository = LocalTeamsRepository();
  Team? team;

  @override
  void initState() {
    super.initState();
    teamFuture = _repository.getTeamById(int.parse(widget.id));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Team detail'),
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () {
              context.push(
                "/add_edit",
                extra: {'id': '${team!.id}', 'userId': '2'},
              );
              setState(() {});
            },
          ),
        ],
      ),
      body: FutureBuilder<Object>(
        future: teamFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          team = snapshot.data as Team;
          return _TeamView(team: team!);
        },
      ),
    );
  }
}

class _TeamView extends StatelessWidget {
  final Team team;

  const _TeamView({super.key, required this.team});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 50),
          Center(
            child: ClipOval(
              child:
                  team.flag != null
                      ? ClipOval(
                        child: Image.network(
                          team.flag!,
                          width: 250,
                          height: 250,
                          fit: BoxFit.fitHeight,
                          errorBuilder: (
                            BuildContext context,
                            Object error,
                            StackTrace? stackTrace,
                          ) {
                            return Icon(Icons.error, size: 200);
                          },
                        ),
                      )
                      : Icon(Icons.flag_circle),
            ),
          ),
          const SizedBox(height: 50),
          Text("Country: ${team.country}"),
          Text("Confederation to which it belongs: ${team.confederation}"),
          Text(
            "This football team currently has ${team.worldCups.toString()} World Cups",
          ),
          team.isWorldChampion == 1
              ? Text("This football team won the last world cup")
              : Text("This football team has not won the last world cup"),
        ],
      ),
    );
  }
}
