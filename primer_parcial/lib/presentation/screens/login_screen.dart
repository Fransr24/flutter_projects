import 'package:flutter/material.dart';
import 'package:primer_parcial/data/users_repository.dart';
import 'package:primer_parcial/domain/models/user.dart';
import 'package:primer_parcial/domain/reporitory/users_repository.dart';
import 'package:primer_parcial/presentation/screens/home_screen.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  //TextEditing controler accede a comportamiento del qidget
  TextEditingController inputController = TextEditingController();
  TextEditingController inputController2 = TextEditingController();
  late Future<List<User>> usersFuture;
  final UsersRepository _repository = LocalUsersRepository();

  String inputText = "Inicie sesión";
  static var inputUser = User(user: "", password: "", age: '', teamFan: '');

  @override
  void initState() {
    super.initState();
    usersFuture = _repository.getUsers();
  }

  @override
  Widget build(BuildContext context) {
    bool myvar;
    return FutureBuilder(
      future: usersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final userList = snapshot.data as List<User>;

        return Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(inputText, style: TextStyle(fontSize: 24)),
                const SizedBox(height: 28),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TextField(
                    controller: inputController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: "User",
                      hintText: "Insert User",
                    ),
                  ),
                ),
                const SizedBox(height: 16), // Espacio entre los TextFields
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TextField(
                    controller: inputController2,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: "Password",
                      hintText: "Insert password",
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    bool userFound = false;
                    for (var u in userList) {
                      if ((u.user == inputController.text) &&
                          (u.password == inputController2.text)) {
                        userFound = true;
                        context.push("/home", extra: u.id);
                        break;
                      }
                    }
                    if (!userFound) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Incorrect user or password")),
                      );
                    }
                  },
                  child: const Text("insert"),
                ),
                const SizedBox(height: 16),

                ElevatedButton(
                  onPressed:
                      () => {
                        {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Creating new user")),
                          ),
                          context.push("/create_account"),
                        },
                      },
                  child: const Text("Create new account"),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
