import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'config/theme.dart';
import 'config/app_routes.dart';
import 'core/constants/strings.dart';
import 'features/layout/pages/layout.dart';
import 'routes/app_router.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/services/local_storage.dart';
import 'features/auth/controller/auth_controller.dart';
import 'data/repository/class_feed_repository.dart';
import 'data/repository/semester_repository.dart';
import 'features/login/pages/login_page.dart';
import 'features/layout/pages/layout.dart';


void main() async {
  
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await LocalStorage.init();
  
  // 🔐 AuthController (source of truth)
  Get.put(AuthController(), permanent: true);

  // 📦 Repositories (no token / no baseUrl)
  Get.put<ClassFeedRepository>(
    ClassFeedRepository(),
    permanent: true,
  );

  Get.put<SemesterRepository>(
    SemesterRepository(),
    permanent: true,
  );

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
      home: const AuthGate(), // 👈 ใช้ widget ตรงนี้แทน
      getPages: AppRouter.routes,
      // home: const MainPage(),
    );
  }
}


class AuthGate extends GetView<AuthController> {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      switch (controller.status.value) {
        case AuthStatus.checking:
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );

        case AuthStatus.authenticated:
          return const MainPage();

        case AuthStatus.unauthenticated:
          return const LoginPage();
      }
    });
  }
}

