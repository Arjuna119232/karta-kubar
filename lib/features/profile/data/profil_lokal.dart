import '../domain/anggota.dart';

/// Data demo profil (dipakai saat backend belum dinyalakan).
class ProfilLokal {
  ProfilLokal._();

  static const Anggota anggota = Anggota(
    nama: 'Sobat Karta',
    peran: 'pengurus',
    divisi: 'Divisi Sosial',
    nomorAnggota: 'KK-2026-0128',
    poin: 340,
    totalKegiatan: 18,
  );
}
