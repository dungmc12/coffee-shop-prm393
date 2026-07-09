/// Model Product - 1 món đồ uống trong menu.
/// Tương ứng 1 dòng trong bảng "products".
class Product {
  final int? id;
  final String name;
  final double price;
  final String image; // tên icon emoji hoặc đường dẫn ảnh
  final String category; // Cà phê / Trà sữa / Đá xay ...
  final String description;

  Product({
    this.id,
    required this.name,
    required this.price,
    required this.image,
    required this.category,
    required this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'image': image,
      'category': category,
      'description': description,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as int?,
      name: map['name'] as String,
      price: (map['price'] as num).toDouble(),
      image: map['image'] as String,
      category: map['category'] as String,
      description: map['description'] as String,
    );
  }
}
