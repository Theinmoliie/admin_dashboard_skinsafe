import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './supabase/supabase_config.dart'; // Make sure this path is correct
import 'screens/dashboard_screen.dart'; // Make sure this path is correct

// The main entry point for your application.
Future<void> main() async {
  // This is required to ensure that plugin services are initialized before running the app.
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase. This must be done before running the app.
  // It uses the credentials from your configuration file.
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );

  // Run the Flutter application.
  runApp(const MyApp());
}

// This is the root widget of your application.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // The title of your application, used by the OS.
      title: 'SkinSafe Admin Dashboard',
      
      // The theme for your application.
      theme: ThemeData(
        // Define a color scheme based on a seed color for a modern Material 3 look.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        
        // Opt-in to use the Material 3 design system.
        useMaterial3: true,

        // Optional: Pre-style some widgets for consistency
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
      
      // The initial screen of your application.
      // Since we are skipping login for now, we go directly to the dashboard.
      home: const DashboardScreen(),

      // Hides the "DEBUG" banner in the top-right corner.
      debugShowCheckedModeBanner: false,
    );
  }
}