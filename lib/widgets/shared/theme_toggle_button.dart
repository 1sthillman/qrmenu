import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:adisyon_uygulamasi/utils/theme_notifier.dart';

class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final isDark = themeNotifier.isDarkMode;

    return GestureDetector(
      onTap: () => themeNotifier.toggleTheme(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 60,
        height: 30,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isDark ? Colors.cyanAccent : Colors.grey.shade300,
            width: 1.5,
          ),
          color: isDark ? Colors.black : Colors.white,
        ),
        child: Stack(
          children: [
            Align(
              alignment: isDark ? Alignment.centerLeft : Alignment.centerRight,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? Colors.cyanAccent : Colors.grey.shade600,
                ),
                child: Icon(
                  isDark ? Icons.nightlight_round : Icons.wb_sunny,
                  size: 16,
                  color: isDark ? Colors.black : Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 