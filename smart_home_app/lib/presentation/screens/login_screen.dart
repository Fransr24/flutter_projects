import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  @override
  Widget build(BuildContext context) {
    return SignInScreen(
      providers: [EmailAuthProvider()],
      headerBuilder: (context, constraints, shrinkOffset) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: AspectRatio(
            aspectRatio: 1,
            child: Image.network(
              "https://media.istockphoto.com/id/172376898/es/foto/control-de-quemaduras.jpg?s=612x612&w=0&k=20&c=ueLoferYqki03C9KsUnWhW5eGyXBJVmLO8_NpaJ6E0w=",
            ),
          ),
        );
      },
      // sideBuilder para que aparezca la imagen en pantallas anchas
      sideBuilder: (context, shrinkOffset) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: AspectRatio(
            aspectRatio: 1,
            child: Image.network(
              "https://media.istockphoto.com/id/172376898/es/foto/control-de-quemaduras.jpg?s=612x612&w=0&k=20&c=ueLoferYqki03C9KsUnWhW5eGyXBJVmLO8_NpaJ6E0w=",
            ),
          ),
        );
      },
    );
  }
}
