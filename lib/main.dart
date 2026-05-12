import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/item_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final authProvider = AuthProvider();
  await authProvider.initUser();

  runApp(MyApp(authProvider: authProvider));
}

class MyApp extends StatelessWidget {
  final AuthProvider authProvider;

  const MyApp({super.key, required this.authProvider});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider(create: (_) => ItemProvider()),
      ],
      child: MaterialApp(
        title: 'findBack',
        debugShowCheckedModeBanner: false,

        theme: ThemeData(
          useMaterial3: false,

          brightness: Brightness.light,
          scaffoldBackgroundColor: Colors.white,

          // 🔥 ЖЁСТКО фиксируем основной цвет
          primaryColor: Colors.black,
          primarySwatch: Colors.grey, // важно, чтобы не было синего fallback

          // ❗ УБРАН colorScheme полностью

          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            elevation: 0,
            iconTheme: IconThemeData(color: Colors.white),
            titleTextStyle: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          iconTheme: const IconThemeData(
            color: Colors.black,
          ),

          textTheme: const TextTheme(
            bodyLarge: TextStyle(color: Colors.black),
            bodyMedium: TextStyle(color: Colors.black),
          ),

          cardTheme: CardThemeData(
            color: Colors.white,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade300),
            ),
          ),

          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
          ),

          progressIndicatorTheme: const ProgressIndicatorThemeData(
            color: Colors.black,
          ),

          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.black),
            ),
            labelStyle: const TextStyle(color: Colors.black),
          ),

          snackBarTheme: const SnackBarThemeData(
            backgroundColor: Colors.black,
            contentTextStyle: TextStyle(color: Colors.white),
          ),
        ),

        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/login': (context) => const LoginScreen(),
          '/home': (context) => const HomeScreen(),
        },
      ),
    );
  }
}