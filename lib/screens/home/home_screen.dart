import 'dart:io';

import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../../models/product.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../chat/chat_screen.dart';
import '../map/store_map_screen.dart';
import '../notifications/notifications_screen.dart';
import '../product/product_detail_screen.dart';

/// Màn hình Trang chủ / Danh sách đồ uống (Thành viên 2).
/// Thiết kế: header chào + avatar, banner khuyến mãi, ô tìm kiếm,
/// thanh lọc theo loại và lưới sản phẩm.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Nạp sản phẩm từ database ngay khi mở màn hình.
    // addPostFrameCallback để gọi sau khi build xong, tránh lỗi.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();

    return Scaffold(
      // Nút chat hỗ trợ nổi ở góc dưới phải.
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ChatScreen()),
          );
        },
        child: const Icon(Iconsax.message),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => productProvider.loadProducts(),
          child: CustomScrollView(
            slivers: [
              // Header: lời chào + avatar + nút bản đồ.
              SliverToBoxAdapter(child: _buildHeader(context)),
              // Ô tìm kiếm dạng viên thuốc có bóng đổ.
              SliverToBoxAdapter(child: _buildSearchBar(productProvider)),
              // Banner khuyến mãi.
              SliverToBoxAdapter(child: _buildPromoBanner()),
              // Thanh lọc theo loại.
              SliverToBoxAdapter(child: _buildCategoryFilter(productProvider)),
              // Lưới sản phẩm hoặc loading.
              if (productProvider.loading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                _buildProductGrid(productProvider.products),
            ],
          ),
        ),
      ),
    );
  }

  /// Header: chào người dùng theo tên + avatar + nút mở bản đồ cửa hàng.
  Widget _buildHeader(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Row(
        children: [
          // Avatar nhỏ (ảnh thật nếu có, không thì chữ cái đầu).
          CircleAvatar(
            radius: 24,
            backgroundColor: AppTheme.accent,
            backgroundImage: (user != null && user.avatar.isNotEmpty)
                ? FileImage(File(user.avatar))
                : null,
            child: (user == null || user.avatar.isEmpty)
                ? Text(
                    (user?.name.isNotEmpty ?? false)
                        ? user!.name[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Chào buổi sáng ☀️',
                    style: TextStyle(color: AppTheme.textGrey, fontSize: 13)),
                Text(
                  user?.name ?? 'bạn',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          // Nút mở màn Thông báo.
          _roundIconButton(
            icon: Iconsax.notification,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              );
            },
          ),
          const SizedBox(width: 10),
          // Nút mở bản đồ cửa hàng gần bạn.
          _roundIconButton(
            icon: Iconsax.location,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StoreMapScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Nút icon tròn nền trắng có bóng nhẹ (dùng ở header).
  Widget _roundIconButton({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: AppTheme.softShadow,
        ),
        child: Icon(icon, size: 22, color: AppTheme.primary),
      ),
    );
  }

  /// Ô tìm kiếm bo tròn, icon Iconsax.
  Widget _buildSearchBar(ProductProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.softShadow,
        ),
        child: TextField(
          onChanged: provider.setSearch,
          decoration: const InputDecoration(
            hintText: 'Bạn muốn uống gì hôm nay?',
            prefixIcon: Icon(Iconsax.search_normal_1, size: 20),
          ),
        ),
      ),
    );
  }

  /// Banner khuyến mãi: gradient nâu + ảnh sản phẩm nổi bật.
  Widget _buildPromoBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          gradient: AppTheme.coffeeGradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: AppTheme.softShadow,
        ),
        child: Row(
          children: [
            // Chữ khuyến mãi bên trái.
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.accent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Ưu đãi hôm nay',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryDark,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Freeship đơn từ 2 món',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Áp dụng cho mọi đồ uống',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Ảnh sản phẩm bên phải, bo tròn theo banner.
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(24)),
              child: Image.asset(
                'assets/images/caramel_macchiato.jpg',
                width: 130,
                height: 140,
                fit: BoxFit.cover,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Thanh chọn loại đồ uống (chip bo tròn).
  Widget _buildCategoryFilter(ProductProvider provider) {
    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        itemCount: provider.categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final cat = provider.categories[i];
          final selected = cat == provider.category;
          return GestureDetector(
            onTap: () => provider.setCategory(cat),
            // AnimatedContainer: đổi màu mượt khi chọn.
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? AppTheme.primary : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: selected ? AppTheme.softShadow : null,
              ),
              child: Text(
                cat,
                style: TextStyle(
                  color: selected ? Colors.white : AppTheme.textGrey,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductGrid(List<Product> products) {
    if (products.isEmpty) {
      return const SliverFillRemaining(
        child: Center(child: Text('Không tìm thấy sản phẩm nào')),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.72,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, i) => _ProductCard(product: products[i]),
          childCount: products.length,
        ),
      ),
    );
  }
}

/// Thẻ hiển thị 1 sản phẩm trong lưới: ảnh thật, tên, loại, giá + nút thêm.
class _ProductCard extends StatelessWidget {
  final Product product;
  const _ProductCard({required this.product});

  void _openDetail(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openDetail(context),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: AppTheme.softShadow,
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ảnh thật của sản phẩm, bo tròn.
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  product.image,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              product.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            Text(
              product.category,
              style: const TextStyle(color: AppTheme.textGrey, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  formatCurrency(product.price),
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                // Nút thêm nhanh: mở màn chi tiết để chọn size/số lượng.
                InkWell(
                  onTap: () => _openDetail(context),
                  customBorder: const CircleBorder(),
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: const BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Iconsax.add,
                        color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
