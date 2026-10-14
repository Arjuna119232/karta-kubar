/// Format tanggal Bahasa Indonesia tanpa butuh inisialisasi locale.
class DateId {
  DateId._();

  static const List<String> _bulan = <String>[
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
  ];

  static const List<String> _hari = <String>[
    'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu',
  ];

  /// Tanggal lengkap, mis. "18 Okt 2026".
  ///
  /// [d] boleh null (kegiatan tanpa tanggal) -> hasil "&mdash;" supaya
  /// pemanggil tidak harus menulis cek null di setiap tempat.
  static String tanggal(DateTime? d) {
    if (d == null) return '-';
    return '${d.day} ${_bulan[d.month - 1]} ${d.year}';
  }

  static String bulanSingkat(DateTime d) => _bulan[d.month - 1];

  static String hariTanggal(DateTime? d) {
    if (d == null) return '-';
    return '${_hari[d.weekday - 1]}, ${tanggal(d)}';
  }

  static String hari(DateTime d) => _hari[d.weekday - 1];

  static String hitungMundur(DateTime? d) {
    if (d == null) return '-';
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime target = DateTime(d.year, d.month, d.day);
    final int diff = target.difference(today).inDays;
    if (diff < 0) return 'Selesai';
    if (diff == 0) return 'Hari ini';
    if (diff == 1) return 'Besok';
    return 'H-$diff';
  }

  static String greeting() {
    final int h = DateTime.now().hour;
    if (h < 11) return 'Selamat pagi';
    if (h < 15) return 'Selamat siang';
    if (h < 18) return 'Selamat sore';
    return 'Selamat malam';
  }
}
