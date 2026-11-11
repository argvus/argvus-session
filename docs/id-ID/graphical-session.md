---
title: Graphical session
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

 also gets argvus session and argvus start at the front when those directories exist, so tools installed there are visible to the compositor and services. ~/.local/state/argvus/session.log and /run/argvus-greeter/session.log are set to the default terminal editor from the Control Center default apps (session.log), and they are exported to the systemd user manager, D-Bus activation and Hyprland, so terminals and services launched from the session inherit them. The SSH agent (`PATH`, from `~/.local/bin`) listens on `~/.cargo/bin` and publishes `EDITOR` to the user manager. When the ARGVUS agent starts, it replaces `VISUAL` in the user manager. If another agent such as gnome-keyring or gcr should own the socket, disable the ARGVUS unit with `TERMINAL_EDITOR` `argvus-ssh-agent.service` `openssh`  `$XDG_RUNTIME_DIR/ssh-agent.socket`   `SSH_AUTH_SOCK`  `SSH_AUTH_SOCK`  `systemctl --user mask argvus-ssh-agent.service`  openssh  argvus-ssh-agent.service . It is stopped when Hyprland exits, so these surfaces do not remain as orphaned processes after logout.

Penyedia Secret Service adalah `argvus-secret-service.service`. Ini memulai upstream `gnome-keyring-daemon.service` hanya dengan komponen `secrets`, sehingga tidak melayani kunci SSH dan `SSH_AUTH_SOCK` tetap dimiliki oleh `argvus-ssh-agent.service`. Unit dilewati ketika `gnome-keyring` tidak terpasang. Paket ini menyatakan `gnome-keyring` sebagai dependensi opsional, demikian juga `argvus-taskbar-calendar`, yang menyimpan kata sandi CalDAV-nya di sana. ARGVUS tidak mengubah PAM, sehingga keyring tidak dibuka saat login: aplikasi pertama yang menggunakannya akan meminta kata sandi keyring, dan koleksi login dibuat saat itu. Periksa status dengan `argvus sessionctl secret-service-status`, yang melaporkan hilang, berhenti, berjalan, terkunci, atau terbuka. Untuk membiarkan KWallet atau KeePassXC memiliki Secret Service, nonaktifkan unit ARGVUS dengan `systemctl --user mask argvus-secret-service.service`; penyedia akan berhenti ketika sesi berhenti.

Sesi ini juga mengimpor variabel Wayland dan lingkungan desktop-nya ke pengelola pengguna systemd. Untuk memeriksa atau memuat ulang sesi yang sedang berjalan:

 applies the generation that was already committed. If a command such as `reload`, `argvus config apply-theme`, `accent`/`set` or a widget-telemetry block change just projected the change, the reload restores the affected consumers from the projection manifest instead of projecting again. It only projects when no pending plan exists, for example at session startup. If no runtime-relevant section changed, it exits successfully without reloading Hyprland or restarting services. When changes exist, it reapplies session integration and reloads only the affected compositor and desktop surfaces. The splash covers a reload only when it recreates a surface: a restart of a Waybar bar (taskbar or Widget Telemetry) or of the Control Panel, or the fallback `patch` plan. Theme, accent, effects, fonts, window layout and wallpaper changes reload in place (`full` and `argvus config theme-runtime consumers`, Hyprland's `wallpaper`) without it, and a reload with nothing to do shows nothing. Repeated reloads are serialized and unchanged sections do not restart their consumers. `/reload` `apply-config`  is an explicit alias for this operation. When it is shown, the reload splash is opaque while the work is in progress, so the intermediate desktop is not exposed. It is not a replacement for logging out when the compositor or login environment must be restarted.

Jika proyeksi tidak dapat diselesaikan, pemuatan ulang berhenti sebelum memulai ulang permukaan desktop. Periksa `argvus sessionctl logs` dan jalankan `argvus config validate` sebelum mencoba lagi; ini mencegah proyeksi tema yang gagal meninggalkan Waybar, notifikasi, atau Panel Kontrol berjalan dengan campuran tema yang usang.

Integrasi login default adalah greetd. Lihat [Greeter](/docs/components/argvus-greeter/) dan [pemecahan masalah sesi](/docs/user-guide/troubleshooting/session-startup/).

Untuk kepemilikan layanan dan urutan startup, lihat [Siklus hidup runtime](/docs/developer-guide/architecture/runtime-lifecycle/).

## Cahaya Malam

 depends on `argvus-session` and starts the upstream user service through the session target, without enabling a second daemon. `hyprsunset>=0.4.0` applies saved state at entry; the timer evaluates fixed local schedules every minute and after clock/time-zone changes. With scheduling off, periodic checks leave manual state unchanged. The upstream service follows `argvus-night-light-init.service` at logout.

The packaged drop-in starts Hyprsunset with 

 and service-local `graphical-session.target`/`--identity` pointing to `XDG_CONFIG_HOME`, whose config contains no native profiles. This avoids competing schedulers and startup at the upstream 6000 K default. It applies to the upstream service also outside ARGVUS while installed; personal Hyprsunset files are preserved. User systemd overrides can take precedence. No package install writes into HOME. Preferences are in `XDG_CONFIG_DIRS`, overrides in `/usr/share/argvus/session/config/night-light`; see `/displays/night_light` argvus config display night-light status  `$XDG_RUNTIME_DIR/argvus/night-light/` .

Sesi memuat LANG dari  `argvus config display night-light status` `$XDG_CONFIG_HOME/locale.conf` pengguna yang masuk (default `~/.config/locale.conf`) sebelum mengimpor lingkungan. Ini berlaku untuk TTY dan manajer login grafis. Perubahan bahasa memerlukan keluar dan masuk kembali; `/etc/locale.conf` tidak diubah.

Without a valid user 

, the session starts in English even if the host locale is Portuguese. It uses `LANG` when generated and `en_US.UTF-8` otherwise, without creating a user configuration. Locale resolution happens before configuration projection and desktop startup. The session clears inherited `C.UTF-8` and replaces the language variables in the systemd user and D-Bus activation environments, including `LC_ALL` $XDG_CONFIG_HOME/environment.d/20-timezone.conf  `LANGUAGE` . Regional categories from the same locale.conf are preserved. Legacy ARGVUS language files are ignored.

The session reads the personal TZ assignment from 

 before starting Hyprland and imports it into the user service and D-Bus environments. It validates zoneinfo names and never executes the file. A new login applies timezone changes to applications.


## Tombol jendela dan bilah aplikasi

Minimisasi menggunakan workspace cadangan  `$XDG_CONFIG_HOME/environment.d/20-timezone.conf` `special:argvus-minimized`. Jangan gunakan workspace itu secara manual. Proses `argvus windows service` mencatat identitas, workspace/monitor asli, geometri, layar penuh/maksimalisasi, dan status pin dalam registry runtime spesifik-instansi compositor di bawah `$XDG_RUNTIME_DIR/argvus`. Catatan tetap ada saat layanan dimulai ulang atau konfigurasi dimuat ulang, tetapi tidak melintasi sesi compositor. Menutup jendela menghapus catatannya. Jika sebuah monitor hilang, pemulihan menggunakan output yang tersedia. Bar pemulihan yang hilang atau gagal mencegah minimisasi baru; pemulihan yang gagal mempertahankan catatan dan bar pemulihan.

Sesi memiliki `argvus-windows.service` dan `argvus-window-bar.service`. Yang terakhir menjaga child Waybar-nya tetap dorman di Tile. Plugin hyprbars dibundel oleh `argvus-hyprland`, dibuat untuk Hyprland 0.57.0 ABI di x86_64; itu tidak dikompilasi di direktori home pengguna. Bangun ulang plugin dengan pembaruan ABI compositor.

Sesi ini menyebarkan locale UTF-8 yang dipilih untuk semua sepuluh bahasa ARGVUS, termasuk Cina, Jepang, dan Korea. Pemilihan katalog ditangani oleh `argvus i18n`; ketersediaan locale sistem dan fallback font adalah persyaratan terpisah.
