using CoffeeShopApi.Data;
using Microsoft.EntityFrameworkCore;

var builder = WebApplication.CreateBuilder(args);

// Lắng nghe trên mọi địa chỉ, cổng 5266 (để máy ảo Android gọi qua 10.0.2.2:5266).
builder.WebHost.UseUrls("http://0.0.0.0:5266");

// Đăng ký DbContext dùng SQL Server với chuỗi kết nối trong appsettings.json.
builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));

builder.Services.AddControllers();
builder.Services.AddOpenApi();

// Bật Swagger UI - trang tài liệu API có giao diện đẹp, test được từng API.
// Mở http://localhost:5266/swagger để xem và thử các API.
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// Cho phép app Flutter (nguồn khác) gọi API - bật CORS.
builder.Services.AddCors(options =>
{
    options.AddDefaultPolicy(policy =>
        policy.AllowAnyOrigin().AllowAnyHeader().AllowAnyMethod());
});

var app = builder.Build();

// Tạo database + nạp dữ liệu mẫu nếu chưa có (tiện cho môi trường học tập).
using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
    db.Database.EnsureCreated();
}

if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

// Swagger UI luôn bật để tiện demo API tại http://localhost:5266/swagger
app.UseSwagger();
app.UseSwaggerUI();

app.UseCors();

// Phục vụ trang WEB ADMIN (file tĩnh trong thư mục wwwroot).
// Mở http://localhost:5266/admin.html trên trình duyệt để quản lý cửa hàng.
app.UseDefaultFiles();
app.UseStaticFiles();

app.UseAuthorization();
app.MapControllers();

app.Run();
