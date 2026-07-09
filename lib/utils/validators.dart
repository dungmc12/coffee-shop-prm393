/// Các hàm kiểm tra hợp lệ (validation) dùng chung cho toàn app.
/// Mỗi hàm trả về null nếu hợp lệ, hoặc chuỗi lỗi để hiển thị dưới ô nhập.
class Validators {
  // Biểu thức chính quy (RegExp) kiểm tra email đúng định dạng:
  // có phần tên, dấu @, tên miền và phần đuôi (vd .com) ít nhất 2 ký tự.
  static final RegExp _emailReg =
      RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');

  // Số điện thoại Việt Nam: bắt đầu bằng số 0, tổng cộng 10 hoặc 11 chữ số.
  static final RegExp _phoneReg = RegExp(r'^0[0-9]{9,10}$');

  /// Kiểm tra email.
  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Vui lòng nhập email';
    if (!_emailReg.hasMatch(v)) return 'Email không hợp lệ (ví dụ: ten@gmail.com)';
    return null;
  }

  /// Kiểm tra số điện thoại.
  static String? phone(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Vui lòng nhập số điện thoại';
    if (!_phoneReg.hasMatch(v)) {
      return 'SĐT phải bắt đầu bằng 0 và có 10–11 số';
    }
    return null;
  }

  /// Kiểm tra mật khẩu (tối thiểu 6 ký tự).
  static String? password(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Vui lòng nhập mật khẩu';
    if (v.length < 6) return 'Mật khẩu tối thiểu 6 ký tự';
    return null;
  }
}
