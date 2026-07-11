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
  /// Tìm kiếm KHÔNG cần gõ dấu và bỏ qua dấu cách:
  /// "caphe", "ca phe", "Cà phê" đều ra "Cà phê".
  List<Product> get products {
    final query = _chuanHoa(_search);
    return _products.where((p) {
      final matchCategory = _category == 'Tất cả' || p.category == _category;
      final matchSearch = _chuanHoa(p.name).contains(query);
      return matchCategory && matchSearch;
    }).toList();
  }

  /// Chuẩn hóa chuỗi để tìm kiếm: chữ thường + bỏ dấu + bỏ khoảng trắng.
  String _chuanHoa(String s) => _boDau(s.toLowerCase()).replaceAll(' ', '');

  /// Bỏ dấu tiếng Việt để so khớp khi tìm kiếm (à→a, ê→e, đ→d...).
  String _boDau(String s) {
    const nhom = {
      'a': 'àáảãạăằắẳẵặâầấẩẫậ',
      'e': 'èéẻẽẹêềếểễệ',
      'i': 'ìíỉĩị',
      'o': 'òóỏõọôồốổỗộơờớởỡợ',
      'u': 'ùúủũụưừứửữự',
      'y': 'ỳýỷỹỵ',
      'd': 'đ',
    };
    final buf = StringBuffer();
    for (final ch in s.split('')) {
      var thay = ch;
      for (final e in nhom.entries) {
        if (e.value.contains(ch)) {
          thay = e.key;
          break;
        }
      }
      buf.write(thay);
    }
    return buf.toString();
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
