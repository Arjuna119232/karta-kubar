import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/format.dart';
import '../core/theme.dart';
import '../state/app_state.dart';
import 'order_detail_screen.dart';
import 'widgets.dart';

/// Daftar order: yang masuk (masih bisa diambil) dan yang sedang berjalan.
class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(title: const Text('Order Saya')),
      body: s.incoming.isEmpty && s.active == null && s.history.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Belum ada order.\n\nTekan AKTIFKAN di Beranda supaya mulai '
                  'menerima order di sekitar.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (s.incoming.isNotEmpty) ...[
                  _Judul('MASUK (${s.incoming.length})', Colors.red),
                  for (final o in s.incoming)
                    OrderCard(
                      o,
                      actions: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => s.reject(o),
                              child: const Text('TOLAK'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: FilledButton(
                              onPressed: () async {
                                final err = await s.accept(o);
                                if (context.mounted && err != null) toast(context, err);
                              },
                              child: const Text('TERIMA'),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
                if (s.active != null) ...[
                  const _Judul('SEDANG BERJALAN', AppColors.primary),
                  OrderCard(
                    s.active!,
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => OrderDetailScreen(order: s.active!))),
                  ),
                ],
                if (s.history.isNotEmpty) ...[
                  _Judul('RIWAYAT (${s.history.length})', Colors.blueGrey),
                  for (final o in s.history.take(30))
                    OrderCard(
                      o,
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => OrderDetailScreen(order: o, readOnly: true))),
                    ),
                ],
                const SizedBox(height: 20),
                Center(
                  child: Text('Total penghasilan: ${rp(s.earned(s.dayStart))}',
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                ),
              ],
            ),
    );
  }
}

class _Judul extends StatelessWidget {
  const _Judul(this.teks, this.warna);
  final String teks;
  final Color warna;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 8),
        child: Text(teks,
            style: TextStyle(color: warna, fontWeight: FontWeight.w800, fontSize: 13)),
      );
}