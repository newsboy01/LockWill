# LockWill — Quy Trình & Tiến Trình Dự Án

> **Mục tiêu:** Ứng dụng kiểm soát thời gian sử dụng điện thoại/máy tính bảng kết hợp giáo dục (Earn-to-Play) cho học sinh Tiểu học (Lớp 1 – Lớp 5) theo chương trình GDPT 2018.  
> **Nền tảng:** Android trước (Flutter + Kotlin Native), mở rộng iOS/iPadOS (Swift `FamilyControls`) ở giai đoạn sau.

---

## Quy ước đánh dấu trạng thái
- `[x]` **Đã làm** — Hoàn thành ở mức hiện tại
- `[ ]` **Chưa làm** — Nằm trong kế hoạch sắp tới
- `[!]` **Cần sửa / Lưu ý kỹ thuật** — Lỗi, hạn chế hoặc điểm cần xử lý trước khi chạy thật
- `[+]` **Cần cải tiến** — Ý tưởng nâng cấp trải nghiệm hoặc mở rộng tính năng

---

## Giai đoạn 1: Khởi tạo & Kiến trúc Đa nền tảng (Android trước, sẵn sàng iOS)
- [x] Chốt ý tưởng, cơ chế bậc thang đổi giờ trong ngày và giao diện thích ứng theo độ tuổi (Lớp 1–2 Audio-First, Lớp 3–5 Gamification)
- [x] Tạo ảnh demo UI minh họa (`docs/demo/demo_kid_ui.png`, `docs/demo/demo_parent_ui.png`)
- [x] Dựng khung project Flutter (`pubspec.yaml`, cấu trúc `lib/core`, `lib/features`)
- [x] Thiết kế lớp trừu tượng `DeviceLockService` qua `MethodChannel` để tách biệt phần khóa OS (Android Kotlin hiện tại / iOS Swift tương lai)
- [x] Tạo GitHub Actions workflow `.github/workflows/build_apk.yml` để build APK tự động trên Cloud (không cần cài Android Studio trên máy)
- [ ] `[!]` **Cần đẩy lên GitHub:** Tạo repo GitHub và push code để GitHub Actions xuất file `app-release.apk` (hoặc cài Flutter/Android SDK nếu muốn build offline).

## Giai đoạn 2: Cơ chế Khóa Thiết bị & Đếm Giờ (Android Native)
- [x] Khai báo quyền trong `AndroidManifest.xml` (`PACKAGE_USAGE_STATS`, `SYSTEM_ALERT_WINDOW`, `FOREGROUND_SERVICE`, `RECEIVE_BOOT_COMPLETED`)
- [x] Tạo khung `MainActivity.kt`, `UsageMonitorService.kt`, `LockOverlayManager.kt`
- [ ] Hoàn thiện logic đọc `UsageStatsManager` theo thời gian thực (tách biệt app Whitelist vs app Giải trí bị giám sát)
- [ ] Hoàn thiện màn hình hướng dẫn phụ huynh cấp quyền đặc biệt trên Android (Usage Access, Display over other apps, Battery Optimization)
- [ ] `[!]` **Cần xử lý đặc thù hãng máy:** Xiaomi (MIUI/HyperOS), Oppo (ColorOS), Samsung hay tự tắt Foreground Service chạy ngầm — cần thêm hướng dẫn tắt tối ưu pin & `DeviceAdminReceiver` chống trẻ tự gỡ app.
- [ ] `[+]` **Cải tiến tương lai (iOS):** Xin quyền Apple `FamilyControls` entitlement và viết Swift plugin tương thích `DeviceLockService`.

## Giai đoạn 3: Thuật toán Đổi giờ & Dữ liệu GDPT 2018 Thời gian thực
- [x] Xây dựng `EscalationEngine` (tăng dần số câu & độ khó qua từng lượt xin thêm giờ trong ngày, tự động reset lúc `00:00`)
- [x] Xây dựng `CurriculumService` (tính tuần học thực tế theo năm học, lọc theo Lớp 1–5 & 3 bộ sách: *Kết nối tri thức*, *Chân trời sáng tạo*, *Cánh Diều*)
- [x] Tạo bộ dữ liệu câu hỏi mẫu `assets/data/sample_questions.json` (Lớp 1 & Lớp 3)
- [ ] Xây dựng bộ sinh biến thể Toán học (Template Engine) để đổi số ngẫu nhiên, tránh trẻ học vẹt đáp án
- [ ] Chuẩn hóa đầy đủ ngân hàng câu hỏi 35 tuần học cho cả 5 khối lớp và đồng bộ từ Cloud (Supabase/Firebase) + Offline Cache (SQLite)
- [ ] `[+]` **Cải tiến:** Tích hợp AI tạo giải thích gợi ý thông minh hoặc câu đố vui theo chủ đề ngày lễ/mùa trong năm.

## Giai đoạn 4: Trải nghiệm Trẻ em (UI/UX + Âm thanh) & Phụ huynh
- [x] Màn hình Khóa (`LockScreen`) với nhân vật đồng hành và trạng thái lượt đổi giờ
- [x] Màn hình Làm bài (`QuizScreen`) hỗ trợ nút lớn cho trẻ nhỏ, gợi ý nhẹ nhàng khi làm sai, không phạt nặng
- [x] Khung `AudioGuideService` đọc câu hỏi/hướng dẫn cho trẻ Lớp 1–2
- [x] Cổng Phụ huynh (`ParentGateDialog`) bảo vệ bằng PIN/phép tính và `ParentDashboardScreen`
- [ ] Thu âm hoặc tạo sẵn file MP3 giọng đọc tiếng Việt tự nhiên cho toàn bộ câu hỏi Lớp 1–2 (tránh giọng TTS mặc định bị khô cứng)
- [ ] Thêm dạng bài kéo-thả, nối hình, điền số trực quan thay vì chỉ chọn đáp án
- [ ] Thêm nhạc nền nhẹ nhàng (có nút tắt/bật) và hiệu ứng âm thanh/pháo hoa khi trả lời đúng
- [ ] `[+]` **Cải tiến:** Thêm hệ thống nuôi thú cưng/nhân vật đồng hành và bảng thành tích cho khối Lớp 3–5.

## Giai đoạn 5: Kiểm thử thực tế & Phát hành
- [ ] Kiểm thử với trẻ Lớp 1 (kiểm tra tốc độ đọc, kích thước nút, khả năng tự hiểu thao tác không cần bố mẹ chỉ)
- [ ] Kiểm thử với trẻ Lớp 4–5 (kiểm tra độ khó bài tập và khả năng chống lách luật khóa app)
- [ ] Đóng gói bản cài đặt APK thử nghiệm nội bộ
