import 'package:adisyon_uygulamasi/main.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

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
            style: TextStyle(color: Theme.of(context).colorScheme.onBackground)),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: adController,
                    style: TextStyle(color: Theme.of(context).colorScheme.onBackground),
                    decoration: InputDecoration(
                      labelText: 'Ürün Adı',
                      labelStyle: TextStyle(color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7)),
                      hintStyle: TextStyle(color: Theme.of(context).colorScheme.onBackground.withOpacity(0.4)),
                      filled: true,
                      fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.white12 : Colors.black12,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    validator: (value) => value!.isEmpty ? 'Bu alan boş bırakılamaz' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: fiyatController,
                    style: TextStyle(color: Theme.of(context).colorScheme.onBackground),
                    decoration: InputDecoration(
                      labelText: 'Fiyat',
                      labelStyle: TextStyle(color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7)),
                      hintStyle: TextStyle(color: Theme.of(context).colorScheme.onBackground.withOpacity(0.4)),
                      filled: true,
                      fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.white12 : Colors.black12,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) => value!.isEmpty ? 'Bu alan boş bırakılamaz' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: kategoriController,
                    style: TextStyle(color: Theme.of(context).colorScheme.onBackground),
                    decoration: InputDecoration(
                      labelText: 'Kategori',
                      labelStyle: TextStyle(color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7)),
                      hintStyle: TextStyle(color: Theme.of(context).colorScheme.onBackground.withOpacity(0.4)),
                      filled: true,
                      fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.white12 : Colors.black12,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    validator: (value) => value!.isEmpty ? 'Bu alan boş bırakılamaz' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: imageController,
                    style: TextStyle(color: Theme.of(context).colorScheme.onBackground),
                    decoration: InputDecoration(
                      labelText: 'Resim URL',
                      labelStyle: TextStyle(color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7)),
                      hintStyle: TextStyle(color: Theme.of(context).colorScheme.onBackground.withOpacity(0.4)),
                      filled: true,
                      fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.white12 : Colors.black12,
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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

class YoneticiPaneli extends StatelessWidget {
  const YoneticiPaneli({super.key});

  @override
  Widget build(BuildContext context) {
    // Neon accent rengi
    const neonColor = Color(0xFF00FFF1);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Ürün Yönetimi',
          style: GoogleFonts.poppins(color: neonColor, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        iconTheme: const IconThemeData(color: neonColor),
        elevation: 0,
        actions: [
          Icon(Icons.inventory_2_outlined, color: neonColor),
          const SizedBox(width: 16),
        ],
      ),
      body: const UrunYonetimEkrani(),
    );
  }
} 