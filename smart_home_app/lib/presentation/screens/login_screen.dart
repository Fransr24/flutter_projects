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
      showPasswordVisibilityToggle: true,
      headerBuilder: (context, constraints, shrinkOffset) {
        return Padding(padding: const EdgeInsets.all(20), child: AspectRatio(aspectRatio: 1, child: Image.asset("assets/AppLogin.png")));
      },
      // sideBuilder para que aparezca la imagen en pantallas anchas
      sideBuilder: (context, shrinkOffset) {
        return Padding(padding: const EdgeInsets.all(20), child: AspectRatio(aspectRatio: 1, child: Image.asset("assets/AppLogin.png")));
      },
    );
  }
}
