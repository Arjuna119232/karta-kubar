class Order {
  final String id, type, customerName, customerPhone, pickupAddress, dropAddress, note, status;
  final double distanceKm;
  final int fee;
  final double? pickupLat, pickupLng, dropLat, dropLng;
  final DateTime createdAt;
  final DateTime? completedAt;

  const Order({
    required this.id,
    required this.type,
    required this.customerName,
    required this.customerPhone,
    required this.pickupAddress,
    required this.dropAddress,
    required this.note,
    required this.status,
    required this.distanceKm,
    required this.fee,
    required this.createdAt,
    this.pickupLat,
    this.pickupLng,
    this.dropLat,
    this.dropLng,
    this.completedAt,
  });

  static double? _d(dynamic v) => v == null ? null : (v as num).toDouble();

  factory Order.fromMap(Map<String, dynamic> m) => Order(
        id: m['id'].toString(),
        type: (m['type'] ?? 'ojek') as String,
        customerName: (m['customer_name'] ?? 'Warga') as String,
        customerPhone: (m['customer_phone'] ?? '') as String,
        pickupAddress: (m['pickup_address'] ?? '') as String,
        dropAddress: (m['drop_address'] ?? '') as String,
        note: (m['note'] ?? '') as String,
        status: (m['status'] ?? 'pending') as String,
        distanceKm: _d(m['distance_km']) ?? 0,
        fee: ((m['fee'] ?? 0) as num).toInt(),
        pickupLat: _d(m['pickup_lat']),
        pickupLng: _d(m['pickup_lng']),
        dropLat: _d(m['drop_lat']),
        dropLng: _d(m['drop_lng']),
        createdAt: DateTime.tryParse('${m['created_at']}') ?? DateTime.now(),
        completedAt: m['completed_at'] == null ? null : DateTime.tryParse('${m['completed_at']}'),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type,
        'customer_name': customerName,
        'customer_phone': customerPhone,
        'pickup_address': pickupAddress,
        'drop_address': dropAddress,
        'note': note,
        'status': status,
        'distance_km': distanceKm,
        'fee': fee,
        'pickup_lat': pickupLat,
        'pickup_lng': pickupLng,
        'drop_lat': dropLat,
        'drop_lng': dropLng,
        'created_at': createdAt.toIso8601String(),
        'completed_at': completedAt?.toIso8601String(),
      };

  Order copyWith({String? status, DateTime? completedAt}) => Order(
        id: id,
        type: type,
        customerName: customerName,
        customerPhone: customerPhone,
        pickupAddress: pickupAddress,
        dropAddress: dropAddress,
        note: note,
        status: status ?? this.status,
        distanceKm: distanceKm,
        fee: fee,
        pickupLat: pickupLat,
        pickupLng: pickupLng,
        dropLat: dropLat,
        dropLng: dropLng,
        createdAt: createdAt,
        completedAt: completedAt ?? this.completedAt,
      );

  String get typeLabel => type == 'jastip' ? 'JASTIP' : 'OJEK';
  bool get isActive => const ['accepted', 'arrived', 'delivering'].contains(status);
  bool get isDone => status == 'done';
  DateTime get doneAt => completedAt ?? createdAt;

  String? get nextStatus => switch (status) {
        'accepted' => 'arrived',
        'arrived' => 'delivering',
        'delivering' => 'done',
        _ => null,
      };

  String get nextLabel => switch (status) {
        'accepted' => type == 'jastip' ? 'SAYA SUDAH DI TOKO' : 'SAYA SUDAH DI TITIK JEMPUT',
        'arrived' => 'MULAI ANTAR',
        'delivering' => 'SELESAI',
        _ => '',
      };

  String get statusLabel => switch (status) {
        'pending' => 'Menunggu',
        'accepted' => 'Menuju lokasi jemput',
        'arrived' => 'Sudah di lokasi jemput',
        'delivering' => 'Sedang diantar',
        'done' => 'Selesai',
        'cancelled' => 'Dibatalkan',
        _ => status,
      };

  /// Tujuan navigasi: titik jemput sebelum barang/penumpang diambil, lalu titik antar.
  (double?, double?, String) get navTarget => status == 'accepted'
      ? (pickupLat, pickupLng, pickupAddress)
      : (dropLat, dropLng, dropAddress);
}

class ChatMessage {
  final String id, senderId, body;
  final DateTime createdAt;
  final bool mine;
  const ChatMessage(this.id, this.senderId, this.body, this.createdAt, this.mine);
}

class Rating {
  final int stars;
  final String comment;
  final DateTime createdAt;
  const Rating(this.stars, this.comment, this.createdAt);
}

class WalletTx {
  final int amount;
  final String kind, note;
  final DateTime createdAt;
  const WalletTx(this.amount, this.kind, this.note, this.createdAt);
}

/// Permintaan tarik saldo. Statusnya diputuskan admin di web panel.
enum StatusWithdraw { pending, disetujui, ditolak, dibayar }

class Withdraw {
  final String id;
  final int jumlah;

  /// 'bank' atau 'ewallet'
  final String metode;

  /// Nomor rekening / nomor HP tujuan
  final String tujuan;
  final StatusWithdraw status;
  final DateTime createdAt;

  const Withdraw({
    required this.id,
    required this.jumlah,
    required this.metode,
    required this.tujuan,
    required this.status,
    required this.createdAt,
  });

  String get statusLabel => switch (status) {
        StatusWithdraw.pending => 'Menunggu diproses',
        StatusWithdraw.disetujui => 'Disetujui admin',
        StatusWithdraw.ditolak => 'Ditolak',
        StatusWithdraw.dibayar => 'Sudah dibayar',
      };

  String get metodeLabel => metode == 'bank' ? 'Transfer bank' : 'E-wallet';

  Map<String, dynamic> toMap() => {
        'id': id,
        'jumlah': jumlah,
        'metode': metode,
        'tujuan': tujuan,
        'status': status.name,
        'created_at': createdAt.toIso8601String(),
      };

  static Withdraw fromMap(Map<String, dynamic> m) => Withdraw(
        id: '${m['id']}',
        jumlah: (m['jumlah'] as num?)?.toInt() ?? 0,
        metode: (m['metode'] ?? 'bank').toString(),
        tujuan: (m['tujuan'] ?? '').toString(),
        status: StatusWithdraw.values.firstWhere(
          (s) => s.name == '${m['status']}',
          orElse: () => StatusWithdraw.pending,
        ),
        createdAt: DateTime.tryParse('${m['created_at']}') ?? DateTime.now(),
      );
}

/// Lencana gamifikasi mitra. Terbuka dihitung dari data nyata, bukan karangan.
class Lencana {
  const Lencana({
    required this.kode,
    required this.judul,
    required this.ikon,
    required this.terbuka,
    required this.jumlah,
  });

  final String kode;
  final String judul;
  final int ikon;
  final bool terbuka;
  final int jumlah;

  String get syaratTerbuka => switch (kode) {
        'order_10' => '10 order selesai',
        'order_100' => '100 order selesai',
        'rating_49' => 'rating 4.9 atau lebih',
        'rajin' => 'online 3 hari',
        'ramah' => 'balas warga 5 kali',
        'target' => 'capai target harian 1x',
        _ => '-',
      };
}
