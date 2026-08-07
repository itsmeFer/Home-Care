# Homecare Mobile App

Aplikasi mobile untuk platform Homecare, memungkinkan pengguna untuk mencari, melihat, dan memesan layanan kesehatan langsung ke rumah.

## 🏗 Tech Stack & Architecture
- **Framework:** Flutter (Dart)
- **API Integration:** RESTful API via `http` package
- **Authentication:** Token-based (Bearer Token) dengan penyimpanan lokal via `shared_preferences`
- **Push Notifications:** Firebase Cloud Messaging (FCM)
- **State Management:** Native Stateful/Stateless Widgets (tergantung implementasi modul)

## 🌟 Core Features
- **Autentikasi & Profil:** Login, registrasi, dan manajemen profil pasien (validasi profil wajib lengkap sebelum pemesanan).
- **Katalog Layanan:** Penelusuran layanan kesehatan berbasis kategori dengan fitur pencarian dan filter (animasi pencarian interaktif).
- **Pemesanan Layanan:** Alur pemesanan layanan kesehatan (Homecare) dengan detail harga, durasi, dan spesifikasi perawat.
- **Notifikasi:** Terintegrasi dengan Firebase Messaging Service untuk notifikasi real-time terkait status pesanan atau promo.

## 🔗 Environment & API
Secara default, aplikasi menunjuk ke *production/staging API*:
`https://homecare.primamadanitalenta.my.id/api`

Untuk mengubah target environment, pastikan untuk menyesuaikan konstanta `kBaseUrl` atau variabel environment yang relevan di dalam source code.

## 📱 Modul Utama (Lokasi Code)
- `lib/users/`: Berisi halaman-halaman utama untuk role User/Pasien (Pilih Layanan, Profil, Pemesanan).
- `lib/screen/`: Layar umum seperti Login / Register.
- `lib/firebase_messaging_service.dart`: Penanganan *background* & *foreground messages* dari FCM.
