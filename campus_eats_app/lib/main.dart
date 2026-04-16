import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'models/cart_item.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/cart_viewmodel.dart';
import 'viewmodels/menu_viewmodel.dart';
import 'viewmodels/order_viewmodel.dart';
import 'viewmodels/location_viewmodel.dart';
import 'views/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(CartItemAdapter());
  runApp(const CampusEatsApp());
}

class CampusEatsApp extends StatelessWidget {
  const CampusEatsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => CartViewModel()..init()),
        ChangeNotifierProvider(create: (_) => MenuViewModel()),
        ChangeNotifierProvider(create: (_) => OrderViewModel()),
        ChangeNotifierProvider(create: (_) => LocationViewModel()),
      ],
      child: MaterialApp(
        title: 'Campus Eats',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFE65100)),
          useMaterial3: true,
          // Remove white surface tint overlay on iOS
          cardTheme: const CardThemeData(surfaceTintColor: Colors.transparent),
          appBarTheme: const AppBarTheme(surfaceTintColor: Colors.transparent),
          navigationBarTheme: const NavigationBarThemeData(
              surfaceTintColor: Colors.transparent),
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
              backgroundColor: Colors.white),
          scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        ),
        home: const SplashScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
