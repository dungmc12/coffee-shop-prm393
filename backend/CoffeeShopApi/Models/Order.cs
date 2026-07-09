namespace CoffeeShopApi.Models;

// Thực thể Order - 1 đơn hàng, có nhiều OrderItem.
public class Order
{
    public int Id { get; set; }
    public int UserId { get; set; }
    public double Total { get; set; }
    public string Address { get; set; } = string.Empty;
    public string PaymentMethod { get; set; } = string.Empty;
    public string Status { get; set; } = "Chờ thanh toán";
    public string CreatedAt { get; set; } = string.Empty;

    // Quan hệ 1 - nhiều: 1 đơn có nhiều dòng chi tiết.
    public List<OrderItem> Items { get; set; } = new();
}

// Thực thể OrderItem - 1 dòng món trong đơn hàng.
public class OrderItem
{
    public int Id { get; set; }
    public int OrderId { get; set; }
    public string ProductName { get; set; } = string.Empty;
    public string Size { get; set; } = string.Empty;
    public int Quantity { get; set; }
    public double Price { get; set; }
}
