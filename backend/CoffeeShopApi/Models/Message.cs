namespace CoffeeShopApi.Models;

// Thực thể Message - 1 tin nhắn trong đoạn chat hỗ trợ khách hàng.
// Sender = "user" (khách gửi) hoặc "shop" (cửa hàng trả lời).
public class Message
{
    public int Id { get; set; }
    public int UserId { get; set; }
    public string Sender { get; set; } = "user";
    public string Text { get; set; } = string.Empty;
    public string CreatedAt { get; set; } = string.Empty;
}
