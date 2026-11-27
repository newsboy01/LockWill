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
- [x] Tạo GitHub Actions workflow `.github/workflows/build_web.yml` để xuất bản bản Web Demo lên GitHub Pages (`0 MB` cài đặt)
- [ ] `[!]` **Cần đẩy lên GitHub:** Tạo repo GitHub và push code để GitHub Actions xuất file `app-release.apk` (hoặc cài Flutter/Android SDK nếu muốn build offline).

## Giai đoạn 2: Cơ chế Khóa Thiết bị & Đếm Giờ (Android Native)
- [x] Khai báo đầy đủ quyền trong `AndroidManifest.xml` (`PACKAGE_USAGE_STATS`, `SYSTEM_ALERT_WINDOW`, `FOREGROUND_SERVICE_SPECIAL_USE`, `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED`, `QUERY_ALL_PACKAGES`)
- [x] Hoàn thiện `UsageMonitorService.kt` nâng cấp **Active Usage Timer** (chỉ trừ giây khi màn hình bật & bé đang mở app bị khóa; bảo lưu thời gian khi tắt máy) + **App Usage Tracker** ghi nhận đầy đủ app con đang mở, thời điểm mở và thời lượng dùng từng app
- [x] Thêm `LockWillAdminReceiver.kt` (`DeviceAdminReceiver`) chống trẻ tự gỡ cài đặt app + nút 1 chạm xin **Bỏ qua tối ưu hóa pin** (`REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`)
- [x] Thêm Gamification: tích **Sao thưởng (`⭐`)**, đổi phụ kiện bạn Cú mèo 3D (`Mũ cử nhân`, `Kính thông minh`, `Vương miện`) và nhạc nền êm dịu (`bgm_gentle.wav`) có nút bật/tắt
- [x] Nâng cấp trang Web Giám Sát & Phân Tích Học Tập (`web_parent_report/index.html`) hiển thị đầy đủ: con đang mở app gì, biểu đồ thời gian dùng từng app, cảnh báo tỷ lệ Giải trí/Học tập, bảng lịch sử sử dụng máy và nhật ký học tập theo Tên bé, Thiết bị, Vị trí
- [x] Mở rộng kho câu hỏi chuẩn GDPT 2018 (đặc biệt Lớp 1: Ghép vần, Hình học, Toán lời văn, Xem giờ, TN&XH, Đố vui) trong `assets/data/sample_questions.json`
- [x] Thêm `BootReceiver.kt` tự khởi chạy lại dịch vụ giám sát khi khởi động lại điện thoại/tablet
- [x] Thêm tính năng liệt kê toàn bộ App đã cài trên máy (`MainActivity.kt` → `getInstalledApps`) và hộp thoại **Chọn App bị khóa** trong `ParentDashboardScreen`
- [ ] `[!]` **Cần xử lý đặc thù hãng máy:** Xiaomi (MIUI/HyperOS), Oppo (ColorOS), Samsung hay tự tắt Foreground Service chạy ngầm — cần thêm hướng dẫn tắt tối ưu pin & `DeviceAdminReceiver` chống trẻ tự gỡ app.
- [ ] `[+]` **Cải tiến tương lai (iOS):** Xin quyền Apple `FamilyControls` entitlement và viết Swift plugin tương thích `DeviceLockService`.

## Giai đoạn 3: Thuật toán Đổi giờ & Dữ liệu GDPT 2018 Thời gian thực
- [x] Xây dựng `EscalationEngine` (tăng dần số câu & độ khó qua từng lượt xin thêm giờ trong ngày, tự động reset lúc `00:00`)
- [x] Xây dựng `CurriculumService` (tính tuần học thực tế theo năm học, lọc theo Lớp 1–5 & 3 bộ sách: *Kết nối tri thức*, *Chân trời sáng tạo*, *Cánh Diều*)
- [x] Tạo bộ dữ liệu câu hỏi mẫu `assets/data/sample_questions.json` cho cả 5 khối lớp (Lớp 1–5) với nhiều dạng bài (`visual_count`, `compare_math`, `true_false`, `multiple_choice`, `fill_number`)
- [x] Xây dựng bộ sinh câu hỏi Toán & Logic động theo từng lớp trong `CurriculumService` kèm cơ chế chống trùng lặp câu hỏi trong phiên/ngày (`_askedPromptsInSession`)
- [x] Lưu trữ bền vững hồ sơ bé (tên, tuổi, lớp, bộ sách, vị trí, mã PIN) và trạng thái sử dụng trong ngày bằng `StorageService` (`shared_preferences`)
- [x] Tự động đồng bộ bộ câu hỏi mới nhất từ GitHub (`CurriculumService.syncQuestionsFromGitHub`) + lưu cache offline (không cần cài lại APK khi thêm câu hỏi mới)
- [x] Ghi nhận kết quả học tập theo từng phiên kèm thông tin thiết bị (hãng/model/Android qua `MainActivity.kt`) và vị trí, đồng bộ lên GitHub (`LearningReportService` → `docs/reports/learning_data.json`)
- [x] Xây dựng trang Web Tổng hợp & Phân tích Học tập miễn phí trên GitHub Pages (`web_parent_report/index.html` → `/parent-report/`) lọc theo Tên bé, Thiết bị, Vị trí, Lớp và tự động đánh giá điểm mạnh/điểm cần ôn thêm
- [ ] Chuẩn hóa đầy đủ ngân hàng câu hỏi 35 tuần học cho cả 5 khối lớp và đồng bộ từ Cloud (Supabase/Firebase) + Offline Cache (SQLite)
- [ ] `[+]` **Cải tiến:** Tích hợp AI tạo giải thích gợi ý thông minh hoặc câu đố vui theo chủ đề ngày lễ/mùa trong năm.

## Giai đoạn 4: Trải nghiệm Trẻ em (UI/UX + Âm thanh) & Phụ huynh
- [x] Màn hình Khóa (`LockScreen`) với nhân vật đồng hành và trạng thái lượt đổi giờ
- [x] Màn hình Làm bài (`QuizScreen`) hỗ trợ nút lớn cho trẻ nhỏ, gợi ý nhẹ nhàng khi làm sai, không phạt nặng
- [x] Khung `AudioGuideService` đọc câu hỏi/hướng dẫn cho trẻ Lớp 1–2
- [x] Cổng Phụ huynh (`ParentGateDialog`) bảo vệ bằng PIN/phép tính và `ParentDashboardScreen`
- [x] Ghim cố định thanh nút **"Làm bài / Học thêm nhận phút"** dưới đáy màn hình `LockScreen` (luôn nhìn thấy ngay không cần cuộn)
- [x] Lấy ảnh **App Icon gốc thật** của từng ứng dụng trên Android (`MainActivity.kt` → `drawableToBase64`) để hiển thị trong danh sách ứng dụng đã mở khóa (`LockScreen`, `CelebrationDialog`) và hộp thoại chọn app khóa (`ParentDashboardScreen`)
- [x] Cho phép phụ huynh chọn **Chế độ chủ đề câu hỏi** (`subjectMode`): **Ngẫu nhiên tất cả chủ đề** hoặc tập trung **1 chủ đề riêng** (*Toán, Tiếng Việt, Tiếng Anh, Tự nhiên & Xã hội, Đố vui*)
- [x] Hệ thống **Nuôi Cú Mèo 3D tương tác (`OwlHomeScreen` + `OwlPetState`)**: 11 cảm xúc (`idle, happy, love, giggle, sideEye, dizzy, angry, crying, eating, sleeping, encourage`), cảm ứng vuốt/chạm (nựng, massage, cù lét, chọc nhẹ, dỗ nín khóc), 4 chỉ số chăm sóc (Cho ăn, Đánh răng/Rửa mặt bọt bong bóng, Tắt đèn đi ngủ, Chơi đùa), Cấp độ (Lv/XP), và **Cửa hàng Sao** với 8 ngoại trang Anh hùng (**CSGT, CSCĐ, CSHS, Quân đội, Bác sĩ Y tế, Lính Cứu hỏa, Phi hành gia, Siêu anh hùng**), 4 màu lông, 5 phụ kiện, 4 phông nền đồng bộ toàn ứng dụng
- [x] Đồng bộ 2 chiều đồng hồ đếm ngược thời gian giải trí thật giữa Android Native và `LockScreen`, chế độ **Đang mở khóa** (nền xanh tươi + danh sách app mở khóa 🔓 bấm mở trực tiếp) và **Hộp thoại Chúc mừng 3D pháo hoa (`CelebrationDialog`)** sau khi làm xong bài
- [x] Chống bấm bừa cho Lớp 1 (tạm khóa 1.5s & làm mờ nút chọn sai khi đọc gợi ý), đọc to cả đề lẫn các lựa chọn đáp án, và **Hàng đợi đồng bộ Offline (`Offline Sync Queue`)** tự đẩy bù lên GitHub khi có mạng lại
- [x] Dọn sạch dữ liệu mẫu trên `learning_data.json` (chỉ giữ dữ liệu thật), thêm bộ lọc **Khoảng thời gian (Hôm nay / 7 ngày / 30 ngày / Tất cả)** và **Biểu đồ xu hướng học tập theo ngày** trên trang Giám Sát Phụ Huynh
- [x] Chuẩn hóa Responsive UI/UX toàn bộ ứng dụng (`ResponsiveLayout`) cho điện thoại nhỏ, điện thoại lớn, máy tính bảng (Tablet) và xoay ngang (bố cục 2 cột trên Tablet ngang, chống tràn chữ/tràn khung, giới hạn `textScaler`, chuẩn hóa đơn vị `dp` cho màn hình khóa Overlay Android)
- [x] Màn hình Thiết lập Lần Đầu (`OnboardingScreen`) khi mới cài app: nhập Tên bé, Tuổi, Kiến thức Lớp, Bộ sách, Tên Bố/Mẹ giám sát, Vị trí, Mã PIN để chọn lọc thư viện câu hỏi ngay từ đầu
- [x] Mở rộng giới hạn trần tối đa mỗi ngày lên **480 phút (8 giờ)** và cho phép tùy chỉnh thời lượng mỗi lần gia hạn (`5–30 phút`) + số câu hỏi cơ bản tự động tỷ lệ theo thời lượng và tăng tiến dần theo lượt (giữ chuẩn kiến thức lớp hiện tại)
- [x] Tập trung mở rộng đa dạng kiến thức **Lớp 1** (Tiếng Việt ghép vần & chính tả `c/k`, `g/gh`; Tiếng Anh Lớp 1 màu sắc/con vật/số đếm/đồ dùng/chào hỏi; Toán lời văn/hình học/xem giờ/lịch tuần; TN&XH; Đạo đức; Đố vui)
- [x] Sửa lỗi CI build trên Ubuntu 24.04 (tạo sẵn bộ icon PNG đa kích thước `assets/icon/resized/ic_*.png` thay cho lệnh `convert`)
- [x] Thiết kế lại App Icon 3D (`assets/icon/app_icon.png`) và tự động tạo đầy đủ icon launcher Android (`mipmap-mdpi..xxxhdpi`) & Web (`favicon.png`, `Icon-192/512`) trong CI
- [x] Nhân vật Cú mèo vẽ khối phong cách hoạt hình 3D (`AnimatedOwlMascot`: đổ bóng khối, chớp mắt, vỗ cánh, nhảy mừng tỏa sao khi đúng, lắc khích lệ khi sai) và nút bấm nổi khối 3D (`Tactile3DButton`)
- [x] Đa dạng 7 dạng câu hỏi tương tác cho Lớp 1–5: Trắc nghiệm, Đếm hình, So sánh (`> < =`), Đúng/Sai, Tự nhập số bằng bàn phím, Kéo thả (`drag_drop`), và Ghép chữ/Ghép vần (`word_build`)
- [x] Tùy chỉnh giọng đọc Tiếng Việt trong Cài đặt Phụ huynh (chọn giọng `vi-VN` trên thiết bị, tốc độ nhanh/chậm, ngữ điệu trầm/tươi vui, kiểu hiệu ứng âm thanh, nút Nghe thử trực tiếp)
- [x] Tối ưu kiến thức Lớp 1 chuẩn GDPT 2018 (ghép vần Tiếng Việt, nhận diện hình học, dãy số, cộng/trừ phạm vi 10–18, TN&XH, đố vui)
- [x] Hiệu ứng phản hồi khi trả lời (rung nhẹ + gợi ý khi sai, phóng to + đổi màu xanh khi đúng, đếm chuỗi combo `🔥`)
- [x] Hiệu ứng âm thanh `.wav` (`correct.wav`, `wrong.wav`, `unlock.wav`) kết hợp giọng đọc tiếng Việt (`AudioGuideService`) và nút tắt/bật âm thanh
- [x] Cho phép phụ huynh sửa trực tiếp Tên, Tuổi, Lớp, Bộ sách, Tuần học, Quỹ giờ và Mã PIN trong `ParentDashboardScreen`
- [ ] Thu âm hoặc tạo sẵn file MP3 giọng đọc tiếng Việt tự nhiên cho toàn bộ câu hỏi Lớp 1–2 (tránh giọng TTS mặc định bị khô cứng)
- [ ] Thêm nhạc nền nhẹ nhàng (có nút tắt/bật)
- [ ] `[+]` **Cải tiến:** Thêm hệ thống nuôi thú cưng/nhân vật đồng hành và bảng thành tích cho khối Lớp 3–5.

## Giai đoạn 5: Kiểm thử thực tế & Phát hành
- [ ] Kiểm thử với trẻ Lớp 1 (kiểm tra tốc độ đọc, kích thước nút, khả năng tự hiểu thao tác không cần bố mẹ chỉ)
- [ ] Kiểm thử với trẻ Lớp 4–5 (kiểm tra độ khó bài tập và khả năng chống lách luật khóa app)
- [ ] Đóng gói bản cài đặt APK thử nghiệm nội bộ
