// main.dart
import 'package:flutter/material.dart';
import 'package:myapp/Pages/log_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://phvlsyelvvbbixiobzht.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBodmxzeWVsdnZiYml4aW9iemh0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MjU0NjExNjAsImV4cCI6MjA0MTAzNzE2MH0.YLNWlOz1vuOESKQWCQTFjL__QRra2lXgBvgcsOXhVtU',
  );

  runApp(const FerreteriaApp());
}

// Get a reference your Supabase client
final supabase = Supabase.instance.client;

class FerreteriaApp extends StatelessWidget {
  const FerreteriaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color.fromARGB(255, 21, 40, 59),
      ),
      home: AuthSignIn(), // Utiliza la pantalla principal
    );
  }
}
