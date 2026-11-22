-- =====================================================================
-- POSYANDU MBG - skema database (MySQL / MariaDB)
-- Sumber: database lama posyandu_flamboyan (posyandu (2)/database.sql)
-- Ditambah 4 tabel yang dipakai halaman PHP lama tetapi tidak ada di
-- database.sql: ibu_balita, ibu_anak, konfirmasi_kehadiran, laporan_kondisi
-- Nama database sengaja TETAP posyandu_flamboyan agar data lama bisa dipakai.
-- =====================================================================
CREATE DATABASE IF NOT EXISTS posyandu_flamboyan CHARACTER SET utf8mb4;
USE posyandu_flamboyan;

CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nk VARCHAR(20) UNIQUE NOT NULL,
    nama VARCHAR(100) NOT NULL,
    email VARCHAR(100),
    password VARCHAR(255) NOT NULL,
    role ENUM('admin', 'kader') NOT NULL DEFAULT 'kader',
    foto VARCHAR(255) DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS jadwal (
    id INT AUTO_INCREMENT PRIMARY KEY,
    kode_jadwal VARCHAR(10) UNIQUE NOT NULL,
    tanggal DATE NOT NULL,
    lokasi VARCHAR(200) NOT NULL,
    kegiatan VARCHAR(200) NOT NULL,
    jam_mulai TIME NOT NULL,
    jam_selesai TIME NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS anak (
    id INT AUTO_INCREMENT PRIMARY KEY,
    kode_anak VARCHAR(20) UNIQUE NOT NULL,
    nama_anak VARCHAR(100) NOT NULL,
    jenis_kelamin ENUM('P', 'L') NOT NULL,
    tanggal_lahir DATE NOT NULL,
    nama_ibu VARCHAR(100) NOT NULL,
    alamat VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS penimbangan (
    id INT AUTO_INCREMENT PRIMARY KEY,
    kode_anak VARCHAR(20) NOT NULL,
    tanggal_kegiatan DATE NOT NULL,
    usia_bulan INT NOT NULL,
    bb DECIMAL(5,2) NOT NULL COMMENT 'Berat Badan (kg)',
    tb DECIMAL(5,2) NOT NULL COMMENT 'Tinggi Badan (cm)',
    status_gizi VARCHAR(50) DEFAULT 'Normal',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (kode_anak) REFERENCES anak(kode_anak) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS vaksin (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_vaksin VARCHAR(10) UNIQUE NOT NULL,
    nama_vaksin VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS imunisasi (
    id INT AUTO_INCREMENT PRIMARY KEY,
    kode_anak VARCHAR(20) NOT NULL,
    id_vaksin VARCHAR(10) NOT NULL,
    tanggal_imunisasi DATE NOT NULL,
    usia_bulan INT NOT NULL,
    keterangan VARCHAR(100) DEFAULT 'Tepat Waktu',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (kode_anak) REFERENCES anak(kode_anak) ON DELETE CASCADE,
    FOREIGN KEY (id_vaksin) REFERENCES vaksin(id_vaksin) ON DELETE CASCADE
);

-- ---- Tabel portal ibu balita (disimpulkan dari query PHP) ----
CREATE TABLE IF NOT EXISTS ibu_balita (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nama VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    no_hp VARCHAR(20) DEFAULT NULL,
    password VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS ibu_anak (
    id INT AUTO_INCREMENT PRIMARY KEY,
    ibu_id INT NOT NULL,
    kode_anak VARCHAR(20) NOT NULL,
    UNIQUE KEY uq_ibu_anak (ibu_id, kode_anak),
    FOREIGN KEY (ibu_id) REFERENCES ibu_balita(id) ON DELETE CASCADE,
    FOREIGN KEY (kode_anak) REFERENCES anak(kode_anak) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS konfirmasi_kehadiran (
    id INT AUTO_INCREMENT PRIMARY KEY,
    ibu_id INT NOT NULL,
    jadwal_id INT NOT NULL,
    kode_anak VARCHAR(20) NOT NULL,
    status ENUM('hadir','tidak_hadir') NOT NULL,
    keterangan VARCHAR(255) DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uq_konf (ibu_id, jadwal_id, kode_anak),
    FOREIGN KEY (ibu_id) REFERENCES ibu_balita(id) ON DELETE CASCADE,
    FOREIGN KEY (jadwal_id) REFERENCES jadwal(id) ON DELETE CASCADE,
    FOREIGN KEY (kode_anak) REFERENCES anak(kode_anak) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS laporan_kondisi (
    id INT AUTO_INCREMENT PRIMARY KEY,
    ibu_id INT NOT NULL,
    kode_anak VARCHAR(20) NOT NULL,
    tanggal_laporan DATE NOT NULL,
    kondisi VARCHAR(50) NOT NULL,
    deskripsi TEXT,
    status_baca ENUM('belum','sudah') NOT NULL DEFAULT 'belum',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (ibu_id) REFERENCES ibu_balita(id) ON DELETE CASCADE,
    FOREIGN KEY (kode_anak) REFERENCES anak(kode_anak) ON DELETE CASCADE
);

-- =================== DATA AWAL (dari database lama) ===================
-- Password default kedua akun: "password"
INSERT IGNORE INTO users (nk, nama, email, password, role) VALUES
('ADMIN001', 'Administrator', 'admin@posyandu.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'admin'),
('11080924', 'Siti Aizah', 'sitiaizah14@gmail.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'kader');

INSERT IGNORE INTO vaksin (id_vaksin, nama_vaksin) VALUES
('HB01', 'HBO [Hepatitis BO]'),
('BC01', 'BCG (TBC)'),
('PL10', 'Polio 1, 2, 3 dan 4'),
('DH11', 'DPT-HB-HiB 1, 2 dan 3'),
('PC12', 'PCV 1 dan 2'),
('RT13', 'Rotavirus 1, 2 dan 3'),
('IP01', 'IPV [Polio Suntik]'),
('CM01', 'Campak / Measles Rubella (MR) 1'),
('DH02', 'DPT-HB-HiB (booster)'),
('CM02', 'Campak/MR (booster)'),
('VIT', 'Vitamin A');

INSERT IGNORE INTO jadwal (kode_jadwal, tanggal, lokasi, kegiatan, jam_mulai, jam_selesai) VALUES
('1225', '2025-12-20', "Majlis Ta'lim Al-Asiyah", 'Penimbangan Dan Imunisasi Bayi & Balita', '10:00:00', '11:00:00'),
('0126', '2026-01-20', "Majlis Ta'lim Al-Asiyah", 'Penimbangan Dan Imunisasi Bayi & Balita', '10:00:00', '11:00:00'),
('0226', '2026-02-20', "Majlis Ta'lim Al-Asiyah", 'Penimbangan Dan Imunisasi Bayi & Balita', '10:00:00', '11:00:00'),
('0326', '2026-03-20', "Majlis Ta'lim Al-Asiyah", 'Penimbangan Dan Imunisasi Bayi & Balita', '10:00:00', '11:00:00'),
('0426', '2026-04-20', "Majlis Ta'lim Al-Asiyah", 'Penimbangan Dan Imunisasi Bayi & Balita', '10:00:00', '11:00:00'),
('0526', '2026-05-20', "Majlis Ta'lim Al-Asiyah", 'Penimbangan Dan Imunisasi Bayi & Balita', '10:00:00', '11:00:00');

INSERT IGNORE INTO anak (kode_anak, nama_anak, jenis_kelamin, tanggal_lahir, nama_ibu, alamat) VALUES
('01120324', 'Anindira', 'P', '2024-03-12', 'Aminah', 'Jl. Kayu Manis III'),
('03200125', 'Chaerunisa', 'P', '2025-01-20', 'Hikmah', 'Jl. Kayu Manis II'),
('01050525', 'Alvaro', 'L', '2025-05-05', 'Akbar', 'Jl. Kayu Manis III'),
('11250825', 'Kirana', 'P', '2025-08-25', 'Arini', 'Jl. Kayu Manis IV'),
('11080525', 'Kenzo', 'L', '2025-05-08', 'Aini', 'Jl. Kayu Manis I'),
('01130925', 'Arin', 'P', '2025-09-13', 'Sari', 'Jl. Kayu Manis II'),
('02150325', 'Baim', 'L', '2025-03-15', 'Dewi', 'Jl. Kayu Manis I'),
('01231125', 'Alaine', 'P', '2025-11-23', 'Rina', 'Jl. Kayu Manis III');

INSERT INTO penimbangan (kode_anak, tanggal_kegiatan, usia_bulan, bb, tb, status_gizi) VALUES
('01120324', '2026-04-20', 24, 10.0, 85.0, 'Normal'),
('03200125', '2026-04-20', 19, 11.0, 80.0, 'Normal'),
('01050525', '2026-04-20', 23, 13.0, 88.0, 'Normal'),
('11250825', '2026-04-20', 10, 7.7, 75.0, 'Normal'),
('11080525', '2026-04-20', 12, 10.1, 80.0, 'Normal');

-- Catatan: database lama punya 2 baris imunisasi untuk kode_anak 04090425 dan
-- 26170525 yang TIDAK ada di tabel anak (melanggar foreign key, import gagal).
-- Dua baris itu dibuang di sini; sisanya tetap.
INSERT INTO imunisasi (kode_anak, id_vaksin, tanggal_imunisasi, usia_bulan, keterangan) VALUES
('01130925', 'BC01', '2025-10-20', 1, 'Tepat Waktu'),
('02150325', 'BC01', '2025-04-20', 1, 'Tepat Waktu'),
('01231125', 'BC01', '2025-12-20', 1, 'Tepat Waktu');
