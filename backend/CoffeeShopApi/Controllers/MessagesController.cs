using CoffeeShopApi.Data;
using CoffeeShopApi.Dtos;
using CoffeeShopApi.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace CoffeeShopApi.Controllers;

[ApiController]
[Route("api/[controller]")] // -> /api/messages
public class MessagesController : ControllerBase
{
    private readonly AppDbContext _db;
    public MessagesController(AppDbContext db) => _db = db;

    // GET /api/messages?userId=1 - toàn bộ đoạn chat của 1 user (cũ thành mới).
    [HttpGet]
    public async Task<IActionResult> GetByUser([FromQuery] int userId)
    {
        var messages = await _db.Messages
            .Where(m => m.UserId == userId)
            .OrderBy(m => m.Id)
            .ToListAsync();
        return Ok(messages);
    }

    // POST /api/messages - khách gửi tin nhắn.
    // Server lưu tin của khách rồi tạo luôn 1 tin trả lời tự động của cửa hàng
    // (trả lời theo từ khóa - chatbot đơn giản, dễ demo).
    [HttpPost]
    public async Task<IActionResult> Send(SendMessageDto dto)
    {
        var now = DateTime.Now.ToString("o");

        var userMsg = new Message
        {
            UserId = dto.UserId,
            Sender = "user",
            Text = dto.Text,
            CreatedAt = now,
        };
        var shopMsg = new Message
        {
            UserId = dto.UserId,
            Sender = "shop",
            Text = AutoReply(dto.Text),
            CreatedAt = now,
        };

        _db.Messages.AddRange(userMsg, shopMsg);
        await _db.SaveChangesAsync();

        // Trả về cả 2 tin để app hiển thị ngay không cần gọi lại GET.
        return Ok(new[] { userMsg, shopMsg });
    }

    // ----- Các API dưới đây dành cho WEB ADMIN (chat 2 chiều với khách) -----

    // GET /api/messages/conversations - danh sách hội thoại (mỗi khách 1 dòng).
    [HttpGet("conversations")]
    public async Task<IActionResult> Conversations()
    {
        var users = await _db.Users.ToDictionaryAsync(u => u.Id, u => u.Name);
        var conversations = await _db.Messages
            .GroupBy(m => m.UserId)
            .Select(g => new
            {
                UserId = g.Key,
                LastText = g.OrderByDescending(m => m.Id).First().Text,
                LastAt = g.OrderByDescending(m => m.Id).First().CreatedAt,
            })
            .ToListAsync();
        var result = conversations
            .OrderByDescending(c => c.LastAt)
            .Select(c => new
            {
                c.UserId, c.LastText, c.LastAt,
                CustomerName = users.GetValueOrDefault(c.UserId, "Không rõ"),
            });
        return Ok(result);
    }

    // POST /api/messages/reply - quản lý (shop) trả lời khách từ web admin.
    [HttpPost("reply")]
    public async Task<IActionResult> Reply(SendMessageDto dto)
    {
        var msg = new Message
        {
            UserId = dto.UserId,
            Sender = "shop",
            Text = dto.Text,
            CreatedAt = DateTime.Now.ToString("o"),
        };
        _db.Messages.Add(msg);
        await _db.SaveChangesAsync();
        return Ok(msg);
    }

    // Trả lời tự động theo từ khóa trong tin nhắn của khách.
    private static string AutoReply(string text)
    {
        var t = text.ToLower();
        if (t.Contains("giờ") || t.Contains("mở cửa"))
            return "Cửa hàng mở cửa từ 7:00 đến 22:00 hằng ngày bạn nhé! ☕";
        if (t.Contains("ship") || t.Contains("giao"))
            return "Bên mình giao hàng trong 30 phút, phí ship 15.000đ. Đơn từ 2 món được freeship!";
        if (t.Contains("giá") || t.Contains("bao nhiêu"))
            return "Bạn xem giá chi tiết ở màn Trang chủ nhé. Đồ uống từ 25.000đ - 50.000đ ạ!";
        if (t.Contains("hủy") || t.Contains("huỷ"))
            return "Bạn vào mục Đơn hàng, chọn đơn đang Chờ thanh toán rồi bấm Hủy đơn nhé!";
        if (t.Contains("cảm ơn") || t.Contains("cám ơn"))
            return "Không có gì ạ! Chúc bạn một ngày tốt lành! 🌟";
        return "Cảm ơn bạn đã nhắn tin! Nhân viên sẽ phản hồi sớm nhất. "
             + "Bạn có thể hỏi về: giờ mở cửa, giao hàng, giá, hủy đơn.";
    }
}
