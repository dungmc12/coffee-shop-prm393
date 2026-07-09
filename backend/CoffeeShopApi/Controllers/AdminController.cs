using CoffeeShopApi.Data;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace CoffeeShopApi.Controllers;

[ApiController]
[Route("api/[controller]")] // -> /api/admin
public class AdminController : ControllerBase
{
    private readonly AppDbContext _db;
    public AdminController(AppDbContext db) => _db = db;

    // GET /api/admin/orders - TẤT CẢ đơn hàng của mọi khách (cho web admin).
    [HttpGet("orders")]
    public async Task<IActionResult> AllOrders()
    {
        var orders = await _db.Orders
            .Include(o => o.Items)
            .OrderByDescending(o => o.Id)
            .ToListAsync();
        // Ghép thêm tên khách hàng cho dễ đọc.
        var users = await _db.Users.ToDictionaryAsync(u => u.Id, u => u.Name);
        var result = orders.Select(o => new
        {
            o.Id, o.UserId, o.Total, o.Address, o.PaymentMethod,
            o.Status, o.CreatedAt, o.Items,
            CustomerName = users.GetValueOrDefault(o.UserId, "Không rõ"),
        });
        return Ok(result);
    }

    // GET /api/admin/stats - số liệu thống kê quan trọng cho người quản lý.
    [HttpGet("stats")]
    public async Task<IActionResult> Stats()
    {
        var orders = await _db.Orders.Include(o => o.Items).ToListAsync();
        var paid = orders.Where(o => o.Status == "Đã thanh toán").ToList();

        // Doanh thu 7 ngày gần nhất (chỉ tính đơn đã thanh toán).
        var today = DateTime.Now.Date;
        var revenueByDay = Enumerable.Range(0, 7)
            .Select(i => today.AddDays(-6 + i))
            .Select(day => new
            {
                Date = day.ToString("dd/MM"),
                Revenue = paid
                    .Where(o => ParseDay(o.CreatedAt) == day)
                    .Sum(o => o.Total),
            })
            .ToList();

        // Top 5 sản phẩm bán chạy (theo số ly đã bán trong đơn đã thanh toán).
        var topProducts = paid
            .SelectMany(o => o.Items)
            .GroupBy(i => i.ProductName)
            .Select(g => new { Name = g.Key, Quantity = g.Sum(i => i.Quantity) })
            .OrderByDescending(x => x.Quantity)
            .Take(5)
            .ToList();

        return Ok(new
        {
            TotalRevenue = paid.Sum(o => o.Total),
            TotalOrders = orders.Count,
            PaidOrders = paid.Count,
            PendingOrders = orders.Count(o => o.Status == "Chờ thanh toán"),
            CancelledOrders = orders.Count(o => o.Status == "Đã hủy"),
            TotalCustomers = await _db.Users.CountAsync(),
            TotalProducts = await _db.Products.CountAsync(),
            RevenueByDay = revenueByDay,
            TopProducts = topProducts,
        });
    }

    // Đọc phần ngày (bỏ giờ) từ chuỗi ISO; lỗi thì trả về ngày rất xa.
    private static DateTime ParseDay(string iso)
    {
        return DateTime.TryParse(iso, out var dt) ? dt.Date : DateTime.MinValue;
    }
}
