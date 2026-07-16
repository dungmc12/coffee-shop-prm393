-- ============================================================
--  Coffee Shop - Cấu trúc cơ sở dữ liệu (SQL Server)
--  Database: CoffeeShopDb
--  Sinh ra theo đúng model Entity Framework Core của backend.
--  Chạy file này trong SSMS để tạo DB + dữ liệu mẫu (nếu muốn
--  tạo tay thay cho EnsureCreated của EF).
-- ============================================================

-- Tạo database nếu chưa có
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'CoffeeShopDb')
    CREATE DATABASE CoffeeShopDb;
GO

USE CoffeeShopDb;
GO

-- Xóa bảng cũ (theo đúng thứ tự khóa ngoại) để chạy lại được nhiều lần
IF OBJECT_ID('dbo.OrderItems', 'U') IS NOT NULL DROP TABLE dbo.OrderItems;
IF OBJECT_ID('dbo.Orders', 'U')     IS NOT NULL DROP TABLE dbo.Orders;
IF OBJECT_ID('dbo.Messages', 'U')   IS NOT NULL DROP TABLE dbo.Messages;
IF OBJECT_ID('dbo.Products', 'U')   IS NOT NULL DROP TABLE dbo.Products;
IF OBJECT_ID('dbo.Users', 'U')      IS NOT NULL DROP TABLE dbo.Users;
GO

-- ============================================================
--  BẢNG: Users (người dùng)
-- ============================================================
CREATE TABLE dbo.Users (
    Id               INT IDENTITY(1,1) PRIMARY KEY,
    Name             NVARCHAR(MAX)   NOT NULL,
    Email            NVARCHAR(450)   NOT NULL,   -- 450 để đánh index unique
    Password         NVARCHAR(MAX)   NOT NULL,   -- lưu chuỗi hash BCrypt
    Phone            NVARCHAR(MAX)   NOT NULL,
    Address          NVARCHAR(MAX)   NOT NULL,
    Avatar           NVARCHAR(MAX)   NOT NULL,
    FailedLoginCount INT             NOT NULL DEFAULT 0,  -- sai 5 lần -> khóa
    IsLocked         BIT             NOT NULL DEFAULT 0
);
GO
-- Email là duy nhất (không cho trùng)
CREATE UNIQUE INDEX IX_Users_Email ON dbo.Users(Email);
GO

-- ============================================================
--  BẢNG: Products (sản phẩm / đồ uống)
-- ============================================================
CREATE TABLE dbo.Products (
    Id          INT IDENTITY(1,1) PRIMARY KEY,
    Name        NVARCHAR(MAX) NOT NULL,
    Price       FLOAT         NOT NULL,
    Image       NVARCHAR(MAX) NOT NULL,
    Category    NVARCHAR(MAX) NOT NULL,
    Description NVARCHAR(MAX) NOT NULL
);
GO

-- ============================================================
--  BẢNG: Orders (đơn hàng)
-- ============================================================
CREATE TABLE dbo.Orders (
    Id            INT IDENTITY(1,1) PRIMARY KEY,
    UserId        INT           NOT NULL,
    Total         FLOAT         NOT NULL,
    Address       NVARCHAR(MAX) NOT NULL,
    PaymentMethod NVARCHAR(MAX) NOT NULL,   -- "Tiền mặt" | "Chuyển khoản"
    Status        NVARCHAR(MAX) NOT NULL,   -- "Chờ thanh toán" | "Đã thanh toán" | "Đã hủy"
    CreatedAt     NVARCHAR(MAX) NOT NULL
);
GO

-- ============================================================
--  BẢNG: OrderItems (chi tiết đơn - quan hệ 1 đơn : nhiều dòng)
-- ============================================================
CREATE TABLE dbo.OrderItems (
    Id          INT IDENTITY(1,1) PRIMARY KEY,
    OrderId     INT           NOT NULL,
    ProductName NVARCHAR(MAX) NOT NULL,
    Size        NVARCHAR(MAX) NOT NULL,
    Quantity    INT           NOT NULL,
    Price       FLOAT         NOT NULL,
    CONSTRAINT FK_OrderItems_Orders FOREIGN KEY (OrderId)
        REFERENCES dbo.Orders(Id) ON DELETE CASCADE
);
GO

-- ============================================================
--  BẢNG: Messages (chat hỗ trợ khách hàng)
--  Sender = "user" (khách) hoặc "shop" (cửa hàng/admin trả lời)
-- ============================================================
CREATE TABLE dbo.Messages (
    Id        INT IDENTITY(1,1) PRIMARY KEY,
    UserId    INT           NOT NULL,
    Sender    NVARCHAR(MAX) NOT NULL,
    Text      NVARCHAR(MAX) NOT NULL,
    CreatedAt NVARCHAR(MAX) NOT NULL
);
GO

-- ============================================================
--  DỮ LIỆU MẪU
-- ============================================================

-- Tài khoản demo (đăng nhập trong app: demo@coffee.com / 123456)
SET IDENTITY_INSERT dbo.Users ON;
INSERT INTO dbo.Users (Id, Name, Email, Password, Phone, Address, Avatar, FailedLoginCount, IsLocked)
VALUES (1, N'Khách Demo', N'demo@coffee.com', N'123456', N'0900000000', N'FPT University', N'', 0, 0);
SET IDENTITY_INSERT dbo.Users OFF;
GO

-- 17 sản phẩm mẫu
SET IDENTITY_INSERT dbo.Products ON;
INSERT INTO dbo.Products (Id, Name, Price, Image, Category, Description) VALUES
(1,  N'Cà phê đen',         25000, N'assets/images/cafe_den.jpg',          N'Cà phê',   N'Cà phê phin truyền thống, đậm đà và thơm nồng.'),
(2,  N'Cà phê sữa',         30000, N'assets/images/cafe_sua.jpg',          N'Cà phê',   N'Cà phê pha cùng sữa đặc, vị ngọt béo hài hòa.'),
(3,  N'Bạc xỉu',            35000, N'assets/images/bac_xiu.jpg',           N'Cà phê',   N'Nhiều sữa, ít cà phê, êm dịu dễ uống.'),
(4,  N'Trà sữa trân châu',  45000, N'assets/images/tra_sua.jpg',           N'Trà sữa',  N'Trà sữa béo ngậy cùng trân châu đường đen dai ngon.'),
(5,  N'Trà đào cam sả',     40000, N'assets/images/tra_dao.jpg',           N'Trà',      N'Trà đào chua ngọt thanh mát, thơm mùi sả.'),
(6,  N'Trà vải',            38000, N'assets/images/tra_vai.jpg',           N'Trà',      N'Trà ô long ủ cùng vải tươi ngọt mát.'),
(7,  N'Matcha đá xay',      50000, N'assets/images/matcha.jpg',            N'Đá xay',   N'Matcha Nhật Bản xay mịn với đá và kem tươi.'),
(8,  N'Chocolate đá xay',   50000, N'assets/images/chocolate.jpg',         N'Đá xay',   N'Socola đậm vị, mát lạnh, phủ kem tươi.'),
(9,  N'Nước cam ép',        35000, N'assets/images/cam_ep.jpg',            N'Nước ép',  N'Cam tươi vắt nguyên chất, giàu vitamin C.'),
(10, N'Espresso',           30000, N'assets/images/espresso.jpg',          N'Cà phê',   N'Một shot espresso nguyên chất, đậm đặc và mạnh mẽ.'),
(11, N'Macchiato',          35000, N'assets/images/macchiato.jpg',         N'Cà phê',   N'Espresso điểm thêm chút bọt sữa mịn màng.'),
(12, N'Caramel Macchiato',  45000, N'assets/images/caramel_macchiato.jpg', N'Cà phê',   N'Cà phê sữa hòa quyện sốt caramel ngọt thơm.'),
(13, N'Trà xanh',           30000, N'assets/images/tra_xanh.jpg',          N'Trà',      N'Trà xanh thanh mát, nhẹ nhàng, tốt cho sức khỏe.'),
(14, N'Trà chanh',          30000, N'assets/images/tra_chanh.jpg',         N'Trà',      N'Trà chanh chua ngọt mát lạnh, thêm bạc hà sảng khoái.'),
(15, N'Sinh tố xoài',       45000, N'assets/images/sinh_to_xoai.jpg',      N'Sinh tố',  N'Xoài chín xay cùng sữa chua, sánh mịn ngọt thơm.'),
(16, N'Sinh tố dâu',        48000, N'assets/images/sinh_to_dau.jpg',       N'Sinh tố',  N'Dâu và các loại berry xay mát lạnh, giàu vitamin.'),
(17, N'Milkshake socola',   50000, N'assets/images/milkshake_socola.jpg',  N'Đá xay',   N'Sữa lắc socola béo ngậy phủ kem tươi và sốt socola.');
SET IDENTITY_INSERT dbo.Products OFF;
GO

-- 1 đơn hàng mẫu của khách demo
SET IDENTITY_INSERT dbo.Orders ON;
INSERT INTO dbo.Orders (Id, UserId, Total, Address, PaymentMethod, Status, CreatedAt)
VALUES (1, 1, 75000, N'FPT University', N'Chuyển khoản', N'Đã thanh toán', CONVERT(NVARCHAR(50), GETDATE(), 126));
SET IDENTITY_INSERT dbo.Orders OFF;
GO

SET IDENTITY_INSERT dbo.OrderItems ON;
INSERT INTO dbo.OrderItems (Id, OrderId, ProductName, Size, Quantity, Price) VALUES
(1, 1, N'Cà phê sữa',        N'M', 1, 30000),
(2, 1, N'Trà sữa trân châu', N'L', 1, 45000);
SET IDENTITY_INSERT dbo.OrderItems OFF;
GO

-- 1 đoạn chat mẫu (khách hỏi - cửa hàng trả lời)
SET IDENTITY_INSERT dbo.Messages ON;
INSERT INTO dbo.Messages (Id, UserId, Sender, Text, CreatedAt) VALUES
(1, 1, N'user', N'Cửa hàng mấy giờ mở cửa vậy?', CONVERT(NVARCHAR(50), GETDATE(), 126)),
(2, 1, N'shop', N'Cửa hàng mở cửa từ 7:00 đến 22:00 hằng ngày bạn nhé! ☕', CONVERT(NVARCHAR(50), GETDATE(), 126));
SET IDENTITY_INSERT dbo.Messages OFF;
GO

PRINT N'Đã tạo xong database CoffeeShopDb với dữ liệu mẫu.';
GO
