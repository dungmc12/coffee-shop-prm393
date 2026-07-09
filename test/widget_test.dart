// WIDGET TEST - kiểm thử giao diện màn hình Đăng nhập.
// Chạy: flutter test test/widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:mobile_application_development/providers/auth_provider.dart';
import 'package:mobile_application_development/screens/auth/login_screen.dart';

void main() {
  // Hàm dựng LoginScreen kèm Provider để test.
  Widget buildTestable() {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: const MaterialApp(home: LoginScreen()),
    );
  }

  testWidgets('Màn Đăng nhập hiển thị đủ thành phần chính', (tester) async {
    await tester.pumpWidget(buildTestable());

    // Có tiêu đề ứng dụng và nút Đăng nhập.
    expect(find.text('Coffee Shop'), findsOneWidget);
    expect(find.text('Đăng nhập'), findsOneWidget);
    // Có 2 ô nhập (Email + Mật khẩu).
    expect(find.byType(TextFormField), findsNWidgets(2));
  });

  testWidgets('Hiện lỗi khi nhập email sai định dạng', (tester) async {
    await tester.pumpWidget(buildTestable());

    // Xóa email mặc định rồi nhập email không hợp lệ.
    await tester.enterText(find.byType(TextFormField).first, 'sai-email');
    // Nhấn nút Đăng nhập để kích hoạt kiểm tra hợp lệ.
    await tester.tap(find.text('Đăng nhập'));
    await tester.pump();

    expect(find.textContaining('Email không hợp lệ'), findsOneWidget);
  });
}
