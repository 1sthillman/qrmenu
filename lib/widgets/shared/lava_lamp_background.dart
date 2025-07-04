import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

class LavaLampBackground extends StatefulWidget {
  final Widget? child;
  const LavaLampBackground({Key? key, this.child}) : super(key: key);

  @override
  _LavaLampBackgroundState createState() => _LavaLampBackgroundState();
}

class _LavaLampBackgroundState extends State<LavaLampBackground> with SingleTickerProviderStateMixin {
  late FragmentProgram _program;
  FragmentShader? _shader;
  late Ticker _ticker;
  late final ValueNotifier<double> _timeNotifier = ValueNotifier<double>(0.0);
  double _lastUpdateTime = 0.0;

  @override
  void initState() {
    super.initState();
    // Shader programını yükle
    FragmentProgram.fromAsset('assets/shaders/lavalamp.frag').then((prog) {
      _program = prog;
      setState(() {
        _shader = _program.fragmentShader();
      });
    });
    // Zaman güncellemesi artık ValueNotifier üzerinden
    _ticker = createTicker((elapsed) {
      final currentTime = elapsed.inMilliseconds / 1000.0;
      // Saniyede ~30 kare güncelleme (33ms aralık)
      if (currentTime - _lastUpdateTime >= 1 / 30) {
        _lastUpdateTime = currentTime;
        _timeNotifier.value = currentTime;
      }
    })..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _timeNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_shader == null) {
      return widget.child ?? const SizedBox.shrink();
    }
    return Stack(
      children: [
        Positioned.fill(
          child: RepaintBoundary(
            child: SizedBox.expand(
              child: CustomPaint(
                painter: _ShaderPainter(_shader!, _timeNotifier),
              ),
            ),
          ),
        ),
        if (widget.child != null)
          Positioned.fill(child: widget.child!),
      ],
    );
  }
}

class _ShaderPainter extends CustomPainter {
  final FragmentShader shader;
  final ValueListenable<double> time;
  _ShaderPainter(this.shader, this.time) : super(repaint: time);

  @override
  void paint(Canvas canvas, Size size) {
    shader
      ..setFloat(0, time.value)
      ..setFloat(1, size.width)
      ..setFloat(2, size.height);
    final paint = Paint()..shader = shader;
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
} 