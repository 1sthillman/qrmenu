import 'package:adisyon_uygulamasi/main.dart';
import 'package:adisyon_uygulamasi/widgets/shared/urun_secim_popup.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert'; // JSON işlemleri için eklendi
import 'package:equatable/equatable.dart';
import 'dart:async'; // Realtime sipariş takibi için

// Sipariş verisi için model
class Urun extends Equatable {
  final int id;
  final String ad;
  final double fiyat;
  final String kategori;
  final String? imageUrl;

  const Urun({
    required this.id,
    required this.ad,
    required this.fiyat,
    required this.kategori,
    this.imageUrl,
  });

  // Equatable için props listesi. ID'ye göre karşılaştırma yeterlidir.
  @override
  List<Object?> get props => [id];

  factory Urun.fromMap(Map<String, dynamic> map) {
    return Urun(
      id: map['id'],
      ad: map['ad'],
      fiyat: (map['fiyat'] as num? ?? 0.0).toDouble(), // Null gelme ihtimaline karşı
      kategori: map['kategori'] ?? 'Diğer',
      imageUrl: map['image_url'],
    );
  }
}

class SiparisEkrani extends StatefulWidget {
  final int masaNo;
  const SiparisEkrani({super.key, required this.masaNo});

  @override
  State<SiparisEkrani> createState() => _SiparisEkraniState();
}

class _SiparisEkraniState extends State<SiparisEkrani> {
  // Seçilen ürünleri ve miktarlarını tutmak için bir Map.
  // Urun nesnesini anahtar olarak kullanarak tüm ürün bilgilerine erişim sağlıyoruz.
  Map<Urun, int> _secilenUrunler = {};
  Map<Urun, int> _oncekiSecilen = {}; // Önceki siparişler, ek sipariş için delta hesaplamada
  final TextEditingController _notController = TextEditingController();
  bool _isLoading = false;
  List<Urun> _tumUrunler = []; // Tüm ürünleri başta bir kez yükleyeceğiz
  String? _siparisId;
  String? _siparisDurum;
  StreamSubscription<List<Map<String, dynamic>>>? _siparisSubscription;

  @override
  void initState() {
    super.initState();
    _initUrunler().then((_) {
      _initSiparis();
      _listenSiparisUpdates();
    });
  }

  // Ürünleri başlangıçta yükleyerek popup'ın daha hızlı açılmasını sağlar.
  Future<void> _initUrunler() async {
    try {
      // Tüm sütunları açıkça seçerek veri bütünlüğünü sağlıyoruz.
      final urunlerData = await supabase.from('urunler').select('*');
      
      if (mounted) {
        setState(() {
          // Gelen verinin bir liste olduğundan ve null olmadığından emin oluyoruz.
          if (urunlerData is List) {
            _tumUrunler = urunlerData.map((data) {
              // Her bir öğenin Map olduğundan emin olarak daha güvenli bir dönüşüm yapıyoruz.
              if (data is Map<String, dynamic>) {
                return Urun.fromMap(data);
              }
              // Beklenmedik bir veri tipi gelirse, boş bir Urun nesnesi döndürerek
              // uygulamanın çökmesini engelliyoruz. (ID'si -1 olan geçersiz bir ürün)
              return const Urun(id: -1, ad: 'Hatalı Ürün', fiyat: 0, kategori: 'Hata');
            }).where((urun) => urun.id != -1).toList(); // Hatalı ürünleri listeden temizle
          }
        });
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar('Ürünler yüklenirken kritik bir hata oluştu: ${e.toString()}');
      }
    }
  }

  // Mevcut masa siparişini DB'den yükler
  Future<void> _initSiparis() async {
    try {
      final result = await supabase
          .from('siparisler')
          .select('id, urunler, durum, olusturulma_zamani')
          .eq('masa_id', widget.masaNo)
          .order('olusturulma_zamani', ascending: false)
          .limit(1)
          .maybeSingle();
      if (result != null) {
        final data = result as Map<String, dynamic>;
        _siparisId = data['id'] as String?;
        _siparisDurum = data['durum'] as String?;
        final urunlerJson = data['urunler'] as Map<String, dynamic>;
        final yeniSecilen = <Urun, int>{};
        urunlerJson.forEach((key, value) {
          final id = int.tryParse(key);
          final miktar = (value['miktar'] as num).toInt();
          if (id != null) {
            final urun = _tumUrunler.firstWhere(
              (u) => u.id == id,
              orElse: () => Urun(id: id, ad: 'Bilinmeyen', fiyat: 0, kategori: ''),
            );
            yeniSecilen[urun] = miktar;
          }
        });
        if (mounted) {
          setState(() => _secilenUrunler = yeniSecilen);
          _oncekiSecilen = Map.from(yeniSecilen);
        }
      }
    } catch (e) {
      debugPrint('Error initializing siparis: $e');
      if (mounted) {
        setState(() {
          _secilenUrunler.clear();
          _siparisDurum = null;
          _siparisId = null;
        });
      }
    }
  }

  // Gerçek zamanlı sipariş güncellemelerini dinler
  void _listenSiparisUpdates() {
    _siparisSubscription = supabase
        .from('siparisler')
        .stream(primaryKey: ['id'])
        .eq('masa_id', widget.masaNo)
        .order('olusturulma_zamani', ascending: false)
        .listen((data) {
      if (data.isNotEmpty) {
        final item = data.first;
        _siparisDurum = item['durum'] as String?;
        final urunlerJson = item['urunler'] as Map<String, dynamic>;
        final yeniSecilen = <Urun, int>{};
        urunlerJson.forEach((key, value) {
          final id = int.tryParse(key);
          final miktar = (value['miktar'] as num).toInt();
          if (id != null) {
            final urun = _tumUrunler.firstWhere(
              (u) => u.id == id,
              orElse: () => Urun(id: id, ad: 'Bilinmeyen', fiyat: 0, kategori: ''),
            );
            yeniSecilen[urun] = miktar;
          }
        });
        if (mounted) setState(() => _secilenUrunler = yeniSecilen);
        _oncekiSecilen = Map.from(yeniSecilen);
      } else if (mounted) {
        setState(() {
          _secilenUrunler.clear();
          _siparisDurum = null;
          _siparisId = null;
        });
      }
    }, onError: (e) => debugPrint('Error in siparis stream: $e'));
  }

  // Ürün seçme popup'ını gösterir.
  Future<void> _showUrunSecimPopup() async {
    // Popup'tan dönebilecek olan güncellenmiş ürün listesini bekliyoruz.
    final Map<Urun, int>? sonuc = await showModalBottomSheet(
      context: context,
      isScrollControlled: true, // İçeriğin tüm ekranı kaplamasına izin ver
      backgroundColor: Colors.transparent,
      builder: (context) => UrunSecimPopup(
        mevcutSecilenUrunler: Map.from(_secilenUrunler), // Değişikliklerin popup içinde kalması için kopya oluştur
        tumUrunler: _tumUrunler,
      ),
    );

    // Sonuç null değilse (yani kullanıcı "Ekle" butonuna bastıysa),
    // yerel state'i güncelliyoruz.
    if (sonuc != null) {
      setState(() {
        _secilenUrunler = sonuc;
      });
    }
  }

  // Siparişi onaylama fonksiyonu
  Future<void> _siparisiOnayla() async {
    if (_secilenUrunler.isEmpty) {
      _showErrorSnackbar('Lütfen siparişe ürün ekleyin.');
      return;
    }

    setState(() => _isLoading = true);

    // Gönderilecek ürünler: eğer ek siparişse sadece delta (yeni eklenenler), aksi halde tüm sipariş
    final Map<Urun, int> toSend;
    if (_oncekiSecilen.isNotEmpty) {
      final delta = <Urun, int>{};
      _secilenUrunler.forEach((urun, miktar) {
        if (!_oncekiSecilen.containsKey(urun)) {
          delta[urun] = miktar;
        }
      });
      if (delta.isEmpty) {
        _showErrorSnackbar('Lütfen ek sipariş için yeni ürün seçin.');
        setState(() => _isLoading = false);
        return;
      }
      toSend = delta;
    } else {
      toSend = Map.from(_secilenUrunler);
    }
    // JSON formatına dönüştürüyoruz
    final urunlerJson = {
      for (var entry in toSend.entries)
        entry.key.id.toString(): {
          'miktar': entry.value,
          'fiyat': entry.key.fiyat,
          'ad': entry.key.ad,
        }
    };

    try {
      await supabase.rpc('siparisi_onayla', params: {
        'p_masa_id': widget.masaNo,
        'p_urunler': urunlerJson,
        'p_notlar': _notController.text,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sipariş başarıyla onaylandı!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Sipariş ekranını kapat
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar('Sipariş gönderilemedi: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Sipariş teslim alındı olarak işaretler
  Future<void> _siparisiTeslimAlindi() async {
    if (_siparisId == null) return;
    setState(() => _isLoading = true);
    try {
      await supabase.rpc('siparisi_teslim_alindi', params: {'p_siparis_id': _siparisId});
      // UI'ı güncelle: Servis Edildi butonunu göster
      if (mounted) setState(() => _siparisDurum = 'teslim_edildi');
    } catch (e) {
      _showErrorSnackbar('Teslim alma sırasında hata: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Servis edildi olarak işaretler ve ekranı kapatır
  Future<void> _servisEdildi() async {
    setState(() => _isLoading = true);
    try {
      await supabase.rpc('servis_edildi', params: {'p_masa_id': widget.masaNo});
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showErrorSnackbar('Servis etme sırasında hata: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Masa ${widget.masaNo} Siparişi', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFF2C3E50),
      ),
      backgroundColor: const Color(0xFF1D2A3A),
      body: Column(
        children: [
          Expanded(
            child: _secilenUrunler.isEmpty
                ? _buildBosSiparisEkrani()
                : _buildSiparisListesi(),
          ),
          _buildAltKontrolPaneli(),
        ],
      ),
    );
  }

  // Sipariş listesi boş olduğunda gösterilecek widget.
  Widget _buildBosSiparisEkrani() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, size: 80, color: Colors.blueGrey.shade300),
          const SizedBox(height: 16),
          Text(
            'Siparişiniz Henüz Boş',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Aşağıdaki butona tıklayarak ürün eklemeye başlayın.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.blueGrey.shade200),
          ),
        ],
      ),
    );
  }

  // Seçilen ürünlerin listelendiği widget.
  Widget _buildSiparisListesi() {
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: _secilenUrunler.length,
      itemBuilder: (context, index) {
        final urun = _secilenUrunler.keys.elementAt(index);
        final miktar = _secilenUrunler[urun]!;
        final toplamFiyat = urun.fiyat * miktar;

        return Card(
          color: const Color(0xFF2C3E50),
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: urun.imageUrl != null
                  ? Image.network(
                      urun.imageUrl!,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => 
                        const Icon(Icons.broken_image, size: 50, color: Colors.white38),
                    )
                  : const Icon(Icons.fastfood, size: 50, color: Colors.white38),
            ),
            title: Text(urun.ad, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Text(
              '$miktar Adet - Birim Fiyat: ${urun.fiyat.toStringAsFixed(2)} TL',
              style: GoogleFonts.poppins(color: Colors.white70),
            ),
            trailing: Text(
              '${toplamFiyat.toStringAsFixed(2)} TL',
              style: GoogleFonts.poppins(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        );
      },
    );
  }

  // Ekranın altındaki not, ürün ekle ve onayla butonlarını içeren panel.
  Widget _buildAltKontrolPaneli() {
    // Toplam tutarı hesapla
    final toplamTutar = _secilenUrunler.entries
        .map((e) => e.key.fiyat * e.value)
        .fold(0.0, (prev, element) => prev + element);
    return Container(
      padding: const EdgeInsets.all(16).copyWith(bottom: MediaQuery.of(context).padding.bottom + 16),
      decoration: const BoxDecoration(
        color: Color(0xFF2C3E50),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, -2)),
        ],
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Toplam Tutar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Toplam Tutar:", style: GoogleFonts.poppins(fontSize: 18, color: Colors.white70, fontWeight: FontWeight.w500)),
              Text("${toplamTutar.toStringAsFixed(2)} TL", style: GoogleFonts.poppins(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          // Not ekleme
          TextField(
            controller: _notController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Sipariş notu ekleyin... (isteğe bağlı)',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
              prefixIcon: const Icon(Icons.note_alt_outlined, color: Colors.white70),
              filled: true,
              fillColor: Colors.white.withOpacity(0.1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Ürün ekle
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: _showUrunSecimPopup,
              icon: const Icon(Icons.add_shopping_cart, color: Colors.white),
              label: Text('Ürün Ekle / Düzenle', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                backgroundColor: Colors.blueGrey.shade600,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Siparişi Onayla
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _siparisiOnayla,
              icon: _isLoading
                  ? const SizedBox.shrink()
                  : const Icon(Icons.check_circle_outline, color: Colors.black87),
              label: _isLoading
                  ? const CircularProgressIndicator(color: Colors.black87)
                  : Text('Siparişi Onayla', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                backgroundColor: Colors.amber,
                disabledBackgroundColor: Colors.grey.shade400,
              ),
            ),
          ),
          // Teslim Aldım butonu (mutfak hazır yapıldıktan sonra)
          if (_siparisDurum == 'hazir') ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _siparisiTeslimAlindi,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text('Teslim Aldım', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.orange,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
          // Servis Edildi butonu (teslim edildikten sonra)
          if (_siparisDurum == 'teslim_edildi') ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _servisEdildi,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text('Servis Edildi', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.purple,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  void dispose() {
    _siparisSubscription?.cancel();
    _notController.dispose();
    super.dispose();
  }
} 