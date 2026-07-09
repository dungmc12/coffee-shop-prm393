using CoffeeShopApi.Data;
using CoffeeShopApi.Dtos;
using CoffeeShopApi.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace CoffeeShopApi.Controllers;

[ApiController]
[Route("api/[controller]")] // -> /api/auth
public class AuthController : ControllerBase
{
    private readonly AppDbContext _db;
    public AuthController(AppDbContext db) => _db = db;

    // POST /api/auth/register - đăng ký tài khoản mới.
    [HttpPost("register")]
    public async Task<IActionResult> Register(RegisterDto dto)
    {
        // Kiểm tra email đã tồn tại chưa.
        var exists = await _db.Users.AnyAsync(u => u.Email == dto.Email);
        if (exists)
            return Conflict(new { message = "Email này đã được đăng ký" });

        var user = new User
        {
            Name = dto.Name,
            Email = dto.Email,
            Password = dto.Password,
            Phone = dto.Phone
        };
        _db.Users.Add(user);
        await _db.SaveChangesAsync();
        return Ok(user); // trả về user kèm Id vừa sinh
    }

    // POST /api/auth/login - đăng nhập.
    [HttpPost("login")]
    public async Task<IActionResult> Login(LoginDto dto)
    {
        var user = await _db.Users.FirstOrDefaultAsync(
            u => u.Email == dto.Email && u.Password == dto.Password);
        if (user == null)
            return Unauthorized(new { message = "Email hoặc mật khẩu không đúng" });
        return Ok(user);
    }

    // PUT /api/auth/{id} - cập nhật hồ sơ (tên, sđt, địa chỉ, avatar).
    [HttpPut("{id}")]
    public async Task<IActionResult> UpdateProfile(int id, UpdateProfileDto dto)
    {
        var user = await _db.Users.FindAsync(id);
        if (user == null) return NotFound();

        user.Name = dto.Name;
        user.Phone = dto.Phone;
        user.Address = dto.Address;
        user.Avatar = dto.Avatar;
        await _db.SaveChangesAsync();
        return Ok(user);
    }
}
