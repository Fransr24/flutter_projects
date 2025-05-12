import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String username = "colo";

  String password = "pereira";

  TextEditingController inputuser = TextEditingController();
  TextEditingController inputpassword = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My profile')),

      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          const SizedBox(height: 50),
          Center(
            child: ClipOval(
              child: Image.network(
                "https://www.defensacentral.com/uploads/s1/38/30/32/0/franco-mastantuono-santiago-bernabeu.jpeg",
                width: 250,
                height: 250,
                fit: BoxFit.fitHeight,
              ),
            ),
          ),
          const SizedBox(height: 50),
          Row(
            children: [
              Expanded(
                child: Text(
                  "Username: $username",
                  style: TextStyle(fontSize: 18),
                ),
              ),
              IconButton(
                icon: Icon(Icons.edit),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          title: Text("Edit username"),
                          content: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: TextField(
                              controller: inputuser,
                              decoration: InputDecoration(
                                hintText: "Enter new username",
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text("Cancel"),
                            ),
                            TextButton(
                              onPressed: () {
                                username = inputuser.text;
                                Navigator.of(context).pop();
                                setState(() {});
                              },
                              child: Text("Yes"),
                            ),
                          ],
                        ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Text(
                  "Password: $password",
                  style: TextStyle(fontSize: 18),
                ),
              ),
              IconButton(
                icon: Icon(Icons.edit),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          title: Text("Change password"),
                          content: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: TextField(
                              controller: inputpassword,
                              decoration: InputDecoration(
                                hintText: "Enter new password",
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text("Cancel"),
                            ),
                            TextButton(
                              onPressed: () {
                                password = inputpassword.text;
                                Navigator.of(context).pop();
                                setState(() {});
                              },
                              child: Text("Yes"),
                            ),
                          ],
                        ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
