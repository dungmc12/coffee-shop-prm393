/// Model Order - 1 đơn hàng đã đặt.
/// Tương ứng 1 dòng bảng "orders". Chi tiết món nằm ở bảng "order_items".
class Order {
  final int? id;
  final int userId;
  final double total;
  final String address;
  final String paymentMethod;
  final String status;
  final String createdAt; // ISO string ngày giờ đặt
  final List<OrderItem> items;

  Order({
    this.id,
    required this.userId,
    required this.total,
    required this.address,
    required this.paymentMethod,
    this.status = 'Chờ thanh toán',
    required this.createdAt,
    this.items = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'total': total,
      'address': address,
      'paymentMethod': paymentMethod,
      'status': status,
      'createdAt': createdAt,
    };
  }

  /// Tạo Order từ JSON trả về bởi API .NET (có sẵn mảng items).
  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as int?,
      userId: json['userId'] as int,
      total: (json['total'] as num).toDouble(),
      address: json['address'] as String,
      paymentMethod: json['paymentMethod'] as String,
      status: json['status'] as String,
      createdAt: json['createdAt'] as String,
      items: ((json['items'] ?? []) as List)
          .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  factory Order.fromMap(Map<String, dynamic> map, {List<OrderItem> items = const []}) {
    return Order(
      id: map['id'] as int?,
      userId: map['userId'] as int,
      total: (map['total'] as num).toDouble(),
      address: map['address'] as String,
      paymentMethod: map['paymentMethod'] as String,
      status: map['status'] as String,
      createdAt: map['createdAt'] as String,
      items: items,
    );
  }
}

/// Chi tiết 1 món trong đơn hàng.
class OrderItem {
  final int? id;
  final int orderId;
  final String productName;
  final String size;
  final int quantity;
  final double price; // đơn giá tại thời điểm mua

  OrderItem({
    this.id,
    required this.orderId,
    required this.productName,
    required this.size,
    required this.quantity,
    required this.price,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'orderId': orderId,
      'productName': productName,
      'size': size,
      'quantity': quantity,
      'price': price,
    };
  }

  /// Tạo OrderItem từ JSON trả về bởi API .NET.
  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] as int?,
      orderId: json['orderId'] as int,
      productName: json['productName'] as String,
      size: json['size'] as String,
      quantity: json['quantity'] as int,
      price: (json['price'] as num).toDouble(),
    );
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      id: map['id'] as int?,
      orderId: map['orderId'] as int,
      productName: map['productName'] as String,
      size: map['size'] as String,
      quantity: map['quantity'] as int,
      price: (map['price'] as num).toDouble(),
    );
  }
}
