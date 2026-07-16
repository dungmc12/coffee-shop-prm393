# ☕ Coffee Shop — Ứng dụng đặt đồ uống

Đồ án cá nhân môn **PRM393 (Flutter Mobile Programming)**.

> **Đề tài:** Ứng dụng đặt đồ uống (cà phê, trà, sinh tố...) cho khách hàng của một quán cà phê.
> **Đối tượng sử dụng:** Khách mua đồ uống (app mobile) và người quản lý quán (web quản trị).

---

## 1. Mô tả ứng dụng

Coffee Shop là ứng dụng di động giúp khách hàng xem thực đơn, đặt đồ uống, thanh toán và
trao đổi với cửa hàng. Toàn bộ dữ liệu lấy từ **server thật (REST API + SQL Server)**, không
hardcode. Người quản lý có **web quản trị** riêng để quản lý sản phẩm, đơn hàng, chat và xem
thống kê doanh thu.

Hệ thống gồm 3 phần dùng **chung một backend API**:
- **App Flutter** (khách hàng) — Android
- **Web quản trị** (chủ quán) — HTML/CSS/JS
- **Backend API + Database** — ASP.NET Core + SQL Server

---

## 2. Chức năng chính

### App khách hàng (Flutter)
- Đăng ký / Đăng nhập (mật khẩu **mã hóa BCrypt**)
- Bảo mật: **khóa tài khoản khi sai mật khẩu 5 lần**, **quên mật khẩu** (đặt lại qua email + SĐT), đổi mật khẩu trong hồ sơ
- Xem thực đơn theo loại, **tìm kiếm không dấu** ("caphe" → "Cà phê")
- Giỏ hàng, chọn size, đặt hàng
- **Thanh toán online** qua trang thanh toán (WebView) — chuyển khoản tự xác nhận; **tiền mặt do admin xác nhận**
- Xem lịch sử đơn hàng, trạng thái đơn
- **Chat** trực tiếp với cửa hàng (cập nhật gần thời gian thực)
- Thông báo trạng thái đơn hàng
- Quản lý hồ sơ cá nhân

### Web quản trị (chủ quán)
- **CRUD sản phẩm** (thêm / sửa / xóa đồ uống)
- Quản lý đơn hàng, **xác nhận thanh toán tiền mặt**
- **Chat 2 chiều** trả lời khách
- **Thống kê**: doanh thu 7 ngày, món bán chạy, số đơn / khách

---

## 3. Công nghệ sử dụng

| Thành phần | Công nghệ |
|---|---|
| **Frontend (Mobile)** | Flutter + Dart |
| **State management** | Provider (ChangeNotifier) |
| **Networking** | package `http` + REST API, async/await |
| **Backend** | ASP.NET Core Web API (.NET 10, C#) |
| **Database** | **SQL Server** (Entity Framework Core) |
| **Bảo mật** | BCrypt.Net (hash mật khẩu) |
| **Lưu cục bộ** | SharedPreferences (trạng thái đăng nhập) |
| **Tài liệu API** | Swagger UI |
| **Web quản trị** | HTML + CSS + JavaScript thuần (fetch API) |

> Không dùng SQLite làm database chính (theo yêu cầu đề).

---

## 4. Cấu trúc thư mục

```
Mobile_application_development/
├── lib/                       # Source code Flutter (app)
│   ├── models/                # Model: User, Product, Order, Message
│   ├── providers/             # State management (Auth, Product, Cart, Order)
│   ├── services/              # ApiService — lớp gọi REST API
│   ├── screens/               # Các màn hình (login, home, cart, orders, chat...)
│   └── theme/                 # Giao diện, màu sắc
├── backend/CoffeeShopApi/     # Source code Backend (ASP.NET Core)
│   ├── Controllers/           # Auth, Products, Orders, Payments, Messages, Admin
│   ├── Models/                # Thực thể ánh xạ DB
│   ├── Data/AppDbContext.cs   # EF Core + dữ liệu mẫu
│   ├── wwwroot/admin.html     # Web quản trị
│   └── schema.sql             # Cấu trúc DB + dữ liệu mẫu (SQL Server)
└── README.md
```

---

## 5. Hướng dẫn chạy

### Yêu cầu
- Flutter SDK, Android Studio (máy ảo) hoặc điện thoại Android
- .NET 10 SDK
- SQL Server (Express) + SSMS

### Bước 1 — Chạy Backend
```bash
cd backend/CoffeeShopApi
dotnet run
```
- Backend chạy ở `http://localhost:5266`
- Lần đầu chạy sẽ **tự tạo database + dữ liệu mẫu** (EF Core).
  Nếu muốn tạo tay: mở `schema.sql` trong SSMS và chạy.
- Sửa chuỗi kết nối SQL trong `appsettings.json` nếu cần.

### Bước 2 — Chạy App Flutter
```bash
flutter pub get
flutter run
```
> Địa chỉ backend trong `lib/services/api_service.dart`:
> - Máy ảo Android: `http://10.0.2.2:5266/api` (mặc định)
> - Điện thoại thật (hotspot máy tính): đổi sang IP máy tính, ví dụ `http://192.168.137.1:5266/api`

---

## 6. Danh sách API (RESTful)

Xem đầy đủ và test trực tiếp tại **Swagger**: `http://localhost:5266/swagger`

| Method | Endpoint | Chức năng |
|---|---|---|
| POST | `/api/auth/register` | Đăng ký |
| POST | `/api/auth/login` | Đăng nhập |
| PUT  | `/api/auth/{id}` | Cập nhật hồ sơ |
| PUT  | `/api/auth/{id}/password` | Đổi mật khẩu |
| POST | `/api/auth/reset` | Quên / đặt lại mật khẩu |
| GET  | `/api/products` | Danh sách sản phẩm |
| POST | `/api/products` | Thêm sản phẩm (admin) |
| PUT  | `/api/products/{id}` | Sửa sản phẩm (admin) |
| DELETE | `/api/products/{id}` | Xóa sản phẩm (admin) |
| POST | `/api/orders` | Tạo đơn hàng |
| GET  | `/api/orders?userId=` | Đơn hàng của khách |
| PUT  | `/api/orders/{id}/status` | Cập nhật trạng thái đơn |
| GET  | `/api/payments/create-url?orderId=` | Tạo link thanh toán VNPay (ký HMAC-SHA512) |
| GET  | `/api/messages?userId=` | Lấy đoạn chat |
| POST | `/api/messages` | Khách gửi tin nhắn |
| GET  | `/api/messages/conversations` | Danh sách hội thoại (admin) |
| POST | `/api/messages/reply` | Admin trả lời (web) |
| GET  | `/admin/orders` | Tất cả đơn hàng (admin) |
| GET  | `/admin/stats` | Thống kê doanh thu, món bán chạy |

---

## 7. Tài khoản test

| Nơi dùng | Tài khoản | Mật khẩu |
|---|---|---|
| App khách hàng | `demo@coffee.com` | `123456` |
| Web quản trị (`/admin.html`) | `admin` | `123456` |

> Có thể tự đăng ký tài khoản mới ngay trong app.

---

## 8. Link

- **Mã nguồn (GitHub):** https://github.com/dungmc12/coffee-shop-prm393
- **Tải app (itch.io):** https://dungmc12.itch.io/coffee-shop
- **Video demo (YouTube):** _(đang cập nhật)_

---

*Đồ án cá nhân — PRM393, FPT University.*
