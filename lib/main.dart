import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:LinkLian/core/services/api_client.dart';
import 'package:LinkLian/features/community/data/repositories/community_repository.dart';
import 'package:LinkLian/features/community/presentation/controllers/community_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'config/theme.dart';
import 'core/constants/strings.dart';
import 'features/layout/pages/layout.dart';
import 'routes/app_router.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/services/local_storage.dart';
import 'features/auth/controller/auth_controller.dart';
import 'features/notification/presentation/widgets/notification_banner.dart';
import 'features/shared/repositories/class_feed_repository.dart';
import 'data/repository/semester_repository.dart';
import 'features/login/pages/login_page.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'features/shared/repositories/bookmark_repository.dart';
import 'features/shared/presentations/bookmark_controller.dart';
import 'features/layout/controllers/navigation_controller.dart';
import 'features/assignment/data/repositories/assignment_repository.dart';
import 'features/assignment/data/repositories/submission_repository.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await dotenv.load(fileName: ".env");
  await LocalStorage.init();
  await initializeDateFormatting('th', null);

  Get.put(ApiClient(), permanent: true);
  Get.put(CommunityRepository(), permanent: true);

  Get.put(
    CommunityController(Get.find<CommunityRepository>()),
    permanent: true,
  );
  Get.put(AuthController(), permanent: true);
  Get.put(NavigationController(), permanent: true);

  Get.put<ClassFeedRepository>(ClassFeedRepository(), permanent: true);

  Get.put<SemesterRepository>(SemesterRepository(), permanent: true);
  Get.put<BookmarkRepository>(
    BookmarkRepository(Get.find<ApiClient>()),
    permanent: true,
  );
  Get.put<BookmarkController>(
    BookmarkController(Get.find<BookmarkRepository>()),
    permanent: true,
  );
  Get.put<AssignmentRepository>(
    AssignmentRepository(apiClient: Get.find<ApiClient>()),
    permanent: true,
  );
  Get.put<SubmissionRepository>(
    SubmissionRepository(apiClient: Get.find<ApiClient>()),
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
      home: const AuthGate(),
      getPages: AppRouter.routes,
      locale: const Locale('th', 'TH'),
      supportedLocales: const [
        Locale('th', 'TH'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => NotificationBannerWrapper(child: child!),
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
