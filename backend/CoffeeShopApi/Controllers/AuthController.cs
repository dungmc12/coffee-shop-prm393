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
        if (user == null)
            return Unauthorized(new { message = "Email hoặc mật khẩu không đúng" });

        // Tài khoản đang bị khóa -> bắt đặt lại mật khẩu mới mở được.
        if (user.IsLocked)
            return Unauthorized(new { message =
                "Tài khoản đã bị khóa do nhập sai 5 lần. Vui lòng dùng \"Quên mật khẩu\" để đặt lại." });

        if (!VerifyPassword(dto.Password, user))
        {
            // Sai mật khẩu -> tăng bộ đếm; đủ 5 lần thì khóa.
            user.FailedLoginCount++;
            if (user.FailedLoginCount >= 5) user.IsLocked = true;
            await _db.SaveChangesAsync();

            var msg = user.IsLocked
                ? "Bạn đã nhập sai 5 lần. Tài khoản bị khóa, hãy dùng \"Quên mật khẩu\" để đặt lại."
                : $"Email hoặc mật khẩu không đúng. Còn {5 - user.FailedLoginCount} lần thử.";
            return Unauthorized(new { message = msg });
        }

        // Đăng nhập đúng -> xóa bộ đếm sai (nếu có).
        if (user.FailedLoginCount != 0)
        {
            user.FailedLoginCount = 0;
            await _db.SaveChangesAsync();
        }
        return Ok(user);
    }

    // PUT /api/auth/{id}/password - đổi mật khẩu khi đang đăng nhập.
    [HttpPut("{id}/password")]
    public async Task<IActionResult> ChangePassword(int id, ChangePasswordDto dto)
    {
        var user = await _db.Users.FindAsync(id);
        if (user == null) return NotFound();
        // Phải nhập đúng mật khẩu cũ mới cho đổi.
        if (!VerifyPassword(dto.OldPassword, user))
            return BadRequest(new { message = "Mật khẩu hiện tại không đúng" });
        if (dto.NewPassword.Length < 6)
            return BadRequest(new { message = "Mật khẩu mới tối thiểu 6 ký tự" });

        user.Password = BCrypt.Net.BCrypt.HashPassword(dto.NewPassword);
        await _db.SaveChangesAsync();
        return Ok(new { message = "Đổi mật khẩu thành công" });
    }

    // POST /api/auth/reset - quên mật khẩu: xác minh email + SĐT rồi đặt mật khẩu mới.
    [HttpPost("reset")]
    public async Task<IActionResult> ResetPassword(ResetPasswordDto dto)
    {
        // Xác minh danh tính: email và số điện thoại phải khớp cùng 1 tài khoản.
        var user = await _db.Users.FirstOrDefaultAsync(
            u => u.Email == dto.Email && u.Phone == dto.Phone);
        if (user == null)
            return BadRequest(new { message = "Email và số điện thoại không khớp tài khoản nào" });
        if (dto.NewPassword.Length < 6)
            return BadRequest(new { message = "Mật khẩu mới tối thiểu 6 ký tự" });

        user.Password = BCrypt.Net.BCrypt.HashPassword(dto.NewPassword);
        user.IsLocked = false;        // mở khóa
        user.FailedLoginCount = 0;    // xóa bộ đếm sai
        await _db.SaveChangesAsync();
        return Ok(new { message = "Đặt lại mật khẩu thành công. Hãy đăng nhập lại." });
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
