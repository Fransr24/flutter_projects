import 'package:flutter/foundation.dart';
import 'package:primer_parcial/data/football_teams_repository.dart';
import 'package:primer_parcial/data/users_repository.dart';
import 'package:primer_parcial/domain/models/team.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:primer_parcial/domain/models/user.dart';
import 'package:primer_parcial/domain/reporitory/teams_repository.dart';
import 'package:primer_parcial/domain/reporitory/users_repository.dart';
import 'package:primer_parcial/presentation/widgets/drawer_menu.dart';

class HomeScreen extends StatefulWidget {
  static const String name = 'home';
  String userId;
  HomeScreen({super.key, this.userId = ""});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final scafoldKey = GlobalKey<ScaffoldState>();
  late Future<List<Team>> teamsFuture;
  late Future<User> userFuture;
  final TeamsRepository _repository = LocalTeamsRepository();
  final UsersRepository _repository_users = LocalUsersRepository();
  User? user;

  @override
  void initState() {
    super.initState();
    teamsFuture = _repository.getTeams();
    userFuture = _repository_users.getUserById(int.parse(widget.userId));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Object>(
      future: userFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        user = snapshot.data as User;

        return Scaffold(
          appBar: AppBar(title: Text("Welcome ${user!.user}")),
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
                Expanded(
                  child: _TeamsListView(
                    teamsFuture: teamsFuture,
                    userId: user!.id.toString(),
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              {
                context.push(
                  "/add_edit",
                  extra: {'id': '', 'userId': widget.userId},
                );
                setState(() {
                  teamsFuture = _repository.getTeams();
                });
              }
            },
            backgroundColor: Colors.yellow,
            tooltip: 'Add new team',
            child: Icon(Icons.add),
          ),
          drawer: DrawerMenu(
            scafoldKey: scafoldKey,
            userId: user!.id.toString(),
          ),
        );
      },
    );
  }
}

class _TeamsListView extends StatefulWidget {
  final Future<List<Team>> teamsFuture;
  final String userId;

  const _TeamsListView({
    super.key,
    required this.teamsFuture,
    required this.userId,
  });

  @override
  State<_TeamsListView> createState() => _TeamsListViewState();
}

class _TeamsListViewState extends State<_TeamsListView> {
  final TeamsRepository _repository = LocalTeamsRepository();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: widget.teamsFuture,
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
        title: Text(team.country),
        subtitle: Text(team.confederation),
        trailing: Icon(Icons.arrow_forward),
        onTap: () {
          context.push('/team_detail/${team.id.toString()}/2}');
        },
      ),
    );
  }
}
