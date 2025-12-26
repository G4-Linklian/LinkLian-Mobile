import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'config/theme.dart';
// import 'config/app_routes.dart';
import 'core/constants/strings.dart';
import 'features/layout/pages/layout.dart';
// import 'routes/app_router.dart';
// import './config/app_routes.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';


void main() async {
  // Get.put(AuthController());
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      // initialRoute: AppRoutes.initial,
      // getPages: AppRouter.routes,
      home: const MainPage(),
    );
  }
}
