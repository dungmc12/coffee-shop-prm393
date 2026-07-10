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
            // Băm (hash) mật khẩu bằng BCrypt trước khi lưu -> database KHÔNG
            // lưu mật khẩu thật. Kể cả bị lộ database cũng không đọc được mật khẩu.
            Password = BCrypt.Net.BCrypt.HashPassword(dto.Password),
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
        // Tìm theo email trước, rồi mới kiểm tra mật khẩu (vì mật khẩu đã bị băm,
        // không so sánh trực tiếp trong câu truy vấn được).
        var user = await _db.Users.FirstOrDefaultAsync(u => u.Email == dto.Email);
        if (user == null || !VerifyPassword(dto.Password, user))
            return Unauthorized(new { message = "Email hoặc mật khẩu không đúng" });
        return Ok(user);
    }

    // Kiểm tra mật khẩu. Xử lý được cả 2 trường hợp:
    //  - Mật khẩu đã băm (BCrypt bắt đầu bằng "$2"): so bằng BCrypt.Verify.
    //  - Mật khẩu cũ còn lưu dạng thường: so trực tiếp, nếu đúng thì TỰ NÂNG CẤP
    //    thành bản băm và lưu lại (nên các tài khoản cũ tự an toàn dần).
    private bool VerifyPassword(string input, User user)
    {
        if (user.Password.StartsWith("$2"))
            return BCrypt.Net.BCrypt.Verify(input, user.Password);

        if (input != user.Password) return false;
        user.Password = BCrypt.Net.BCrypt.HashPassword(input); // nâng cấp
        _db.SaveChanges();
        return true;
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
