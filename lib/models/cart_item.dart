import 'product.dart';

/// Model CartItem - 1 dòng trong giỏ hàng (1 sản phẩm + size + số lượng).
class CartItem {
  final Product product;
  final String size; // S / M / L
  int quantity;

  CartItem({
    required this.product,
    this.size = 'M',
    this.quantity = 1,
  });

  /// Phụ thu theo size: S = 0đ, M = +5.000đ, L = +10.000đ
  double get sizeExtra {
    switch (size) {
      case 'S':
        return 0;
      case 'L':
        return 10000;
      default:
        return 5000;
    }
  }

  /// Đơn giá đã cộng phụ thu size.
  double get unitPrice => product.price + sizeExtra;

  /// Thành tiền của dòng này = đơn giá * số lượng.
  double get totalPrice => unitPrice * quantity;
}
