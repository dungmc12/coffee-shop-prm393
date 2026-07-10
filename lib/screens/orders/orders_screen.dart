import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../payment/payment_webview_screen.dart';

import '../../models/order.dart';
import '../../services/api_service.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';

/// Màn hình Lịch sử đơn hàng / Thông báo (Thành viên 3).
/// Đọc các đơn đã đặt của user hiện tại từ SQLite và hiển thị.
class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  late Future<List<Order>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _ordersFuture = _loadOrders();
  }

  Future<List<Order>> _loadOrders() {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return Future.value([]);
    return ApiService.instance.getOrdersByUser(user.id!);
  }

  void _refresh() {
    // Gọi _loadOrders() TRƯỚC rồi mới setState (setState không được trả về Future).
    final future = _loadOrders();
    setState(() {
      _ordersFuture = future;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đơn hàng của tôi'),
        actions: [
          IconButton(icon: const Icon(Iconsax.refresh), onPressed: _refresh),
        ],
      ),
      body: FutureBuilder<List<Order>>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final orders = snapshot.data ?? [];
          if (orders.isEmpty) return _emptyState();
          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              // onChanged: tải lại danh sách sau khi đổi trạng thái đơn.
              itemBuilder: (context, i) =>
                  _OrderCard(order: orders[i], onChanged: _refresh),
            ),
          );
        },
      ),
    );
  }

  Widget _emptyState() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Iconsax.receipt_2, size: 90, color: AppTheme.textGrey),
          SizedBox(height: 16),
          Text('Chưa có đơn hàng nào',
              style: TextStyle(fontSize: 18, color: AppTheme.textGrey)),
        ],
      ),
    );
  }
}

/// Thẻ hiển thị 1 đơn hàng + danh sách món bên trong.
class _OrderCard extends StatelessWidget {
  final Order order;
  final VoidCallback onChanged; // gọi để tải lại sau khi đổi trạng thái
  const _OrderCard({required this.order, required this.onChanged});

  /// Màu hiển thị tương ứng từng trạng thái đơn.
  Color get _statusColor {
    switch (order.status) {
      case 'Đã thanh toán':
        return AppTheme.success;
      case 'Đã hủy':
        return AppTheme.danger;
      default: // Chờ thanh toán
        return AppTheme.accent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      // Bấm vào đơn để mở bảng thao tác (thanh toán / hủy).
      onTap: () => _showActions(context),
      child: Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Đơn #${order.id}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(order.status,
                      style: TextStyle(
                        color: _statusColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      )),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(formatDateTime(order.createdAt),
                style: const TextStyle(color: AppTheme.textGrey, fontSize: 13)),
            const Divider(height: 20),
            // Danh sách món trong đơn
            ...order.items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${item.productName} (${item.size}) x${item.quantity}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      Text(formatCurrency(item.price * item.quantity),
                          style: const TextStyle(fontSize: 14)),
                    ],
                  ),
                )),
            const Divider(height: 20),
            Row(
              children: [
                const Icon(Iconsax.location, size: 16, color: AppTheme.textGrey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(order.address,
                      style: const TextStyle(color: AppTheme.textGrey, fontSize: 13)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Iconsax.card, size: 16, color: AppTheme.textGrey),
                const SizedBox(width: 4),
                Text(order.paymentMethod,
                    style: const TextStyle(color: AppTheme.textGrey, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Tổng tiền',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text(formatCurrency(order.total),
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    )),
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }

  /// Mở bảng thao tác cho đơn: thanh toán hoặc hủy.
  void _showActions(BuildContext context) {
    // Đơn đã thanh toán hoặc đã hủy thì không cho thao tác nữa.
    final canAct = order.status == 'Chờ thanh toán';
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Đơn #${order.id} • ${order.status}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            if (canAct) ...[
              // Thanh toán ONLINE: mở trang cổng thanh toán trên trình duyệt.
              ListTile(
                leading: const Icon(Iconsax.card, color: Color(0xFF1A73E8)),
                title: const Text('Thanh toán online'),
                subtitle: const Text('Mở cổng thanh toán (thẻ ngân hàng)',
                    style: TextStyle(fontSize: 12)),
                onTap: () => _payOnline(sheetCtx),
              ),
              // Thanh toán khi nhận hàng: chỉ đổi trạng thái trong hệ thống.
              ListTile(
                leading: const Icon(Iconsax.card_tick, color: AppTheme.success),
                title: const Text('Đã thanh toán tiền mặt'),
                onTap: () => _updateStatus(sheetCtx, 'Đã thanh toán'),
              ),
              ListTile(
                leading: const Icon(Iconsax.close_circle, color: AppTheme.danger),
                title: const Text('Hủy đơn'),
                onTap: () => _updateStatus(sheetCtx, 'Đã hủy'),
              ),
            ] else
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Text('Đơn này đã hoàn tất, không thể thay đổi.',
                    style: TextStyle(color: AppTheme.textGrey)),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// Thanh toán online: mở trang cổng thanh toán NGAY TRONG APP (WebView).
  /// Thanh toán xong backend cập nhật đơn "Đã thanh toán"; WebView đóng lại
  /// và trả về true -> màn Đơn hàng tự tải lại danh sách.
  Future<void> _payOnline(BuildContext sheetCtx) async {
    final url = ApiService.instance.getMockPayUrl(order.id!);
    final navigator = Navigator.of(sheetCtx);
    navigator.pop(); // đóng bottom sheet
    final paid = await navigator.push<bool>(
      MaterialPageRoute(builder: (_) => PaymentWebViewScreen(url: url)),
    );
    if (paid == true) onChanged(); // tải lại đơn để thấy trạng thái mới
  }

  /// Lưu trạng thái mới vào DB rồi yêu cầu màn hình tải lại.
  /// Có try/catch: nếu gọi API lỗi thì hiện thông báo đỏ thay vì im lặng.
  Future<void> _updateStatus(BuildContext sheetCtx, String status) async {
    // Lấy messenger trước khi await để còn hiện SnackBar sau khi sheet đóng.
    final messenger = ScaffoldMessenger.of(sheetCtx);
    try {
      await ApiService.instance.updateOrderStatus(order.id!, status);
      if (sheetCtx.mounted) Navigator.pop(sheetCtx);
      messenger.showSnackBar(
        SnackBar(
          content: Text('Đơn #${order.id}: $status'),
          backgroundColor: AppTheme.success,
          duration: const Duration(seconds: 2),
        ),
      );
      onChanged(); // tải lại danh sách đơn
    } catch (e) {
      if (sheetCtx.mounted) Navigator.pop(sheetCtx);
      messenger.showSnackBar(
        SnackBar(
          content: Text('Lỗi: $e'),
          backgroundColor: AppTheme.danger,
        ),
      );
    }
  }
}
