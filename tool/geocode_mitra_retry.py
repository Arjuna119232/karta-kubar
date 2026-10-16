import json, math, time, urllib.parse, urllib.request

UA = "KUNBARConnect/0.14.4 (patch koordinat mitra usaha)"
J = json.load(open("/data/data/com.termux/files/usr/tmp/zyvo/geocode_mitra.json"))
CENTROID = J["centroid"]

def jarak(a, b, c, d):
    R = 6371000.0
    p1, p2 = math.radians(a), math.radians(c)
    dp, dl = math.radians(c-a), math.radians(d-b)
    x = math.sin(dp/2)**2 + math.cos(p1)*math.cos(p2)*math.sin(dl/2)**2
    return 2*R*math.asin(math.sqrt(x))

# Varian ejaan -> Nominatim Indonesia sering pakai "Jalan ..." bukan "Jl. ...".
VARIAN = {
    "m3":  ["Jalan Kuningan Barat III, Jakarta Selatan", "Kuningan Barat III, Kebayoran Baru, Jakarta"],
    "m4":  ["Jalan Terusan H.R. Rasuna Said, Jakarta Selatan", "Terusan Rasuna Said, Kebayoran Baru, Jakarta"],
    "m7":  ["Jalan Tegal Parang Selatan I, Jakarta Selatan", "Tegal Parang Selatan Satu, Tebet, Jakarta"],
    "m8":  ["Jalan Tegal Parang Utara V, Jakarta Selatan", "Tegal Parang Utara Lima, Tebet, Jakarta"],
    "m18": ["Jalan Mampang Prapatan Raya, Tebet, Jakarta Selatan", "Mampang Prapatan Raya, Jakarta"],
    "m24": ["Pasar Rengas, Jakarta Selatan", "Rawa Barat, Jakarta Selatan"],
    "m32": ["Jalan Mampang Prapatan Raya, Tebet, Jakarta", "Mampang Prapatan, Jakarta Selatan"],
    "m33": ["Jalan Mampang Prapatan XV, Jakarta Selatan", "Mampang Prapatan XV, Tebet, Jakarta"],
    "m36": ["Jalan Tegal Parang Utara III, Jakarta Selatan", "Tegal Parang Utara Tiga, Tebet, Jakarta"],
    "m37": ["Jalan Mampang Prapatan XI, Jakarta Selatan", "Mampang Prapatan Sebelas, Tebet, Jakarta"],
    "m38": ["Jalan Tegal Parang Selatan I, Jakarta Selatan", "Tegal Parang Selatan Satu, Tebet, Jakarta"],
    "m42": ["Jalan Bangka IX, Pela Mampang, Jakarta Selatan", "Bangka IX, Jakarta Selatan"],
    "m43": ["Jalan Bangka VIII, Pela Mampang, Jakarta Selatan", "Bangka VIII, Jakarta Selatan"],
    "m44": ["Jalan Kemang Utara I, Bangka, Jakarta Selatan", "Kemang Utara I, Jakarta Selatan"],
}
KEL = {"m3":"Kuningan Barat","m4":"Kuningan Barat","m7":"Tegal Parang","m8":"Tegal Parang",
       "m18":"Mampang Prapatan","m24":"Kuningan Barat","m32":"Mampang Prapatan","m33":"Mampang Prapatan",
       "m36":"Tegal Parang","m37":"Tegal Parang","m38":"Tegal Parang","m42":"Pela Mampang",
       "m43":"Pela Mambang_PLACEHOLDER" if False else "Pela Mampang","m44":"Bangka"}
BAWAH = {"m4":1800,"m24":3500}   #-known di luar borough -> radius longgar khusus

hasil = J["hasil"]
for mid, qs in VARIAN.items():
    kel = KEL[mid]
    clat, clon = CENTROID[kel]
    pad = 0.010
    vb = f"{clon-pad},{clat+pad},{clon+pad},{clat-pad}"
    batas = BAWAH.get(mid, 700)
    terbaik = None
    for q in qs:
        url = ("https://nominatim.openstreetmap.org/search?format=jsonv2&limit=5&countrycodes=id"
               f"&viewbox={vb}&bounded=1&q=" + urllib.parse.quote(q))
        try:
            req = urllib.request.Request(url, headers={"User-Agent": UA})
            with urllib.request.urlopen(req, timeout=25) as r:
                data = json.loads(r.read().decode())
        except Exception as e:
            print(f"{mid:4} GAGAL {q[:40]}: {e}"); time.sleep(1.3); continue
        for d in data:
            la, lo = float(d["lat"]), float(d["lon"])
            dj = jarak(la, lo, clat, clon)
            if dj <= batas and (terbaik is None or dj < terbaik[2]):
                terbaik = (la, lo, dj, d["type"], d["display_name"][:70])
        if terbaik: break
        time.sleep(1.3)
    if terbaik:
        print(f"{mid:4} COCOK {terbaik[0]:.6f}, {terbaik[1]:.6f}  {terbaik[3]:18} {terbaik[2]:5.0f} m  <- {terbaik[4][:50]}")
        hasil[mid] = {"lat": terbaik[0], "lng": terbaik[1], "jarak_m": round(terbaik[2]), "tipe": terbaik[3], "label": terbaik[4]}
    else:
        print(f"{mid:4} TOLAK  semua varian (>{batas} m dari {kel})")
        hasil[mid] = None
    time.sleep(1.3)

json.dump({"centroid": CENTROID, "hasil": hasil}, open("/data/data/com.termux/files/usr/tmp/zyvo/geocode_mitra.json","w"), indent=1)
