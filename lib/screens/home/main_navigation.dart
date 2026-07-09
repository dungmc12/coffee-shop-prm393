import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../../providers/cart_provider.dart';
import '../../theme/app_theme.dart';
import '../cart/cart_screen.dart';
import '../orders/orders_screen.dart';
import '../profile/profile_screen.dart';
import 'home_screen.dart';

/// MainNavigation - khung chính sau khi đăng nhập, chứa thanh điều hướng dưới.
/// 4 tab: Trang chủ - Giỏ hàng - Đơn hàng - Hồ sơ (icon bộ Iconsax).
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _index = 0;
  // Bộ đếm để buộc màn Đơn hàng tải lại mỗi khi mở tab này.
  int _ordersKey = 0;

  @override
  Widget build(BuildContext context) {
    // Lấy số lượng món trong giỏ để hiển thị badge.
    final cartCount = context.watch<CartProvider>().totalQuantity;

    // Đổi ValueKey mỗi lần mở tab Đơn hàng -> widget được tạo lại
    // và initState chạy lại để nạp đơn mới nhất từ database.
    final screens = [
      const HomeScreen(),
      const CartScreen(),
      OrdersScreen(key: ValueKey(_ordersKey)),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() {
          _index = i;
          if (i == 2) _ordersKey++; // mở tab Đơn hàng -> tải lại
        }),
        backgroundColor: Colors.white,
        indicatorColor: AppTheme.accent.withValues(alpha: 0.25),
        destinations: [
          const NavigationDestination(
            icon: Icon(Iconsax.home_2),
            selectedIcon: Icon(Iconsax.home_2, color: AppTheme.primary),
            label: 'Trang chủ',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: cartCount > 0,
              label: Text('$cartCount'),
              child: const Icon(Iconsax.shopping_cart),
            ),
            selectedIcon:
                const Icon(Iconsax.shopping_cart, color: AppTheme.primary),
            label: 'Giỏ hàng',
          ),
          const NavigationDestination(
            icon: Icon(Iconsax.receipt_2),
            selectedIcon: Icon(Iconsax.receipt_2, color: AppTheme.primary),
            label: 'Đơn hàng',
          ),
          const NavigationDestination(
            icon: Icon(Iconsax.user),
            selectedIcon: Icon(Iconsax.user, color: AppTheme.primary),
            label: 'Hồ sơ',
          ),
        ],
      ),
    );
  }
}
