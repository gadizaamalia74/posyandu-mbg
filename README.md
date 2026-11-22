# Posyandu MBG

Pembuatan ulang sistem Posyandu Flamboyan VI dengan Flutter.

- **Data**: database lama `posyandu_flamboyan` (MySQL) — lihat `database/schema.sql`
- **Tampilan**: meniru UI PHP di `posyandu (2)` (navy `#0d2d4a`, font Plus Jakarta Sans, topbar + navbar + sidebar)
- **Backend**: REST API Dart (`shelf`) di `backend/`, pengganti halaman PHP
- **Aplikasi**: Flutter di `app/` (Android / iOS / web / desktop)

```
posyandu_mbg/
├── database/schema.sql   # skema + data awal
├── backend/              # API Dart (port 8080)
└── app/                  # aplikasi Flutter
```

## Menjalankan

### 1. Database
Pastikan MySQL/MariaDB (mis. XAMPP) berjalan, lalu:
```
mysql -u root < database/schema.sql
```
Jika database lama (`posyandu_flamboyan`) sudah berisi data asli, **jangan** import file ini
apa adanya — cukup jalankan bagian `CREATE TABLE ... ibu_balita / ibu_anak /
konfirmasi_kehadiran / laporan_kondisi` bila tabel itu belum ada.

### 2. Backend
```
cd backend
dart pub get
dart run bin/server.dart
```
Konfigurasi DB lewat environment variable (default: root tanpa password, 127.0.0.1:3306):
`DB_HOST`, `DB_PORT`, `DB_USER`, `DB_PASS`, `DB_NAME`, dan `PORT` (default 8080).

### 3. Aplikasi
```
cd app
flutter pub get
flutter run
```
Alamat server default `http://10.0.2.2:8080` (emulator Android). Untuk HP asli / web / desktop,
ketuk **"Atur alamat server"** di layar login (mis. `http://192.168.1.10:8080`).

## Akun awal (password: `password`)
| Peran | Login |
|---|---|
| Admin | NK `ADMIN001` |
| Kader | NK `11080924` |
| Ibu balita | daftar sendiri dari layar login → tab "Ibu Balita" → "Daftar di sini" (pakai kode anak, mis. `01120324`) |

## Fitur (setara PHP lama)
- **Admin/Kader**: dashboard, jadwal (kalender mini; tambah/hapus khusus admin), penimbangan (CRUD + status gizi), imunisasi per vaksin (CRUD), laporan kondisi anak dari ibu, statistik 6 bulan, notifikasi, profil
- **Khusus admin**: kehadiran ibu per jadwal, data vaksin & vitamin, manajemen user
- **Ibu balita**: daftar/login, beranda, riwayat imunisasi + vaksin berikutnya (jadwal Kemenkes), konfirmasi kehadiran, laporan kondisi anak, profil + tambah anak

## Catatan penting
- Kode ini **belum dikompilasi/dijalankan** (lingkungan pembuatnya tanpa Dart/Flutter/MySQL). Jalankan `dart analyze` dan `flutter analyze` dulu; kemungkinan ada perbaikan kecil.
- Hash password PHP (`$2y$`) dipakai apa adanya: backend mengubah awalan menjadi `$2a$` saat verifikasi. Cek login `ADMIN001` / `password` sebagai uji pertama.
- Sesi login disimpan di memori server: restart backend = semua pengguna harus login ulang.
- Semua query memakai parameter (PHP lama memakai string langsung).
- Foto profil (`users.foto`) belum didukung di aplikasi.
