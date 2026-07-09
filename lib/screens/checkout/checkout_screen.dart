import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../../models/order.dart';
import '../../services/api_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';

/// Màn hình Thanh toán (Thành viên 3).
/// Nhập địa chỉ, chọn phương thức thanh toán, đặt hàng -> lưu vào SQLite.
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _addressCtrl = TextEditingController();
  String _payment = 'Tiền mặt';
  bool _placing = false;

  static const double _shippingFee = 15000;

  @override
  void initState() {
    super.initState();
    // Tự điền sẵn địa chỉ từ hồ sơ người dùng (nếu có).
    final user = context.read<AuthProvider>().currentUser;
    _addressCtrl.text = user?.address ?? '';
  }

  @override
  void dispose() {
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _placeOrder(CartProvider cart) async {
    if (_addressCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập địa chỉ giao hàng')),
      );
      return;
    }
    setState(() => _placing = true);

    final user = context.read<AuthProvider>().currentUser!;
    final total = cart.subtotal + _shippingFee;

    // Tạo đối tượng đơn hàng cùng danh sách chi tiết.
    final order = Order(
      userId: user.id!,
      total: total,
      address: _addressCtrl.text.trim(),
      paymentMethod: _payment,
      createdAt: DateTime.now().toIso8601String(),
      items: cart.items
          .map((c) => OrderItem(
                orderId: 0, // server sẽ tự gán orderId khi lưu
                productName: c.product.name,
                size: c.size,
                quantity: c.quantity,
                price: c.unitPrice,
              ))
          .toList(),
    );

    // Gửi đơn hàng lên server (lưu vào SQL Server qua API).
    await ApiService.instance.createOrder(order);
    cart.clear();

    if (!mounted) return;
    setState(() => _placing = false);
    _showSuccessDialog();
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Iconsax.tick_circle, color: AppTheme.success, size: 80),
            const SizedBox(height: 12),
            const Text(
              'Đặt hàng thành công!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'Đơn hàng của bạn đã được ghi nhận và đang được xử lý.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textGrey),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx); // đóng dialog
                Navigator.pop(context); // quay về giỏ -> main
              },
              child: const Text('Về trang chủ'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final total = cart.subtotal + _shippingFee;

    return Scaffold(
      appBar: AppBar(title: const Text('Thanh toán')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _sectionTitle('Địa chỉ giao hàng'),
          TextField(
            controller: _addressCtrl,
            maxLines: 2,
            decoration: const InputDecoration(
              hintText: 'Nhập địa chỉ nhận hàng...',
              prefixIcon: Icon(Iconsax.location, size: 20),
            ),
          ),
          const SizedBox(height: 20),
          _sectionTitle('Phương thức thanh toán'),
          _paymentTile('Tiền mặt', Iconsax.money_3),
          _paymentTile('Chuyển khoản', Iconsax.bank),
          _paymentTile('Ví Momo', Iconsax.wallet_2),
          const SizedBox(height: 20),
          _sectionTitle('Tóm tắt đơn hàng'),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  ...cart.items.map((c) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text('${c.product.name} (${c.size}) x${c.quantity}'),
                            ),
                            Text(formatCurrency(c.totalPrice)),
                          ],
                        ),
                      )),
                  const Divider(),
                  _summaryRow('Tạm tính', formatCurrency(cart.subtotal)),
                  _summaryRow('Phí giao hàng', formatCurrency(_shippingFee)),
                  const Divider(),
                  _summaryRow('Tổng cộng', formatCurrency(total), highlight: true),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: _placing || cart.isEmpty ? null : () => _placeOrder(cart),
            child: _placing
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  )
                : Text('Đặt hàng • ${formatCurrency(total)}'),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(text,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      );

  Widget _paymentTile(String name, IconData icon) {
    final selected = _payment == name;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: selected ? AppTheme.accent.withValues(alpha: 0.15) : Colors.white,
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primary),
        title: Text(name),
        trailing: selected
            ? const Icon(Iconsax.tick_circle, color: AppTheme.primary)
            : const Icon(Iconsax.record, color: AppTheme.textGrey),
        onTap: () => setState(() => _payment = name),
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                color: highlight ? AppTheme.textDark : AppTheme.textGrey,
                fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
                fontSize: highlight ? 17 : 14,
              )),
          Text(value,
              style: TextStyle(
                color: highlight ? AppTheme.primary : AppTheme.textDark,
                fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
                fontSize: highlight ? 19 : 14,
              )),
        ],
      ),
    );
  }
}
