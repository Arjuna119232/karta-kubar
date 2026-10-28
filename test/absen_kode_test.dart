import 'package:flutter_test/flutter_test.dart';
import 'package:kubar_connect/features/absen/data/absen_state.dart';
import 'package:kubar_connect/features/kegiatan/domain/kegiatan.dart';

void main() {
  group('absenPayload', () {
    test('membuat payload yang bisa dibaca kembali', () {
      final Kegiatan a = Kegiatan(
        judul: 'Kerja Bakti RW 05',
        kategori: 'Sosial',
        tanggal: DateTime(2026, 3, 7),
        lokasi: 'Balai RW 05',
        mendatang: false,
      );

      final AbsenKode? kode = bacaAbsenKode(absenPayload(a));

      expect(kode, isNotNull);
      expect(kode!.judul, 'Kerja Bakti RW 05');
      expect(kode.tanggal, DateTime(2026, 3, 7));
    });

    test('judul berisi garis miring tetap utuh', () {
      final Kegiatan a = Kegiatan(
        judul: 'Rapat A/B',
        kategori: 'Rapat',
        tanggal: DateTime(2026, 1, 2),
        lokasi: 'Sekretariat',
        mendatang: false,
      );

      expect(bacaAbsenKode(absenPayload(a))?.judul, 'Rapat A/B');
    });

    test('kegiatan tanpa tanggal tetap bisa dibuatkan QR', () {
      const Kegiatan a = Kegiatan(
        judul: 'Kerja Bakti',
        kategori: 'Sosial',
        tanggal: null,
        lokasi: 'Balai RW 05',
        mendatang: true,
      );

      final AbsenKode? kode = bacaAbsenKode(absenPayload(a));

      expect(kode, isNotNull);
      expect(kode!.judul, 'Kerja Bakti');
      expect(kode.tanggal, isNull);
    });
  });

  group('bacaAbsenKode', () {
    test('menolak teks yang bukan QR absen', () {
      expect(bacaAbsenKode('https://kubar.id'), isNull);
      expect(bacaAbsenKode('karta-kubar://absen/'), isNull);
      expect(bacaAbsenKode(''), isNull);
    });

    test('menolak QR tanpa judul', () {
      expect(bacaAbsenKode('karta-kubar://absen/20260307'), isNull);
      expect(bacaAbsenKode('karta-kubar://absen/20260307/'), isNull);
      expect(bacaAbsenKode('karta-kubar://absen/20260307/%20%20'), isNull);
    });

    test('tanggal rusak tidak membatalkan absensi', () {
      // 31 Februari bergulir jadi 3 Maret di DateTime — harus ditolak sebagai
      // tanggal, tapi judulnya tetap dipakai supaya absen tidak gagal.
      final AbsenKode? kode = bacaAbsenKode('karta-kubar://absen/20260231/Halusinasi');
      expect(kode, isNotNull);
      expect(kode!.judul, 'Halusinasi');
      expect(kode.tanggal, isNull);
    });

    test('tanggal tidak lengkap jadi null, judul tetap ada', () {
      final AbsenKode? kode = bacaAbsenKode('karta-kubar://absen/2026/Senam');
      expect(kode, isNotNull);
      expect(kode!.judul, 'Senam');
      expect(kode.tanggal, isNull);
    });

    test('spasi di ujung judul dipangkas', () {
      expect(
        bacaAbsenKode('karta-kubar://absen/20260307/%20Kerja%20Bakti%20')?.judul,
        'Kerja Bakti',
      );
    });
  });
}
