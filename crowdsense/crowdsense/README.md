# CrowdSense Stock Intelligence

Flutter (mobile) + Laravel (cloud). Isi paket:

- `app/`  : kode Flutter (`lib/`, `test/`, `pubspec.yaml`)
- `api/`  : file tambahan untuk proyek Laravel baru (migration, model, controller, route, seeder)

## 1. Jalankan cloud (Laravel 11/12, PHP 8.2+)

```bash
composer create-project laravel/laravel crowdsense-api
cd crowdsense-api
php artisan install:api            # memasang Sanctum
cp -r ../crowdsense/api/* .        # salin overlay (timpa User.php, routes/api.php, dll.)
echo "CROWDSENSE_ADMIN_KEY=ganti-dengan-kunci-rahasia" >> .env
php artisan migrate --seed
php artisan db:seed --class=DemoReportSeeder   # opsional: data contoh
php artisan storage:link
php artisan serve --host=0.0.0.0 --port=8000
```

Catatan: `routes/api.php` dan `app/Models/User.php` bawaan Laravel akan tertimpa. Jika `bootstrap/app.php`
belum memuat `api: __DIR__.'/../routes/api.php'`, jalankan `php artisan install:api` dulu (sudah menambahkannya).

### Endpoint
| Method | Path | Fungsi |
|---|---|---|
| POST | /api/devices | daftar perangkat anonim, mengembalikan token |
| GET | /api/dashboard | aktivitas per saham (5 bucket x 2 menit) + banyak alert |
| GET | /api/stocks, /api/stocks/{code} | daftar kode saham, detail saham |
| GET | /api/topics/{id} | detail informasi, bukti, sumber |
| POST | /api/reports | kirim laporan (multipart, idempotent lewat `client_id`) |
| POST | /api/topics/{id}/sources | admin: tambah sumber resmi, status jadi terverifikasi |
| PATCH | /api/topics/{id}/status | admin: ubah status verifikasi |

Header admin: `X-Admin-Key: <CROWDSENSE_ADMIN_KEY>`.

## 2. Jalankan aplikasi Flutter

```bash
flutter create crowdsense_app --org id.ac.um --platforms android,ios
# ganti lib/, test/, pubspec.yaml dengan isi folder app/
cd crowdsense_app && flutter pub get
flutter test
flutter run --dart-define=API_URL=http://10.0.2.2:8000     # emulator Android
# HP fisik: --dart-define=API_URL=http://IP_LAPTOP:8000
```

Android (`android/app/src/main/AndroidManifest.xml`, di dalam `<manifest>` dan `<application>`):
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<application android:usesCleartextTraffic="true" ...>   <!-- hanya untuk dev (HTTP) -->
```
Dan `minSdkVersion 23` di `android/app/build.gradle` (syarat flutter_secure_storage). Untuk produksi pakai HTTPS.
iOS: tambahkan `NSPhotoLibraryUsageDescription` di `Info.plist` (untuk memilih screenshot).

## 3. Peta proses TIA -> kode

| Proses | Algoritma | File |
|---|---|---|
| 1 Kompres screenshot | JPEG/DCT | `services/image_service.dart` |
| 2 Deteksi kode saham | Aho-Corasick | `core/aho_corasick.dart` |
| 3 Laporan mirip | SimHash + Hamming | `core/simhash.dart` |
| 4 Gaya bahasa | Multinomial Naive Bayes | `core/naive_bayes.dart` |
| 5 Tren aktivitas | EWMA | `core/ewma.dart` |
| 6 Relevansi | Weighted Sum Model | `core/wsm.dart`, `state/app_state.dart` |
| 7 Top alert | Min-Heap | `core/topk.dart` |
| 8 Cache | LRU | `core/lru.dart`, `services/cache_service.dart` |
| 9 Sinkronisasi | Exponential Backoff + jitter | `core/backoff.dart`, `services/sync_queue.dart` |
| 10 Keamanan lokal | AES-256-GCM | `services/secure_store.dart` |

Sisi cloud: agregasi dan pengelompokan laporan mirip (`TopicClusterer`), hitungan aktivitas (`ActivityService`),
penyimpanan, dan status verifikasi.

## 4. Yang belum ada (jujur)
- Cek sumber resmi otomatis (IDX/OJK/situs emiten): saat ini sumber resmi ditambahkan lewat endpoint admin.
  Langkah berikutnya: job terjadwal Laravel yang mengambil pengumuman resmi lalu memanggil logika yang sama.
- Push notification alert (FCM). Alert saat ini muncul ketika dashboard dimuat atau di-refresh.
- Model Naive Bayes dilatih dari contoh kecil; perbanyak data latih agar akurat. Ambang SimHash
  (`SimHash.threshold`, `TopicClusterer::THRESHOLD`) perlu dituning dengan data nyata.
- Login pengguna: saat ini token anonim per perangkat.
- Kode belum dikompilasi atau dijalankan di lingkungan ini (tidak ada Flutter/PHP). Jalankan `flutter test` dan
  `php artisan migrate` lebih dulu untuk menangkap kesalahan kecil.
