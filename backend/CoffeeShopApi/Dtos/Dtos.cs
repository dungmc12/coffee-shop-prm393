namespace CoffeeShopApi.Dtos;

// Các DTO (Data Transfer Object) - định dạng dữ liệu trao đổi với app Flutter.

public record LoginDto(string Email, string Password);

public record RegisterDto(string Name, string Email, string Password, string Phone);

public record UpdateProfileDto(string Name, string Phone, string Address, string Avatar);

public record CreateOrderItemDto(string ProductName, string Size, int Quantity, double Price);

public record CreateOrderDto(
    int UserId,
    double Total,
    string Address,
    string PaymentMethod,
    List<CreateOrderItemDto> Items);

public record UpdateStatusDto(string Status);

public record SendMessageDto(int UserId, string Text);

// Đổi mật khẩu khi đang đăng nhập (cần biết mật khẩu cũ).
public record ChangePasswordDto(string OldPassword, string NewPassword);

// Đặt lại mật khẩu khi quên (xác minh bằng email + số điện thoại đã đăng ký).
public record ResetPasswordDto(string Email, string Phone, string NewPassword);
