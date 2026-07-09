import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../../models/order.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';

/// Màn hình Thông báo (Thành viên 3).
/// Thông báo được sinh ra từ dữ liệu thật: mỗi đơn hàng và trạng thái của nó
/// tạo thành 1 thông báo (đặt thành công / đã thanh toán / đã hủy),
/// kèm các thông báo ưu đãi của cửa hàng.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late Future<List<_NotificationItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadNotifications();
  }

  /// Đọc đơn hàng từ API rồi chuyển mỗi đơn thành 1 thông báo.
  Future<List<_NotificationItem>> _loadNotifications() async {
    final user = context.read<AuthProvider>().currentUser;
    final items = <_NotificationItem>[];

    if (user != null) {
      final orders = await ApiService.instance.getOrdersByUser(user.id!);
      for (final order in orders) {
        items.add(_fromOrder(order));
      }
    }

    // Thông báo ưu đãi chung của cửa hàng (luôn hiển thị cuối danh sách).
    items.add(_NotificationItem(
      icon: Iconsax.gift,
      color: AppTheme.accent,
      title: 'Ưu đãi hôm nay 🎉',
      body: 'Freeship cho mọi đơn từ 2 món. Đặt ngay kẻo lỡ!',
      time: '',
    ));
    items.add(_NotificationItem(
      icon: Iconsax.coffee,
      color: AppTheme.primary,
      title: 'Chào mừng bạn đến Coffee Shop',
      body: 'Khám phá 17 đồ uống với ảnh thật và đặt món trong 1 phút.',
      time: '',
    ));
    return items;
  }

  /// Chuyển 1 đơn hàng thành 1 thông báo theo trạng thái.
  _NotificationItem _fromOrder(Order order) {
    switch (order.status) {
      case 'Đã thanh toán':
        return _NotificationItem(
          icon: Iconsax.tick_circle,
          color: AppTheme.success,
          title: 'Đơn #${order.id} đã thanh toán',
          body: 'Cảm ơn bạn! Đơn ${formatCurrency(order.total)} đang được pha chế.',
          time: formatDateTime(order.createdAt),
        );
      case 'Đã hủy':
        return _NotificationItem(
          icon: Iconsax.close_circle,
          color: AppTheme.danger,
          title: 'Đơn #${order.id} đã hủy',
          body: 'Đơn hàng của bạn đã được hủy thành công.',
          time: formatDateTime(order.createdAt),
        );
      default: // Chờ thanh toán
        return _NotificationItem(
          icon: Iconsax.clock,
          color: AppTheme.accent,
          title: 'Đơn #${order.id} đặt thành công',
          body:
              'Đơn ${formatCurrency(order.total)} đang chờ thanh toán. Vào mục Đơn hàng để thanh toán nhé!',
          time: formatDateTime(order.createdAt),
        );
    }
  }

  void _refresh() => setState(() => _future = _loadNotifications());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo'),
        actions: [
          IconButton(icon: const Icon(Iconsax.refresh), onPressed: _refresh),
        ],
      ),
      body: FutureBuilder<List<_NotificationItem>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data ?? [];
          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, i) => _NotificationCard(item: items[i]),
            ),
          );
        },
      ),
    );
  }
}

/// Dữ liệu 1 thông báo hiển thị.
class _NotificationItem {
  final IconData icon;
  final Color color;
  final String title;
  final String body;
  final String time;
  _NotificationItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
    required this.time,
  });
}

/// Thẻ hiển thị 1 thông báo: icon tròn màu + tiêu đề + nội dung + thời gian.
class _NotificationCard extends StatelessWidget {
  final _NotificationItem item;
  const _NotificationCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.softShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(item.icon, color: item.color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 3),
                Text(item.body,
                    style: const TextStyle(
                        color: AppTheme.textGrey, fontSize: 13, height: 1.4)),
                if (item.time.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(item.time,
                      style: const TextStyle(
                          color: AppTheme.textGrey, fontSize: 11)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
