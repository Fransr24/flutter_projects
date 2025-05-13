import 'package:primer_parcial/presentation/screens/add_edit_screen.dart';
import 'package:primer_parcial/presentation/screens/create_account_screen.dart';
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
      builder: (context, state) => HomeScreen(userId: state.extra.toString()),
    ),
    GoRoute(
      path: "/team_detail/:team_id/:user_id",
      builder: (context, state) {
        final String teamId = state.pathParameters['team_id']!;
        final String userId = state.pathParameters['user_id']!;
        return TeamDetail(id: teamId, userId: userId);
      },
    ),
    GoRoute(
      path: "/add_edit",
      builder: (context, state) {
        final Map<String, String> extras = state.extra as Map<String, String>;
        final String id = extras['id'] ?? '';
        final String userId = extras['userId'] ?? '';

        return AddEditScreen(id: id, userId: userId);
      },
    ),
    GoRoute(
      path: "/profile",
      builder: (context, state) => ProfileScreen(id: state.extra.toString()),
    ),
    GoRoute(path: "/settings", builder: (context, state) => SettingsScreen()),
    GoRoute(
      path: "/create_account",
      builder: (context, state) => CreateAccountScreen(),
    ),
  ],
);
