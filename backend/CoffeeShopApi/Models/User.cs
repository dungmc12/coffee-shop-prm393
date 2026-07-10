namespace CoffeeShopApi.Models;

// Thực thể User - ánh xạ tới bảng Users trong SQL Server.
public class User
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string Password { get; set; } = string.Empty;
    public string Phone { get; set; } = string.Empty;
    public string Address { get; set; } = string.Empty;
    public string Avatar { get; set; } = string.Empty;

    // Số lần nhập sai mật khẩu liên tiếp. Đủ 5 lần thì khóa tài khoản.
    public int FailedLoginCount { get; set; }
    // Tài khoản có đang bị khóa không (phải đặt lại mật khẩu để mở).
    public bool IsLocked { get; set; }
}
