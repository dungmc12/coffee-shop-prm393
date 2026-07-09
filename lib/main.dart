import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/product_provider.dart';
import 'providers/cart_provider.dart';
import 'theme/app_theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/main_navigation.dart';

void main() {
  runApp(const CoffeeShopApp());
}

/// Widget gốc của ứng dụng.
/// MultiProvider: đăng ký 3 provider ở trên cùng cây widget để mọi
/// màn hình con đều truy cập được trạng thái dùng chung.
class CoffeeShopApp extends StatelessWidget {
  const CoffeeShopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: MaterialApp(
        title: 'Coffee Shop',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        // Tùy trạng thái đăng nhập mà hiển thị màn phù hợp.
        home: Consumer<AuthProvider>(
          builder: (context, auth, _) {
            return auth.isLoggedIn ? const MainNavigation() : const LoginScreen();
          },
        ),
      ),
    );
  }
}
