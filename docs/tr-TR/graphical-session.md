---
title: Grafik oturumu
description: ARGVUS'u grafiksel bir giriş akışı aracılığıyla başlatın.
---

Grafik giriş noktası `argvus session`'dir. Oturum ortamını ayarlar ve `argvus start`'ye devreder; bu modül onu kullanıcı yöneticisine aktarır, paketlenmiş veya kullanıcı Hyprland Lua yapılandırmasını doğrular, tespit edilen grafik uyumluluk ayarlarını uygular, Hyprland'i başlatır ve kompozitörün hazır olmasını bekler.

Kayıtlar `~/.local/state/argvus/session.log` dosyasına yazılır. Karşılama programı, giriş yapmadan önce kendi kullanıcısı olarak çalışır, bu nedenle giriş öncesi çıktısı `/run/argvus-greeter/session.log` dosyasında tutulur ve oturum başladığında `session.log` dosyasına eklenir. Hyprland'ten gelen bir başlangıç uyarısı oturum günlüğünde görünmediğinde önce bu dosyayı kontrol edin.

Oturum, giriş yöneticisi (örneğin greetd ile source_profile=false) bir değer dışa aktarmasa bile, shell `PATH` ortam değişkeninin mantıklı bir varsayılan değere ayarlanmasını sağlar. Bu, Hyprland tarafından başlatıldığında kullanılan  `source_profile=false` `hyprland-dialog` gibi yardımcı programların alt süreçler tarafından bulunabilir olmasını garanti eder.

Hyprland hazır olduktan sonra, `argvus sessionctl` `argvus-session.target`'u başlatır. Bu hedef, görev çubuğunu, Denetim Masası'nı, bildirimleri, duvar kağıdını, boşta çalışma yönetimini, panoyu, SSH ajanını, Gizli Servis sağlayıcısını ve ilgili servisleri başlatır. Tek bir yükleme simgesi, giriş devri tamamlanana kadar ekranda kalır ve bu servisler başlatıldıktan ve duvar kağıdı ile görev çubuğu ekranda görünene kadar (en fazla 1,5 saniye daha) devam eder. Hyprland'ı başlatmadan önce, `argvus-start` yapılandırma projeksiyonunu (`argvus-config.service`) sıraya alır; bu, kompozitör başlatılırken çalışır ve karşılayıcının DRM devri yüzeyinden ekranı serbest bırakmasını ister (`/usr/lib/argvus/greeter/handoff --send release`); o yüzey çalıştığında, öncelikle `loginctl activate` ile oturumu etkinleştirir, böylece Hyprland asla arka plandaki bir VT üzerinde başlamaz. Oturum simgesi daha sonra yüzeye Hyprland'ın ilk karelerini gizleyen katmanı kaldırmasını söyler.

Masaüstü hazır olduktan sonra, oturum TTY için `argvus welcome --if-needed`, ARGVUS Greeter ve diğer oturum açma yöneticilerini çalıştırır. Kullanıcıya özel ilerleme kayıtları `opened`, tamamlama veya reddetme olmadıkça entegre Kontrol Merkezi Hoş Geldiniz sayfasını açar. İlk başarılı render `opened`'yi `${XDG_STATE_HOME:-$HOME/.local/state}/argvus/welcome/progress.json`'de kaydeder ve sonraki oturum açmalarda yeniden açılmasını engeller. `/etc/skel`'ya bağlı değildir. O kayıt olmayan mevcut hesaplar da bir otomatik açılış alır. Render öncesi hatalar, bir sonraki oturum açmada başka bir denemeye izin verir. Manuel `argvus welcome` kullanılmaya devam eder.

`PATH`, bu dizinler mevcut olduğunda önde `~/.local/bin` ve `~/.cargo/bin`'yi de alır, böylece oraya kurulan araçlar kompozitör ve servisler tarafından görünür hale gelir. `EDITOR` ve `VISUAL`, Kontrol Merkezi varsayılan uygulamalarından (`TERMINAL_EDITOR`) varsayılan terminal editörüne ayarlanmıştır ve bunlar systemd kullanıcı yöneticisine, D-Bus etkinleştirmesine ve Hyprland'e aktarılır, böylece oturumdan başlatılan terminaller ve servisler bunları devralır. SSH ajanı (`argvus-ssh-agent.service`, `openssh`'den) `$XDG_RUNTIME_DIR/ssh-agent.socket` üzerinde dinler ve `SSH_AUTH_SOCK`'yi kullanıcı yöneticisine yayınlar. ARGVUS ajanı başladığında, kullanıcı yöneticisinde `SSH_AUTH_SOCK`'yi değiştirir. gnome-keyring veya gcr gibi başka bir ajanın sokete sahip olması gerekiyorsa, ARGVUS birimini `systemctl --user mask argvus-ssh-agent.service` ile devre dışı bırakın. Hyprland çıkış yaptığında durdurulur, böylece bu yüzeyler oturum kapandıktan sonra yetim süreçler olarak kalmaz.

Gizli Servis sağlayıcısı `argvus-secret-service.service`'dir. Sadece secrets bileşeni ile yukarı akış `gnome-keyring-daemon.service`'yi başlatır, bu nedenle SSH anahtarlarını sağlamaz ve  `secrets` `SSH_AUTH_SOCK` `argvus-ssh-agent.service` tarafından sahip olunmaya devam eder. `gnome-keyring` yüklü değilse birim atlanır. Paket, `gnome-keyring`'yi isteğe bağlı bir bağımlılık olarak bildirir ve CalDAV şifrelerini orada depolayan `argvus-taskbar-calendar` de öyle yapar. ARGVUS PAM'i değiştirmez, bu nedenle anahtar halkası girişte kilidi açılmaz: onu kullanan ilk uygulama anahtar halkası şifresini sorar ve o zaman giriş koleksiyonu oluşturulur. Durumu, eksik, durdurulmuş, çalışan, kilitli veya kilidi açılmış olarak rapor eden `argvus sessionctl secret-service-status` ile kontrol edin. KWallet veya KeePassXC'nin yerine Gizli Servis'e sahip olmasına izin vermek için ARGVUS birimini `systemctl --user mask argvus-secret-service.service` ile devre dışı bırakın; oturum durduğunda sağlayıcı durdurulur.

Oturum ayrıca Wayland ve masaüstü ortamı değişkenlerini systemd kullanıcı yöneticisine aktarır. Çalışan bir oturumu incelemek veya yeniden yüklemek için:

```sh
argvus sessionctl status
argvus sessionctl logs
argvus sessionctl reload
```

 zaten taahhüt edilmiş olan nesli uygular. `reload`, `argvus config apply-theme`, `accent`/`set` gibi bir komut veya bir widget telemetri bloğu değişikliği sadece değişikliği yansıttıysa, yeniden yükleme, etkilenen tüketicileri tekrar yansıtmak yerine projeksiyon bildiriminden geri yükler. Yalnızca, örneğin oturum başlangıcında, bekleyen bir plan bulunmadığında projelendirilir. Çalışma zamanı ile ilgili hiçbir bölüm değişmediyse, Hyprland yeniden yüklenmeden veya hizmetler yeniden başlatılmadan başarıyla çıkılır. Değişiklikler olduğunda oturum entegrasyonunu yeniden uygular ve yalnızca etkilenen derleyici ve masaüstü yüzeylerini yeniden yükler. Sıçrama, yalnızca bir yüzeyi yeniden oluşturduğunda yeniden yüklemeyi kapsar: Waybar çubuğunun (görev çubuğu veya Widget Telemetrisi) veya Kontrol Panelinin veya geri dönüş `patch` planının yeniden başlatılması. Tema, vurgu, efektler, yazı tipleri, pencere düzeni ve duvar kağıdı değişiklikleri (`full` ve `argvus config theme-runtime consumers`, Hyprland'nin `wallpaper`) bu olmadan yerinde yeniden yüklenir ve yapacak hiçbir şey olmadan yeniden yükleme hiçbir şey göstermez. Tekrarlanan yeniden yüklemeler serileştirilir ve değiştirilmeyen bölümler tüketicilerini yeniden başlatmaz. `/reload` `apply-config` bu işlem için açık bir takma addır. Gösterildiğinde, çalışma devam ederken yeniden yükleme ekranı opaktır, dolayısıyla ara masaüstü açıkta kalmaz. Besteci veya oturum açma ortamının yeniden başlatılması gerektiğinde oturumu kapatmanın yerini almaz.

Projeksiyon tamamlanamazsa, yeniden başlatmadan önce masaüstü yüzeylerinin yeniden yüklenmesi durur. Tekrar denemeden önce `argvus sessionctl logs`'yi kontrol edin ve `argvus config validate`'yi çalıştırın; bu, başarısız bir tema projeksiyonunun Waybar, bildirimler veya Kontrol Paneli'nin eski bir tema karışımıyla çalışmaya devam etmesini önler.

Varsayılan giriş entegrasyonu greetd'dir. Bkz. [Greeter](/docs/components/argvus-greeter/) ve [oturum sorun giderme](/docs/user-guide/troubleshooting/session-startup/).

Servis sahipliği ve başlatma sırası için, bkz. [Runtime yaşam döngüsü](/docs/developer-guide/architecture/runtime-lifecycle/).

## Gece Lambası

`argvus-session`, `hyprsunset>=0.4.0`'ye bağlıdır ve ikinci bir daemon etkinleştirmeden oturum hedefi üzerinden üst akış kullanıcı servisini başlatır. `argvus-night-light-init.service`, girişte kaydedilmiş durumu uygular; zamanlayıcı her dakika ve saat/dakika dilimi değişikliklerinden sonra sabit yerel programları değerlendirir. Zamanlama kapalıyken, periyodik kontroller manuel durumu değiştirmez. Üst akış servisi, çıkışta `graphical-session.target`'yu izler.

Paketlenmiş drop-in, `--identity` ile Hyprsunset'i ve `XDG_CONFIG_HOME`/`XDG_CONFIG_DIRS` hizmet-lokal'ını `/usr/share/argvus/session/config/night-light`'ya yönlendirerek başlatır; bunun yapılandırması yerel profiller içermez. Bu, rakip zamanlayıcılardan ve 6000 K varsayılanında üst akımda başlatmadan kaçınır. Yüklendiğinde, ARGVUS dışında da üst akım hizmetine uygulanır; kişisel Hyprsunset dosyaları korunur. Kullanıcı systemd geçersiz kılmaları öncelik alabilir. Hiçbir paket kurulumu HOME içine yazmaz. Tercihler `/displays/night_light`'dedir, geçersiz kılmalar `$XDG_RUNTIME_DIR/argvus/night-light/`'dedir; `argvus config display night-light status`'ya bakın.

Oturum, ortamı içe aktarmadan önce oturum açmış kullanıcının `$XDG_CONFIG_HOME/locale.conf`'sinden (varsayılan `~/.config/locale.conf`) LANG yükler. Bu, TTY ve grafiksel giriş yöneticileri için geçerlidir. Dil değişiklikleri için çıkış yapıp tekrar giriş yapmak gerekir; `/etc/locale.conf` değiştirilmez.

Geçerli bir `LANG` kullanıcı olmadan, oturum, ana bilgisayar yerel ayarı Portekizce olsa bile İngilizce olarak başlar. Oluşturulduğunda `en_US.UTF-8` kullanılır ve aksi takdirde `C.UTF-8` kullanılır; kullanıcı yapılandırması oluşturmaz. Yerel ayar çözümü, yapılandırma projeksiyonu ve masaüstü başlatmadan önce gerçekleşir. Oturum, devralınan `LC_ALL` temizler ve sistemd kullanıcı ve D-Bus etkinleştirme ortamlarındaki dil değişkenlerini, `LANGUAGE` dahil olmak üzere değiştirir. Aynı locale.conf dosyasından gelen bölgesel kategoriler korunur. Eski ARGVUS dil dosyaları göz ardı edilir.

Oturum, Hyprland'i başlatmadan önce `$XDG_CONFIG_HOME/environment.d/20-timezone.conf`'dan kişisel TZ atamasını okur ve kullanıcı servisi ile D-Bus ortamlarına aktarır. Zoneinfo adlarını doğrular ve dosyayı asla çalıştırmaz. Yeni bir oturum açma, uygulamalara zaman dilimi değişikliklerini uygular.


## Pencere düğmeleri ve uygulama çubuğu

Minimize etme, rezerve edilmiş `special:argvus-minimized` çalışma alanını kullanır. Bu çalışma alanını manuel olarak kullanmayın. `argvus windows service` işlemi, kimliği, orijinal çalışma alanını/monitörü, geometrisini, tam ekran/masimleştirme ve sabitleme durumunu `$XDG_RUNTIME_DIR/argvus` altında her kompozitör örneğine özgü bir çalışma zamanı kaydında kaydeder. Kayıtlar bir servis yeniden başlatması veya yapılandırma yeniden yüklemesini geçirir, ancak kompozitör oturumlarını geçmez. Bir pencere kapatıldığında kaydı silinir. Bir monitör kaybolursa, geri yükleme mevcut bir çıktı kullanır. Eksik veya başarısız bir geri kazanım çubuğu, yeni minimize işlemlerini engeller; başarısız geri yükleme kaydı ve geri kazanım çubuğunu korur.

Oturum `argvus-windows.service` ve `argvus-window-bar.service` adlı öğelere sahiptir. İkincisi Waybar alt öğesini Tile içinde pasif tutar. hyprbars eklentisi `argvus-hyprland` tarafından paketlenmiştir, Hyprland 0.57.0 ABI için x86_64 üzerinde oluşturulmuştur; kullanıcı ev dizininde derlenmemiştir. Eklentiyi bir compositor ABI güncellemesi ile yeniden derleyin.

Oturum, Çin, Japon ve Korece dahil olmak üzere tüm on ARGVUS dili için seçilen UTF-8 yerel ayarını yayar. Katalog seçimi `argvus i18n` tarafından yönetilir; sistem yerel ayar kullanılabilirliği ve yazı tipi yedeği ayrı gereksinimlerdir.
