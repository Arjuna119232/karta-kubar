# -*- coding: utf-8 -*-
"""Generate lib/features/mitra_usaha/data/mitra_usaha_lokal.dart from
tool/data_mitra_baru.json, with hard validation.

Validation happens BEFORE writing. If any check fails the script exits 1 and
does NOT touch the Dart file. That is the point: a corrupted string inside a
data file is invisible on screen but ships in the APK.
"""
from __future__ import annotations

import json
import math
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "tool" / "data_mitra_baru.json"
DST = ROOT / "lib" / "features" / "mitra_usaha" / "data" / "mitra_usaha_lokal.dart"

KELURAHAN = {"Kuningan Barat", "Tegal Parang", "Pela Mampang", "Bangka",
             "Mampang Prapatan"}
KATEGORI = {"warungKelontong", "tokoRoti", "pasar", "spbu", "apotek"}
JAM = re.compile(r"^(24 jam|Belum dikonfirmasi|\d{2}:\d{2} - \d{2}:\d{2})$")
# Huruf yang boleh: ASCII, Latin-1/Extended (U+00C0-U+024F), dan tanda baca
# umum. Apa pun di luar itu = bukan Latin, dan `tool/check_nonlatin.py` di CI
# akan menolaknya.
NON_LATIN = re.compile(
    "[^\x00-\x7FÀ-ɏ‘’“”–—…•°]"
)

AWAL_SIMBOL = re.compile(
    r"^(?:final|const|int|double|String|bool|void|"
    r"Map<[^>\n]*>|List<[^>\n]*>|MitraUsaha\??)"
    r"\s+([a-zA-Z_][A-Za-z0-9_]*)",
    re.M,
)


def simbol_atas(isi: str) -> set[str]:
    """Nama deklarasi tingkat atas di satu berkas Dart."""
    return set(AWAL_SIMBOL.findall(isi))

# Helper = SEMUA yang ada di bawah daftar. Awalnya marker doc dipakai
# ("Jumlah mitra per kelurahan"), dan itu langsung.drop `jumlahKategori`
# karena helper itu justru letaknya satu baris LEBIH ATAS marker.
# Satu-satunya penanda yang tidak bisa meleset: baris yang sama persis
# dengan `];` menutup daftar.
helper = ""
sebelum: set[str] = set()
if DST.exists():
    isi_lama = DST.read_text(encoding="utf-8")
    sebelum = simbol_atas(isi_lama)
    penutup = re.search(r"^\];\s*$", isi_lama, re.M)
    if penutup:
        helper = isi_lama[penutup.end():].replace(
            "cukup untuk 47 data lokal", "cukup untuk daftar lokal")

errors: list[str] = []
rows = json.loads(SRC.read_text(encoding="utf-8"))

# ---------------------------------------------------------------- validasi
seen_id: dict[str, int] = {}
seen_nama: dict[str, str] = {}
titik: list[tuple[str, float, float]] = []

for i, r in enumerate(rows):
    tag = f"{r.get('id', '?')}/{r.get('nama', '?')}"
    for kunci in ("id", "nama", "kategori", "alamat", "kelurahan", "fitur",
                  "lat", "lng", "jamBuka", "perkiraan", "layanan", "info"):
        if kunci not in r:
            errors.append(f"{tag}: field '{kunci}' hilang")
    if r["id"] in seen_id:
        errors.append(f"{tag}: id dipakai ganda (baris {seen_id[r['id']]})")
    seen_id[r["id"]] = i
    kunci_nama = r["nama"].strip().lower()
    if kunci_nama in seen_nama:
        errors.append(f"{tag}: nama sama dengan {seen_nama[kunci_nama]}")
    seen_nama[kunci_nama] = r["id"]
    if r["kelurahan"] not in KELURAHAN:
        errors.append(f"{tag}: kelurahan '{r['kelurahan']}' tidak dikenal")
    for k in r["kategori"]:
        if k not in KATEGORI:
            errors.append(f"{tag}: kategori '{k}' tidak dikenal")
    if not JAM.match(r["jamBuka"]):
        errors.append(f"{tag}: jamBuka '{r['jamBuka']}' tidak sesuai pola")
    no_hp = r.get("noHp")
    if no_hp and not re.match(r"^0\d{9,12}$", no_hp):
        errors.append(f"{tag}: noHp '{no_hp}' tidak sesuai 08xx (10-13 digit)")
    if not (-6.30 < r["lat"] < -6.20 and 106.78 < r["lng"] < 106.90):
        errors.append(f"{tag}: koordinat di luar Jakarta Selatan")
    for medan in ("nama", "alamat", "fitur"):
        if NON_LATIN.search(r[medan]):
            errors.append(f"{tag}: karakter non-Latin di {medan}: "
                          f"{NON_LATIN.search(r[medan]).group(0)!r}")
    if r.get("info") and NON_LATIN.search(r["info"]):
        errors.append(f"{tag}: karakter non-Latin di info")
    if NON_LATIN.search(r["id"]):
        errors.append(f"{tag}: id mengandung karakter non-Latin")
    titik.append((r["id"], r["lat"], r["lng"]))

# dua pin di titik yang persis sama = bug yang terlihat, bukan data.
for a in range(len(titik)):
    for b in range(a + 1, len(titik)):
        d = math.dist((titik[a][1], titik[a][2]), (titik[b][1], titik[b][2]))
        if d < 0.00005:  # < 5.5 m
            errors.append(f"{titik[a][0]} dan {titik[b][0]} titiknya kembar "
                          f"({d * 111000:.1f} m)")

if errors:
    print("GAGAL validasi, berkas Dart TIDAK disentuh:")
    for e in errors:
        print("  -", e)
    sys.exit(1)

# ---------------------------------------------------------------- tulis Dart
def q(teks: str) -> str:
    return "'" + teks.replace("\\", "\\\\").replace("'", "\\'") + "'"


baris = [
    "import '../../../shared/models/order.dart';",
    "import '../domain/mitra_usaha.dart';",
    "",
    "/// %d mitra usaha di Kecamatan Mampang Prapatan." % len(rows),
    "///",
    "/// Dua sumber koordinat, dan aplikasi menampilkan bedanya:",
    "///",
    "/// - `titikPerkiraan: false` = koordinat persis dari OpenStreetMap",
    "///   (node/way amenity & shop), diambil langsung dari data OSM.",
    "/// - `titikPerkiraan: true` = titik atau alamat masih perkiraan.",
    "///   Alamatnya benar, titik pintunya belum. Jangan dua-duanya",
    "///   dicampur tanpa penjelasan.",
    "///",
    "/// Jam buka hanya dipakai kalau sumbernya menuliskannya (tag",
    "/// `opening_hours` di OSM). Yang tidak tertulis diberi label",
    "/// 'Belum dikonfirmasi', BUKAN jam karangan.",
    "///",
    "/// No HP sama-sama hanya dari sumber (tag phone), divalidasi pola 08xx.",
    "/// Kalau tidak ada, null dan tombol telepon disembunyikan oleh UI.",
    "///",
    "/// Daftar ini sengaja bukan `const`: `Kelurahan.dari(...)` memanggil",
    "/// `firstWhere`, dan fungsi tidak boleh dipanggil dalam ekspresi const.",
    "final List<MitraUsaha> daftarMitraUsaha = <MitraUsaha>[",
]
for r in rows:
    kat = ", ".join(f"KategoriMitraUsaha.{k}" for k in r["kategori"])
    baris += [
        "  MitraUsaha(",
        f"    id: {q(r['id'])},",
        f"    nama: {q(r['nama'])},",
        f"    kategori: <KategoriMitraUsaha>[{kat}],",
        f"    alamat: {q(r['alamat'])},",
        f"    kelurahan: Kelurahan.dari({q(r['kelurahan'])}),",
        f"    fitur: {q(r['fitur'])},",
        f"    titik: TitikPeta(lat: {r['lat']:.6f}, lng: {r['lng']:.6f}),",
        f"    jamBuka: {q(r['jamBuka'])},",
        f"    titikPerkiraan: {str(r['perkiraan']).lower()},",
        "    layanan: const <String>[" + ", ".join(q(x) for x in r["layanan"]) + "],",
    ]
    if r.get("info"):
        baris.append(f"    info: {q(r['info'])},")
    if r.get("noHp"):
        baris.append(f"    noHp: {q(r['noHp'])},")
    baris.append("  ),")
baris += ["];", ""]

# Helper di ekor file (jumlahKategori, jumlahKelurahan, mitraUsahaById,
# saringMitraUsaha, mitraTerdekat, produkUmum) dipakai layar lain. Kalau
# generator hanya menulis daftar, helper ikut hilang dan build breakage jauh
# dari sumber. Jadi: ambil lagi dari file yang sekarang di disk SEBELUM
# menimpanya.
isi_baru = "\n".join(baris)
if helper:
    isi_baru += "\n" + helper

# SEMUA pemeriksaan dilakukan di ISI BARU, sebelum menyentuh disk. Versi
# sebelumnya menulis dulu baru memeriksa, jadi berkas rusak ikut tertinggal
# di disk walaupun skrip exit 1.
nulis = len(re.findall(r"^  MitraUsaha\($", isi_baru, re.M))
if nulis != len(rows):
    print(f"GAGAL: isi baru punya {nulis} entri, JSON punya {len(rows)}")
    sys.exit(1)
for simbol in ("jumlahKategori", "jumlahKelurahan", "mitraUsahaById",
               "saringMitraUsaha", "mitraTerdekat", "produkUmum"):
    if f"{simbol}(" not in isi_baru:
        print(f"GAGAL: helper '{simbol}' hilang dari isi baru")
        sys.exit(1)

# Tidak boleh ada deklarasi tingkat atas yang HILANG. Ini penjaga yang
# menangkap `jumlahKategori`: helper itu dipakai 2 layar, jadi kalau hilang
# build rusak jauh dari sumber (masalah muncul di berkas lain).
hilang = sorted(sebelum - simbol_atas(isi_baru))
if hilang:
    print(f"GAGAL: deklarasi ini hilang setelah generate: {', '.join(hilang)}")
    sys.exit(1)

DST.write_text(isi_baru, encoding="utf-8")

# Bukti tulis: skrip pernah print "OK" padahal `write_text` hilang saat
# patching, jadi berkas lama utuh. Baca balik dan bandingkan.
kembali = DST.read_text(encoding="utf-8")
if kembali != isi_baru:
    print("GAGAL: isi di disk berbeda dari isi yang baru ditulis")
    sys.exit(1)

# ---------------------------------------------------------------- laporan
pasti = sum(1 for r in rows if not r["perkiraan"])
print(f"OK  {DST.relative_to(ROOT)}")
print(f"    {len(rows)} mitra  |  koordinat persis {pasti}  |  perkiraan {len(rows)-pasti}")
jam = sum(1 for r in rows if r["jamBuka"] != "Belum dikonfirmasi")
print(f"    jam buka terkonfirmasi {jam}  |  belum dikonfirmasi {len(rows)-jam}")