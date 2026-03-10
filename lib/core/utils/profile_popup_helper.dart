import 'package:LinkLian/features/classes/presentation/widgets/profile_popup.dart';
import 'package:LinkLian/features/shared/models/profile_model.dart';
import 'package:get/get.dart';


void showProfilePopup(ProfileModel profile) {
  Get.dialog(
    ProfilePopup(profile: profile),
    barrierDismissible: true,
  );
}