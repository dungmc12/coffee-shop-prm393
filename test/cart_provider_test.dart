// UNIT TEST - kiểm thử logic nghiệp vụ của giỏ hàng (CartProvider).
// Chạy: flutter test test/cart_provider_test.dart
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile_application_development/models/product.dart';
import 'package:mobile_application_development/providers/cart_provider.dart';

void main() {
  // Sản phẩm mẫu giá 25.000đ dùng chung cho các test.
  final coffee = Product(
    id: 1,
    name: 'Cà phê đen',
    price: 25000,
    image: '☕',
    category: 'Cà phê',
    description: 'Test',
  );

  group('CartProvider - logic giỏ hàng', () {
    test('Thêm sản phẩm thì tổng số lượng và tạm tính đúng', () {
      final cart = CartProvider();
      // size M cộng phụ thu 5.000đ -> đơn giá 30.000đ
      cart.addToCart(coffee, size: 'M', quantity: 2);

      expect(cart.totalQuantity, 2);
      expect(cart.subtotal, 60000); // 30.000 * 2
    });

    test('Thêm trùng sản phẩm + size thì gộp số lượng', () {
      final cart = CartProvider();
      cart.addToCart(coffee, size: 'M', quantity: 1);
      cart.addToCart(coffee, size: 'M', quantity: 3);

      expect(cart.items.length, 1); // chỉ 1 dòng
      expect(cart.totalQuantity, 4);
    });

    test('Phụ thu theo size: L cộng 10.000đ', () {
      final cart = CartProvider();
      cart.addToCart(coffee, size: 'L', quantity: 1);

      // 25.000 + 10.000 = 35.000
      expect(cart.subtotal, 35000);
    });

    test('Giảm số lượng về 0 thì xóa món khỏi giỏ', () {
      final cart = CartProvider();
      cart.addToCart(coffee, size: 'S', quantity: 1);
      cart.decrease(cart.items.first);

      expect(cart.isEmpty, true);
    });

    test('clear() làm rỗng giỏ hàng', () {
      final cart = CartProvider();
      cart.addToCart(coffee, quantity: 5);
      cart.clear();

      expect(cart.isEmpty, true);
      expect(cart.subtotal, 0);
    });
  });
}
