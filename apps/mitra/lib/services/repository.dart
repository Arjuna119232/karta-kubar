import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config.dart';
import '../models/models.dart';

/// Satu pintu data. Mode demo = memori lokal; selain itu = Supabase.
class OrderRepository {
  SupabaseClient get _sb => Supabase.instance.client;
  String get uid => _sb.auth.currentUser!.id;

  // ---------- DEMO ----------
  int _n = 0;
  final List<Order> _demoPending = [];
  final List<Order> _demoHistory = [];
  Order? _demoActive;
  final _demoCtl = StreamController<List<Order>>.broadcast();
  final Map<String, List<ChatMessage>> _demoChat = {};
  final _demoChatCtl = StreamController<String>.broadcast();
  bool _demoSeeded = false;

  Order _dummy() {
    final i = _n++;
    const names = ['Bu Siti', 'Pak Andi', 'Mbak Rina', 'Mas Dedi'];
    const pick = [
      'Warung Bu Tini, Jl. Kuningan Barat 3',
      'Indomaret Mampang Prapatan',
      'Pasar Mampang',
      'Apotek K24 Kuningan'
    ];
    const drop = [
      'RT 05 RW 05 Kuningan Barat',
      'Gg. Mangga No. 7',
      'Jl. Tegal Parang Utara 12',
      'Apartemen Kuningan Place'
    ];
    return Order(
      id: 'demo-${DateTime.now().millisecondsSinceEpoch}-$i',
      type: i.isEven ? 'ojek' : 'jastip',
      customerName: names[i % 4],
      customerPhone: '081234567890',
      pickupAddress: pick[i % 4],
      dropAddress: drop[i % 4],
      note: i.isEven ? '' : 'Titip nasi goreng 2 bungkus, pedas sedang',
      status: 'pending',
      distanceKm: 1.2 + (i % 5) * 0.8,
      fee: 8000 + (i % 5) * 2500,
      pickupLat: -6.2385 + i * 0.001,
      pickupLng: 106.8280,
      dropLat: -6.2410,
      dropLng: 106.8310 + i * 0.001,
      createdAt: DateTime.now(),
    );
  }

  void _seed() {
    if (_demoSeeded) return;
    _demoSeeded = true;
    _demoPending.addAll([_dummy(), _dummy()]);
    for (var k = 0; k < 6; k++) {
      final o = _dummy().copyWith(status: 'done', completedAt: DateTime.now().subtract(Duration(hours: k * 20 + 2)));
      _demoHistory.add(o);
    }
  }

  void addDummy() {
    _seed();
    _demoPending.add(_dummy());
    _demoCtl.add(List.of(_demoPending));
  }

  // ---------- AUTH / PROFIL ----------
  Future<Map<String, dynamic>> profile() async {
    if (Config.demo) return {'role': 'mitra', 'name': 'Mitra Demo'};
    return await _sb.from('profiles').select().eq('id', uid).single();
  }

  Future<void> signOut() async {
    if (!Config.demo) await _sb.auth.signOut();
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    if (Config.demo) return;
    await _sb.from('profiles').update(data).eq('id', uid);
  }

  Future<void> setOnline(bool v) => updateProfile({'is_online': v});

  // ---------- ORDER ----------
  Stream<List<Order>> watchPending() async* {
    if (Config.demo) {
      _seed();
      yield List.of(_demoPending);
      yield* _demoCtl.stream;
    } else {
      yield* _sb
          .from('orders')
          .stream(primaryKey: ['id'])
          .eq('status', 'pending')
          .map((rows) => rows.map(Order.fromMap).toList());
    }
  }

  Future<Order?> accept(String id) async {
    if (Config.demo) {
      final i = _demoPending.indexWhere((o) => o.id == id);
      if (i < 0) return null;
      _demoActive = _demoPending.removeAt(i).copyWith(status: 'accepted');
      _demoCtl.add(List.of(_demoPending));
      return _demoActive;
    }
    final rows = await _sb
        .from('orders')
        .update({'status': 'accepted', 'mitra_id': uid})
        .eq('id', id)
        .eq('status', 'pending')
        .select();
    return rows.isEmpty ? null : Order.fromMap(rows.first);
  }

  Future<Order> updateStatus(String id, String status) async {
    if (Config.demo) {
      final o = _demoActive!.copyWith(
          status: status, completedAt: status == 'done' ? DateTime.now() : null);
      if (status == 'done') {
        _demoHistory.insert(0, o);
        _demoActive = null;
      } else {
        _demoActive = o;
      }
      return o;
    }
    final data = <String, dynamic>{'status': status};
    if (status == 'done') data['completed_at'] = DateTime.now().toUtc().toIso8601String();
    final rows = await _sb.from('orders').update(data).eq('id', id).eq('mitra_id', uid).select();
    return Order.fromMap(rows.first);
  }

  Future<Order?> activeOrder() async {
    if (Config.demo) return _demoActive;
    final rows = await _sb
        .from('orders')
        .select()
        .eq('mitra_id', uid)
        .inFilter('status', ['accepted', 'arrived', 'delivering'])
        .limit(1);
    return rows.isEmpty ? null : Order.fromMap(rows.first);
  }

  Future<List<Order>> history() async {
    if (Config.demo) {
      _seed();
      return List.of(_demoHistory);
    }
    final rows = await _sb
        .from('orders')
        .select()
        .eq('mitra_id', uid)
        .inFilter('status', ['done', 'cancelled'])
        .order('created_at', ascending: false)
        .limit(300);
    return rows.map<Order>((r) => Order.fromMap(r)).toList();
  }

  // ---------- LOKASI & SOS ----------
  Future<void> pushLocation(String orderId, double lat, double lng) async {
    if (Config.demo) return;
    await _sb.from('mitra_locations').upsert({
      'order_id': orderId,
      'mitra_id': uid,
      'lat': lat,
      'lng': lng,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<void> sendSos(double? lat, double? lng, String? orderId) async {
    if (Config.demo) return;
    await _sb.from('sos_events').insert({
      'mitra_id': uid,
      'order_id': orderId,
      'lat': lat,
      'lng': lng,
    });
  }

  // ---------- CHAT ----------
  Stream<List<ChatMessage>> messages(String orderId) async* {
    if (Config.demo) {
      List<ChatMessage> cur() => List.of(_demoChat[orderId] ?? []);
      yield cur();
      await for (final id in _demoChatCtl.stream) {
        if (id == orderId) yield cur();
      }
    } else {
      yield* _sb
          .from('messages')
          .stream(primaryKey: ['id'])
          .eq('order_id', orderId)
          .order('created_at')
          .map((rows) => rows
              .map((r) => ChatMessage(r['id'].toString(), r['sender_id'].toString(), r['body'] as String,
                  DateTime.tryParse('${r['created_at']}') ?? DateTime.now(), r['sender_id'] == uid))
              .toList());
    }
  }

  Future<void> sendMessage(String orderId, String body) async {
    if (Config.demo) {
      final l = _demoChat.putIfAbsent(orderId, () => []);
      l.add(ChatMessage('${l.length}', 'me', body, DateTime.now(), true));
      _demoChatCtl.add(orderId);
      Future.delayed(const Duration(seconds: 2), () {
        l.add(ChatMessage('${l.length}', 'warga', 'Siap, terima kasih ya 🙏', DateTime.now(), false));
        _demoChatCtl.add(orderId);
      });
      return;
    }
    await _sb.from('messages').insert({'order_id': orderId, 'sender_id': uid, 'body': body});
  }

  // ---------- RATING & DOMPET ----------
  Future<List<Rating>> ratings() async {
    if (Config.demo) {
      return [
        Rating(5, 'Cepat dan ramah!', DateTime.now().subtract(const Duration(days: 1))),
        Rating(5, 'Makasih Pak, rapi.', DateTime.now().subtract(const Duration(days: 2))),
        Rating(4, 'Agak lama tapi aman.', DateTime.now().subtract(const Duration(days: 4))),
      ];
    }
    final rows = await _sb.from('ratings').select().eq('mitra_id', uid).order('created_at', ascending: false).limit(100);
    return rows
        .map<Rating>((r) => Rating((r['stars'] as num).toInt(), (r['comment'] ?? '') as String,
            DateTime.tryParse('${r['created_at']}') ?? DateTime.now()))
        .toList();
  }

  Future<List<WalletTx>> wallet() async {
    if (Config.demo) {
      _seed();
      return _demoHistory
          .where((o) => o.isDone)
          .map((o) => WalletTx(o.fee, 'credit', 'Order ${o.typeLabel}', o.doneAt))
          .toList();
    }
    final rows = await _sb.from('wallet_tx').select().eq('mitra_id', uid).order('created_at', ascending: false).limit(200);
    return rows
        .map<WalletTx>((r) => WalletTx((r['amount'] as num).toInt(), (r['kind'] ?? '') as String,
            (r['note'] ?? '') as String, DateTime.tryParse('${r['created_at']}') ?? DateTime.now()))
        .toList();
  }
}
