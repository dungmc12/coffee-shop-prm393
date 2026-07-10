import 'package:flutter/material.dart';

import '../models/user.dart';
import '../services/api_service.dart';

/// AuthProvider - quản lý trạng thái đăng nhập của người dùng.
///
/// ChangeNotifier: khi gọi notifyListeners() thì các widget đang "lắng nghe"
/// (Consumer / context.watch) sẽ tự build lại. Đây là cốt lõi của Provider.
/// Dữ liệu lấy qua ApiService (gọi backend .NET), không còn dùng SQLite.
class AuthProvider extends ChangeNotifier {
  final ApiService _api = ApiService.instance;

  User? _currentUser;
  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  /// Đăng nhập. Trả về null nếu thành công, hoặc chuỗi lỗi để hiển thị.
  Future<String?> login(String email, String password) async {
    try {
      _currentUser = await _api.login(email.trim(), password);
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Không kết nối được máy chủ. Kiểm tra backend đã chạy chưa.';
    }
  }

  /// Đăng ký tài khoản mới.
  Future<String?> register(User user) async {
    try {
      // Đăng ký xong server trả về user (kèm id) -> tự đăng nhập luôn.
      _currentUser = await _api.register(user);
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Không kết nối được máy chủ. Kiểm tra backend đã chạy chưa.';
    }
  }

  /// Cập nhật hồ sơ người dùng hiện tại.
  Future<void> updateProfile({required String name, required String phone, required String address}) async {
    if (_currentUser == null) return;
    final updated = _currentUser!.copyWith(name: name, phone: phone, address: address);
    _currentUser = await _api.updateProfile(updated);
    notifyListeners();
  }

  /// Cập nhật ảnh đại diện (gửi đường dẫn file lên server).
  Future<void> updateAvatar(String avatarPath) async {
    if (_currentUser == null) return;
    final updated = _currentUser!.copyWith(avatar: avatarPath);
    _currentUser = await _api.updateProfile(updated);
    notifyListeners();
  }

  /// Đổi mật khẩu (đang đăng nhập). Trả về null nếu OK, hoặc chuỗi lỗi.
  Future<String?> changePassword(String oldPassword, String newPassword) async {
    if (_currentUser == null) return 'Chưa đăng nhập';
    try {
      await _api.changePassword(_currentUser!.id!, oldPassword, newPassword);
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Không kết nối được máy chủ. Kiểm tra backend đã chạy chưa.';
    }
  }

  /// Đăng xuất.
  void logout() {
    _currentUser = null;
    notifyListeners();
  }
}
