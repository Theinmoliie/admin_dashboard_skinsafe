import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase/supabase_config.dart';
import 'screens/splash_screen.dart'; // Import the new splash screen

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SkinSafe Admin Dashboard',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.deepPurple.shade700,
          foregroundColor: Colors.white,
          elevation: 2,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Colors.deepPurple.shade700,
          foregroundColor: Colors.white,
        ),
      ),
      // --- Use the SplashScreen as the home widget ---
      // It will handle redirecting to either Login or Dashboard.
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}