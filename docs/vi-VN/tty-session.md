---
title: phiên TTY
description: Khởi động ARGVUS thủ công từ một terminal ảo.
---

Sau khi đăng nhập trên TTY, bắt đầu phiên làm việc với:

```sh
argvus --start-desktop
```

Đây là điểm nhập thủ công được hỗ trợ từ `argvus session`. Nó sử dụng cùng `argvus start` và vòng đời dịch vụ người dùng giống như đăng nhập bằng giao diện đồ họa.

Để kiểm tra hoặc khởi động lại phiên kết quả, hãy sử dụng `argvus sessionctl status`, `argvus sessionctl reload` hoặc `argvus sessionctl logs`.

## Di chuyển từ `exec argvus-tty`

Các phiên bản trước đã cài đặt `argvus-tty` trong `/usr/bin`, và một số người dùng đã bắt đầu phiên làm việc từ `~/.profile` với `exec argvus-tty`. Tệp đó hiện nay là riêng tư và không còn trên `PATH`, vì vậy dòng này thất bại sau khi nâng cấp. Thay thế nó bằng điểm vào được hỗ trợ:

```sh
exec argvus --start-desktop
```

`argvus tty` là cùng một điểm vào. Xóa hoặc cập nhật dòng trong `~/.profile`, `~/.zprofile` hoặc `~/.bash_profile` trước lần đăng nhập tiếp theo trên TTY.
