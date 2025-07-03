import 'package:adisyon_uygulamasi/widgets/kasiyer/odeme_dialog.dart';
import 'package:flutter/material.dart';
import 'package:adisyon_uygulamasi/main.dart';
import 'dart:async'; // realtime ödeme güncellemesi için
import 'package:supabase_flutter/supabase_flutter.dart';

class KasiyerPaneli extends StatefulWidget {
  const KasiyerPaneli({super.key});

  @override
  State<KasiyerPaneli> createState() => _KasiyerPaneliState();
}

class _KasiyerPaneliState extends State<KasiyerPaneli> {
  // Ödeme bekleyen masaları tutan state
  List<Map<String, dynamic>> _odenecekMasalar = [];
  bool _isLoading = true;
  String? _error;
  StreamSubscription<List<Map<String, dynamic>>>? _masaSub;

  @override
  void initState() {
    super.initState();
    _fetchOdemeMasalar(); // İlk veri yükle
    // Masalar tablosundan güncellemeleri dinle, view'den veri yenile
    _masaSub = supabase
      .from('masalar')
      .stream(primaryKey: ['id'])
      .listen((_) => _fetchOdemeMasalar());
  }

  /// Ödeme bekleyen masaları view'den çek
  Future<void> _fetchOdemeMasalar() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final data = await supabase
        .from('odeme_bekleyen_masalar')
        .select()
        .order('masa_no');
      _odenecekMasalar = List<Map<String, dynamic>>.from(data);
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _masaSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text('Hata: $_error'));
    }
    if (_odenecekMasalar.isEmpty) {
      return const Center(
        child: Text('Ödeme Bekleyen Masa Yok', style: TextStyle(fontSize: 24, color: Colors.grey)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _odenecekMasalar.length,
      itemBuilder: (context, index) {
        final masa = _odenecekMasalar[index];
        final masaNo = masa['masa_no'] as int;
        final toplam = (masa['toplam_tutar'] as num).toDouble();
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          elevation: 4,
          child: ListTile(
            leading: const Icon(Icons.receipt_long, size: 40, color: Colors.blueAccent),
            title: Text('Masa $masaNo', style: Theme.of(context).textTheme.headlineSmall),
            trailing: Text('${toplam.toStringAsFixed(2)} TL', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            onTap: () => _showPaymentSheet(context, masaNo, toplam),
          ),
        );
      },
    );
  }

  // Masaya tıklanınca ödeme bottom sheet'i göster
  void _showPaymentSheet(BuildContext context, int masaNo, double toplamTutar) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => PaymentBottomSheet(masaNo: masaNo, toplamTutar: toplamTutar),
    );
  }
}

/// Ödeme ve fiş işlemleri için bottom sheet widget
class PaymentBottomSheet extends StatefulWidget {
  final int masaNo;
  final double toplamTutar;
  const PaymentBottomSheet({super.key, required this.masaNo, required this.toplamTutar});
  @override State<PaymentBottomSheet> createState() => _PaymentBottomSheetState();
}

class _PaymentBottomSheetState extends State<PaymentBottomSheet> {
  bool _isLoading = false;
  String _odemeTipi = 'nakit';
  final TextEditingController _nakitController = TextEditingController();
  double _paraUstu = 0.0;
  Map<int, Map<String, dynamic>> _urunler = {};

  @override
  void initState() {
    super.initState();
    _loadOrderDetails();
  }

  Future<void> _loadOrderDetails() async {
    final data = await supabase.from('siparisler').select('urunler').eq('masa_id', widget.masaNo);
    final temp = <int, Map<String, dynamic>>{};
    for (var row in data) {
      final items = row['urunler'] as Map<String, dynamic>;
      items.forEach((k, v) {
        final id = int.tryParse(k);
        if (id != null) {
          final miktar = (v['miktar'] as num).toInt();
          final fiyat = (v['fiyat'] as num).toDouble();
          final ad = v['ad'] as String;
          temp.update(id, (e) { e['miktar'] += miktar; return e; }, ifAbsent: () => {'ad': ad, 'miktar': miktar, 'fiyat': fiyat});
        }
      });
    }
    if (mounted) setState(() => _urunler = temp);
  }

  void _hesapla() {
    final alinan = double.tryParse(_nakitController.text) ?? widget.toplamTutar;
    setState(() => _paraUstu = alinan - widget.toplamTutar);
  }

  Future<void> _printReceipt() async {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fiş yazdırıldı')));
  }

  Future<void> _odemeYap() async {
    setState(() => _isLoading = true);
    try {
      await supabase.rpc('odemeyi_tamamla', params: {
        'p_masa_id': widget.masaNo,
        'p_odeme_tipi': _odemeTipi,
        'p_alinan_tutar': double.tryParse(_nakitController.text) ?? widget.toplamTutar,
      });
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ödeme hatası: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Masa ${widget.masaNo} - Sipariş Detayı', style: Theme.of(context).textTheme.headlineSmall),
          ),
          ..._urunler.entries.map((e) => ListTile(
            title: Text('${e.value['ad']} x${e.value['miktar']}'),
            trailing: Text('${(e.value['fiyat'] as double).toStringAsFixed(2)} TL'),
          )),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Toplam: ${widget.toplamTutar.toStringAsFixed(2)} TL'),
                if (_odemeTipi == 'nakit') SizedBox(
                  width: 100,
                  child: TextField(
                    controller: _nakitController,
                    onChanged: (_) => _hesapla(),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Alınan'),
                  ),
                ),
              ],
            ),
          ),
          Text('Para Üstü: ${_paraUstu >= 0 ? _paraUstu.toStringAsFixed(2) : '0.00'} TL'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: TextButton(onPressed: _printReceipt, child: const Text('Fiş Yazdır'))),
              Expanded(child: ElevatedButton(onPressed: _isLoading ? null : _odemeYap, child: const Text('Ödeme Al'))),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
} 