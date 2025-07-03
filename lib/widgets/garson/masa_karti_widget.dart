import 'package:flutter/material.dart';

// Masa durumlarına karşılık gelen renk, metin ve ikonları tanımlayan bir yardımcı fonksiyon
(Color, String, IconData) getMasaDurumBilgisi(String durum) {
  switch (durum) {
    case 'aktif':
      return (const Color(0xFF2196F3), 'AKTİF', Icons.local_fire_department_outlined);
    case 'hazir':
      return (const Color(0xFF4CAF50), 'HAZIR', Icons.notifications_active_outlined);
    case 'teslim_alindi':
      return (const Color(0xFFFF9800), 'TESLİM ALINDI', Icons.delivery_dining_outlined);
    case 'servis_edildi':
      return (const Color(0xFF9C27B0), 'SERVİS EDİLDİ', Icons.room_service_outlined);
    case 'bos':
    default:
      return (const Color(0xFFBDBDBD), 'BOŞ', Icons.chair_outlined); // Rengi biraz koyulaştırdık
  }
}

class MasaKarti extends StatelessWidget {
  final int masaNo;
  final String durum;
  final VoidCallback onTap;

  const MasaKarti({
    super.key,
    required this.masaNo,
    required this.durum,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final (renk, durumMetni, ikon) = getMasaDurumBilgisi(durum);

    return Card(
      elevation: 6,
      clipBehavior: Clip.antiAlias, // Taşan parlama efektini engeller
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: renk,
            gradient: LinearGradient(
              colors: [renk.withOpacity(0.8), renk],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                 AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                  child: Icon(
                    ikon,
                    key: ValueKey<String>(durum), // Durum değiştikçe widget'ı yeniden oluşturur
                    size: 40,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Masa ${masaNo.toString()}',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          const Shadow(
                            blurRadius: 2.0,
                            color: Colors.black26,
                            offset: Offset(1.0, 1.0),
                          ),
                        ],
                      ),
                ),
                const SizedBox(height: 8),
                if (durum != 'bos')
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      durumMetni,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 