---
title: sesi TTY
description: Mulai ARGVUS secara manual dari terminal virtual.
---

Setelah masuk di TTY, mulai sesi dengan:

```sh
argvus --start-desktop
```

Ini adalah titik masuk manual yang didukung dari argvus session. Ini menggunakan argvus start dan siklus hidup layanan pengguna yang sama seperti login grafis.

Untuk memeriksa atau memulai ulang sesi yang dihasilkan, gunakan argvus sessionctl logs, argvus sessionctl reload atau argvus sessionctl logs.

## Migrasi dari exec argvus-tty

Earlier versions installed

 in

, dan beberapa pengguna memulai sesi dari `argvus session` dengan `argvus start`. File tersebut sekarang bersifat pribadi dan tidak lagi ada di `argvus sessionctl status`, sehingga saluran gagal setelah peningkatan. Ganti dengan titik masuk yang didukung:

```sh
exec argvus --start-desktop
```

 PATH  exec argvus-tty  ~/.profile  /usr/bin  argvus-tty  exec argvus-tty  argvus sessionctl logs  `argvus sessionctl reload`  `argvus sessionctl logs`  `exec argvus-tty`  `argvus-tty`  `/usr/bin`  `~/.profile`  `exec argvus-tty`  `PATH` `argvus tty` adalah titik masuk yang sama. Hapus atau perbarui baris di `~/.profile`, `~/.zprofile`, atau `~/.bash_profile` sebelum login berikutnya di TTY.
