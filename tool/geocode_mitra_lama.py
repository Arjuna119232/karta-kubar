import json, math, time, urllib.parse, urllib.request

UA = "KUNBARConnect/0.14.4 (patch koordinat mitra usaha)"
BASE = "https://nominatim.openstreetmap.org/search?format=jsonv2&limit=3&countrycodes=id&q="

# Sentroid kelurahan dihitung dari 41 titik ASLI milik warga (batch baru).
AUTHORITATIVE = {
    "Kuningan Barat": [(-6.236688,106.819702),(-6.236920,106.818810),(-6.235980,106.817540),(-6.2391,106.8225)],
    "Mampang Prapatan": [(-6.236109,106.824982),(-6.237248,106.826042),(-6.238120,106.825100),
                          (-6.2410,106.8242),(-6.2425,106.8251),(-6.2423,106.8250)],
    "Tegal Parang": [(-6.241538,106.827368),(-6.242852,106.822201),(-6.240510,106.831200),(-6.243110,106.828940),
                     (-6.245210,106.830110),(-6.240180,106.826850),(-6.249215,106.828514),(-6.2458,106.8315),
                     (-6.2452,106.8298),(-6.2415,106.8282),(-6.2482,106.8331),(-6.2451,106.8309),
                     (-6.2415,106.8339),(-6.2443,106.8318)],
    "Pela Mampang": [(-6.245100,106.821100),(-6.246830,106.819210),(-6.241105,106.814521),(-6.242900,106.816800),
                     (-6.243300,106.817200),(-6.242500,106.816100),(-6.243800,106.817900),(-6.246100,106.822500),
                     (-6.2471,106.8219),(-6.2412,106.8175),(-6.2413,106.8174),(-6.2418,106.8179),
                     (-6.2457,106.8188),(-6.2482,106.8208)],
    "Bangka": [(-6.2526,106.8282),(-6.2519,106.8214)],
}
CENTROID = {k: (sum(p[0] for p in v)/len(v), sum(p[1] for p in v)/len(v)) for k, v in AUTHORITATIVE.items()}

def jarak(lat1, lon1, lat2, lon2):
    R = 6371000.0
    p1, p2 = math.radians(lat1), math.radians(lat2)
    dp, dl = math.radians(lat2-lat1), math.radians(lon2-lon1)
    a = math.sin(dp/2)**2 + math.cos(p1)*math.cos(p2)*math.sin(dl/2)**2
    return 2*R*math.asin(math.sqrt(a))

# 19 entri lama yang TIDAK ada di data baru -> coba cari koordinat asli jalannya.
TANYA = [
    ("m3",  "Kuningan Barat",    "Jl. Kuningan Barat III, Kebayoran Baru, Jakarta Selatan"),
    ("m4",  "Kuningan Barat",    "Jalan Terusan H.R. Rasuna Said, Kebayoran Baru, Jakarta Selatan"),
    ("m7",  "Tegal Parang",      "Jl. Tegal Parang Selatan I, Jakarta Selatan"),
    ("m8",  "Tegal Parang",      "Jl. Tegal Parang Utara V, Jakarta Selatan"),
    ("m18", "Mampang Prapatan",  "Jl. Mampang Prapatan Raya, Jakarta Selatan"),
    ("m24", "Kuningan Barat",    "Pasar Rengas, Rawa Barat, Jakarta Selatan"),
    ("m26", "Kuningan Barat",    "Jl. Kuningan Barat Raya, Jakarta Selatan"),
    ("m27", "Kuningan Barat",    "Jl. Kuningan Barat Raya, Jakarta Selatan"),
    ("m29", "Pela Mampang",      "Jl. Bangka IV, Pela Mampang, Jakarta Selatan"),
    ("m30", "Bangka",            "Jl. Kemang Utara, Bangka, Jakarta Selatan"),
    ("m32", "Mampang Prapatan",  "Jl. Mampang Prapatan Raya No. 58, Jakarta Selatan"),
    ("m33", "Mampang Prapatan",  "Jl. Mampang Prapatan XV, Jakarta Selatan"),
    ("m36", "Tegal Parang",      "Jl. Tegal Parang Utara III, Jakarta Selatan"),
    ("m37", "Tegal Parang",      "Jl. Mampang Prapatan XI, Jakarta Selatan"),
    ("m38", "Tegal Parang",      "Jl. Tegal Parang Selatan I, Jakarta Selatan"),
    ("m41", "Pela Mampang",      "Jl. Bangka II, Pela Mampang, Jakarta Selatan"),
    ("m42", "Pela Mampang",      "Jl. Bangka IX, Pela Mampang, Jakarta Selatan"),
    ("m43", "Pela Mampang",      "Jl. Bangka VIII, Pela Mampang, Jakarta Selatan"),
    ("m44", "Bangka",            "Jl. Kemang Utara I, Bangka, Jakarta Selatan"),
]

hasil = {}
for mid, kel, q in TANYA:
    url = BASE + urllib.parse.quote(q)
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    try:
        with urllib.request.urlopen(req, timeout=25) as r:
            data = json.loads(r.read().decode())
    except Exception as e:
        print(f"{mid:4} GAGAL  {q[:45]:47} {e}")
        hasil[mid] = None
        time.sleep(1.2); continue
    clat, clon = CENTROID[kel]
    terbaik = None
    for d in data:
        la, lo = float(d["lat"]), float(d["lon"])
        djar = jarak(la, lo, clat, clon)
        if -6.35 < la < -6.15 and 106.70 < lo < 106.95 and (terbaik is None or djar < terbaik[1]):
            terbaik = (la, lo, djar, d["type"])
    if terbaik:
        print(f"{mid:4} COCOK  {terbaik[0]:.6f}, {terbaik[1]:.6f}  {terbaik[3]:18} {terbaik[2]*1000:5.0f} m dari {kel}")
        hasil[mid] = {"lat": terbaik[0], "lng": terbaik[1], "jarak_m": round(terbaik[2]), "tipe": terbaik[3],
                      "label": data[0]["display_name"][:80]}
    else:
        print(f"{mid:4} TOLAK  {q[:45]:47} (di luar batas / jauh dari {kel})")
        hasil[mid] = None
    time.sleep(1.2)

json.dump({"centroid": CENTROID, "hasil": hasil}, open("/data/data/com.termux/files/usr/tmp/zyvo/geocode_mitra.json", "w"), indent=1)
print("\n=== CENTROID KELURAHAN (dari 41 titik asli warga) ===")
for k, (a, b) in CENTROID.items():
    print(f"{k:20} {a:.6f}, {b:.6f}")
