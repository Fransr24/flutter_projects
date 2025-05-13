import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:primer_parcial/core/database/database.dart';
import 'package:primer_parcial/presentation/provider/settings_provider.dart';
import 'core/router/app_router.dart';

late AppDatabase database;
void main() async {
  // Ensure that the binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the database and measure initialization time
  final stopwatch = Stopwatch()..start();
  database = await AppDatabase.create('app_database.db');
  stopwatch.stop();
  log('Database initialized in ${stopwatch.elapsed.inMilliseconds}ms');

  runApp(const ProviderScope(child: MainApp()));
}

class MainApp extends ConsumerWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appTheme = ref.watch(settingsNotifierProvider);

    return MaterialApp.router(
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
      theme: appTheme.getTheme(),
    );
  }
}
