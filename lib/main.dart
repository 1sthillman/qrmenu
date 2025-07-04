import 'package:adisyon_uygulamasi/screens/home_screen.dart';
import 'package:adisyon_uygulamasi/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:adisyon_uygulamasi/widgets/shared/lava_lamp_background.dart';
import 'package:provider/provider.dart';
import 'package:adisyon_uygulamasi/utils/theme_notifier.dart';
import 'package:hive_flutter/hive_flutter.dart';

// Global Supabase istemcisi
late final SupabaseClient supabase;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Hive for local caching
  await Hive.initFlutter();
  await Hive.openBox('masalarBox');

  // Supabase'i başlatırken daha kararlı ayarlar kullanıyoruz.
  // - persistSession: false -> Oturum bilgilerini cihazda saklama, her seferinde temiz başla.
  // - authFlowType: AuthFlowType.implicit -> Web uygulamaları için daha uygun bir kimlik doğrulama akışı.
  await Supabase.initialize(
    url: 'https://egcklzfiyxxnvyxwoowq.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVnY2tsemZpeXh4bnZ5eHdvb3dxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDg0NjQxMTcsImV4cCI6MjA2NDA0MDExN30.dfRQv3lYFCaI1T5ydOw4HyoEJ0I1wOSIUcG8ueEbxKQ',
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.implicit,
    ),
  );

  supabase = Supabase.instance.client;

  // NetworkImage yükleme hatalarını yoksay
  FlutterError.onError = (FlutterErrorDetails details) {
    if (details.exception is NetworkImageLoadException) {
      return;
    }
    FlutterError.dumpErrorToConsole(details);
  };

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeNotifier(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    // Neon accent ve temalar
    const neonColor = Color(0xFF00FFF1);

    final darkColorScheme = ColorScheme.fromSeed(
      seedColor: neonColor,
      brightness: Brightness.dark,
    );

    final lightColorScheme = ColorScheme.fromSeed(
      seedColor: neonColor,
      brightness: Brightness.light,
    );

    return MaterialApp(
      title: 'Adisyon Uygulaması',
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        // Solid mat siyah arka plan
        return Container(
          color: themeNotifier.isDarkMode ? Colors.black : Colors.white,
          child: child,
        );
      },
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: lightColorScheme,
        textTheme: GoogleFonts.poppinsTextTheme().apply(
          bodyColor: lightColorScheme.onBackground,
          displayColor: lightColorScheme.onBackground,
        ),
        primaryTextTheme: GoogleFonts.poppinsTextTheme().apply(
          bodyColor: lightColorScheme.onPrimary,
          displayColor: lightColorScheme.onPrimary,
        ),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          iconTheme: IconThemeData(color: neonColor),
          elevation: 0,
          titleTextStyle: TextStyle(
            fontSize: 20, fontWeight: FontWeight.w600, color: neonColor),
        ),
        cardTheme: CardThemeData(
          color: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: neonColor.withOpacity(0.6)),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: neonColor,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        bottomSheetTheme: BottomSheetThemeData(
          backgroundColor: Colors.grey.shade200,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: darkColorScheme,
        textTheme: GoogleFonts.poppinsTextTheme().apply(
          bodyColor: darkColorScheme.onBackground,
          displayColor: darkColorScheme.onBackground,
        ),
        primaryTextTheme: GoogleFonts.poppinsTextTheme().apply(
          bodyColor: darkColorScheme.onPrimary,
          displayColor: darkColorScheme.onPrimary,
        ),
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          iconTheme: IconThemeData(color: neonColor),
          elevation: 0,
          titleTextStyle: TextStyle(
            fontSize: 20, fontWeight: FontWeight.w600, color: neonColor),
        ),
        cardTheme: CardThemeData(
          color: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: neonColor.withOpacity(0.6)),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: neonColor,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        bottomSheetTheme: BottomSheetThemeData(
          backgroundColor: Colors.grey[900],
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
        ),
      ),
      themeMode: themeNotifier.themeMode,
      home: const LoginScreen(),
    );
  }
} 