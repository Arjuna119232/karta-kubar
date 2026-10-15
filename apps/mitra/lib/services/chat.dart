import '../models/models.dart';

/// Jenis isi pesan.
enum JenisPesan { teks, foto, lokasi }

extension JenisPesanX on JenisPesan {
  String get label => switch (this) {
        JenisPesan.teks => 'teks',
        JenisPesan.foto => 'foto',
        JenisPesan.lokasi => 'lokasi',
      };

  static JenisPesan dari(String? v) => switch (v) {
        'foto' => JenisPesan.foto,
        'lokasi' => JenisPesan.lokasi,
        _ => JenisPesan.teks,
      };
}

class Pesan {
  Pesan({
    required this.id,
    required this.orderId,
    required this.isi,
    required this.waktu,
    required this.mine,
    this.jenis = JenisPesan.teks,
    this.attachmentUrl,
    this.lat,
    this.lng,
    this.dibaca = false,
    this.balasId,
    this.balasRingkas,
  });

  final String id;
  final String orderId;
  final String isi;
  final DateTime waktu;

  /// true = dikirim oleh mitra (bubble kanan).
  final bool mine;
  final JenisPesan jenis;

  /// Path foto lokal (mode demo) atau URL storage (mode Supabase).
  final String? attachmentUrl;
  final double? lat;
  final double? lng;

  /// Hanya relevan untuk pesan milik mitra: sudah dibaca warga atau belum.
  final bool dibaca;

  /// Balasan singkat dari pesan yang dibalas.
  final String? balasId;
  final String? balasRingkas;

  bool get terkirim => true;

  Map<String, dynamic> toMap() => {
        'id': id,
        'order_id': orderId,
        'body': isi,
        'jenis': jenis.name,
        'attachment_url': attachmentUrl,
        'lat': lat,
        'lng': lng,
        'is_read': dibaca,
        'balas_id': balasId,
        'balas_ringkas': balasRingkas,
        'mine': mine,
        'created_at': waktu.toIso8601String(),
      };

  static Pesan fromSupabase(Map<String, dynamic> m, String uid) => Pesan(
        id: '${m['id']}',
        orderId: '${m['order_id']}',
        isi: (m['body'] ?? '') as String,
        jenis: JenisPesanX.dari(m['jenis'] as String?),
        attachmentUrl: m['attachment_url'] as String?,
        lat: (m['lat'] as num?)?.toDouble(),
        lng: (m['lng'] as num?)?.toDouble(),
        dibaca: (m['is_read'] as bool?) ?? false,
        balasId: m['balas_id'] as String?,
        balasRingkas: m['balas_ringkas'] as String?,
        waktu: DateTime.tryParse('${m['created_at']}') ?? DateTime.now(),
        mine: '${m['sender_id']}' == uid,
      );
}

/// Template pesan cepat (bisa diganti sendiri nanti).
const templateCepat = <String, String>{
  'OTW': 'Saya sedang OTW kak',
  'Sudah di lokasi': 'Saya sudah sampai di lokasi',
  'Tunggu sebentar': 'Mohon tunggu sebentar ya',
  'Sudah diterima': 'Barang sudah saya terima kak',
  'Terima kasih': 'Terima kasih banyak kak',
};

List<String> get daftarTemplateCepat =>
    templateCepat.keys.where((k) => (templateCepat[k] ?? '').isNotEmpty).toList();

/// Filter daftar chat.
enum FilterChat { semua, belumDibaca, orderAktif, selesai }

extension FilterChatX on FilterChat {
  String get label => switch (this) {
        FilterChat.semua => 'Semua',
        FilterChat.belumDibaca => 'Belum dibaca',
        FilterChat.orderAktif => 'Order aktif',
        FilterChat.selesai => 'Selesai',
      };
}

/// Satu baris di daftar chat.
class BarisChat {
  const BarisChat({
    required this.order,
    required this.jumlahPesan,
    required this.belumDibaca,
    required this.terakhir,
    required this.online,
    required this.diarsipkan,
  });

  final Order order;
  final int jumlahPesan;
  final int belumDibaca;
  final Pesan? terakhir;
  final bool online;
  final bool diarsipkan;
}