/// Model User - đại diện cho 1 người dùng (khách hàng).
/// Mỗi đối tượng tương ứng 1 dòng trong bảng "users" của SQLite.
class User {
  final int? id; // null khi chưa lưu vào DB, DB tự sinh id
  final String name;
  final String email;
  final String password;
  final String phone;
  final String address;
  final String avatar; // đường dẫn file ảnh đại diện ('' nếu chưa có)

  User({
    this.id,
    required this.name,
    required this.email,
    required this.password,
    this.phone = '',
    this.address = '',
    this.avatar = '',
  });

  /// Chuyển User -> Map để ghi vào SQLite (insert/update).
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'password': password,
      'phone': phone,
      'address': address,
      'avatar': avatar,
    };
  }

  /// Tạo User từ Map đọc được từ SQLite (query).
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int?,
      name: map['name'] as String,
      email: map['email'] as String,
      password: map['password'] as String,
      phone: (map['phone'] ?? '') as String,
      address: (map['address'] ?? '') as String,
      avatar: (map['avatar'] ?? '') as String,
    );
  }

  /// Tạo bản sao có sửa vài trường (dùng khi cập nhật hồ sơ).
  User copyWith({String? name, String? phone, String? address, String? avatar}) {
    return User(
      id: id,
      name: name ?? this.name,
      email: email,
      password: password,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      avatar: avatar ?? this.avatar,
    );
  }
}
