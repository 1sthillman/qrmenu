import 'dart:async';
import 'package:adisyon_uygulamasi/main.dart';
import 'package:adisyon_uygulamasi/screens/garson/siparis_ekrani.dart';
import 'package:adisyon_uygulamasi/widgets/garson/masa_karti_widget.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:adisyon_uygulamasi/utils/theme_helpers.dart';
import 'package:hive/hive.dart';
import 'package:adisyon_uygulamasi/widgets/shared/glass_container.dart';

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
  // Segment index: 0 = all, 1-5 for id ranges
  int _selectedSegmentIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeCacheAndMasalar();
  }

  // Load cached tables then fetch fresh data
  Future<void> _initializeCacheAndMasalar() async {
    final box = Hive.box('masalarBox');
    final cached = box.get('masalar', defaultValue: []);
    if (cached is List) {
      setState(() {
        _masalar = List<Map<String, dynamic>>.from(cached);
        _isLoading = false;
      });
    }
    await _initializeMasalar();
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
        // Cache tables locally
        final box = Hive.box('masalarBox');
        box.put('masalar', _masalar);
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
            // Update cache on real-time change
            Hive.box('masalarBox').put('masalar', _masalar);
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

    // Responsive sütun sayısı: mobilde 2, onun üzerinde 5
    final crossCount = MediaQuery.of(context).size.width < 600 ? 2 : 5;
    
    // Sort tables: active first
    final sortedMasalar = List<Map<String, dynamic>>.from(_masalar)
      ..sort((a, b) {
        final aActive = a['durum'] != 'bos';
        final bActive = b['durum'] != 'bos';
        if (aActive && !bActive) return -1;
        if (!aActive && bActive) return 1;
        return (a['id'] as int).compareTo(b['id'] as int);
      });

    // Prepare status colors and presence flags
    final activeColor = _getMasaRenk('aktif');
    final hasAktif = sortedMasalar.any((m) => m['durum'] == 'aktif');
    final readyColor = _getMasaRenk('hazir');
    final hasReady = sortedMasalar.any((m) => m['durum'] == 'hazir');
    final doneColor = _getMasaRenk('servis_edildi');
    final hasDone = sortedMasalar.any((m) => m['durum'] == 'servis_edildi');

    // Filter by segment (0=all, 1-5=id ranges, 6=aktif,7=hazir,8=servis_edildi)
    List<Map<String, dynamic>> displayMasalar;
    if (_selectedSegmentIndex == 0) {
      displayMasalar = sortedMasalar;
    } else if (_selectedSegmentIndex >= 1 && _selectedSegmentIndex <= 5) {
      final lower = (_selectedSegmentIndex - 1) * 20 + 1;
      final upper = _selectedSegmentIndex * 20;
      displayMasalar = sortedMasalar.where((m) {
        final id = m['id'] as int;
        return id >= lower && id <= upper;
      }).toList();
    } else if (_selectedSegmentIndex == 6) {
      displayMasalar = sortedMasalar.where((m) => m['durum'] == 'aktif').toList();
    } else if (_selectedSegmentIndex == 7) {
      displayMasalar = sortedMasalar.where((m) => m['durum'] == 'hazir').toList();
    } else {
      displayMasalar = sortedMasalar.where((m) => m['durum'] == 'servis_edildi').toList();
    }

    // Segment labels (ranges and statuses)
    final segments = <ChoiceChip>[
      ChoiceChip(
        label: const Text('Tüm Masalar'),
        selected: _selectedSegmentIndex == 0,
        onSelected: (_) => setState(() => _selectedSegmentIndex = 0),
      ),
    ];
    // Add ID range chips
    for (var i = 1; i <= 5; i++) {
      final start = (i - 1) * 20 + 1;
      final end = i * 20;
      segments.add(ChoiceChip(
        label: Text('$start-$end'),
        selected: _selectedSegmentIndex == i,
        onSelected: (_) => setState(() => _selectedSegmentIndex = i),
      ));
    }
    // Add status chips
    segments.addAll([
      ChoiceChip(
        label: const Text('Aktif'),
        selected: _selectedSegmentIndex == 6,
        onSelected: (_) => setState(() => _selectedSegmentIndex = 6),
        backgroundColor: Colors.transparent,
        selectedColor: activeColor,
        side: BorderSide(color: hasAktif ? activeColor : context.subtleBorder()),
        labelStyle: TextStyle(
          color: _selectedSegmentIndex == 6
              ? Colors.white
              : (hasAktif ? activeColor : context.onBg(0.7)),
        ),
      ),
      ChoiceChip(
        label: const Text('Hazır'),
        selected: _selectedSegmentIndex == 7,
        onSelected: (_) => setState(() => _selectedSegmentIndex = 7),
        backgroundColor: Colors.transparent,
        selectedColor: readyColor,
        side: BorderSide(color: hasReady ? readyColor : context.subtleBorder()),
        labelStyle: TextStyle(
          color: _selectedSegmentIndex == 7
              ? Colors.white
              : (hasReady ? readyColor : context.onBg(0.7)),
        ),
      ),
      ChoiceChip(
        label: const Text('Servis Edildi'),
        selected: _selectedSegmentIndex == 8,
        onSelected: (_) => setState(() => _selectedSegmentIndex = 8),
        backgroundColor: Colors.transparent,
        selectedColor: doneColor,
        side: BorderSide(color: hasDone ? doneColor : context.subtleBorder()),
        labelStyle: TextStyle(
          color: _selectedSegmentIndex == 8
              ? Colors.white
              : (hasDone ? doneColor : context.onBg(0.7)),
        ),
      ),
    ]);

    return Column(
      children: [
        // Quick segment navigation with glass effect
        Padding(
          padding: const EdgeInsets.all(8),
          child: GlassContainer(
            borderRadius: 12,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  ...segments,
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ),
        ),
        // Table grid
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossCount,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.0,
            ),
            itemCount: displayMasalar.length,
            itemBuilder: (context, index) {
              final masa = displayMasalar[index];
              final masaNo = masa['id'] as int;
              final durum = masa['durum'] as String;
              final renk = _getMasaRenk(durum);
              return MasaKarti(
                masaNo: masaNo,
                durum: durum,
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
              );
            },
          ),
        ),
      ],
    );
  }
} 