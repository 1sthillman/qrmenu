import 'dart:async';
import 'package:adisyon_uygulamasi/main.dart';
import 'package:adisyon_uygulamasi/screens/garson/siparis_ekrani.dart';
import 'package:adisyon_uygulamasi/widgets/garson/masa_karti_widget.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MasaGridi extends StatefulWidget {
  const MasaGridi({super.key});

  @override
  State<MasaGridi> createState() => _MasaGridiState();
}

class _MasaGridiState extends State<MasaGridi> {
  late List<Map<String, dynamic>> _masalar = [];
  StreamSubscription<List<Map<String, dynamic>>>? _masaSubscription;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeMasalar();
  }

  Future<void> _initializeMasalar() async {
    try {
      debugPrint('[MasaGridi] Initializing... Fetching initial table data.');
      // 1. İlk veriyi Future ile hızlıca çek.
      final initialData = await supabase.from('masalar').select().order('id');
      
      if (mounted) {
        setState(() {
          _masalar = List<Map<String, dynamic>>.from(initialData);
          _isLoading = false;
          debugPrint('[MasaGridi] Initial data loaded successfully. ${_masalar.length} tables found.');
        });
        _listenForUpdates(); // İlk veri geldikten sonra anlık güncellemeleri dinle.
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Masalar yüklenirken bir hata oluştu: ${e.toString()}';
          _isLoading = false;
          debugPrint('[MasaGridi] Error fetching initial data: $_error');
        });
      }
    }
  }

  void _listenForUpdates() {
    debugPrint('[MasaGridi] Listening for real-time updates...');
    // 2. Realtime stream'i dinle.
    _masaSubscription = supabase
        .from('masalar')
        .stream(primaryKey: ['id'])
        .order('id')
        .listen((updatedData) {
          if (mounted) {
            setState(() {
              _masalar = updatedData;
              debugPrint('[MasaGridi] Real-time update received. ${_masalar.length} tables updated.');
            });
              }
        }, onError: (e) {
          debugPrint('[MasaGridi] Real-time subscription error: $e');
        });
  }

  @override
  void dispose() {
    debugPrint('[MasaGridi] Disposing... Cancelling stream subscription.');
    _masaSubscription?.cancel();
    super.dispose();
  }

  Color _getMasaRenk(String durum) {
    switch (durum) {
      case 'aktif':
        return Colors.blue.shade700;
      case 'hazir':
        return Colors.green.shade600;
      case 'teslim_alindi':
        return Colors.orange.shade700;
      case 'servis_edildi':
        return Colors.purple.shade700;
      case 'bos':
      default:
        return Colors.grey.shade800;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      debugPrint('[MasaGridi] Showing loading indicator.');
          return const Center(child: CircularProgressIndicator());
        }

    if (_masalar.isEmpty) {
      debugPrint('[MasaGridi] No tables found. Showing empty message.');
      return const Center(child: Text('Gösterilecek masa bulunamadı.'));
    }

    // Responsive sütun sayısı: mobilde 3, onun üzerinde 5
    final crossCount = MediaQuery.of(context).size.width < 600 ? 3 : 5;
    debugPrint('[MasaGridi] Building grid with ${_masalar.length} tables.');
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.0,
      ),
      itemCount: _masalar.length,
      itemBuilder: (context, index) {
        final masa = _masalar[index];
        final masaNo = masa['id'] as int;
        final durum = masa['durum'] as String;
        final renk = _getMasaRenk(durum);

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SiparisEkrani(
                  key: ValueKey(masaNo),
                  masaNo: masaNo,
                ),
              ),
            );
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              color: renk,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: renk.withOpacity(0.5),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Masa',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 16,
                  ),
                ),
                Text(
                  masaNo.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (durum != 'bos')
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      durum.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
} 