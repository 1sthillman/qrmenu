import 'package:adisyon_uygulamasi/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void showOdemeDialog(BuildContext context, int masaNo, double toplamTutar) {
  showDialog(
    context: context,
    builder: (context) {
      return OdemeDialog(masaNo: masaNo, toplamTutar: toplamTutar);
    },
  );
}

class OdemeDialog extends StatefulWidget {
  final int masaNo;
  final double toplamTutar;

  const OdemeDialog({super.key, required this.masaNo, required this.toplamTutar});

  @override
  State<OdemeDialog> createState() => _OdemeDialogState();
}

class _OdemeDialogState extends State<OdemeDialog> {
  String _odemeTipi = 'kredi_karti';
  final _nakitController = TextEditingController();
  double _paraUstu = 0.0;
  bool _isLoading = false;

  void _hesapla() {
    final alinanTutar = double.tryParse(_nakitController.text) ?? 0.0;
    setState(() {
      _paraUstu = alinanTutar - widget.toplamTutar;
    });
  }

  Future<void> _odemeyiTamamla() async {
    setState(() => _isLoading = true);
    try {
      await supabase.rpc('odemeyi_tamamla', params: {
        'p_masa_id': widget.masaNo,
        'p_odeme_tipi': _odemeTipi,
        'p_alinan_tutar': double.tryParse(_nakitController.text),
      });
      if(mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Masa ${widget.masaNo} için ödeme tamamlandı.'), backgroundColor: Colors.green),
        );
      }
    } on PostgrestException catch (e) {
      if (mounted) {
        String errorMessage = 'Bir veritabanı hatası oluştu.';
        if (e.message.contains('Masa durumu "servis_edildi" değil')) {
          errorMessage = 'Bu masanın durumu değişmiş. Lütfen listeyi yenileyin.';
        } else {
           errorMessage = 'Ödeme alınamadı: ${e.message}';
        }
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
       if(mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('İşlem başarısız. Bağlantınızı kontrol edin.'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if(mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Masa ${widget.masaNo} - Ödeme'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Toplam Tutar: ${widget.toplamTutar.toStringAsFixed(2)} TL', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 20),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'kredi_karti', label: Text('Kredi Kartı'), icon: Icon(Icons.credit_card)),
                ButtonSegment(value: 'nakit', label: Text('Nakit'), icon: Icon(Icons.money)),
              ],
              selected: {_odemeTipi},
              onSelectionChanged: (yeniSecim) {
                setState(() => _odemeTipi = yeniSecim.first);
              },
            ),
            if (_odemeTipi == 'nakit') ...[
              const SizedBox(height: 20),
              TextField(
                controller: _nakitController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                decoration: const InputDecoration(labelText: 'Alınan Tutar'),
                onChanged: (_) => _hesapla(),
              ),
              const SizedBox(height: 10),
              Text('Para Üstü: ${_paraUstu >= 0 ? _paraUstu.toStringAsFixed(2) : '0.00'} TL'),
            ]
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('İptal')),
        ElevatedButton(
          onPressed: _isLoading ? null : _odemeyiTamamla,
          child: _isLoading ? const CircularProgressIndicator() : const Text('Ödemeyi Tamamla'),
        ),
      ],
    );
  }
} 