import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:ui';

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

    return ClipPath(
      clipper: OctagonClipper(),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          color: Colors.white.withOpacity(0.1),
          child: Stack(
            children: [
              // Stronger neon border
              Positioned.fill(
                child: CustomPaint(
                  painter: OctagonPainter(color: renk),
                ),
              ),
              // Glassy content
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(ikon, size: 40, color: renk),
                        const SizedBox(height: 8),
                        Text(
                          'Masa ${masaNo}',
                          style: TextStyle(
                            color: renk,
                            fontWeight: FontWeight.bold,
                            shadows: [Shadow(blurRadius: 12, color: renk, offset: Offset(0, 0))],
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (durum != 'bos') Text(
                          durumMetni,
                          style: TextStyle(
                            color: renk,
                            fontWeight: FontWeight.w600,
                            shadows: [Shadow(blurRadius: 10, color: renk, offset: Offset(0, 0))],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Saksı kartı için 8 köşeli neon kenar çizen CustomPainter ve Clipper
class OctagonClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final double w = size.width;
    final double h = size.height;
    final Path path = Path()
      ..moveTo(w * 0.4, 0)
      ..lineTo(w * 0.6, 0)
      ..lineTo(w, h * 0.4)
      ..lineTo(w, h * 0.6)
      ..lineTo(w * 0.6, h)
      ..lineTo(w * 0.4, h)
      ..lineTo(0, h * 0.6)
      ..lineTo(0, h * 0.4)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class OctagonPainter extends CustomPainter {
  final Color color;
  OctagonPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final path = OctagonClipper().getClip(size);
    // Stronger glow stroke
    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..color = color.withOpacity(0.8)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawPath(path, glowPaint);
    // Sharp neon stroke
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..color = color;
    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
} 