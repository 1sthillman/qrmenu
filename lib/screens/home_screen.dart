import 'package:adisyon_uygulamasi/screens/login_screen.dart';
import 'package:flutter/material.dart';
import '../widgets/garson/masa_gridi_widget.dart';
import '../widgets/mutfak/mutfak_paneli_widget.dart';
import '../widgets/kasiyer/kasiyer_paneli_widget.dart';
import 'yonetici/yonetici_paneli.dart'; // Yönetici paneli importu
import 'package:animations/animations.dart';

class HomeScreen extends StatelessWidget {
  final String userRole;

  const HomeScreen({super.key, required this.userRole});

  Widget _buildPanelForRole(String role) {
    switch (role) {
      case 'garson':
        return const MasaGridi();
      case 'mutfak':
        return const MutfakPaneli();
      case 'kasiyer':
        return const KasiyerPaneli();
      case 'yonetici':
        return const YoneticiPaneli();
      default:
        return const Center(child: Text('Bilinmeyen rol veya yetkiniz yok.'));
    }
  }

  String _getTitleForRole(String role) {
    switch (role) {
      case 'garson':
        return 'Garson Paneli - Masalar';
      case 'mutfak':
        return 'Mutfak Paneli - Siparişler';
      case 'kasiyer':
        return 'Kasiyer Paneli - Ödemeler';
      case 'yonetici':
        return 'Yönetici Paneli';
      default:
        return 'Adisyon Sistemi';
    }
  }

  void _logout(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitleForRole(userRole)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Çıkış Yap',
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: PageTransitionSwitcher(
        duration: const Duration(milliseconds: 400),
        reverse: false,
        transitionBuilder: (child, primaryAnimation, secondaryAnimation) {
          return SharedAxisTransition(
            fillColor: Theme.of(context).colorScheme.background,
            animation: primaryAnimation,
            secondaryAnimation: secondaryAnimation,
            transitionType: SharedAxisTransitionType.horizontal,
            child: child,
          );
        },
        child: _buildPanelForRole(userRole),
      ),
    );
  }
} 