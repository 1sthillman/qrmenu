import 'package:adisyon_uygulamasi/screens/login_screen.dart';
import 'package:flutter/material.dart';
import '../widgets/garson/masa_gridi_widget.dart';
import '../widgets/mutfak/mutfak_paneli_widget.dart';
import '../widgets/kasiyer/kasiyer_paneli_widget.dart';
import 'yonetici/yonetici_paneli.dart'; // Yönetici paneli importu
import 'package:animations/animations.dart';
import '../widgets/shared/theme_toggle_button.dart';

class HomeScreen extends StatelessWidget {
  final String userRole;

  const HomeScreen({super.key, required this.userRole});

  // Ortak panel kart stili
  Widget _styledPanel(Widget child) {
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.2)
                  : Colors.black.withOpacity(0.1),
            ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
        );
      },
    );
  }

  Widget _buildPanelForRole(String role) {
    switch (role) {
      case 'garson':
        return _styledPanel(const MasaGridi());
      case 'mutfak':
        return _styledPanel(const MutfakPaneli());
      case 'kasiyer':
        return _styledPanel(const KasiyerPaneli());
      case 'yonetici':
        return _styledPanel(const YoneticiPaneli());
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
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(_getTitleForRole(userRole)),
        actions: [
          const ThemeToggleButton(),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Çıkış Yap',
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Mat siyah arka plan
          Positioned.fill(
            child: Container(
              color: Theme.of(context).scaffoldBackgroundColor,
            ),
          ),
          SafeArea(
            child: PageTransitionSwitcher(
              duration: const Duration(milliseconds: 400),
              reverse: false,
              transitionBuilder: (child, primaryAnimation, secondaryAnimation) {
                return SharedAxisTransition(
                  fillColor: Colors.transparent,
                  animation: primaryAnimation,
                  secondaryAnimation: secondaryAnimation,
                  transitionType: SharedAxisTransitionType.horizontal,
                  child: child,
                );
              },
              child: _buildPanelForRole(userRole),
            ),
          ),
        ],
      ),
    );
  }
} 