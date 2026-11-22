# Tool Filter — Bản portable

Công cụ **chỉ đọc** giúp rà soát dung lượng ổ **C:** và chia thành 3 nhóm:
🟢 An toàn · 🟡 Xem xét · 🔴 Không xóa (khóa).

> Tool **không có chức năng xóa**. Bạn tự quyết định và tự xóa bằng File Explorer.

## Chạy

1. Giải nén **toàn bộ** thư mục này (đừng chỉ lấy file `ToolFilter.exe`).
2. Nhấp đôi **`ToolFilter.exe`**.
3. Lần đầu: bấm **“Quét lại ổ C:”** (khoảng 2–4 phút).
4. Khi cửa sổ quét đóng, bấm **“Tải lại dữ liệu”**.
5. Lọc theo nhóm, chọn mục → **“Thêm vào danh sách của tôi”** → **“Xuất danh sách (CSV)”**.
6. Tự xóa bằng tay trong Explorer (nên Shift+Delete với nhóm An toàn).

## Yêu cầu

- Windows 10 / 11 (64-bit).
- PowerShell 5.1 — có sẵn trong Windows, không cần cài thêm.
- Không cần quyền Administrator (một số thư mục hệ thống sẽ không đọc được và được ghi chú).

## Gặp lỗi?

Chạy **`Troubleshoot.cmd`** để mở tool kèm cửa sổ console và xem thông báo lỗi.

## Gỡ cài đặt

Xóa thư mục này. Tool không ghi vào registry, không cài service, không gửi dữ liệu đi đâu.
Dữ liệu quét nằm trong `data\index.json` và `data\scan.log` — xóa kèm nếu muốn.

## Giấy phép

MIT — xem `LICENSE`.
