import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/format.dart';
import '../state/app_state.dart';

/// Semua ulasan warga + sebaran rating.
class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key});
  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  int? _bintang;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final semua = s.ratings;
    final tampil = _bintang == null ? semua : semua.where((r) => r.stars == _bintang).toList();
    final sebaran = {for (var i = 1; i <= 5; i++) i: semua.where((r) => r.stars == i).length};

    return Scaffold(
      appBar: AppBar(title: const Text('Ulasan Warga')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(s.avgRating <= 0 ? '-' : s.avgRating.toStringAsFixed(1),
                      style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w800)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 1; i <= 5; i++)
                        Icon(s.avgRating >= i ? Icons.star_rounded : Icons.star_outline_rounded,
                            color: Colors.amber, size: 20),
                    ],
                  ),
                  Text('${semua.length} ulasan',
                      style: const TextStyle(fontSize: 12)),
                  const SizedBox(height: 12),
                  for (var i = 5; i >= 1; i--)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          SizedBox(width: 16, child: Text('$i')),
                          const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: semua.isEmpty
                                    ? 0
                                    : (sebaran[i] ?? 0) / semua.length,
                                minHeight: 8,
                                backgroundColor: Colors.grey.withValues(alpha: 0.18),
                                color: Colors.amber,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(width: 22, child: Text('${sebaran[i] ?? 0}')),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: const Text('Semua'),
                    selected: _bintang == null,
                    onSelected: (_) => setState(() => _bintang = null),
                  ),
                ),
                for (var i = 5; i >= 1; i--)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text('$i bintang'),
                      selected: _bintang == i,
                      onSelected: (_) => setState(() => _bintang = i),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (tampil.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: Text('Tidak ada ulasan pada filter ini')),
            )
          else
            for (final r in tampil)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(
                            radius: 18,
                            backgroundColor: Color(0xFFE8F5E9),
                            child: Icon(Icons.person, color: Color(0xFF1B5E20), size: 20),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    for (var i = 1; i <= 5; i++)
                                      Icon(
                                          i <= r.stars
                                              ? Icons.star_rounded
                                              : Icons.star_outline_rounded,
                                          size: 15,
                                          color: Colors.amber),
                                  ],
                                ),
                                Text(jam(r.createdAt),
                                    style: const TextStyle(fontSize: 11)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(r.comment),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
