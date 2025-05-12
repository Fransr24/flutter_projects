import 'package:primer_parcial/presentation/screens/add_edit_screen.dart';
import 'package:primer_parcial/presentation/screens/home_screen.dart';
import 'package:primer_parcial/presentation/screens/login_screen.dart';
import 'package:primer_parcial/presentation/screens/profile_screen.dart';
import 'package:primer_parcial/presentation/screens/settings_screen.dart';
import 'package:primer_parcial/presentation/screens/team_detail.dart';
import 'package:go_router/go_router.dart';

final appRouter = GoRouter(
  initialLocation: "/login",
  routes: [
    GoRoute(path: "/login", builder: (context, state) => LoginScreen()),
    GoRoute(
      path: "/home",
      builder: (context, state) => HomeScreen(userName: state.extra.toString()),
      //Tambien se puede poner en path parameters en vez de extra, hay que modificarlo en la parte de login en la clase esta
    ),
    GoRoute(
      path: "/team_detail/:team_country",
      builder:
          (context, state) =>
              TeamDetail(country: state.pathParameters['team_country']!),
    ),
    GoRoute(path: "/add_edit", builder: (context, state) => AddEditScreen()),
    GoRoute(path: "/profile", builder: (context, state) => ProfileScreen()),
    GoRoute(path: "/settings", builder: (context, state) => SettingsScreen()),
  ],
);
