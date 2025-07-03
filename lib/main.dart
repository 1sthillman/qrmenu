import 'package:adisyon_uygulamasi/screens/home_screen.dart';
import 'package:adisyon_uygulamasi/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

// Global Supabase istemcisi
late final SupabaseClient supabase;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Renk paleti ve tema ayarları
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF4A69BD),
      brightness: Brightness.dark,
    );
    return MaterialApp(
      title: 'Adisyon Uygulaması',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        textTheme: GoogleFonts.poppinsTextTheme().apply(
          bodyColor: colorScheme.onBackground,
          displayColor: colorScheme.onBackground,
        ),
        primaryTextTheme: GoogleFonts.poppinsTextTheme().apply(
          bodyColor: colorScheme.onPrimary,
          displayColor: colorScheme.onPrimary,
        ),
        scaffoldBackgroundColor: colorScheme.background,
        appBarTheme: AppBarTheme(
          backgroundColor: colorScheme.primary,
          surfaceTintColor: colorScheme.surfaceTint,
          elevation: 2,
          titleTextStyle: GoogleFonts.poppins(
            fontSize: 20, fontWeight: FontWeight.w600, color: colorScheme.onPrimary),
        ),
        cardTheme: CardThemeData(
          color: colorScheme.surfaceVariant,
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primaryContainer,
            foregroundColor: colorScheme.onPrimaryContainer,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        bottomSheetTheme: BottomSheetThemeData(
          backgroundColor: colorScheme.surface,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
        ),
      ),
      home: const LoginScreen(),
    );
  }
} 