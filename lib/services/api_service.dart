import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/user.dart';
import '../models/product.dart';
import '../models/order.dart';
import '../models/message.dart';

/// Ngoại lệ mang theo thông điệp lỗi từ API để hiển thị cho người dùng.
class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

/// ApiService - lớp trung tâm gọi REST API tới backend ASP.NET Core (.NET).
///
/// Thay thế cho việc truy cập SQLite trực tiếp: giờ dữ liệu nằm ở SQL Server,
/// app (frontend) giao tiếp với backend qua HTTP/JSON.
class ApiService {
  // Singleton để toàn app dùng chung.
  ApiService._();
  static final ApiService instance = ApiService._();

  // Địa chỉ backend.
  //  - Máy ảo Android: 10.0.2.2 trỏ về "localhost" của máy tính.
  //  - Máy thật: thay bằng IP LAN của máy chạy backend (vd 192.168.1.5).
  static const String baseUrl = 'http://10.0.2.2:5266/api';

  final _headers = {'Content-Type': 'application/json; charset=utf-8'};

  /// Thời gian chờ tối đa cho 1 lời gọi API.
  /// Quá thời gian này sẽ báo lỗi thay vì treo mãi.
  static const Duration _timeout = Duration(seconds: 10);

  /// Giải mã body JSON đúng UTF-8 (giữ dấu tiếng Việt).
  dynamic _decode(http.Response res) => jsonDecode(utf8.decode(res.bodyBytes));

  /// Lấy thông điệp lỗi từ body (nếu có).
  String _error(http.Response res, String fallback) {
    try {
      final body = _decode(res);
      if (body is Map && body['message'] != null) return body['message'];
    } catch (_) {}
    return fallback;
  }

  // ===================== AUTH =====================

  Future<User> login(String email, String password) async {
    final res = await http
        .post(
          Uri.parse('$baseUrl/auth/login'),
          headers: _headers,
          body: jsonEncode({'email': email, 'password': password}),
        )
        .timeout(_timeout);
    if (res.statusCode == 200) return User.fromMap(_decode(res));
    throw ApiException(_error(res, 'Email hoặc mật khẩu không đúng'));
  }

  Future<User> register(User user) async {
    final res = await http
        .post(
          Uri.parse('$baseUrl/auth/register'),
          headers: _headers,
          body: jsonEncode({
            'name': user.name,
            'email': user.email,
            'password': user.password,
            'phone': user.phone,
          }),
        )
        .timeout(_timeout);
    if (res.statusCode == 200) return User.fromMap(_decode(res));
    throw ApiException(_error(res, 'Email này đã được đăng ký'));
  }

  Future<User> updateProfile(User user) async {
    final res = await http
        .put(
          Uri.parse('$baseUrl/auth/${user.id}'),
          headers: _headers,
          body: jsonEncode({
            'name': user.name,
            'phone': user.phone,
            'address': user.address,
            'avatar': user.avatar,
          }),
        )
        .timeout(_timeout);
    if (res.statusCode == 200) return User.fromMap(_decode(res));
    throw ApiException(_error(res, 'Cập nhật hồ sơ thất bại'));
  }

  // ===================== PRODUCTS =====================

  Future<List<Product>> getProducts() async {
    final res =
        await http.get(Uri.parse('$baseUrl/products')).timeout(_timeout);
    if (res.statusCode == 200) {
      final list = _decode(res) as List;
      return list.map((e) => Product.fromMap(e as Map<String, dynamic>)).toList();
    }
    throw ApiException('Không tải được danh sách sản phẩm');
  }

  // ===================== ORDERS =====================

  Future<Order> createOrder(Order order) async {
    final res = await http
        .post(
      Uri.parse('$baseUrl/orders'),
      headers: _headers,
      body: jsonEncode({
        'userId': order.userId,
        'total': order.total,
        'address': order.address,
        'paymentMethod': order.paymentMethod,
        'items': order.items
            .map((i) => {
                  'productName': i.productName,
                  'size': i.size,
                  'quantity': i.quantity,
                  'price': i.price,
                })
            .toList(),
      }),
    )
        .timeout(_timeout);
    if (res.statusCode == 200) return Order.fromJson(_decode(res));
    throw ApiException('Đặt hàng thất bại');
  }

  Future<List<Order>> getOrdersByUser(int userId) async {
    final res = await http
        .get(Uri.parse('$baseUrl/orders?userId=$userId'))
        .timeout(_timeout);
    if (res.statusCode == 200) {
      final list = _decode(res) as List;
      return list.map((e) => Order.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw ApiException('Không tải được đơn hàng');
  }

  Future<void> updateOrderStatus(int orderId, String status) async {
    final res = await http
        .put(
          Uri.parse('$baseUrl/orders/$orderId/status'),
          headers: _headers,
          body: jsonEncode({'status': status}),
        )
        .timeout(_timeout);
    if (res.statusCode != 200) {
      throw ApiException('Cập nhật trạng thái thất bại');
    }
  }

  // ===================== MESSAGES (CHAT) =====================

  /// Lấy toàn bộ đoạn chat của user (cũ -> mới).
  Future<List<Message>> getMessages(int userId) async {
    final res = await http
        .get(Uri.parse('$baseUrl/messages?userId=$userId'))
        .timeout(_timeout);
    if (res.statusCode == 200) {
      final list = _decode(res) as List;
      return list.map((e) => Message.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw ApiException('Không tải được tin nhắn');
  }

  /// Gửi 1 tin nhắn. Server lưu tin của mình + tạo tin trả lời tự động
  /// của cửa hàng, rồi trả về cả 2 tin để hiển thị ngay.
  Future<List<Message>> sendMessage(int userId, String text) async {
    final res = await http
        .post(
          Uri.parse('$baseUrl/messages'),
          headers: _headers,
          body: jsonEncode({'userId': userId, 'text': text}),
        )
        .timeout(_timeout);
    if (res.statusCode == 200) {
      final list = _decode(res) as List;
      return list.map((e) => Message.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw ApiException('Gửi tin nhắn thất bại');
  }
}
