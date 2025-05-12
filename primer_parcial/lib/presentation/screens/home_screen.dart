import 'package:primer_parcial/data/football_teams.dart';
import 'package:primer_parcial/domain/models/team.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:primer_parcial/domain/reporitory/teams_repository.dart';
import 'package:primer_parcial/presentation/widgets/drawer_menu.dart';

class HomeScreen extends StatelessWidget {
  static const String name = 'home';
  String userName;
  HomeScreen({super.key, this.userName = ""});
  final scafoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Welcome $userName")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Team List",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Expanded(child: _TeamsListView()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          {
            context.push("/add_edit");
          }
        },
        backgroundColor: Colors.yellow,
        tooltip: 'Add new team',
        child: Icon(Icons.add),
      ),
      drawer: DrawerMenu(scafoldKey: scafoldKey),
    );
  }
}

class _TeamsListView extends StatefulWidget {
  //final List<Team> teamList;

  const _TeamsListView({super.key /* required this.teamList */});

  @override
  State<_TeamsListView> createState() => _TeamsListViewState();
}

class _TeamsListViewState extends State<_TeamsListView> {
  late final Future<List<Team>> teamsFuture;
  final TeamsRepository _repository = JsonTeamsRepository();

  @override
  void initState() {
    super.initState();
    teamsFuture = _repository.getTeams();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: teamsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final teamList = snapshot.data as List<Team>;

        return ListView.builder(
          itemBuilder: (context, index) {
            return _TeamListItem(team: teamList[index]);
          },
          itemCount: teamList.length,
        );
      },
    );
  }
}

class _TeamListItem extends StatelessWidget {
  final Team team;

  const _TeamListItem({super.key, required this.team});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading:
            team.flag != null
                ? ClipOval(
                  child: Image.network(
                    team.flag!,
                    width: 50,
                    height: 100,
                    fit: BoxFit.fill,
                  ),
                )
                : Icon(Icons.flag_circle),
        title: Text(team.country),
        subtitle: Text(team.confederation),
        trailing: Icon(Icons.arrow_forward),
        onTap: () {
          context.push('/team_detail/${team.country}');
        },
      ),
    );
  }
}
