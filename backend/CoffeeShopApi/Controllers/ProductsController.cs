using CoffeeShopApi.Data;
using CoffeeShopApi.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace CoffeeShopApi.Controllers;

[ApiController]
[Route("api/[controller]")] // -> /api/products
public class ProductsController : ControllerBase
{
    private readonly AppDbContext _db;
    public ProductsController(AppDbContext db) => _db = db;

    // GET /api/products - Lấy toàn bộ danh sách sản phẩm.
    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        var products = await _db.Products.OrderBy(p => p.Id).ToListAsync();
        return Ok(products);
    }

    // ----- các API dưới đây dành cho WEB ADMIN (CRUD sản phẩm) -----

    // POST /api/products - Thêm sản phẩm mới.
    [HttpPost]
    public async Task<IActionResult> Create(Product product)
    {
        product.Id = 0; // Để SQL Server tự cấp Id
        _db.Products.Add(product);
        await _db.SaveChangesAsync();
        return Ok(product);
    }

    // PUT /api/products/{id} - Sửa sản phẩm.
    [HttpPut("{id}")]
    public async Task<IActionResult> Update(int id, Product product)
    {
        var existing = await _db.Products.FindAsync(id);
        if (existing == null) return NotFound();
        existing.Name = product.Name;
        existing.Price = product.Price;
        existing.Image = product.Image;
        existing.Category = product.Category;
        existing.Description = product.Description;
        await _db.SaveChangesAsync();
        return Ok(existing);
    }

    // DELETE /api/products/{id} - Xóa sản phẩm.
    [HttpDelete("{id}")]
    public async Task<IActionResult> Delete(int id)
    {
        var existing = await _db.Products.FindAsync(id);
        if (existing == null) return NotFound();
        _db.Products.Remove(existing);
        await _db.SaveChangesAsync();
        return Ok(new { message = "Đã xóa sản phẩm" });
    }
}
