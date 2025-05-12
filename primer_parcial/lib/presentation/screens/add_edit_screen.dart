import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AddEditScreen extends StatefulWidget {
  @override
  State<AddEditScreen> createState() => _AddEditScreenState();
}

class _AddEditScreenState extends State<AddEditScreen> {
  TextEditingController inputCountry = TextEditingController();

  TextEditingController inputConfedetarion = TextEditingController();

  TextEditingController inputWorldCups = TextEditingController();

  bool is_world_champion = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New team')),

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
                hintText: "Intert country",
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
                      {Navigator.pop(context)},
                  },
              child: const Text("Insert"),
            ),
          ),
        ],
      ),
    );
  }
}
