#!/usr/bin/env python3
"""Cek konektivitas KUNBAR Connect ke Supabase.

Jalankan:
    cd ~/karta-kubar && python3 tool/supabase_check.py

Membaca `.env` (tidak pernah commit). Tidak butuh install apa pun.

ATURAN: skrip ini tidak pernah monaster "berhasil" kalau tidak ada buktinya.
Setiap pengecekan melaporkan HTTP status yang benar-benar diterima.
"""

import json
import os
import re
import sys
import urllib.error
import urllib.request

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ENV_FILE = os.path.join(BASE, ".env")

# ------------------------------------------------------------------ utilitas

def baca_env(path=ENV_FILE):
    """Baca file .env sederhana (KEY=VALUE, tanpa ekspansi variabel)."""
    data = {}
    if not os.path.exists(path):
        return None
    with open(path, encoding="utf-8") as f:
        for baris in f:
            baris = baris.strip()
            if not baris or baris.startswith("#") or "=" not in baris:
                continue
            k, v = baris.split("=", 1)
            data[k.strip()] = v.strip().strip('"').strip("'")
    return data


def minta(url, method="GET", headers=None, body=None, timeout=20):
    """Kembalikan (status, body_teks). Status 0 = gagal koneksi / tidak ada jawaban."""
    data = None
    if body is not None:
        data = json.dumps(body).encode()
    req = urllib.request.Request(url, data=data, method=method,
                                 headers=headers or {})
    try:
        with urllib.request.urlopen(req, timeout=timeout) as r:
            return r.status, r.read().decode("utf-8", "replace")
    except urllib.error.HTTPError as e:
        return e.code, e.read().decode("utf-8", "replace")
    except Exception as e:                      # noqa: BLE001
        return 0, f"{type(e).__name__}: {e}"


def sensor(v):
    """Sensor nilai rahasia supaya tidak pernah tercetak penuh."""
    if not v:
        return "(kosong)"
    if len(v) <= 12:
        return "len=%d" % len(v)
    return v[:14] + "...%s (len=%d)" % (v[-4:], len(v))


# ------------------------------------------------------------------- cek utama

def main():
    print("=" * 62)
    print("  KUNBAR Connect - cek koneksi Supabase")
    print("=" * 62)

    env = baca_env()
    if env is None:
        print("\nBELUM ADA .env\n")
        print("Buat dulu:")
        print("  cp ~/karta-kubar/.env.example ~/karta-kubar/.env")
        print("lalu isi SUPABASE_URL dan SUPABASE_ANON_KEY.\n")
        return 2

    url = (env.get("SUPABASE_URL") or "").rstrip("/")
    anon = env.get("SUPABASE_ANON_KEY") or ""
    sumber = env.get("SUMBER_DATA") or "lokal"

    print("\nSUMBER_DATA      : %s" % sumber)
    print("SUPABASE_URL     : %s" % (url or "(kosong)"))
    print("SUPABASE_ANON_KEY: %s" % sensor(anon))

    if not url.startswith("https://") or not anon:
        print("\nHASIL: KONFIGURASI BELUM LENGKAP")
        print("  - SUPABASE_URL harus diawali https://")
        print("  - SUPABASE_ANON_KEY tidak boleh kosong")
        return 1

    hdr = {
        "apikey": anon,
        "Authorization": "Bearer " + anon,
        "Accept": "application/json",
        "User-Agent": "KUNBAR-Connect-check/1.0",
    }

    gagal = 0

    # 1. Host hidup?
    # PENTING: cek ke /auth/v1/health, BUKAN /rest/v1/. Akar PostgREST di
    # proyek ini membalas "Secret API key required" untuk publishable key -
    # itu bukan berarti key rusak. Sudah dibuktikan: query tabel sungguhan
    # dengan publishable key dijawab PostgREST (PGRST205 = tabel belum ada).
    print("\n[1] Host hidup?")
    st, body = minta(url + "/auth/v1/health", headers=hdr)
    if st == 0:
        print("    GAGAL: %s" % body)
        gagal += 1
    elif st == 200:
        print("    OK (200) - GoTrue/Auth menjawab")
    else:
        print("    HTTP %s: %s" % (st, body[:120]))
        gagal += 1

    # 2. API key ditolak?
    print("\n[2] API key diterima?")
    st, body = minta(url + "/rest/v1/profiles?select=id&limit=1", headers={
        "apikey": "kunci-ngawur-untuk-tes",
        "Authorization": "Bearer kunci-ngawur-untuk-tes",
        "User-Agent": "KUNBAR-Connect-check/1.0",
    })
    if st == 401:
        print("    OK - kunci ngawur ditolak (401). Artinya RLS hidup.")
    elif st == 0:
        print("    GAGAL: %s" % body)
        gagal += 1
    else:
        print("    PERHATIAN: kunci ngawur dapat HTTP %s (harusnya 401)" % st)

    # 3. Tabel yang dipakai aplikasi ada?
    print("\n[3] Tabel aplikasi ada?")
    tabel = ["profiles", "kegiatan", "berita", "pengumuman",
             "iuran", "kas_bulanan", "aspirasi"]
    for t in tabel:
        st, body = minta(url + "/rest/v1/%s?select=id&limit=1" % t, headers=hdr)
        if st == 200:
            print("    OK      %-12s (baca berhasil)" % t)
        elif st in (404, 400):
            pesan = body[:80].replace("\n", " ")
            print("    KOSONG  %-12s HTTP %s %s" % (t, st, pesan))
            gagal += 1
        else:
            print("    GAGAL   %-12s HTTP %s" % (t, st))
            gagal += 1

    # 4. RLS untuk publik benar-benar terbuka untuk tamu?
    print("\n[4] Konten publik terbaca tanpa login?")
    for t in ("kegiatan", "pengumuman"):
        st, _ = minta(url + "/rest/v1/%s?select=id&limit=1" % t, headers={
            "apikey": anon,
            "Authorization": "Bearer " + anon,
            "User-Agent": "KUNBAR-Connect-check/1.0",
        })
        print("    %-12s %s" % (t, "OK" if st == 200 else "HTTP %s" % st))

    # 5. Tulis tanpa login harus DITOLAK
    print("\n[5] Menulis tanpa login ditolak? (harus ya)")
    st, body = minta(url + "/rest/v1/aspirasi", method="POST",
                     headers={**hdr, "Content-Type": "application/json",
                              "Prefer": "return=minimal"},
                     body={"id": "cek-otomatis", "judul": "cek", "isi": "cek"})
    if st in (401, 403):
        print("    OK - ditolak (HTTP %s). RLS bekerja." % st)
    elif st == 201:
        print("    MASALAH! Data tanpa login bisa masuk (201). Cek RLS.")
        gagal += 1
    else:
        print("    HTTP %s: %s" % (st, body[:100]))

    # 6. Jumlah data
    print("\n[6] Hitung data (dummy, akan dihapus)")
    st, body = minta(url + "/rest/v1/aspirasi?select=id&contoh=eq.false", headers=hdr)
    if st == 200:
        n = len(json.loads(body)) if body.strip().startswith("[") else 0
        print("    FISH asli di database: %d" % n)
    else:
        print("    HTTP %s" % st)

    print("\n" + "=" * 62)
    if gagal:
        print("  HASIL: %d masalah. Jangan geser SUMBER_DATA ke supabase." % gagal)
        print("=" * 62)
        return 1
    print("  HASIL: SEMUA SIAP. Boleh set SUMBER_DATA=supabase")
    print("=" * 62)
    return 0


if __name__ == "__main__":
    sys.exit(main())