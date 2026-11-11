---
title: Graphical session
description: Khởi động ARGVUS thông qua luồng đăng nhập đồ họa.
---

Điểm nhập đồ họa là `argvus session`. Nó thiết lập môi trường phiên làm việc và chuyển cho `argvus start`, người nhập nó vào trình quản lý người dùng, xác thực cấu hình Hyprland Lua đã đóng gói hoặc của người dùng, áp dụng các cài đặt tương thích đồ họa được phát hiện, khởi chạy Hyprland và chờ cho trình tổng hợp sẵn sàng.

Nhật ký được ghi vào `~/.local/state/argvus/session.log`. Trình chào đón chạy dưới tài khoản riêng của nó trước khi đăng nhập, vì vậy đầu ra trước khi đăng nhập của nó được giữ trong `/run/argvus-greeter/session.log` và được thêm vào `session.log` khi phiên bắt đầu. Hãy kiểm tra tệp này trước khi một cảnh báo khởi động từ Hyprland không xuất hiện trong nhật ký phiên.

Phiên làm việc đảm bảo rằng biến môi trường shell `PATH` được thiết lập mặc định hợp lý ngay cả khi trình quản lý đăng nhập (chẳng hạn như greetd với `source_profile=false`) không xuất ra một biến nào. Điều này đảm bảo rằng các tiện ích như `hyprland-dialog`, được Hyprland sử dụng khi khởi động, có thể được các tiến trình con phát hiện.

Sau khi Hyprland sẵn sàng, `argvus sessionctl` bắt đầu `argvus-session.target`. Mục tiêu này khởi động thanh tác vụ, Bảng điều khiển, thông báo, hình nền, xử lý nhàn rỗi, clipboard, tác nhân SSH, nhà cung cấp Dịch vụ Bí mật và các dịch vụ liên quan. Một vòng quay tải đơn vẫn hiển thị trên màn hình từ khi chuyển giao đăng nhập cho đến khi các dịch vụ đó đã được khởi động và hình nền cũng như thanh tác vụ đã xuất hiện trên màn hình (tối đa thêm 1,5 giây). Trước khi khởi chạy Hyprland, `argvus-start` xếp hàng chiếu cấu hình (`argvus-config.service`), sau đó chạy trong quá trình khởi động trình kết xuất, và yêu cầu bề mặt giao tiếp DRM của greeter giải phóng màn hình (`/usr/lib/argvus/greeter/handoff --send release`); khi bề mặt đó đang chạy, nó trước tiên kích hoạt phiên với `loginctl activate`, vì vậy Hyprland không bao giờ khởi động trên một VT nền. Vòng quay phiên sau đó yêu cầu bề mặt loại bỏ lớp phủ đã che đi các khung hình đầu tiên của Hyprland.

Sau khi máy tính để bàn sẵn sàng, phiên làm việc chạy `argvus welcome --if-needed` cho TTY, ARGVUS Greeter và các trình quản lý đăng nhập khác. Nó mở trang Chào mừng của Trung tâm Kiểm soát tích hợp trừ khi hồ sơ tiến trình của từng người dùng `opened`, hoàn thành hoặc từ chối. Lần hiển thị thành công đầu tiên lưu `opened` trong `${XDG_STATE_HOME:-$HOME/.local/state}/argvus/welcome/progress.json`, ngăn không cho mở lại trong các lần đăng nhập sau. Nó không phụ thuộc vào `/etc/skel`. Các tài khoản hiện có mà không có hồ sơ đó cũng nhận được một lần mở tự động. Thất bại trước khi hiển thị cho phép thực hiện lại vào lần đăng nhập tiếp theo. `argvus welcome` thủ công vẫn khả dụng.

`PATH` cũng nhận `~/.local/bin` và `~/.cargo/bin` ở phía trước khi các thư mục đó tồn tại, vì vậy các công cụ được cài đặt ở đó sẽ hiển thị cho bộ tổng hợp và các dịch vụ. `EDITOR` và `VISUAL` được đặt làm trình soạn thảo terminal mặc định từ các ứng dụng mặc định của Trung tâm điều khiển (`TERMINAL_EDITOR`), và chúng được xuất sang trình quản lý người dùng systemd, kích hoạt D-Bus và Hyprland, do đó các terminal và dịch vụ được khởi chạy từ phiên làm việc kế thừa chúng. Tác nhân SSH (`argvus-ssh-agent.service`, từ `openssh`) lắng nghe trên `$XDG_RUNTIME_DIR/ssh-agent.socket` và công bố `SSH_AUTH_SOCK` cho trình quản lý người dùng. Khi tác nhân ARGVUS khởi động, nó thay thế `SSH_AUTH_SOCK` trong trình quản lý người dùng. Nếu một tác nhân khác như gnome-keyring hoặc gcr nên sở hữu socket, hãy tắt đơn vị ARGVUS bằng `systemctl --user mask argvus-ssh-agent.service`. Nó bị dừng khi Hyprland thoát, vì vậy các bề mặt này không còn lại như các tiến trình mồ côi sau khi đăng xuất.

Nhà cung cấp Dịch vụ Bí mật là `argvus-secret-service.service`. Nó bắt đầu upstream `gnome-keyring-daemon.service` chỉ với thành phần `secrets`, vì vậy nó không phục vụ các khóa SSH và `SSH_AUTH_SOCK` vẫn thuộc sở hữu của `argvus-ssh-agent.service`. Đơn vị này bị bỏ qua khi `gnome-keyring` không được cài đặt. Gói khai báo `gnome-keyring` là một phụ thuộc tùy chọn, và `argvus-taskbar-calendar` cũng vậy, nó lưu trữ mật khẩu CalDAV của mình ở đó. ARGVUS không thay đổi PAM, vì vậy chuỗi khóa không được mở khóa khi đăng nhập: ứng dụng đầu tiên sử dụng nó sẽ yêu cầu mật khẩu chuỗi khóa, và bộ sưu tập đăng nhập được tạo ra lúc đó. Kiểm tra trạng thái với `argvus sessionctl secret-service-status`, nó báo cáo thiếu, đã dừng, đang chạy, bị khóa hoặc đã mở khóa. Để KWallet hoặc KeePassXC sở hữu Dịch vụ Bí mật thay vào đó, hãy vô hiệu hóa đơn vị ARGVUS với `systemctl --user mask argvus-secret-service.service`; nhà cung cấp sẽ dừng khi phiên kết thúc.

Phiên làm việc cũng nhập các biến Wayland và môi trường máy tính để bàn của nó vào trình quản lý người dùng systemd. Để kiểm tra hoặc nạp lại một phiên làm việc đang chạy:

```sh
argvus sessionctl status
argvus sessionctl logs
argvus sessionctl reload
```

 applies the generation that was already committed. If a command such as `reload`, `argvus config apply-theme`, `accent`/`set` or a widget-telemetry block change just projected the change, the reload restores the affected consumers from the projection manifest instead of projecting again. It only projects when no pending plan exists, for example at session startup. If no runtime-relevant section changed, it exits successfully without reloading Hyprland or restarting services. When changes exist, it reapplies session integration and reloads only the affected compositor and desktop surfaces. The splash covers a reload only when it recreates a surface: a restart of a Waybar bar (taskbar or Widget Telemetry) or of the Control Panel, or the fallback `patch` plan. Theme, accent, effects, fonts, window layout and wallpaper changes reload in place (`full` and `argvus config theme-runtime consumers`, Hyprland's `wallpaper`) without it, and a reload with nothing to do shows nothing. Repeated reloads are serialized and unchanged sections do not restart their consumers. `/reload` `apply-config`  is an explicit alias for this operation. When it is shown, the reload splash is opaque while the work is in progress, so the intermediate desktop is not exposed. It is not a replacement for logging out when the compositor or login environment must be restarted.

Nếu việc chiếu không thể hoàn thành, việc nạp lại sẽ dừng trước khi khởi động lại các bề mặt màn hình. Kiểm tra `argvus sessionctl logs` và chạy `argvus config validate` trước khi thử lại; điều này ngăn việc chiếu giao diện thất bại khiến Waybar, các thông báo hoặc Bảng điều khiển chạy với một hỗn hợp giao diện lỗi thời.

Tích hợp đăng nhập mặc định là greetd. Xem [Greeter](/docs/components/argvus-greeter/) và [khắc phục sự cố phiên](/docs/user-guide/troubleshooting/session-startup/).

Đối với quyền sở hữu dịch vụ và trình tự khởi động, xem [Vòng đời thời gian chạy](/docs/developer-guide/architecture/runtime-lifecycle/).

## Đèn ban đêm

`argvus-session` phụ thuộc vào `hyprsunset>=0.4.0` và khởi động dịch vụ người dùng thượng nguồn thông qua mục tiêu phiên, mà không bật trình nền thứ hai. `argvus-night-light-init.service` áp dụng trạng thái đã lưu khi nhập; bộ hẹn giờ đánh giá các lịch trình cục bộ cố định mỗi phút và sau khi thay đổi đồng hồ/múi giờ. Khi tắt lập lịch, các kiểm tra định kỳ không thay đổi trạng thái thủ công. Dịch vụ thượng nguồn tuân theo `graphical-session.target` khi đăng xuất.

Gói drop-in đã đóng gói khởi động Hyprsunset với `--identity` và dịch vụ-local `XDG_CONFIG_HOME`/`XDG_CONFIG_DIRS` trỏ đến `/usr/share/argvus/session/config/night-light`, mà cấu hình của nó không chứa hồ sơ gốc nào. Điều này tránh các bộ lập lịch cạnh tranh và khởi động ở giá trị mặc định 6000 K của upstream. Nó cũng áp dụng cho dịch vụ upstream bên ngoài ARGVUS trong khi được cài đặt; các tệp Hyprsunset cá nhân được giữ nguyên. Các ghi đè systemd của người dùng có thể được ưu tiên. Không có cài đặt gói nào ghi vào HOME. Các tùy chọn có trong `/displays/night_light`, ghi đè trong `$XDG_RUNTIME_DIR/argvus/night-light/`; xem `argvus config display night-light status`.

Phiên làm việc tải ngôn ngữ LANG từ `$XDG_CONFIG_HOME/locale.conf` của người dùng đã đăng nhập (mặc định `~/.config/locale.conf`) trước khi nhập môi trường. Điều này áp dụng cho TTY và các trình quản lý đăng nhập đồ họa. Thay đổi ngôn ngữ yêu cầu đăng xuất và đăng nhập lại; `/etc/locale.conf` không được thay đổi.

Không có người dùng hợp lệ `LANG`, phiên làm việc sẽ bắt đầu bằng tiếng Anh ngay cả khi cục bộ máy chủ là tiếng Bồ Đào Nha. Nó sử dụng `en_US.UTF-8` khi được tạo ra và `C.UTF-8` trong các trường hợp khác, mà không tạo cấu hình người dùng. Việc xác định ngôn ngữ diễn ra trước khi chiếu cấu hình và khởi động máy tính để bàn. Phiên làm việc sẽ xóa `LC_ALL` kế thừa và thay thế các biến ngôn ngữ trong môi trường kích hoạt người dùng systemd và D-Bus, bao gồm `LANGUAGE`. Các danh mục khu vực từ cùng một locale.conf được giữ nguyên. Các tệp ngôn ngữ ARGVUS cũ bị bỏ qua.

Phiên làm việc đọc bản phân công TZ cá nhân từ `$XDG_CONFIG_HOME/environment.d/20-timezone.conf` trước khi khởi động Hyprland và nhập nó vào môi trường dịch vụ người dùng và D-Bus. Nó xác thực tên zoneinfo và không bao giờ thực thi tệp. Một lần đăng nhập mới áp dụng các thay đổi múi giờ cho các ứng dụng.


## 

Việc thu gọn sử dụng không gian làm việc `special:argvus-minimized` đã được dành riêng. Không sử dụng không gian làm việc đó một cách thủ công. Quá trình `argvus windows service` ghi nhận danh tính, không gian làm việc/màn hình gốc, hình học, chế độ toàn màn hình/tối đa hóa và trạng thái ghim trong một đăng ký thời gian chạy cụ thể cho từng phiên bản compositor dưới `$XDG_RUNTIME_DIR/argvus`. Bản ghi tồn tại sau khi dịch vụ khởi động lại hoặc tải lại cấu hình, nhưng không vượt quá các phiên bản compositor. Đóng cửa sổ sẽ xóa bản ghi của nó. Nếu một màn hình biến mất, việc khôi phục sẽ sử dụng một đầu ra có sẵn. Thanh phục hồi bị mất hoặc thất bại sẽ ngăn việc thu gọn mới; việc khôi phục thất bại sẽ giữ lại bản ghi và thanh phục hồi.

Phiên làm việc sở hữu `argvus-windows.service` và `argvus-window-bar.service`. Cái sau giữ con Waybar của nó trong trạng thái ngủ trong Tile. Plugin hyprbars được đóng gói bởi `argvus-hyprland`, được xây dựng cho ABI Hyprland 0.57.0 trên x86_64; nó không được biên dịch trong thư mục nhà của người dùng. Xây dựng lại plugin với cập nhật ABI trình hợp nhất.

Phiên làm việc truyền bá cài đặt ngôn ngữ UTF-8 đã chọn cho tất cả mười ngôn ngữ ARGVUS, bao gồm cả tiếng Trung, tiếng Nhật và tiếng Hàn. Việc chọn danh mục được xử lý bởi `argvus i18n`; tính khả dụng của ngôn ngữ hệ thống và việc thay thế phông chữ là các yêu cầu riêng biệt.
