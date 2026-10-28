# -*- coding: utf-8 -*-
"""Convert tool/osm_kandidat.json (hasil scrape OpenStreetMap) menjadi
tool/data_mitra_baru.json yang bisa dicerna tool/gen_mitra_usaha.py.

Prinsip kejujuran (sama dengan generator):
- Koordinat langsung dari OSM -> perkiraan = false. Konversi ini TIDAK
  menjalankan snap ke jalan; kandidat sudah dibeku di lat/lon OSM.
- jamBuka hanya dari tag opening_hours. Tidak tertulis = 'Belum
  dikonfirmasi'.
- noHp hanya dari tag phone / contact:phone, dinormalisasi +62 -> 0,
  divalidasi pola 0 + 9-12 digit. Tidak ada = tidak ditulis.
- layanan hanya dari tag fuel:* untuk SPBU. Kategori lain = [] (UI
  menyembunyikan bagian kosong).
"""
from __future__ import annotations

import json
import math
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "tool" / "osm_kandidat.json"
DST = ROOT / "tool" / "data_mitra_baru.json"

FITUR = {
    "tokoRoti": "Toko roti dan kue",
    "pasar": "Pasar tradisional",
    "spbu": "Stasiun pengisian bahan bakar umum",
    "apotek": "Apotek kebutuhan obat",
}
RANTAI = {"indomaret", "alfamart", "alfamidi", "circle k", "lawson",
          "shell select", "ranch market", "daily foodhall", "bright"}


def slug(s: str) -> str:
    s = s.lower()
    return re.sub(r"-+", "-", re.sub(r"[^a-z0-9]+", "-", s)).strip("-")


def jalan_pendek(jalan: str) -> str:
    return jalan.replace("Jalan ", "", 1)


def brand(x: dict) -> str:
    nama = (x["nama"] or "").lower()
    tags = x.get("tags", {}) or {}
    operator = str(tags.get("operator", "") or "").lower()
    if "pertamina" in operator or "pertamina" in nama or re.search(r"^[\d.]+$", nama):
        return "pertamina"
    if nama.startswith("shell"):
        return "shell"
    if "vivo" in nama:
        return "vivo"
    if nama:
        # nama bebas: identitas merek = token PERTAMA, lewati kata generik
        # ("Warung Kelontong Ayo Mudo" != merek "warung" vs "ayo").
        for kata in ("warung", "pasar", "toko"):
            if nama.startswith(kata + " "):
                nama = nama[len(kata) + 1:]
        return nama.split(" ")[0]
    return "-"


def normalisasi_no_hp(tags: dict) -> str | None:
    raw = tags.get("phone") or tags.get("contact:phone") or ""
    for part in re.split(r"[;,/]", raw):
        t = part.strip().replace("-", "").replace(" ", "")
        if t.startswith("+62"):
            t = "0" + t[3:]
        if re.match(r"^0\d{9,12}$", t):
            return t
    return None


def jam_buka(tags: dict) -> str:
    oh = (tags.get("opening_hours") or "").strip()
    if not oh:
        return "Belum dikonfirmasi"
    if "24/7" in oh:
        return "24 jam"
    m = re.match(r"^(\d{2}:\d{2})\s*-\s*(\d{2}:\d{2})$", oh)
    if m:
        return f"{m.group(1)} - {m.group(2)}"
    m = re.match(r"^Mo-Su\s+(\d{2}:\d{2})\s*-\s*(\d{2}:\d{2})$", oh)
    if m:
        return f"{m.group(1)} - {m.group(2)}"
    return "Belum dikonfirmasi"


def layanan_entri(x: dict, tags: dict) -> list[str]:
    if x["kode"] != "spbu":
        return []
    hasil: list[str] = []
    if any(k.startswith("fuel:octane") and v in ("yes", "true", "1")
           for k, v in tags.items()):
        hasil.append("Bensin")
    if tags.get("fuel:diesel") in ("yes", "true", "1"):
        hasil.append("Solar")
    if tags.get("fuel:cng") in ("yes", "true", "1"):
        hasil.append("Gas")
    return hasil


def nama_spbu(x: dict) -> str:
    nama = (x["nama"] or "").strip()
    street = jalan_pendek(x.get("jalan", "") or "") or (x.get("kel", "") or "")
    if re.match(r"^[\d.]+$", nama):
        # Kode bangunan SPBU (mis. '31.127.01') - operator tag memuat merek.
        op = str((x.get("tags", {}) or {}).get("operator", "") or "")
        merek = op.replace("PT ", "").replace("PT.", "").strip() or "Pertamina"
        return f"SPBU {merek} {nama}"
    m = re.match(r"^(Shell .+?)-\d+\s*SOUTH JKT$", nama)
    if m:
        return f"SPBU {m.group(1).strip()}"
    if nama.startswith("SPBU"):
        return nama
    if nama.lower() == "pertamina":
        return f"SPBU Pertamina {street}"
    return f"SPBU {nama}"


def fitur(x: dict) -> str:
    kode = x["kode"]
    if kode != "warungKelontong":
        return FITUR[kode]
    nama = (x["nama"] or "").lower()
    if nama in RANTAI or any(r in nama for r in RANTAI):
        return "Minimarket rantai"
    if "kitchen organic" in nama:
        return "Toko makanan organik"
    return "Warung kelontong harian"


# ------------------------------------------------------------------ main
print("baca", SRC)
kandidat: list[dict] = json.loads(SRC.read_text(encoding="utf-8"))
print(f"{len(kandidat)} kandidat dari OpenStreetMap")

# Merge entri merek sama yang beda < 35 m = toko fisik yang sama, di-
# mapping dua kali di OSM (berlaku SEMUA kategori - SPBU, minimarket, dll).
kelompok: list[tuple[dict, list[dict]]] = []
for x in kandidat:
    target = None
    for i, (dasar, anggota) in enumerate(kelompok):
        if brand(dasar) == brand(x) and math.dist(
                (dasar["lat"], dasar["lon"]),
                (x["lat"], x["lon"])) * 111000 < 35.0:
            target = i
            break
    if target is None:
        kelompok.append((x, [x]))
    else:
        kelompok[target][1].append(x)

gabungan: list[dict] = []
nb_merge = 0
for dasar, anggota in kelompok:
    if len(anggota) > 1:
        nb_merge += 1
        tags = {}
        for e in anggota:
            tags.update(e.get("tags", {}) or {})
        # SPBU dengan nama kode menang; kategori lain nama terlengkap
        # (terpanjang) menang.
        if dasar["kode"] == "spbu":
            dasar = sorted(anggota, key=lambda e: 0 if re.match(
                r"^[\d.]+$", e["nama"]) else 1)[0]
        else:
            dasar = sorted(anggota, key=lambda e: -len(e["nama"] or ""))[0]
        info = ("Dua entri OSM merek sama berjarak di bawah 35 m digabung "
                "jadi satu.")
    else:
        tags = dict(anggota[0].get("tags", {}) or {})
        info = None
    gabungan.append({**dasar, "tags": tags, "__info": info})
print(f"merge: {len(kandidat)} entri -> {len(gabungan)} toko fisik "
      f"({nb_merge} merge)")

rows: list[dict] = []
for x in gabungan:
    tags = x.get("tags", {}) or {}
    nama = nama_spbu(x) if x["kode"] == "spbu" else (x["nama"] or "").strip()
    kel = x["kel"]
    street = jalan_pendek(x.get("jalan", "") or "")
    alamat = f"Jl. {street}, Kel. {kel}" if street else f"Kel. {kel}"
    baris: dict = {
        "id": "mu-" + slug(kel) + "-" + slug(nama),
        "nama": nama,
        "kategori": [x["kode"]],
        "alamat": alamat,
        "kelurahan": kel,
        "fitur": fitur(x),
        "lat": round(float(x["lat"]), 7),
        "lng": round(float(x["lon"]), 7),
        "jamBuka": jam_buka(tags),
        "perkiraan": False,
        "layanan": layanan_entri(x, tags),
        "info": x.get("__info"),
    }
    no_hp = normalisasi_no_hp(tags)
    if no_hp:
        baris["noHp"] = no_hp
    rows.append(baris)

# ------------------------------------------------- nama ganda -> disambig
# Kelompokkan dulu (snapshot), baru ubah nama - biar tidak saling geser.
kelompok_nama: dict[str, list[dict]] = {}
for r in rows:
    kelompok_nama.setdefault(r["nama"], []).append(r)
for nama, daftar in kelompok_nama.items():
    if len(daftar) <= 1:
        continue
    per_street: dict[str, list[dict]] = {}
    for r in daftar:
        per_street.setdefault(jalan_pendek(r["alamat"].split(", ")[0]),
                              []).append(r)
    for street, anggota in per_street.items():
        if len(anggota) == 1 and len(per_street) > 1:
            anggota[0]["nama"] = f"{nama} ({street})"
        elif len(anggota) > 1:
            # beda merek-jalan ganda: nomor urut bawaan data.
            for i, r in enumerate(anggota):
                akhir = f"{street} {i + 1}" if len(per_street) > 1 else str(i + 1)
                r["nama"] = f"{nama} ({akhir})"

# ------------------------------------------------------------- id unik
terpakai: set[str] = set()
for r in rows:
    dasar = r["id"]
    if dasar in terpakai:
        n = 2
        while f"{dasar}-{n}" in terpakai:
            n += 1
        r["id"] = f"{dasar}-{n}"
    terpakai.add(r["id"])

print(f"hasil: {len(rows)} mitra")
for kategori in sorted({x["kode"] for x in kandidat}):
    n = sum(1 for r in rows if kategori in r["kategori"])
    print(f"  {kategori}: {n}")

# --------------------------------------------------------------- tulis
isi = "[\n" + ",\n".join(json.dumps(r, ensure_ascii=False) for r in rows) + "\n]"
DST.write_text(isi + "\n", encoding="utf-8")
print("tulis", DST)

# ------------------------------------------------- verifikasi sendiri
# (pelajaran .env bocor: pernyataan wajib jadi KODE yang dicek)
baca = json.loads(DST.read_text(encoding="utf-8"))
assert len(baca) == len(rows)
assert all(set(o) >= {"id", "nama", "kategori", "alamat", "kelurahan",
                      "fitur", "lat", "lng", "jamBuka", "perkiraan",
                      "layanan", "info"} for o in baca)
assert all(re.search(r"[\u4e00-\u9fff\uff01-\uff5e]", o["nama"]) is None
           for o in baca), "ada karakter non-Latin di nama"
terpakai_id = {o["id"] for o in baca}
assert len(terpakai_id) == len(rows), "id tidak unik"
terpakai_nama = {o["nama"] for o in baca}
assert len(terpakai_nama) == len(rows), "nama tetap ada yang ganda"
print("verifikasi: semua lolos, id & nama unik, 12 kunci lengkap")
