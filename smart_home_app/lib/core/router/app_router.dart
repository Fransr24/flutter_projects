import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_home_app/presentation/screens/air_conditioning_screen.dart';
import 'package:smart_home_app/presentation/screens/home_screen.dart';
import 'package:smart_home_app/presentation/screens/light_screen.dart';
import 'package:smart_home_app/presentation/screens/login_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

/// provider para escuchar el estado de autenticación
final authProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

/// esto es para refrescar el router cuando cambia el estado del usuario
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final isLoggedIn = FirebaseAuth.instance.currentUser != null;

  return GoRouter(
    initialLocation: isLoggedIn ? '/home' : '/login',

    refreshListenable: GoRouterRefreshStream(
      FirebaseAuth.instance.authStateChanges(),
    ),
    redirect: (context, state) {
      final user = FirebaseAuth.instance.currentUser;
      final isLoggingIn = state.uri.path == '/login';

      if (user == null && !isLoggingIn) return '/login';
      if (user != null && isLoggingIn) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: "/login", builder: (context, state) => LoginScreen()),
      GoRoute(path: "/home", builder: (context, state) => HomeScreen()),
      GoRoute(path: "/light", builder: (context, state) => LightScreen()),
      GoRoute(
        path: "/air",
        builder: (context, state) => AirConditioningScreen(),
      ),
    ],
  );
});
