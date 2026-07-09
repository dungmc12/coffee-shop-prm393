using CoffeeShopApi.Models;
using Microsoft.EntityFrameworkCore;

namespace CoffeeShopApi.Data;

// AppDbContext - cầu nối giữa code C# và SQL Server (Entity Framework Core).
public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

    public DbSet<User> Users => Set<User>();
    public DbSet<Product> Products => Set<Product>();
    public DbSet<Order> Orders => Set<Order>();
    public DbSet<OrderItem> OrderItems => Set<OrderItem>();
    public DbSet<Message> Messages => Set<Message>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        // Email là duy nhất (không cho trùng).
        modelBuilder.Entity<User>().HasIndex(u => u.Email).IsUnique();

        // Tài khoản demo để tiện đăng nhập khi demo với thầy.
        modelBuilder.Entity<User>().HasData(new User
        {
            Id = 1,
            Name = "Khách Demo",
            Email = "demo@coffee.com",
            Password = "123456",
            Phone = "0900000000",
            Address = "FPT University"
        });

        // Nạp sẵn 17 sản phẩm.
        modelBuilder.Entity<Product>().HasData(SeedProducts());
    }

    // Danh sách sản phẩm mẫu (giống dữ liệu bên app Flutter).
    private static Product[] SeedProducts() => new[]
    {
        new Product { Id = 1, Name = "Cà phê đen", Price = 25000, Image = "assets/images/cafe_den.jpg", Category = "Cà phê", Description = "Cà phê phin truyền thống, đậm đà và thơm nồng." },
        new Product { Id = 2, Name = "Cà phê sữa", Price = 30000, Image = "assets/images/cafe_sua.jpg", Category = "Cà phê", Description = "Cà phê pha cùng sữa đặc, vị ngọt béo hài hòa." },
        new Product { Id = 3, Name = "Bạc xỉu", Price = 35000, Image = "assets/images/bac_xiu.jpg", Category = "Cà phê", Description = "Nhiều sữa, ít cà phê, êm dịu dễ uống." },
        new Product { Id = 4, Name = "Trà sữa trân châu", Price = 45000, Image = "assets/images/tra_sua.jpg", Category = "Trà sữa", Description = "Trà sữa béo ngậy cùng trân châu đường đen dai ngon." },
        new Product { Id = 5, Name = "Trà đào cam sả", Price = 40000, Image = "assets/images/tra_dao.jpg", Category = "Trà", Description = "Trà đào chua ngọt thanh mát, thơm mùi sả." },
        new Product { Id = 6, Name = "Trà vải", Price = 38000, Image = "assets/images/tra_vai.jpg", Category = "Trà", Description = "Trà ô long ủ cùng vải tươi ngọt mát." },
        new Product { Id = 7, Name = "Matcha đá xay", Price = 50000, Image = "assets/images/matcha.jpg", Category = "Đá xay", Description = "Matcha Nhật Bản xay mịn với đá và kem tươi." },
        new Product { Id = 8, Name = "Chocolate đá xay", Price = 50000, Image = "assets/images/chocolate.jpg", Category = "Đá xay", Description = "Socola đậm vị, mát lạnh, phủ kem tươi." },
        new Product { Id = 9, Name = "Nước cam ép", Price = 35000, Image = "assets/images/cam_ep.jpg", Category = "Nước ép", Description = "Cam tươi vắt nguyên chất, giàu vitamin C." },
        new Product { Id = 10, Name = "Espresso", Price = 30000, Image = "assets/images/espresso.jpg", Category = "Cà phê", Description = "Một shot espresso nguyên chất, đậm đặc và mạnh mẽ." },
        new Product { Id = 11, Name = "Macchiato", Price = 35000, Image = "assets/images/macchiato.jpg", Category = "Cà phê", Description = "Espresso điểm thêm chút bọt sữa mịn màng." },
        new Product { Id = 12, Name = "Caramel Macchiato", Price = 45000, Image = "assets/images/caramel_macchiato.jpg", Category = "Cà phê", Description = "Cà phê sữa hòa quyện sốt caramel ngọt thơm." },
        new Product { Id = 13, Name = "Trà xanh", Price = 30000, Image = "assets/images/tra_xanh.jpg", Category = "Trà", Description = "Trà xanh thanh mát, nhẹ nhàng, tốt cho sức khỏe." },
        new Product { Id = 14, Name = "Trà chanh", Price = 30000, Image = "assets/images/tra_chanh.jpg", Category = "Trà", Description = "Trà chanh chua ngọt mát lạnh, thêm bạc hà sảng khoái." },
        new Product { Id = 15, Name = "Sinh tố xoài", Price = 45000, Image = "assets/images/sinh_to_xoai.jpg", Category = "Sinh tố", Description = "Xoài chín xay cùng sữa chua, sánh mịn ngọt thơm." },
        new Product { Id = 16, Name = "Sinh tố dâu", Price = 48000, Image = "assets/images/sinh_to_dau.jpg", Category = "Sinh tố", Description = "Dâu và các loại berry xay mát lạnh, giàu vitamin." },
        new Product { Id = 17, Name = "Milkshake socola", Price = 50000, Image = "assets/images/milkshake_socola.jpg", Category = "Đá xay", Description = "Sữa lắc socola béo ngậy phủ kem tươi và sốt socola." },
    };
}
