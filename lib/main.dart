import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'config/theme.dart';
// import 'config/app_routes.dart';
import 'core/constants/strings.dart';
import 'features/layout/pages/layout.dart';

void main() {
  // Get.put(AuthController());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: const MainPage(),
    );
  }
}
