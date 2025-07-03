import 'package:adisyon_uygulamasi/main.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MutfakSiparisKarti extends StatelessWidget {
  final Map<String, dynamic> siparis;
  final Map<int, String> urunAdlari; // Ürün adları için sözlük
  final VoidCallback onHazirlandi;
  final bool isLoading;

  const MutfakSiparisKarti({
    super.key,
    required this.siparis,
    required this.urunAdlari,
    required this.onHazirlandi,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final olusturulmaZamani = DateTime.parse(siparis['olusturulma_zamani']);
    final formattedTime = DateFormat('HH:mm:ss').format(olusturulmaZamani);
    final isEkSiparis = siparis['is_ek_siparis'] ?? false;
    
    // Urunler JSONB tipinde olabilir, Map'e dönüştürülmesi gerekir
    Map<String, dynamic> urunler = {};
    if (siparis['urunler'] is Map) {
      urunler = Map<String, dynamic>.from(siparis['urunler']);
    } else {
      // Eğer farklı bir formatta geldiyse (JSON string vb.) burada işle
      print('Beklenmeyen urunler formatı: ${siparis['urunler']}');
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Masa ${siparis['masa_id']}',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    if (isEkSiparis) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade700,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'EK SİPARİŞ',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  formattedTime,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const Divider(),
            // Ürün listesi başlığı
            const Padding(
              padding: EdgeInsets.only(bottom: 8.0),
              child: Text('Ürünler:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            ),
            // Ürünler
            ...urunler.entries.map((entry) {
              // Ürün ID'sini bul
              int? urunId = entry.key is int ? entry.key as int : int.tryParse(entry.key);
              final urunAdi = urunId != null ? urunAdlari[urunId] : 'Ürün Bulunamadı';
              // JSON objesinden miktarı al
              final v = entry.value as Map<String, dynamic>;
              final miktar = (v['miktar'] as num).toInt();
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Text(
                  '$urunAdi: $miktar Adet',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white),
                ),
              );
            }).toList(),
            // Notlar
            if (siparis['notlar'] != null && siparis['notlar'].isNotEmpty) ...[
              const Divider(),
              Text(
                'Notlar:',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(siparis['notlar']),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isLoading ? null : onHazirlandi,
                icon: isLoading
                    ? const SizedBox.shrink()
                    : const Icon(Icons.check_circle_outline),
                label: isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white))
                    : const Text('Hazırlandı'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 