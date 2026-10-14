import '../domain/keuangan.dart';

/// Data demo keuangan (dipakai saat backend belum dinyalakan).
class KeuanganLokal {
  KeuanganLokal._();

  static const List<Iuran> iuran = <Iuran>[
    Iuran(periode: 'Oktober 2026', nominal: 25000, lunas: false),
    Iuran(periode: 'September 2026', nominal: 25000, lunas: true),
    Iuran(periode: 'Agustus 2026', nominal: 25000, lunas: true),
    Iuran(periode: 'Juli 2026', nominal: 25000, lunas: true),
  ];

  static const List<KasBulanan> kasBulanan = <KasBulanan>[
    KasBulanan(label: 'Jun', juta: 8.4),
    KasBulanan(label: 'Jul', juta: 11.2),
    KasBulanan(label: 'Agu', juta: 9.1),
    KasBulanan(label: 'Sep', juta: 13.6),
    KasBulanan(label: 'Okt', juta: 12.0),
  ];
}
