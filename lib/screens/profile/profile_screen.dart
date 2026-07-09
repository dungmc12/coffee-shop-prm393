import 'dart:io';

import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/validators.dart';

/// Màn hình Hồ sơ (Thành viên 1).
/// Hiển thị thông tin người dùng, cho phép sửa và đăng xuất.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // watch: lắng nghe để tự cập nhật khi user thay đổi thông tin.
    final user = context.watch<AuthProvider>().currentUser;
    if (user == null) return const SizedBox();

    return Scaffold(
      appBar: AppBar(title: const Text('Hồ sơ của tôi')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Phần đầu: avatar + tên + email
          Center(
            child: Column(
              children: [
                // Chạm vào avatar (hoặc nút máy ảnh) để đổi ảnh đại diện.
                Stack(
                  children: [
                    GestureDetector(
                      onTap: () => _pickAvatar(context),
                      child: CircleAvatar(
                        radius: 48,
                        backgroundColor: AppTheme.accent,
                        // Nếu có ảnh thì hiển thị ảnh, không thì hiển thị chữ cái đầu.
                        backgroundImage: user.avatar.isNotEmpty
                            ? FileImage(File(user.avatar))
                            : null,
                        child: user.avatar.isNotEmpty
                            ? null
                            : Text(
                                user.name.isNotEmpty
                                    ? user.name[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  fontSize: 42,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    // Nút máy ảnh nhỏ ở góc dưới avatar.
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: GestureDetector(
                        onTap: () => _pickAvatar(context),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Iconsax.camera,
                              color: Colors.white, size: 18),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  user.name,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                Text(user.email, style: const TextStyle(color: AppTheme.textGrey)),
              ],
            ),
          ),
          const SizedBox(height: 30),
          _infoTile(Iconsax.call, 'Số điện thoại',
              user.phone.isEmpty ? 'Chưa cập nhật' : user.phone),
          _infoTile(Iconsax.location, 'Địa chỉ',
              user.address.isEmpty ? 'Chưa cập nhật' : user.address),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => _showEditDialog(context),
            icon: const Icon(Iconsax.edit_2, size: 20),
            label: const Text('Chỉnh sửa thông tin'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              foregroundColor: AppTheme.primary,
              side: const BorderSide(color: AppTheme.primary),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {
              // Đăng xuất: xóa giỏ + thoát phiên đăng nhập.
              context.read<CartProvider>().clear();
              context.read<AuthProvider>().logout();
            },
            icon: const Icon(Iconsax.logout, size: 20),
            label: const Text('Đăng xuất'),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
          ),
        ],
      ),
    );
  }

  /// Hiện bảng chọn nguồn ảnh (Máy ảnh / Thư viện) rồi đổi avatar.
  void _pickAvatar(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Đổi ảnh đại diện',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            ListTile(
              leading: const Icon(Iconsax.camera, color: AppTheme.primary),
              title: const Text('Chụp ảnh'),
              onTap: () {
                Navigator.pop(sheetCtx);
                _getImage(context, ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Iconsax.gallery, color: AppTheme.primary),
              title: const Text('Chọn từ thư viện'),
              onTap: () {
                Navigator.pop(sheetCtx);
                _getImage(context, ImageSource.gallery);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// Lấy ảnh từ nguồn đã chọn, copy vào thư mục app rồi lưu vào DB.
  Future<void> _getImage(BuildContext context, ImageSource source) async {
    final auth = context.read<AuthProvider>();
    final picker = ImagePicker();
    // imageQuality: nén nhẹ cho ảnh đỡ nặng.
    final picked = await picker.pickImage(source: source, imageQuality: 70);
    if (picked == null) return; // người dùng hủy chọn

    // Copy ảnh vào thư mục riêng của app để không bị xóa theo cache.
    final dir = await getApplicationDocumentsDirectory();
    final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}${p.extension(picked.path)}';
    final saved = await File(picked.path).copy(p.join(dir.path, fileName));

    await auth.updateAvatar(saved.path);
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primary),
        title: Text(label, style: const TextStyle(color: AppTheme.textGrey, fontSize: 13)),
        subtitle: Text(value, style: const TextStyle(fontSize: 16, color: AppTheme.textDark)),
      ),
    );
  }

  /// Hộp thoại chỉnh sửa thông tin -> lưu vào SQLite qua AuthProvider.
  void _showEditDialog(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final user = auth.currentUser!;
    final nameCtrl = TextEditingController(text: user.name);
    final phoneCtrl = TextEditingController(text: user.phone);
    final addressCtrl = TextEditingController(text: user.address);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Chỉnh sửa thông tin'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Họ và tên'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Số điện thoại'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addressCtrl,
                decoration: const InputDecoration(labelText: 'Địa chỉ'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Kiểm tra số điện thoại trước khi lưu.
              final phoneError = Validators.phone(phoneCtrl.text);
              if (phoneError != null) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(content: Text(phoneError), backgroundColor: AppTheme.danger),
                );
                return;
              }
              await auth.updateProfile(
                name: nameCtrl.text.trim(),
                phone: phoneCtrl.text.trim(),
                address: addressCtrl.text.trim(),
              );
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(minimumSize: const Size(90, 44)),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }
}
