using CoffeeShopApi.Data;
using CoffeeShopApi.Dtos;
using CoffeeShopApi.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace CoffeeShopApi.Controllers;

[ApiController]
[Route("api/[controller]")] // -> /api/orders
public class OrdersController : ControllerBase
{
    private readonly AppDbContext _db;
    public OrdersController(AppDbContext db) => _db = db;

    // GET /api/orders?userId=1 - lịch sử đơn của 1 user (mới nhất lên đầu).
    [HttpGet]
    public async Task<IActionResult> GetByUser([FromQuery] int userId)
    {
        var orders = await _db.Orders
            .Where(o => o.UserId == userId)
            .Include(o => o.Items) // kèm chi tiết món
            .OrderByDescending(o => o.Id)
            .ToListAsync();
        return Ok(orders);
    }

    // POST /api/orders - tạo đơn hàng mới kèm danh sách món.
    [HttpPost]
    public async Task<IActionResult> Create(CreateOrderDto dto)
    {
        var order = new Order
        {
            UserId = dto.UserId,
            Total = dto.Total,
            Address = dto.Address,
            PaymentMethod = dto.PaymentMethod,
            Status = "Chờ thanh toán",
            CreatedAt = DateTime.Now.ToString("o"),
            Items = dto.Items.Select(i => new OrderItem
            {
                ProductName = i.ProductName,
                Size = i.Size,
                Quantity = i.Quantity,
                Price = i.Price
            }).ToList()
        };
        _db.Orders.Add(order);
        await _db.SaveChangesAsync();
        return Ok(order);
    }

    // PUT /api/orders/{id}/status - cập nhật trạng thái đơn hàng.
    [HttpPut("{id}/status")]
    public async Task<IActionResult> UpdateStatus(int id, UpdateStatusDto dto)
    {
        var order = await _db.Orders.FindAsync(id);
        if (order == null) return NotFound();
        order.Status = dto.Status;
        await _db.SaveChangesAsync();
        return Ok(order);
    }
}
