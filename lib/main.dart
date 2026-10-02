import 'package:flutter/material.dart';
import 'data/database.dart';
import 'screens/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppDatabase.instance.init();
  runApp(const SinvoApp());
}

class SinvoApp extends StatelessWidget {
  const SinvoApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'SINVO',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
    darkTheme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo, brightness: Brightness.dark),
    themeMode: ThemeMode.system,
    home: const AppShell(),
  );
}
