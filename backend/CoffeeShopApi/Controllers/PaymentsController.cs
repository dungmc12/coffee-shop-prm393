using System.Security.Cryptography;
using System.Text;
using CoffeeShopApi.Data;
using Microsoft.AspNetCore.Mvc;

namespace CoffeeShopApi.Controllers;

// Thanh toán online qua VNPay (môi trường SANDBOX - thẻ Test, không mất tiền thật).
// Luồng: App bấm "Thanh toán VNPay" -> gọi create-url -> mở trang VNPay trong trình duyệt
//        -> khách nhập thẻ test -> VNPay gọi về vnpay-return -> backend kiểm tra chữ ký
//        -> cập nhật đơn "Đã thanh toán" -> hiện trang kết quả.
[ApiController]
[Route("api/[controller]")] // -> /api/payments
public class PaymentsController : ControllerBase
{
    private readonly AppDbContext _db;
    private readonly IConfiguration _config;
    public PaymentsController(AppDbContext db, IConfiguration config)
    {
        _db = db;
        _config = config;
    }

    // GET /api/payments/create-url?orderId=5 - tạo link thanh toán VNpay cho 1 đơn.
    [HttpGet("create-url")]
    public async Task<IActionResult> CreateUrl([FromQuery] int orderId)
    {
        var order = await _db.Orders.FindAsync(orderId);
        if (order == null) return NotFound(new { message = "Không tìm thấy đơn hàng" });
        if (order.Status != "Chờ thanh toán")
            return BadRequest(new { message = "Đơn này không ở trạng thái chờ thanh toán" });

        var tmnCode = _config["Vnpay:TmnCode"];
        var hashSecret = _config["Vnpay:HashSecret"];
        if (string.IsNullOrEmpty(tmnCode) || string.IsNullOrEmpty(hashSecret))
            return BadRequest(new
            {
                message = "Chưa cấu hình VNPay. Điền TmnCode và HashSecret vào appsettings.json"
            });

        var now = DateTime.Now;
        // Tham số bắt buộc theo tài liệu VNPay v2.1.0. sortedDictionary để
        // tự sắp xếp theo alphabet - VNPay yêu cầu khi ký.
        var p = new SortedDictionary<string, string>
        {
            ["vnp_Version"] = "2.1.0",
            ["vnp_Command"] = "pay",
            ["vnp_TmnCode"] = tmnCode,
            // VNPay quy định số tiền nhân 100 (đơn vị = đồng x 100).
            ["vnp_Amount"] = ((long)(order.Total * 100)).ToString(),
            ["vnp_CreateDate"] = now.ToString("yyyyMMddHHmmss"),
            ["vnp_ExpireDate"] = now.AddMinutes(15).ToString("yyyyMMddHHmmss"),
            ["vnp_CurrCode"] = "VND",
            ["vnp_IpAddr"] = HttpContext.Connection.RemoteIpAddress?.ToString() ?? "127.0.0.1",
            ["vnp_Locale"] = "vn",
            ["vnp_OrderInfo"] = $"Thanh toan don hang {order.Id}",
            ["vnp_OrderType"] = "other",
            ["vnp_ReturnUrl"] = _config["Vnpay:ReturnUrl"] ?? "http://10.0.2.2:5266/api/payments/vnpay-return",
            // TxnRef phải là duy nhất mỗi lần thanh toán: ghép orderId + giờ hiện tại.
            ["vnp_TxnRef"] = $"{order.Id}-{now:HHmmss}",
        };

        // Chuỗi dữ liệu để ký + URL: key=value nối bằng &, value được URL-encode.
        var query = string.Join("&",
            p.Select(kv => $"{kv.Key}={Uri.EscapeDataString(kv.Value)}"));
        var secureHash = HmacSha512(hashSecret, query);
        var payUrl = $"{_config["Vnpay:PaymentUrl"]}?{query}&vnp_SecureHash={secureHash}";

        return Ok(new { url = payUrl });
    }

    // GET /api/payments/vnpay-return - VNPay chuyển hướng về đây sau khi thanh toán.
    [HttpGet("vnpay-return")]
    public async Task<IActionResult> VnpayReturn()
    {
        var hashSecret = _config["Vnpay:HashSecret"] ?? "";

        // Lấy toàn bộ tham số vnp_ (trừ chữ ký) và kiểm tra lại chữ ký
        // để chắc chắn dữ liệu do VNPay gửi, không bị giả mạo.
        var receivedHash = Request.Query["vnp_SecureHash"].ToString();
        var p = new SortedDictionary<string, string>();
        foreach (var (key, value) in Request.Query)
        {
            if (key.StartsWith("vnp_") && key != "vnp_SecureHash" && key != "vnp_SecureHashType")
                p[key] = value.ToString();
        }
        var data = string.Join("&",
            p.Select(kv => $"{kv.Key}={Uri.EscapeDataString(kv.Value)}"));
        var expectedHash = HmacSha512(hashSecret, data);

        var responseCode = Request.Query["vnp_ResponseCode"].ToString();
        var txnRef = Request.Query["vnp_TxnRef"].ToString();
        var orderId = int.TryParse(txnRef.Split('-')[0], out var id) ? id : 0;

        bool valid = string.Equals(expectedHash, receivedHash, StringComparison.OrdinalIgnoreCase);
        bool success = valid && responseCode == "00"; // "00" = giao dịch thành công

        if (success)
        {
            var order = await _db.Orders.FindAsync(orderId);
            if (order != null)
            {
                order.Status = "Đã thanh toán";
                order.PaymentMethod = "VNPay";
                await _db.SaveChangesAsync();
            }
        }

        // Trả về trang HTML đơn giản báo kết quả (hiện trong trình duyệt).
        var (color, icon, title) = success
            ? ("#4CAF50", "&#10004;", $"Thanh toán thành công đơn #{orderId}!")
            : ("#E05D5D", "&#10008;", "Thanh toán thất bại hoặc bị hủy.");
        var html = $@"<!DOCTYPE html><html><head><meta charset='utf-8'>
<meta name='viewport' content='width=device-width, initial-scale=1'>
<title>Kết quả thanh toán</title></head>
<body style='font-family:sans-serif;text-align:center;padding-top:80px;background:#F9F5F0'>
<div style='font-size:72px;color:{color}'>{icon}</div>
<h2 style='color:#2E2420'>{title}</h2>
<p style='color:#9C8F86'>Bạn có thể đóng trang này và quay lại ứng dụng Coffee Shop.<br>
Vào mục Đơn hàng, kéo xuống để làm mới trạng thái.</p>
</body></html>";
        return Content(html, "text/html; charset=utf-8");
    }

    // ============ THANH TOÁN MÔ PHỎNG (khi chưa có key VNPay sandbox) ============
    // Mô phỏng lại đúng trải nghiệm cổng thanh toán thật: hiện số tiền, chọn ngân
    // hàng, nhập thẻ test rồi bấm thanh toán. Dùng để demo khi chưa được cấp key
    // sandbox. Code VNPay thật ở trên vẫn giữ nguyên, có key là chạy được ngay.

    // GET /api/payments/mock?orderId=5 - hiện trang thanh toán mô phỏng.
    [HttpGet("mock")]
    public async Task<IActionResult> Mock([FromQuery] int orderId)
    {
        var order = await _db.Orders.FindAsync(orderId);
        if (order == null) return NotFound("Không tìm thấy đơn hàng");

        var amount = order.Total.ToString("#,##0") + "đ";
        var html = $@"<!DOCTYPE html><html lang='vi'><head><meta charset='utf-8'>
<meta name='viewport' content='width=device-width, initial-scale=1'>
<title>Cổng thanh toán</title>
<style>
  body{{font-family:sans-serif;background:#ECEFF4;margin:0;padding:16px;color:#2E2420}}
  .box{{max-width:420px;margin:20px auto;background:#fff;border-radius:16px;overflow:hidden;box-shadow:0 8px 30px rgba(0,0,0,.12)}}
  .head{{background:linear-gradient(135deg,#3E2B1F,#6F4E37);color:#fff;padding:18px 20px}}
  .head h2{{margin:0;font-size:18px}}
  .head .sub{{opacity:.8;font-size:13px;margin-top:2px}}
  .body{{padding:20px}}
  .amount{{text-align:center;margin-bottom:18px}}
  .amount .l{{color:#9C8F86;font-size:13px}}
  .amount .v{{font-size:30px;font-weight:bold;color:#6F4E37}}
  label{{display:block;font-size:13px;color:#9C8F86;margin:12px 0 5px}}
  select,input{{width:100%;padding:12px;border:1px solid #E0D6CC;border-radius:10px;font-size:15px;box-sizing:border-box}}
  .btn{{width:100%;margin-top:20px;padding:14px;border:none;border-radius:12px;background:#6F4E37;color:#fff;font-size:16px;font-weight:bold;cursor:pointer}}
  .btn.cancel{{background:#fff;color:#E05D5D;border:1px solid #E05D5D;margin-top:10px}}
  .note{{font-size:12px;color:#9C8F86;padding:10px;border-radius:8px;margin-top:14px;background:#F9F5F0}}
</style></head>
<body>
<div class='box'>
  <div class='head'><h2>☕ Cổng thanh toán Coffee Shop</h2><div class='sub'>Đơn hàng #{order.Id} • Mô phỏng</div></div>
  <div class='body'>
    <div class='amount'><div class='l'>Số tiền thanh toán</div><div class='v'>{amount}</div></div>
    <form method='post' action='/api/payments/mock-confirm'>
      <input type='hidden' name='orderId' value='{order.Id}'>
      <label>Chọn ngân hàng</label>
      <select name='bank'>
        <option>NCB - Ngân hàng Quốc Dân</option>
        <option>Vietcombank</option>
        <option>Techcombank</option>
        <option>VietinBank</option>
        <option>BIDV</option>
      </select>
      <label>Số thẻ (thẻ test)</label>
      <input name='card' value='9704198526191432198' inputmode='numeric'>
      <label>Tên chủ thẻ</label>
      <input name='name' value='NGUYEN VAN A'>
      <button class='btn' type='submit' name='result' value='success'>Thanh toán {amount}</button>
      <button class='btn cancel' type='submit' name='result' value='cancel'>Hủy giao dịch</button>
    </form>
    <div class='note'>Đây là trang thanh toán mô phỏng phục vụ demo. Thẻ test điền sẵn,
    bấm ""Thanh toán"" để mô phỏng giao dịch thành công.</div>
  </div>
</div>
</body></html>";
        return Content(html, "text/html; charset=utf-8");
    }

    // POST /api/payments/mock-confirm - xử lý kết quả thanh toán mô phỏng.
    [HttpPost("mock-confirm")]
    [Consumes("application/x-www-form-urlencoded")]
    public async Task<IActionResult> MockConfirm(
        [FromForm] int orderId, [FromForm] string result)
    {
        bool success = result == "success";
        if (success)
        {
            var order = await _db.Orders.FindAsync(orderId);
            if (order != null && order.Status == "Chờ thanh toán")
            {
                order.Status = "Đã thanh toán";
                order.PaymentMethod = "Thanh toán online";
                await _db.SaveChangesAsync();
            }
        }
        return Content(ResultHtml(success, orderId), "text/html; charset=utf-8");
    }

    // Trang HTML báo kết quả (dùng chung cho cả VNPay thật và mô phỏng).
    private static string ResultHtml(bool success, int orderId)
    {
        var (color, icon, title) = success
            ? ("#4CAF50", "&#10004;", $"Thanh toán thành công đơn #{orderId}!")
            : ("#E05D5D", "&#10008;", "Thanh toán đã bị hủy.");
        return $@"<!DOCTYPE html><html><head><meta charset='utf-8'>
<meta name='viewport' content='width=device-width, initial-scale=1'>
<title>Kết quả thanh toán</title></head>
<body style='font-family:sans-serif;text-align:center;padding-top:80px;background:#F9F5F0'>
<div style='font-size:72px;color:{color}'>{icon}</div>
<h2 style='color:#2E2420'>{title}</h2>
<p style='color:#9C8F86'>Bạn có thể đóng trang này và quay lại ứng dụng Coffee Shop.<br>
Vào mục Đơn hàng, kéo xuống để làm mới trạng thái.</p>
</body></html>";
    }

    // Ký HMAC-SHA512 theo chuẩn VNPay.
    private static string HmacSha512(string key, string data)
    {
        using var hmac = new HMACSHA512(Encoding.UTF8.GetBytes(key));
        var bytes = hmac.ComputeHash(Encoding.UTF8.GetBytes(data));
        return Convert.ToHexString(bytes).ToLower();
    }
}
