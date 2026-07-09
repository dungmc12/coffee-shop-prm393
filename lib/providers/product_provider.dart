import 'package:flutter/material.dart';

import '../models/product.dart';
import '../services/api_service.dart';

/// ProductProvider - tải & lọc danh sách sản phẩm từ backend (API).
class ProductProvider extends ChangeNotifier {
  final ApiService _api = ApiService.instance;

  List<Product> _products = [];
  bool _loading = false;
  String _search = '';
  String _category = 'Tất cả';

  bool get loading => _loading;
  String get category => _category;

  /// Danh sách các loại để hiển thị thanh lọc.
  List<String> get categories {
    final set = {'Tất cả', ..._products.map((p) => p.category)};
    return set.toList();
  }

  /// Sản phẩm sau khi áp dụng tìm kiếm + lọc theo loại.
  List<Product> get products {
    return _products.where((p) {
      final matchCategory = _category == 'Tất cả' || p.category == _category;
      final matchSearch = p.name.toLowerCase().contains(_search.toLowerCase());
      return matchCategory && matchSearch;
    }).toList();
  }

  /// Nạp dữ liệu sản phẩm từ SQLite.
  Future<void> loadProducts() async {
    _loading = true;
    notifyListeners();
    _products = await _api.getProducts();
    _loading = false;
    notifyListeners();
  }

  void setSearch(String value) {
    _search = value;
    notifyListeners();
  }

  void setCategory(String value) {
    _category = value;
    notifyListeners();
  }
}
