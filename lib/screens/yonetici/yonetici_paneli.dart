import 'package:adisyon_uygulamasi/main.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

// Ürün modelini buraya taşıyarak yeniden kullanılabilir hale getirelim
class Urun {
  final int id;
  final String ad;
  final double fiyat;
  final String kategori;
  final String? imageUrl;  // Resim URL'si (isteğe bağlı)

  Urun({required this.id, required this.ad, required this.fiyat, required this.kategori, this.imageUrl});

  factory Urun.fromMap(Map<String, dynamic> map) {
    return Urun(
      id: map['id'],
      ad: map['ad'],
      fiyat: (map['fiyat'] as num).toDouble(),
      kategori: map['kategori'],
      imageUrl: map['image_url'] as String?,
    );
  }
}

class UrunYonetimEkrani extends StatefulWidget {
  const UrunYonetimEkrani({super.key});

  @override
  State<UrunYonetimEkrani> createState() => _UrunYonetimEkraniState();
}

class _UrunYonetimEkraniState extends State<UrunYonetimEkrani> {
  final _urunlerStream = supabase.from('urunler').stream(primaryKey: ['id']).order('kategori').order('ad');

  Future<void> _showUrunDialog({Urun? urun}) async {
    final formKey = GlobalKey<FormState>();
    final adController = TextEditingController(text: urun?.ad);
    final fiyatController = TextEditingController(text: urun?.fiyat.toString());
    final kategoriController = TextEditingController(text: urun?.kategori);
    final imageController = TextEditingController(text: (urun is Urun) ? urun.imageUrl : null);

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: Text(urun == null ? 'Yeni Ürün Ekle' : 'Ürünü Düzenle',
            style: const TextStyle(color: Colors.white)),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: adController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Ürün Adı',
                      labelStyle: const TextStyle(color: Colors.white70),
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: Colors.white12,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    validator: (value) => value!.isEmpty ? 'Bu alan boş bırakılamaz' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: fiyatController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Fiyat',
                      labelStyle: const TextStyle(color: Colors.white70),
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: Colors.white12,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) => value!.isEmpty ? 'Bu alan boş bırakılamaz' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: kategoriController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Kategori',
                      labelStyle: const TextStyle(color: Colors.white70),
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: Colors.white12,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    validator: (value) => value!.isEmpty ? 'Bu alan boş bırakılamaz' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: imageController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Resim URL',
                      labelStyle: const TextStyle(color: Colors.white70),
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: Colors.white12,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    keyboardType: TextInputType.url,
                  ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('İptal'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text('Kaydet'),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  try {
                    final upsertData = {
                      'ad': adController.text,
                      'fiyat': double.parse(fiyatController.text),
                      'kategori': kategoriController.text,
                      'image_url': imageController.text,
                    };
                    if (urun != null) {
                      await supabase.from('urunler').update(upsertData).eq('id', urun.id);
                    } else {
                      await supabase.from('urunler').insert(upsertData);
                    }
                    Navigator.of(context).pop();
                  } on PostgrestException catch (e) {
                     if(mounted) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Hata: ${e.message}'),
                          backgroundColor: Colors.red,
                        ));
                     }
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteUrun(int id) async {
     try {
        await supabase.from('urunler').delete().eq('id', id);
     } on PostgrestException catch (e) {
        if(mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Hata: ${e.message}'),
            backgroundColor: Colors.red,
          ));
        }
     }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _urunlerStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Hata: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final urunler = snapshot.data!.map((map) => Urun.fromMap(map)).toList();

          return ListView.builder(
            itemCount: urunler.length,
            itemBuilder: (context, index) {
              final urun = urunler[index];
              return ListTile(
                title: Text(urun.ad),
                subtitle: Text(urun.kategori),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${urun.fiyat.toStringAsFixed(2)} TL'),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => _showUrunDialog(urun: urun),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _deleteUrun(urun.id),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showUrunDialog(),
        label: const Text('Yeni Ürün'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}

class RaporlamaEkrani extends StatefulWidget {
  const RaporlamaEkrani({super.key});

  @override
  State<RaporlamaEkrani> createState() => _RaporlamaEkraniState();
}

class _RaporlamaEkraniState extends State<RaporlamaEkrani> {
  DateTime _baslangicTarihi = DateTime.now().subtract(const Duration(days: 7));
  DateTime _bitisTarihi = DateTime.now();
  bool _isLoading = false;

  Map<String, dynamic>? _ciroRaporu;
  List<Map<String, dynamic>>? _enCokSatanlar;

  Future<void> _tarihSec(BuildContext context, bool isBaslangic) async {
    final DateTime? secilen = await showDatePicker(
      context: context,
      initialDate: isBaslangic ? _baslangicTarihi : _bitisTarihi,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (secilen != null) {
      setState(() {
        if (isBaslangic) {
          _baslangicTarihi = secilen;
        } else {
          _bitisTarihi = secilen;
        }
      });
    }
  }

  Future<void> _raporOlustur() async {
    setState(() => _isLoading = true);
    try {
      final ciroData = await supabase.rpc('get_ciro_raporu', params: {
        'baslangic_tarihi': _baslangicTarihi.toIso8601String(),
        'bitis_tarihi': _bitisTarihi.toIso8601String(),
      }).single();

      final enCokSatanlarData = await supabase.rpc('get_en_cok_satan_urunler', params: {
        'baslangic_tarihi': _baslangicTarihi.toIso8601String(),
        'bitis_tarihi': _bitisTarihi.toIso8601String(),
        'urun_limiti': 5,
      });

      setState(() {
        _ciroRaporu = ciroData;
        _enCokSatanlar = List<Map<String, dynamic>>.from(enCokSatanlarData);
      });

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Rapor oluşturulurken hata: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Tarih Seçim Alanı
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text('Rapor Tarih Aralığı', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _tarihSec(context, true),
                          icon: const Icon(Icons.calendar_today),
                          label: Text('Başlangıç: ${DateFormat('dd/MM/yyyy').format(_baslangicTarihi)}'),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _tarihSec(context, false),
                          icon: const Icon(Icons.calendar_today),
                          label: Text('Bitiş: ${DateFormat('dd/MM/yyyy').format(_bitisTarihi)}'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _raporOlustur,
                      child: _isLoading ? const CircularProgressIndicator() : const Text('Rapor Oluştur'),
                    ),
                  ],
                ),
              ),
            ),
            
            if (_isLoading) const Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(child: CircularProgressIndicator()),
            ),

            if (!_isLoading && _ciroRaporu != null) ...[
              const SizedBox(height: 20),
              // Ciro Raporu Kartı
              Card(
                child: ListTile(
                  leading: const Icon(Icons.monetization_on, color: Colors.green, size: 40),
                  title: Text('${_ciroRaporu!['toplam_ciro'].toStringAsFixed(2)} TL'),
                  subtitle: const Text('Toplam Ciro'),
                ),
              ),
              Card(
                 child: ListTile(
                  leading: const Icon(Icons.receipt_long, color: Colors.blue, size: 40),
                  title: Text(_ciroRaporu!['toplam_siparis_sayisi'].toString()),
                  subtitle: const Text('Toplam Sipariş Sayısı'),
                ),
              ),
            ],

            if (!_isLoading && _enCokSatanlar != null) ...[
              const SizedBox(height: 20),
              // En Çok Satanlar Tablosu
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                       Text('En Çok Satan Ürünler', style: Theme.of(context).textTheme.titleLarge),
                       const SizedBox(height: 8),
                      DataTable(
                        columns: const [
                          DataColumn(label: Text('Ürün Adı')),
                          DataColumn(label: Text('Satış Adeti'), numeric: true),
                        ],
                        rows: _enCokSatanlar!.map((urun) => DataRow(
                          cells: [
                            DataCell(Text(urun['urun_adi'].toString())),
                            DataCell(Text(urun['satis_adeti'].toString())),
                          ]
                        )).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}

class YoneticiPaneli extends StatelessWidget {
  const YoneticiPaneli({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 0,
          bottom: TabBar(
            labelColor: Theme.of(context).colorScheme.onPrimary,
            unselectedLabelColor: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
            indicatorColor: Theme.of(context).colorScheme.secondary,
            tabs: [
              Tab(icon: Icon(Icons.inventory_2_outlined), text: 'Ürün Yönetimi'),
              Tab(icon: Icon(Icons.bar_chart_outlined), text: 'Raporlama'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            UrunYonetimEkrani(),
            RaporlamaEkrani(),
          ],
        ),
      ),
    );
  }
} 