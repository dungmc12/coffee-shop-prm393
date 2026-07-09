using CoffeeShopApi.Data;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace CoffeeShopApi.Controllers;

[ApiController]
[Route("api/[controller]")] // -> /api/products
public class ProductsController : ControllerBase
{
    private readonly AppDbContext _db;
    public ProductsController(AppDbContext db) => _db = db;

    // GET /api/products - lấy toàn bộ danh sách sản phẩm.
    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        var products = await _db.Products.OrderBy(p => p.Id).ToListAsync();
        return Ok(products);
    }
}
