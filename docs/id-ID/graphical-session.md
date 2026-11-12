---
title: Sesi grafis
description: Mulai ARGVUS melalui alur login grafis.
---

Titik masuk grafis adalah `argvus session`. Ini mengatur lingkungan sesi dan mendelegasikan ke `argvus start`, yang mengimpornya ke dalam pengelola pengguna, memvalidasi konfigurasi Hyprland Lua yang dikemas atau pengguna, menerapkan pengaturan kompatibilitas grafis yang terdeteksi, meluncurkan Hyprland dan menunggu kesiapan kompositor.

Log ditulis ke `~/.local/state/argvus/session.log`. Greeter berjalan sebagai pengguna tersendiri sebelum login, jadi output pra-login-nya disimpan di `/run/argvus-greeter/session.log` dan ditambahkan ke `session.log` ketika sesi dimulai. Periksa file ini terlebih dahulu ketika peringatan saat startup dari Hyprland tidak muncul di log sesi.

Sesi memastikan bahwa variabel lingkungan shell `PATH` diatur ke nilai default yang masuk akal bahkan ketika manajer login (seperti greetd dengan `source_profile=false`) tidak mengekspornya. Ini menjamin bahwa utilitas seperti `hyprland-dialog`, yang digunakan oleh Hyprland saat startup, dapat ditemukan oleh proses anak.

Setelah Hyprland siap, `argvus sessionctl` memulai `argvus-session.target`. Target ini memulai taskbar, Panel Kontrol, notifikasi, wallpaper, penanganan idle, clipboard, agen SSH, penyedia Layanan Rahasia dan layanan terkait. Sebuah spinner pemuatan tunggal tetap di layar dari serah terima login sampai layanan tersebut telah dimulai dan wallpaper serta taskbar muncul di layar (paling lama 1,5 detik lagi). Sebelum meluncurkan Hyprland, `argvus-start` mengantri proyeksi konfigurasi (`argvus-config.service`), yang kemudian dijalankan selama startup compositor, dan meminta permukaan serah terima DRM greeter untuk melepaskan tampilan (`/usr/lib/argvus/greeter/handoff --send release`); ketika permukaan itu berjalan, pertama-tama mengaktifkan sesi dengan `loginctl activate`, sehingga Hyprland tidak pernah memulai di VT di latar belakang. Spinner sesi kemudian memberi tahu permukaan untuk menghapus lapisan yang menyembunyikan frame pertama Hyprland.

Setelah desktop siap, sesi menjalankan `argvus welcome --if-needed` untuk TTY, ARGVUS Greeter, dan pengelola login lainnya. Ini membuka halaman Selamat Datang Pusat Kontrol terintegrasi kecuali catatan kemajuan per pengguna `opened`, penyelesaian, atau penutupan. Render pertama yang berhasil menyimpan `opened` di `${XDG_STATE_HOME:-$HOME/.local/state}/argvus/welcome/progress.json`, mencegah pembukaan kembali pada login berikutnya. Ini tidak bergantung pada `/etc/skel`. Akun yang ada tanpa catatan itu juga akan menerima pembukaan otomatis. Kegagalan sebelum render memungkinkan percobaan lain pada login berikutnya. `argvus welcome` manual tetap tersedia.

```sh
argvus sessionctl status
argvus sessionctl logs
argvus sessionctl reload
```

juga mendapatkan sesi argvus dan argvus dimulai di depan ketika direktori tersebut ada, sehingga alat yang dipasang di sana dapat dilihat oleh kompositor dan layanan. ~/.local/state/argvus/session.log dan /run/argvus-greeter/session.log diatur ke editor terminal default dari aplikasi default Pusat Kontrol (session.log), dan diekspor ke manajer pengguna systemd, aktivasi D-Bus dan Hyprland, sehingga terminal dan layanan yang diluncurkan dari sesi mewarisinya. Agen SSH (`PATH`, dari `~/.local/bin`) mendengarkan `~/.cargo/bin` dan memublikasikan `EDITOR` ke manajer pengguna. Saat agen ARGVUS dimulai, agen tersebut menggantikan `VISUAL` di manajer pengguna. Jika agen lain seperti gnome-keyring atau gcr harus memiliki soket, nonaktifkan unit ARGVUS dengan `TERMINAL_EDITOR` `argvus-ssh-agent.service` `openssh` `$XDG_RUNTIME_DIR/ssh-agent.socket` `SSH_AUTH_SOCK` `SSH_AUTH_SOCK` `systemctl --user mask argvus-ssh-agent.service` openssh argvus-ssh-agent.service . Ini dihentikan ketika Hyprland keluar, sehingga permukaan ini tidak tetap menjadi proses tanpa induk setelah logout.

Penyedia Secret Service adalah `argvus-secret-service.service`. Ini memulai upstream `gnome-keyring-daemon.service` hanya dengan komponen `secrets`, sehingga tidak melayani kunci SSH dan `SSH_AUTH_SOCK` tetap dimiliki oleh `argvus-ssh-agent.service`. Unit dilewati ketika `gnome-keyring` tidak terpasang. Paket ini menyatakan `gnome-keyring` sebagai dependensi opsional, demikian juga `argvus-taskbar-calendar`, yang menyimpan kata sandi CalDAV-nya di sana. ARGVUS tidak mengubah PAM, sehingga keyring tidak dibuka saat login: aplikasi pertama yang menggunakannya akan meminta kata sandi keyring, dan koleksi login dibuat saat itu. Periksa status dengan `argvus sessionctl secret-service-status`, yang melaporkan hilang, berhenti, berjalan, terkunci, atau terbuka. Untuk membiarkan KWallet atau KeePassXC memiliki Secret Service, nonaktifkan unit ARGVUS dengan `systemctl --user mask argvus-secret-service.service`; penyedia akan berhenti ketika sesi berhenti.

Sesi ini juga mengimpor variabel Wayland dan lingkungan desktop-nya ke pengelola pengguna systemd. Untuk memeriksa atau memuat ulang sesi yang sedang berjalan:

 menerapkan generasi yang sudah berkomitmen. Jika perintah seperti `reload`, `argvus config apply-theme`, `accent`/`set` atau perubahan blok telemetri widget hanya memproyeksikan perubahan, pemuatan ulang akan memulihkan konsumen yang terpengaruh dari manifes proyeksi, bukan memproyeksikan lagi. Ini hanya memproyeksikan ketika tidak ada rencana yang tertunda, misalnya saat sesi dimulai. Jika tidak ada bagian yang relevan dengan runtime yang diubah, maka bagian tersebut berhasil keluar tanpa memuat ulang Hyprland atau memulai ulang layanan. Jika ada perubahan, integrasi sesi akan diterapkan kembali dan hanya memuat ulang kompositor dan permukaan desktop yang terpengaruh. Percikan mencakup pemuatan ulang hanya ketika membuat ulang permukaan: memulai ulang bilah Waybar (bilah tugas atau Telemetri Widget) atau Panel Kontrol, atau paket cadangan `patch`. Perubahan tema, aksen, efek, font, tata letak jendela, dan wallpaper dimuat ulang di tempatnya (`full` dan `argvus config theme-runtime consumers`, Hyprland `wallpaper`) tanpanya, dan memuat ulang tanpa melakukan apa pun tidak menunjukkan apa pun. Pemuatan ulang yang berulang bersifat serial dan bagian yang tidak diubah tidak memulai ulang konsumennya. `/reload` `apply-config` adalah alias eksplisit untuk operasi ini. Ketika ditampilkan, splash reload buram saat pekerjaan sedang berlangsung, sehingga desktop perantara tidak terekspos. Ini bukan pengganti logout ketika compositor atau lingkungan login harus dimulai ulang.

Jika proyeksi tidak dapat diselesaikan, pemuatan ulang berhenti sebelum memulai ulang permukaan desktop. Periksa `argvus sessionctl logs` dan jalankan `argvus config validate` sebelum mencoba lagi; ini mencegah proyeksi tema yang gagal meninggalkan Waybar, notifikasi, atau Panel Kontrol berjalan dengan campuran tema yang usang.

Integrasi login default adalah greetd. Lihat [Greeter](/docs/components/argvus-greeter/) dan [pemecahan masalah sesi](/docs/user-guide/troubleshooting/session-startup/).

Untuk kepemilikan layanan dan urutan startup, lihat [Siklus hidup runtime](/docs/developer-guide/architecture/runtime-lifecycle/).

## Cahaya Malam

 bergantung pada `argvus-session` dan memulai layanan pengguna upstream melalui target sesi, tanpa mengaktifkan daemon kedua. `hyprsunset>=0.4.0` menerapkan status tersimpan saat masuk; pengatur waktu mengevaluasi jadwal lokal tetap setiap menit dan setelah perubahan jam/zona waktu. Jika penjadwalan dinonaktifkan, pemeriksaan berkala tidak mengubah status manual. Layanan upstream mengikuti `argvus-night-light-init.service` saat logout.

The packaged drop-in starts Hyprsunset with

dan layanan lokal `graphical-session.target`/`--identity` menunjuk ke `XDG_CONFIG_HOME`, yang konfigurasinya tidak berisi profil asli. Hal ini menghindari persaingan penjadwal dan startup pada default upstream 6000 K. Ini berlaku untuk layanan upstream juga di luar ARGVUS saat diinstal; file Hyprsunset pribadi disimpan. Penggantian pengguna systemd dapat diutamakan. Tidak ada instalasi paket yang menulis ke HOME. Preferensi ada di `XDG_CONFIG_DIRS`, diganti di `/usr/share/argvus/session/config/night-light`; lihat `/displays/night_light` argvus config menampilkan status lampu malam `$XDG_RUNTIME_DIR/argvus/night-light/` .

Sesi memuat LANG dari  `argvus config display night-light status` `$XDG_CONFIG_HOME/locale.conf` pengguna yang masuk (default `~/.config/locale.conf`) sebelum mengimpor lingkungan. Ini berlaku untuk TTY dan manajer login grafis. Perubahan bahasa memerlukan keluar dan masuk kembali; `/etc/locale.conf` tidak diubah.

Without a valid user

, sesi dimulai dalam bahasa Inggris meskipun lokasi tuan rumah adalah bahasa Portugis. Ia menggunakan `LANG` saat dibuat dan `en_US.UTF-8` sebaliknya, tanpa membuat konfigurasi pengguna. Resolusi lokal terjadi sebelum proyeksi konfigurasi dan startup desktop. Sesi ini menghapus warisan `C.UTF-8` dan menggantikan variabel bahasa di lingkungan aktivasi pengguna systemd dan D-Bus, termasuk `LC_ALL` $XDG_CONFIG_HOME/environment.d/20-timezone.conf `LANGUAGE` . Kategori regional dari locale.conf yang sama dipertahankan. File bahasa lama ARGVUS diabaikan.

The session reads the personal TZ assignment from

 sebelum memulai Hyprland dan mengimpornya ke layanan pengguna dan lingkungan D-Bus. Ini memvalidasi nama zoneinfo dan tidak pernah mengeksekusi file. Login baru menerapkan perubahan zona waktu pada aplikasi.


## Tombol jendela dan bilah aplikasi

Minimisasi menggunakan workspace cadangan  `$XDG_CONFIG_HOME/environment.d/20-timezone.conf` `special:argvus-minimized`. Jangan gunakan workspace itu secara manual. Proses `argvus windows service` mencatat identitas, workspace/monitor asli, geometri, layar penuh/maksimalisasi, dan status pin dalam registry runtime spesifik-instansi compositor di bawah `$XDG_RUNTIME_DIR/argvus`. Catatan tetap ada saat layanan dimulai ulang atau konfigurasi dimuat ulang, tetapi tidak melintasi sesi compositor. Menutup jendela menghapus catatannya. Jika sebuah monitor hilang, pemulihan menggunakan output yang tersedia. Bar pemulihan yang hilang atau gagal mencegah minimisasi baru; pemulihan yang gagal mempertahankan catatan dan bar pemulihan.

Sesi memiliki `argvus-windows.service` dan `argvus-window-bar.service`. Yang terakhir menjaga child Waybar-nya tetap dorman di Tile. Plugin hyprbars dibundel oleh `argvus-hyprland`, dibuat untuk Hyprland 0.57.0 ABI di x86_64; itu tidak dikompilasi di direktori home pengguna. Bangun ulang plugin dengan pembaruan ABI compositor.

Sesi ini menyebarkan locale UTF-8 yang dipilih untuk semua sepuluh bahasa ARGVUS, termasuk Cina, Jepang, dan Korea. Pemilihan katalog ditangani oleh `argvus i18n`; ketersediaan locale sistem dan fallback font adalah persyaratan terpisah.
