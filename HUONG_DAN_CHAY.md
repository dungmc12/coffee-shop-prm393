# HƯỚNG DẪN CHẠY ỨNG DỤNG (Frontend + Backend)

Ứng dụng gồm **2 phần** phải chạy cùng lúc:

```
Flutter (app điện thoại)  ──HTTP──►  Backend .NET (Web API)  ──►  SQL Server
```

---

## BƯỚC 1 — Chạy Backend (.NET + SQL Server)

> Cần: đã cài .NET SDK và SQL Server Express (máy bạn đã có sẵn).

Mở **PowerShell**, gõ:

```powershell
cd e:\android\Mobile_application_development\backend\CoffeeShopApi
dotnet run
```

- Lần đầu chạy, backend **tự tạo database `CoffeeShopDb`** trong SQL Server và nạp sẵn 17 sản phẩm + tài khoản demo.
- Khi thấy dòng `Now listening on: http://0.0.0.0:5266` là backend đã chạy.
- **Để nguyên cửa sổ này** (đừng tắt) trong suốt lúc demo.

**Kiểm tra nhanh:** mở trình duyệt vào `http://localhost:5266/api/products` — nếu thấy danh sách sản phẩm dạng JSON là OK.

### Nếu kết nối SQL Server lỗi
Mở file `backend/CoffeeShopApi/appsettings.json`, sửa dòng `DefaultConnection` cho đúng tên SQL Server của bạn:
- SQL Server Express: `Server=.\\SQLEXPRESS;...`
- LocalDB: `Server=(localdb)\\MSSQLLocalDB;...`
- SQL Server mặc định: `Server=.;...`

---

## BƯỚC 2 — Chạy App Flutter

Mở **PowerShell thứ 2** (không tắt cái backend):

```powershell
cd e:\android\Mobile_application_development
flutter run
```

Chọn **máy ảo Android** (hoặc điện thoại thật).

- App gọi backend qua địa chỉ `http://10.0.2.2:5266` (10.0.2.2 = "localhost của máy tính" khi nhìn từ máy ảo Android).
- **Tài khoản demo:** email `demo@coffee.com` / mật khẩu `123456`.

### Nếu chạy trên ĐIỆN THOẠI THẬT (không phải máy ảo)
Điện thoại không hiểu `10.0.2.2`. Cần:
1. Điện thoại và máy tính **cùng mạng Wifi**.
2. Tìm IP máy tính: chạy `ipconfig`, lấy dòng `IPv4 Address` (vd `192.168.1.5`).
3. Sửa file `lib/services/api_service.dart`, đổi:
   ```dart
   static const String baseUrl = 'http://192.168.1.5:5266/api';
   ```
4. Mở firewall cổng 5266 (nếu bị chặn).

---

## WEB ADMIN (trang quản trị cho quản lý)

Sau khi backend chạy, mở trình duyệt vào:

```
http://localhost:5266/admin.html
```

- **Đăng nhập:** tài khoản `admin` / mật khẩu `123456`.
- Gồm 4 phần: **Thống kê** (doanh thu 7 ngày, top sản phẩm), **Sản phẩm** (thêm/sửa/xóa - CRUD),
  **Đơn hàng** (xem tất cả đơn, xác nhận thanh toán/hủy), **Tin nhắn** (trả lời chat của khách,
  khách thấy ngay trong app).

---

## THANH TOÁN ONLINE VNPay (sandbox - thẻ test, không mất tiền thật)

### Bước 1: Đăng ký tài khoản test VNPay (1 lần, miễn phí)
1. Vào https://sandbox.vnpayment.vn/devreg/ điền email đăng ký.
2. VNPay gửi email chứa **Terminal ID (vnp_TmnCode)** và **Secret Key (vnp_HashSecret)**.
3. Mở `backend/CoffeeShopApi/appsettings.json`, điền 2 giá trị đó vào mục `Vnpay`.
4. Chạy lại backend.

### Bước 2: Thanh toán trong app
1. Đặt 1 đơn hàng -> vào mục **Đơn hàng** -> bấm vào đơn "Chờ thanh toán".
2. Chọn **"Thanh toán online (VNPay)"** -> trình duyệt mở trang VNPay.
3. Chọn "Thẻ nội địa" -> nhập **thẻ test** của VNPay:
   - Ngân hàng: **NCB**
   - Số thẻ: `9704198526191432198`
   - Tên: `NGUYEN VAN A` - Ngày phát hành: `07/15` - OTP: `123456`
4. Thanh toán xong VNPay tự gọi về backend -> đơn chuyển **"Đã thanh toán"**.
   Quay lại app, kéo làm mới danh sách đơn để thấy trạng thái mới.

---

## Tóm tắt khi DEMO với thầy
1. Mở SQL Server (đang chạy sẵn dạng dịch vụ).
2. Chạy backend: `dotnet run` trong thư mục `backend/CoffeeShopApi`.
3. Chạy app: `flutter run`.
4. Đăng nhập và thao tác — mọi dữ liệu (user, đơn hàng) đều lưu **thật vào SQL Server** qua API .NET.

> Có thể mở **SQL Server Management Studio (SSMS)** xem database `CoffeeShopDb` để chứng minh dữ liệu được lưu thật vào SQL Server.
