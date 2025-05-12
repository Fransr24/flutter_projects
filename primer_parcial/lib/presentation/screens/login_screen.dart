import 'package:flutter/material.dart';
import 'package:primer_parcial/data/users_list.dart';
import 'package:primer_parcial/domain/user.dart';
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

  String inputText = "Inicie sesión";
  static var inputUser = User(user: "", password: "");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(inputText, style: TextStyle(fontSize: 24)),
            const SizedBox(height: 28),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              // Widget que me permite el ingreso de texto
              child: TextField(
                //keyboardType mejora experiencia de usuario, investigar
                controller: inputController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: "Usuario",
                  hintText: "Intertar Usuario",
                ),
              ),
            ),
            const SizedBox(height: 16), // Espacio entre los TextFields
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              // Widget que me permite el ingreso de texto
              child: TextField(
                //keyboardType mejora experiencia de usuario, investigar
                controller: inputController2,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: "Contraseña",
                  hintText: "Intertar Contraseña",
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed:
                  () => {
                    inputUser.user = inputController.text,
                    inputUser.password = inputController2.text,
                    if (usersList.any(
                      (u) =>
                          (u.user == inputUser.user) &&
                          (u.password == inputUser.password),
                    ))
                      {context.push("/home", extra: inputUser.user)}
                    else
                      {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Usuario y/o contraseña incorrectos"),
                          ),
                        ),
                      },

                    setState(() {}),
                  },
              child: const Text("insert"),
            ),
          ],
        ),
      ),
    );
  }
}
