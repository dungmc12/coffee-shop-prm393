import 'package:flutter/material.dart';

import '../models/cart_item.dart';
import '../models/product.dart';

/// CartProvider - quản lý trạng thái giỏ hàng.
/// Mọi thao tác thêm/sửa/xóa đều gọi notifyListeners() để UI cập nhật.
class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);

  /// Tổng số lượng món (để hiển thị badge trên icon giỏ).
  int get totalQuantity => _items.fold(0, (sum, e) => sum + e.quantity);

  /// Tổng tiền tạm tính của cả giỏ.
  double get subtotal => _items.fold(0, (sum, e) => sum + e.totalPrice);

  bool get isEmpty => _items.isEmpty;

  /// Thêm sản phẩm vào giỏ. Nếu trùng (cùng sp + size) thì tăng số lượng.
  void addToCart(Product product, {String size = 'M', int quantity = 1}) {
    final index = _items.indexWhere(
      (e) => e.product.id == product.id && e.size == size,
    );
    if (index >= 0) {
      _items[index].quantity += quantity;
    } else {
      _items.add(CartItem(product: product, size: size, quantity: quantity));
    }
    notifyListeners();
  }

  void increase(CartItem item) {
    item.quantity++;
    notifyListeners();
  }

  void decrease(CartItem item) {
    if (item.quantity > 1) {
      item.quantity--;
    } else {
      _items.remove(item);
    }
    notifyListeners();
  }

  void remove(CartItem item) {
    _items.remove(item);
    notifyListeners();
  }

  /// Xóa sạch giỏ (gọi sau khi đặt hàng thành công).
  void clear() {
    _items.clear();
    notifyListeners();
  }
}
