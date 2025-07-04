import 'package:adisyon_uygulamasi/main.dart';
import 'package:adisyon_uygulamasi/widgets/mutfak/siparis_karti_widget.dart';
import 'package:flutter/material.dart';
import 'package:adisyon_uygulamasi/utils/sound_player.dart';

class MutfakPaneli extends StatefulWidget {
  const MutfakPaneli({super.key});

  @override
  State<MutfakPaneli> createState() => _MutfakPaneliState();
}

class _MutfakPaneliState extends State<MutfakPaneli> {
  late final Future<Map<int, String>> _urunAdlariFuture;

  @override
  void initState() {
    super.initState();
    _urunAdlariFuture = _getUrunAdlari();
  }

  // Tüm ürünleri bir kere çekip bir sözlüğe (Map) dönüştürür.
  Future<Map<int, String>> _getUrunAdlari() async {
    try {
      final data = await supabase.from('urunler').select('id, ad');
      return {for (var urun in data) urun['id'] as int: urun['ad'] as String};
    } catch (e) {
      // Hata durumunda boş bir map döndür, stream builder hatayı gösterecektir.
      return {};
    }
  }

  final _siparislerStream = supabase
      .from('siparisler')
      .stream(primaryKey: ['id']).order('olusturulma_zamani');

  final Set<String> _loadingSiparisler = {};

  Future<void> _siparisiHazirla(String siparisId) async {
    if (_loadingSiparisler.contains(siparisId)) return;

    setState(() {
      _loadingSiparisler.add(siparisId);
    });

    try {
      await supabase.rpc('siparisi_hazir_yap', params: {'p_siparis_id': siparisId});
      // Siparişi hazır yapıldığında ses çal
      SoundPlayer.orderReady();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loadingSiparisler.remove(siparisId);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Önce ürün adlarını yükle, sonra siparişleri dinlemeye başla.
    return FutureBuilder<Map<int, String>>(
      future: _urunAdlariFuture,
      builder: (context, urunlerSnapshot) {
        if (urunlerSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (urunlerSnapshot.hasError || !urunlerSnapshot.hasData) {
          return Center(child: Text('Ürünler yüklenemedi: ${urunlerSnapshot.error}'));
        }

        final urunAdlari = urunlerSnapshot.data!;

        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: _siparislerStream,
          builder: (context, siparislerSnapshot) {
            if (siparislerSnapshot.hasError) {
              return Center(child: Text('Siparişler yüklenirken hata oluştu: ${siparislerSnapshot.error}'));
            }
            if (!siparislerSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final allSiparisler = siparislerSnapshot.data!;
            final bekleyenSiparisler = allSiparisler
                .where((s) => s['durum'] == 'bekliyor')
                .toList();
            if (bekleyenSiparisler.isEmpty) {
              return const Center(
                child: Text(
                  'Bekleyen Sipariş Yok',
                  style: TextStyle(fontSize: 24, color: Colors.grey),
                ),
              );
            }

            return ListView.builder(
              itemCount: bekleyenSiparisler.length,
              itemBuilder: (context, index) {
                final siparis = bekleyenSiparisler[index];
                final siparisId = siparis['id'] as String;
                return MutfakSiparisKarti(
                  siparis: siparis,
                  urunAdlari: urunAdlari,
                  isLoading: _loadingSiparisler.contains(siparisId),
                  onHazirlandi: () => _siparisiHazirla(siparisId),
                );
              },
            );
          },
        );
      },
    );
  }
} 