# Changelog

Mọi thay đổi đáng chú ý của dự án được ghi tại đây.
Định dạng dựa trên [Keep a Changelog](https://keepachangelog.com/vi/1.1.0/),
phiên bản theo [Semantic Versioning](https://semver.org/lang/vi/).

## [1.0.0] — 2026-11-22

### Thêm mới
- Giao diện desktop WPF nền sáng, tiếng Việt: lọc theo 3 nhóm **An toàn / Xem xét / Không xóa**.
- Quét toàn ổ C: ở chế độ **chỉ đọc** bằng `robocopy /L` (~2 phút cho ~700.000 file).
- Phân loại tự động theo quy tắc trong `Scan.ps1`; mọi đường dẫn lạ mặc định **khóa**.
- Tìm kiếm, lọc theo nhóm, sắp xếp theo dung lượng, nhấp đúp mở Explorer.
- “Danh sách của tôi” + xuất CSV (đường dẫn, dung lượng, nhóm, lý do).
- Bản portable: `ToolFilter.exe` + `resources\`, không cần cài đặt, không cần admin.
- Script build (`build\Build-Portable.ps1`) và workflow phát hành GitHub Actions.
