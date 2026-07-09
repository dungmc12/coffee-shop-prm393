import 'package:intl/intl.dart';

/// Hàm tiện ích định dạng giá tiền sang dạng "35.000đ".
String formatCurrency(double value) {
  final formatter = NumberFormat('#,###', 'vi_VN');
  return '${formatter.format(value)}đ';
}

/// Định dạng chuỗi ngày ISO sang "dd/MM/yyyy HH:mm".
/// toLocal(): đổi về giờ địa phương (server trả ISO kèm múi giờ,
/// nếu không đổi sẽ hiển thị lệch 7 tiếng so với giờ Việt Nam).
String formatDateTime(String iso) {
  try {
    final dt = DateTime.parse(iso).toLocal();
    return DateFormat('dd/MM/yyyy HH:mm').format(dt);
  } catch (_) {
    return iso;
  }
}
