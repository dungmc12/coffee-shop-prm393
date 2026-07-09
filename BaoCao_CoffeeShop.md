# BÁO CÁO KỸ THUẬT
## Đề tài: Ứng dụng đặt đồ uống "Coffee Shop"
### Môn: PRM393 – Mobile Application Development (Flutter)

> **Hướng dẫn dùng file này:** Mở bằng Word (hoặc dán nội dung vào Word), điền tên thành viên ở Mục 1 và Mục 7, chèn ảnh chụp màn hình ở phần Demo, rồi xuất ra PDF để nộp.

---

## 1. Giới thiệu nhóm (Team Introduction)

Nhóm gồm **3 thành viên**, cùng phát triển một ứng dụng đặt đồ uống trên nền tảng Flutter.

| STT | Họ và tên | Vai trò / Phụ trách | Đóng góp |
|----|-----------|---------------------|----------|
| 1 | _(Điền tên TV1)_ | Module Tài khoản (Auth) – Đăng nhập, Đăng ký, Hồ sơ | 33% |
| 2 | _(Điền tên TV2)_ | Module Sản phẩm & Giỏ hàng – Trang chủ, Chi tiết, Giỏ hàng | 33% |
| 3 | _(Điền tên TV3)_ | Module Đặt hàng & Tiện ích – Thanh toán, Lịch sử đơn, Bản đồ | 34% |

Cả nhóm cùng thống nhất kiến trúc, thiết kế cơ sở dữ liệu và phối hợp tích hợp các module.

---

## 2. Case Study (Mô tả bài toán nghiệp vụ)

**Lĩnh vực:** Bán hàng trực tuyến cho cửa hàng đồ uống (Coffee & Tea Shop).

**Bối cảnh:** Một chuỗi cửa hàng cà phê – trà sữa muốn có một ứng dụng di động giúp khách hàng tự đặt đồ uống mà không cần xếp hàng. Khách có thể:
- Tạo tài khoản, đăng nhập để quản lý thông tin cá nhân.
- Xem menu đồ uống, tìm kiếm và lọc theo loại (Cà phê, Trà, Trà sữa, Đá xay, Nước ép).
- Xem chi tiết, chọn size (S/M/L) và số lượng, thêm vào giỏ hàng.
- Đặt hàng kèm địa chỉ giao và phương thức thanh toán.
- Xem lại lịch sử các đơn đã đặt.
- Xem vị trí các cửa hàng trên bản đồ.

**Lợi ích:** Giảm thời gian chờ, tăng trải nghiệm khách hàng, lưu lại lịch sử mua hàng phục vụ chăm sóc khách hàng.

---

## 3. Phân tích nghiệp vụ & Thiết kế hệ thống (Business Analysis / System Design)

### 3.1. Yêu cầu chức năng (Functional Requirements)
1. FR1 – Đăng ký tài khoản mới (lưu vào CSDL).
2. FR2 – Đăng nhập / Đăng xuất.
3. FR3 – Xem và cập nhật hồ sơ cá nhân.
4. FR4 – Hiển thị danh sách sản phẩm từ CSDL.
5. FR5 – Tìm kiếm và lọc sản phẩm theo loại.
6. FR6 – Xem chi tiết sản phẩm, chọn size & số lượng.
7. FR7 – Thêm/sửa/xóa sản phẩm trong giỏ hàng, tự tính tổng tiền.
8. FR8 – Thanh toán: nhập địa chỉ, chọn phương thức, lưu đơn hàng vào CSDL.
9. FR9 – Xem lịch sử đơn hàng của người dùng.
10. FR10 – Xem vị trí cửa hàng trên bản đồ.

### 3.2. Yêu cầu phi chức năng (Non-functional Requirements)
- NFR1 – Giao diện thân thiện, đồng bộ (Material Design 3).
- NFR2 – Dữ liệu được lưu cục bộ, hoạt động offline (không cần Internet trừ bản đồ).
- NFR3 – Phản hồi nhanh, có hiệu ứng loading khi xử lý.
- NFR4 – Mã nguồn rõ ràng, có comment, dễ bảo trì.
- NFR5 – Kiểm thử tự động bằng Unit Test & Widget Test.

### 3.3. Kiến trúc ứng dụng (Architecture)
Ứng dụng áp dụng mô hình phân lớp kết hợp **Provider (gần với MVVM)**:

```
┌─────────────────────────────────────────┐
│  VIEW (screens/)  – các màn hình giao diện │
│        ↕ (lắng nghe & gọi)                 │
│  STATE (providers/) – Auth/Product/Cart    │  ← ChangeNotifier
│        ↕                                   │
│  DATA (database/) – DatabaseHelper (SQLite)│
│        ↕                                   │
│  MODEL (models/) – User/Product/Order...   │
└─────────────────────────────────────────┘
```

- **View:** Widget hiển thị, dùng `Consumer` / `context.watch` để tự cập nhật khi dữ liệu đổi.
- **Provider (State Management):** `AuthProvider`, `ProductProvider`, `CartProvider` kế thừa `ChangeNotifier`, gọi `notifyListeners()` để thông báo UI build lại.
- **DatabaseHelper:** lớp Singleton thao tác trực tiếp với SQLite (CRUD).
- **Model:** các lớp dữ liệu có `toMap()` / `fromMap()` để chuyển đổi với CSDL.

### 3.4. Thiết kế cơ sở dữ liệu (Database Design – SQLite)

**Bảng `users`**
| Cột | Kiểu | Ghi chú |
|----|------|--------|
| id | INTEGER PK AUTOINCREMENT | Khóa chính |
| name | TEXT | Họ tên |
| email | TEXT UNIQUE | Email (không trùng) |
| password | TEXT | Mật khẩu |
| phone | TEXT | Số điện thoại |
| address | TEXT | Địa chỉ |

**Bảng `products`**
| Cột | Kiểu | Ghi chú |
|----|------|--------|
| id | INTEGER PK | Khóa chính |
| name | TEXT | Tên đồ uống |
| price | REAL | Giá gốc |
| image | TEXT | Biểu tượng/ảnh |
| category | TEXT | Loại |
| description | TEXT | Mô tả |

**Bảng `orders`**
| Cột | Kiểu | Ghi chú |
|----|------|--------|
| id | INTEGER PK | Khóa chính |
| userId | INTEGER | FK → users.id |
| total | REAL | Tổng tiền |
| address | TEXT | Địa chỉ giao |
| paymentMethod | TEXT | Phương thức |
| status | TEXT | Trạng thái |
| createdAt | TEXT | Thời điểm đặt |

**Bảng `order_items`**
| Cột | Kiểu | Ghi chú |
|----|------|--------|
| id | INTEGER PK | Khóa chính |
| orderId | INTEGER | FK → orders.id |
| productName | TEXT | Tên món |
| size | TEXT | Size đã chọn |
| quantity | INTEGER | Số lượng |
| price | REAL | Đơn giá khi mua |

**Quan hệ:** `users 1 — N orders`, `orders 1 — N order_items`.

### 3.5. Công nghệ mới tự tìm hiểu (ngoài bài học)
- **`sqflite`** – thư viện CSDL SQLite cho Flutter (lưu dữ liệu thật trên thiết bị).
- **`provider`** – quản lý trạng thái theo mẫu ChangeNotifier.
- **`flutter_map` + OpenStreetMap** – hiển thị bản đồ **miễn phí, không cần API key** (thay cho Google Maps phải tính phí).
- **`intl`** – định dạng tiền tệ VND và ngày giờ.

### 3.6. Luồng giao diện (UI Flow)
```
Đăng nhập ──► Trang chủ ──► Chi tiết SP ──► (thêm vào) Giỏ hàng ──► Thanh toán ──► Đặt hàng thành công
   │              │                                                       │
   ▼              ▼                                                       ▼
Đăng ký      Bản đồ cửa hàng                                       Lịch sử đơn hàng
                                                                    Hồ sơ / Đăng xuất
```

---

## 4. Yêu cầu phát triển (Development)

- **UI Implementation:** 9 màn hình theo Material Design 3, theme tông cà phê đồng bộ.
- **State Management:** Provider (3 ChangeNotifier).
- **Database:** SQLite cục bộ với đầy đủ thao tác CRUD và transaction khi lưu đơn hàng.
- **Deployment:** Build Release APK bằng lệnh `flutter build apk --release`; chứng minh chạy ở Release Mode bằng `flutter run --release`.
- **Testing:**
  - **Unit Test** (`test/cart_provider_test.dart`): kiểm thử logic giỏ hàng (cộng phụ thu size, gộp món trùng, tính tổng tiền, xóa món).
  - **Widget Test** (`test/widget_test.dart`): kiểm thử màn Đăng nhập hiển thị đủ thành phần và báo lỗi khi email sai.
  - Kết quả: **7/7 test PASS**.

---

## 5. Demo ứng dụng

> Chèn ảnh chụp màn hình cho từng chức năng vào đây khi làm slide:
> 1. Đăng nhập / Đăng ký
> 2. Trang chủ + tìm kiếm + lọc loại
> 3. Chi tiết sản phẩm (chọn size, số lượng)
> 4. Giỏ hàng (tăng/giảm/xóa, tổng tiền)
> 5. Thanh toán + đặt hàng thành công
> 6. Lịch sử đơn hàng
> 7. Bản đồ cửa hàng
> 8. Hồ sơ + chỉnh sửa + đăng xuất
> 9. Kết quả chạy test (`flutter test`)

**Tài khoản demo:** email `demo@coffee.com` – mật khẩu `123456`.

---

## 6. Kết luận & Thảo luận

**Ưu điểm:**
- Đầy đủ luồng mua hàng end-to-end, dữ liệu lưu thật bằng SQLite.
- Áp dụng đúng kiến trúc phân lớp và Provider, mã nguồn rõ ràng có comment.
- Giao diện đẹp, đồng bộ; hoạt động offline; có kiểm thử tự động.

**Nhược điểm:**
- Mật khẩu lưu dạng plain text (chưa mã hóa).
- Dữ liệu chỉ nằm trên 1 thiết bị (chưa đồng bộ đám mây).
- Chưa có vai trò quản trị (admin) để thêm/sửa sản phẩm.

**Bài học rút ra:**
- Hiểu cách quản lý trạng thái bằng Provider và vòng đời widget.
- Biết thiết kế và thao tác CSDL SQLite (CRUD, transaction).
- Biết viết Unit Test / Widget Test và build APK Release.

**Hướng phát triển nếu có thêm thời gian:**
- Mã hóa mật khẩu (hash), thêm đăng nhập bằng Google.
- Chuyển sang Firebase để đồng bộ nhiều thiết bị.
- Thêm trang quản trị, thanh toán online thật, thông báo đẩy (push notification).

---

## 7. Đánh giá đóng góp thành viên (Contribution)

| Hạng mục | Tổng | TV1 | TV2 | TV3 |
|----------|------|-----|-----|-----|
| Case Study Analysis | 100% | _%_ | _%_ | _%_ |
| Business analysis | 100% | _%_ | _%_ | _%_ |
| System design | 100% | _%_ | _%_ | _%_ |
| Implementation | 100% | _%_ | _%_ | _%_ |
| Documentation | 100% | _%_ | _%_ | _%_ |

> Điền tỉ lệ % thực tế của từng thành viên (tổng mỗi hàng = 100%).
