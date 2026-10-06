# Document Scanner (Flutter & Google ML Kit)

Ứng dụng số hóa tài liệu thông minh xây dựng bằng **Flutter** và thư viện **`flutter_doc_scanner`** theo đúng quy trình và tính năng mô tả trong slide thuyết trình.

---

## 🌟 Chức năng nổi bật (Theo Slide)

1. **Cấu hình phiên quét (Bước 1)**:
   - Tùy chỉnh giới hạn số trang tối đa (1 - 50 trang).
   - Chế độ quét nhanh 1 ảnh tài liệu (`useAutomaticSinglePictureProcessing`).
   - Lựa chọn định dạng xuất tài liệu: Tất cả, Chỉ PDF, hoặc Chỉ Ảnh (PNG/JPEG).

2. **Chụp tài liệu & Nhận diện tự động (Bước 2 & 3)**:
   - Tự động nhận diện 4 góc mép tài liệu trong khung hình camera.
   - Cắt bỏ phông nền và tự động căn chỉnh phối cảnh (perspective transform).

3. **Chỉnh sửa & Làm rõ ảnh (Bước 4)**:
   - Hỗ trợ xoay ảnh 90°, 180°, 270°.
   - Bộ lọc xử lý tài liệu thông minh: Làm sạch viền, Đen trắng (B&W), Tăng độ sắc nét.
   - Xử lý hoàn toàn trực tiếp trên thiết bị (On-device processing qua Google ML Kit / Apple VisionKit), bảo mật và không cần gửi dữ liệu lên server.

4. **Xuất và Lưu trữ (Bước 5)**:
   - Xuất file PDF hoặc hình ảnh chất lượng cao.
   - Hỗ trợ mở trực tiếp tài liệu (`open_filex`) và chia sẻ/lưu vào máy (`share_plus`).

---

## 🚀 Hướng dẫn cài đặt & Chạy ứng dụng

### 1. Chuẩn bị môi trường Android
1. Cài đặt **Android Studio** từ file `android-studio-...-windows.exe`.
2. Mở Android Studio để hoàn tất tải về **Android SDK** (API 34/35) và **Android SDK Command-line Tools**.
3. Cấp phép license Android bằng lệnh:
   ```bash
   flutter doctor --android-licenses
   ```

### 2. Kết nối thiết bị
- **Dùng điện thoại thật (Khuyên dùng)**:
  - Bật **Tùy chọn cho nhà phát triển** trên điện thoại.
  - Bật **Gỡ lỗi qua USB (USB Debugging)**.
  - Cắm cáp kết nối điện thoại với máy tính.
- **Hoặc dùng máy ảo (Emulator)**:
  - Mở **Device Manager** trong Android Studio, tạo một máy ảo có sẵn biểu tượng **Google Play Store**.

### 3. Chạy ứng dụng
Mở terminal trong thư mục `d:\Document_Scanner` và chạy:
```bash
flutter run
```
