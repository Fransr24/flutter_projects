import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:primer_parcial/data/users_repository.dart';
import 'package:primer_parcial/domain/models/user.dart';
import 'package:primer_parcial/domain/reporitory/users_repository.dart';

class CreateAccountScreen extends StatelessWidget {
  final UsersRepository _repository = LocalUsersRepository();
  late final Future<User> editUser;

  TextEditingController inputUsername = TextEditingController();

  TextEditingController inputPassword = TextEditingController();

  TextEditingController inputAge = TextEditingController();

  TextEditingController inputTeamFan = TextEditingController();

  TextEditingController inputProfilePicture = TextEditingController();

  @override
  Widget build(BuildContext context) {
    late User newUser;

    return Scaffold(
      appBar: AppBar(title: Text("Create account")),

      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              "Add new user details:",
              style: TextStyle(fontSize: 24),
            ),
          ),
          const SizedBox(height: 28),

          Text("Username"),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: TextField(
              controller: inputUsername,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Intert username",
              ),
            ),
          ),
          const SizedBox(height: 15),
          Text("Password"),

          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: TextField(
              controller: inputPassword,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Insert password",
              ),
            ),
          ),
          const SizedBox(height: 15),
          Text("Age"),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: TextField(
              controller: inputAge,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Insert age",
              ),
              keyboardType: TextInputType.number,
            ),
          ),
          const SizedBox(height: 15),
          Text("User's team "),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: TextField(
              controller: inputTeamFan,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Insert User's team",
              ),
              keyboardType: TextInputType.number,
            ),
          ),

          const SizedBox(height: 10),
          Text("Profile Picture (optional)"),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: TextField(
              controller: inputProfilePicture,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Insert Profile picure URL",
              ),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: ElevatedButton(
              onPressed:
                  () => {
                    if (inputPassword.text.isEmpty ||
                        inputUsername.text.isEmpty ||
                        inputAge.text.isEmpty ||
                        inputTeamFan.text.isEmpty)
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
                        if (!RegExp(r'^\d+$').hasMatch(inputAge.text))
                          {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Age can only be a number"),
                              ),
                            ),
                          }
                        else
                          {
                            newUser = User(
                              user: inputUsername.text,
                              password: inputPassword.text,
                              age: inputAge.text,
                              teamFan: inputTeamFan.text,
                              profilePicture: inputProfilePicture.text,
                            ),

                            _repository.insertUser(newUser),
                            context.push("/login"),
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
