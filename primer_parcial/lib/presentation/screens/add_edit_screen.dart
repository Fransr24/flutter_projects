import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:primer_parcial/data/football_teams_repository.dart';
import 'package:primer_parcial/domain/models/team.dart';
import 'package:primer_parcial/domain/reporitory/teams_repository.dart';

class AddEditScreen extends StatefulWidget {
  String userId;
  String id;

  AddEditScreen({super.key, this.id = "", required this.userId});
  @override
  State<AddEditScreen> createState() => _AddEditScreenState();
}

class _AddEditScreenState extends State<AddEditScreen> {
  final TeamsRepository _repository = LocalTeamsRepository();
  late final Future<Team> editTeam;

  TextEditingController inputCountry = TextEditingController();

  TextEditingController inputConfedetarion = TextEditingController();

  TextEditingController inputWorldCups = TextEditingController();

  TextEditingController inputFlag = TextEditingController();

  bool is_world_champion = false;
  bool isEdit = false;
  late int id;

  @override
  void initState() {
    super.initState();
    if (widget.id != "") {
      id = int.parse(widget.id);
      editTeam = _repository.getTeamById(id);
      isEdit = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    late Team newTeam;
    // edito elemento
    if (isEdit) {
      return Scaffold(
        appBar: AppBar(title: Text("Edit Team")),
        body: FutureBuilder<Object>(
          future: editTeam,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            final team = snapshot.data as Team;
            inputCountry.text = team.country;
            inputConfedetarion.text = team.confederation;
            inputWorldCups.text = team.worldCups.toString();
            inputFlag.text = team.flag != null ? team.flag! : "";
            is_world_champion = team.isWorldChampion == 1;

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    "Edit team details:",
                    style: TextStyle(fontSize: 24),
                  ),
                ),
                const SizedBox(height: 28),

                Text("Country", style: TextStyle(fontSize: 18)),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: TextField(
                    controller: inputCountry,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: "Insert country",
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                Text("Confederation", style: TextStyle(fontSize: 18)),

                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: TextField(
                    controller: inputConfedetarion,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: "Insert Confederation",
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                Text("World cups", style: TextStyle(fontSize: 18)),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: TextField(
                    controller: inputWorldCups,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: "Insert how many world cups does the team have",
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(height: 15),

                SwitchListTile(
                  title: const Text('Is the team the actual world champion?'),
                  subtitle: const Text('No/Yes'),
                  value: is_world_champion,
                  onChanged: (value) {
                    setState(() {
                      is_world_champion = !is_world_champion;
                    });
                  },
                  activeColor: Colors.green,
                  inactiveTrackColor: Colors.red.shade100,
                  inactiveThumbColor: Colors.red,
                ),
                const SizedBox(height: 10),
                Text("Flag (optional)", style: TextStyle(fontSize: 18)),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: TextField(
                    controller: inputFlag,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: "Insert Flag URL",
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: ElevatedButton(
                    onPressed:
                        () => {
                          if (inputConfedetarion.text.isEmpty ||
                              inputCountry.text.isEmpty ||
                              inputWorldCups.text.isEmpty)
                            {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Fill all the required fields"),
                                ),
                              ),
                            }
                          else
                            {
                              // r' rawString, con \d indico que solo sean digitos, indico que la string solo contenga numeros
                              if (!RegExp(
                                r'^\d+$',
                              ).hasMatch(inputWorldCups.text))
                                {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        "WorldCups can only be numbers",
                                      ),
                                    ),
                                  ),
                                }
                              else
                                {
                                  newTeam = Team(
                                    id: team.id,
                                    country: inputCountry.text,
                                    confederation: inputConfedetarion.text,
                                    worldCups: int.parse(inputWorldCups.text),
                                    isWorldChampion: is_world_champion ? 1 : 0,
                                    flag: inputFlag.text,
                                  ),

                                  _repository.updateTeam(newTeam),
                                  setState(() {}),
                                  context.push("/home"),
                                },
                            },
                        },
                    child: const Text("Insert"),
                  ),
                ),
                const SizedBox(height: 10),

                Center(
                  child: ElevatedButton(
                    onPressed:
                        () => {
                          showDialog(
                            context: context,
                            builder:
                                (context) => AlertDialog(
                                  title: Text("Deleting team"),
                                  content: Text(
                                    "Are you sure you want to delete the team?",
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed:
                                          () => Navigator.of(context).pop(),
                                      child: Text("No"),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();

                                        _repository.deleteTeam(team);
                                        setState(() {});
                                        context.push("/home");
                                        ;
                                      },
                                      child: Text("Yes"),
                                    ),
                                  ],
                                ),
                          ),
                        },
                    child: const Text("Delete"),
                  ),
                ),
              ],
            );
          },
        ),
      );
    }
    //Nuevo elemento
    else {
      bool idOption = widget.id == "yes";
      return Scaffold(
        appBar: AppBar(title: Text('New team')),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                "Add new team details:",
                style: TextStyle(fontSize: 24),
              ),
            ),
            const SizedBox(height: 28),

            Text("Country", style: TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: TextField(
                controller: inputCountry,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: "Insert country",
                ),
              ),
            ),
            const SizedBox(height: 15),
            Text("Confederation", style: TextStyle(fontSize: 18)),

            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: TextField(
                controller: inputConfedetarion,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: "Insert Confederation",
                ),
              ),
            ),
            const SizedBox(height: 15),
            Text("World cups", style: TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: TextField(
                controller: inputWorldCups,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: "Insert how many world cups does the team have",
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(height: 15),

            SwitchListTile(
              title: const Text('Is the team the actual world champion?'),
              subtitle: const Text('No/Yes'),
              value: is_world_champion,
              onChanged: (value) {
                setState(() {
                  is_world_champion = !is_world_champion;
                });
              },
              activeColor: Colors.green,
              inactiveTrackColor: Colors.red.shade100,
              inactiveThumbColor: Colors.red,
            ),
            const SizedBox(height: 10),
            Text("Flag (optional)", style: TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: TextField(
                controller: inputFlag,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: "Insert Flag URL",
                ),
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: ElevatedButton(
                onPressed:
                    () => {
                      if (inputConfedetarion.text.isEmpty ||
                          inputCountry.text.isEmpty ||
                          inputWorldCups.text.isEmpty)
                        {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Fill all the required fields"),
                            ),
                          ),
                        }
                      else
                        {
                          // r' rawString, con \d indico que solo sean digitos, indico que la string solo contenga numeros
                          if (!RegExp(r'^\d+$').hasMatch(inputWorldCups.text))
                            {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    "WorldCups can only be numbers",
                                  ),
                                ),
                              ),
                            }
                          else
                            {
                              newTeam = Team(
                                country: inputCountry.text,
                                confederation: inputConfedetarion.text,
                                worldCups: int.parse(inputWorldCups.text),
                                isWorldChampion: is_world_champion ? 1 : 0,
                                flag: inputFlag.text,
                              ),

                              _repository.insertTeam(newTeam),
                              setState(() {}),
                              context.push("/home"),
                            },
                        },
                    },
                child: const Text("Insert"),
              ),
            ),
          ],
        ),
      );
    }
  }
}
