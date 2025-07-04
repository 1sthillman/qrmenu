import 'package:audioplayers/audioplayers.dart';

class SoundPlayer {
  static final AudioPlayer _player = AudioPlayer();

  static Future<void> _play(String asset) => _player.play(AssetSource(asset));

  static Future<void> orderConfirmed() async => _play('sounds/order_confirmed.mp3');
  static Future<void> orderReady() async => _play('sounds/order_ready.mp3');
  static Future<void> orderReceived() async => _play('sounds/order_received.mp3');
  static Future<void> serviceCompleted() async => _play('sounds/service_completed.mp3');
  static Future<void> paymentReceived() async => _play('sounds/payment_received.mp3');
} 