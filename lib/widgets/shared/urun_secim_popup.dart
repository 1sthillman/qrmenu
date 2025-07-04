import 'package:adisyon_uygulamasi/main.dart';
import 'package:adisyon_uygulamasi/screens/garson/siparis_ekrani.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'glass_container.dart';
import 'package:adisyon_uygulamasi/utils/theme_helpers.dart';
import 'package:cached_network_image/cached_network_image.dart';

// Ürün seçimi için kullanılacak olan, alttan açılan modern popup.
class UrunSecimPopup extends StatefulWidget {
  // Mevcut seçilmiş ürünleri ve tüm ürün listesini dışarıdan alır.
  final Map<Urun, int> mevcutSecilenUrunler;
  final List<Urun> tumUrunler;

  const UrunSecimPopup({
    super.key,
    required this.mevcutSecilenUrunler,
    required this.tumUrunler,
  });

  @override
  State<UrunSecimPopup> createState() => _UrunSecimPopupState();
}

class _UrunSecimPopupState extends State<UrunSecimPopup> {
  late Map<Urun, int> _secilenUrunler;
  late List<Urun> _filtrelenmisUrunler;
  String _seciliKategori = 'Tümü';
  final TextEditingController _aramaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Popup açıldığında, dışarıdan gelen seçili ürünlerin bir kopyasını oluşturur.
    // Bu sayede, "Ekle" butonuna basılmadan yapılan değişiklikler ana sipariş ekranını etkilemez.
    _secilenUrunler = Map.from(widget.mevcutSecilenUrunler);
    _filtrelenmisUrunler = widget.tumUrunler;
    _aramaController.addListener(_filtrele);
  }

  @override
  void dispose() {
    _aramaController.dispose();
    super.dispose();
  }

  // Arama ve kategoriye göre ürünleri filtreler.
  void _filtrele() {
    setState(() {
      _filtrelenmisUrunler = widget.tumUrunler.where((urun) {
        final aramaSorgusu = _aramaController.text.toLowerCase();
        final aramaKosulu = urun.ad.toLowerCase().contains(aramaSorgusu);
        final kategoriKosulu = _seciliKategori == 'Tümü' || urun.kategori == _seciliKategori;
        return aramaKosulu && kategoriKosulu;
      }).toList();
    });
  }

  // Bir ürünün miktarını artırır veya azaltır.
  void _miktarGuncelle(Urun urun, int degisim) {
    setState(() {
      final mevcutMiktar = _secilenUrunler[urun] ?? 0;
      final yeniMiktar = mevcutMiktar + degisim;
      if (yeniMiktar > 0) {
        _secilenUrunler[urun] = yeniMiktar;
      } else {
        _secilenUrunler.remove(urun);
      }
    });
  }

  bool _isDark(BuildContext context) => Theme.of(context).brightness == Brightness.dark;

  Color _textColor(BuildContext context, [double opacity = 1]) {
    return Theme.of(context).colorScheme.onBackground.withOpacity(opacity);
  }

  Color _cardColor(BuildContext context, double darkOpacity, double lightOpacity) {
    final isDark = _isDark(context);
    return (isDark ? Colors.white : Colors.black).withOpacity(isDark ? darkOpacity : lightOpacity);
  }

  @override
  Widget build(BuildContext context) {
    // Kategorileri dinamik olarak ürün listesinden oluşturur.
    final kategoriler = ['Tümü', ...widget.tumUrunler.map((u) => u.kategori).toSet()];

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return GlassContainer(
          borderRadius: 20,
          child: Container(
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                _buildHeader(),
                _buildAramaVeFiltre(kategoriler),
                Expanded(
                  child: _buildUrunGrid(scrollController),
                ),
                _buildFooter(),
              ],
            ),
          ),
        );
      },
    );
  }

  // Popup başlığı ve kapatma butonu
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 10, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Ürün Seçimi',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: _textColor(context),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: context.isDark ? Colors.white : Colors.black),
            onPressed: () => Navigator.pop(context), // Değişiklikleri kaydetmeden kapat
          ),
        ],
      ),
    );
  }
  
  // Arama çubuğu ve kategori filtreleri
  Widget _buildAramaVeFiltre(List<String> kategoriler) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          TextField(
            controller: _aramaController,
            style: TextStyle(color: context.isDark ? Colors.white : Colors.black),
            decoration: InputDecoration(
              hintText: 'Ürün ara...',
              hintStyle: TextStyle(color: (context.isDark ? Colors.white : Colors.black).withOpacity(0.5)),
              prefixIcon: Icon(Icons.search, color: (context.isDark ? Colors.white : Colors.black).withOpacity(0.7)),
              filled: true,
              fillColor: _cardColor(context,0.1,0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: kategoriler.length,
              itemBuilder: (context, index) {
                final kategori = kategoriler[index];
                final isSelected = kategori == _seciliKategori;
                return ChoiceChip(
                  label: Text(kategori),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _seciliKategori = kategori;
                        _filtrele();
                      });
                    }
                  },
                  backgroundColor: _cardColor(context,0.1,0.05),
                  selectedColor: Colors.amber,
                  labelStyle: GoogleFonts.poppins(
                    color: isSelected ? Colors.black87 : _textColor(context),
                    fontWeight: FontWeight.w600,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: Colors.transparent),
                  ),
                );
              },
              separatorBuilder: (context, index) => const SizedBox(width: 8),
            ),
          ),
        ],
      ),
    );
  }

  // Ürünlerin listelendiği grid yapı
  Widget _buildUrunGrid(ScrollController scrollController) {
    if (_filtrelenmisUrunler.isEmpty) {
      return Center(
        child: Text(
          'Aramanızla eşleşen ürün bulunamadı.',
          style: GoogleFonts.poppins(color: _textColor(context,0.7)),
        ),
      );
    }
    
    // Responsive sütun sayısı: mobilde 2, geniş ekranda 5
    final crossCount = MediaQuery.of(context).size.width < 600 ? 2 : 5;
    
    return GridView.builder(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossCount,
        childAspectRatio: 0.75, // Kartların en-boy oranı
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _filtrelenmisUrunler.length,
      itemBuilder: (context, index) {
        final urun = _filtrelenmisUrunler[index];
        final miktar = _secilenUrunler[urun] ?? 0;

        const neonColor = Color(0xFF00FFF1);
        return Container(
          decoration: BoxDecoration(
            color: _isDark(context) ? Colors.black : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: neonColor.withOpacity(0.6), width: 1.5),
            boxShadow: [
              BoxShadow(color: neonColor.withOpacity(0.3), blurRadius: 8, spreadRadius: 1),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: urun.imageUrl != null && urun.imageUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: urun.imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary)),
                      errorWidget: (context, url, error) => Center(child: Icon(Icons.fastfood, color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7), size: 40)),
                    )
                  : Center(child: Icon(Icons.fastfood, color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7), size: 40)),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      urun.ad,
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: _textColor(context)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${urun.fiyat.toStringAsFixed(2)} TL',
                      style: GoogleFonts.poppins(color: _textColor(context,0.7)),
                    ),
                  ],
                ),
              ),
              Container(
                color: _isDark(context) ? Colors.black.withOpacity(0.2) : Colors.grey.shade200,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _circleButton(Icons.remove, Colors.redAccent, () => _miktarGuncelle(urun, -1)),
                    Text(
                      miktar.toString(),
                      style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: _textColor(context)),
                    ),
                    _circleButton(Icons.add, Colors.greenAccent, () => _miktarGuncelle(urun, 1)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _circleButton(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 1.5),
          boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 4)],
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  // Popup alt bilgisi ve "Ekle" butonu
  Widget _buildFooter() {
    final toplamAdet = _secilenUrunler.values.fold(0, (prev, miktar) => prev + miktar);
    
    return Container(
      padding: const EdgeInsets.all(16).copyWith(bottom: MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(
        color: _isDark(context) ? const Color(0xFF2C3E50) : Colors.grey.shade300,
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, -2))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              '$toplamAdet Ürün Seçildi',
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: _textColor(context)),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              // Seçilen ürünleri ana sipariş ekranına geri gönderir.
              Navigator.pop(context, _secilenUrunler);
            },
            icon: const Icon(Icons.check, color: Colors.black87),
            label: Text('Ekle', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.black87)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
} 