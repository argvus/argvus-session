---
title: TTY oturumu
description: Sanal bir terminalden ARGVUS'u manuel olarak başlatın.
---

Bir TTY üzerinden giriş yaptıktan sonra oturumu şu şekilde başlatın:

```sh
argvus --start-desktop
```

Bu, `argvus session`'dan desteklenen manuel giriş noktasıdır. Grafiksel bir girişle aynı `argvus start` ve kullanıcı hizmeti yaşam döngüsünü kullanır.

Oluşan oturumu incelemek veya yeniden başlatmak için `argvus sessionctl status`, `argvus sessionctl reload` veya `argvus sessionctl logs` kullanın.

## `exec argvus-tty`'dan geçiş yapma

Daha önceki sürümler `argvus-tty`'u `/usr/bin`'e yükledi ve bazı kullanıcılar `~/.profile`'dan `exec argvus-tty` ile oturumu başlattı. O dosya artık özel ve `PATH` üzerinde bulunmuyor, bu yüzden yükseltmeden sonra satır başarısız oluyor. Desteklenen giriş noktasıyla değiştirin:

```sh
exec argvus --start-desktop
```

`argvus tty` aynı giriş noktasıdır. Bir sonraki TTY oturum açmadan önce `~/.profile`, `~/.zprofile` veya `~/.bash_profile`'daki satırı kaldırın veya güncelleyin.
