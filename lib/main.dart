import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:to_do_app/auth_screen.dart';
import 'package:to_do_app/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://jwwtyxijsywbbwmmmzdo.supabase.co',
    anonKey: 'sb_publishable_gBQ3Jp1348NORJr2KYlOFQ_tH848wE7',
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final supabase = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'To-Do App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.indigo, useMaterial3: true),
      home: supabase.auth.currentSession != null ? HomeScreen() : AuthScreen(),
    );
  }
}
