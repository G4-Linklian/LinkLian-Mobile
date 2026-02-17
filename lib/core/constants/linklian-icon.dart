import 'package:LinkLian/core/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hugeicons/hugeicons.dart';

abstract class _BaseHugeIcon {
  const _BaseHugeIcon();

  static Widget build({
    required dynamic icon,
    required double size,
    required Color color,
    double visualScale = 0.9,
  }) {
    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: HugeIcon(
          icon: icon,
          size: size * visualScale,
          color: color,
        ),
      ),
    );
  }
}
class LinkLianHugeIcon {

  const LinkLianHugeIcon._(); 

  static Widget anonymous({
    double size = 18,
    Color color = Colors.black,
  }) {
    return _BaseHugeIcon.build(
      icon: HugeIcons.strokeRoundedAnonymous,
      size: size,
      color: color,
    );
  }

static Widget comment({
  double size = 18,
  Color color = Colors.black,
  double stroke = 2,
}) {
  return Stack(
    alignment: Alignment.center,
    children: [      Transform.scale(
        scale: 1 + (stroke / size),
        child: _BaseHugeIcon.build(
          icon: HugeIcons.strokeRoundedComment01,
          size: size,
          color: color,
        ),
      ),
      _BaseHugeIcon.build(
        icon: HugeIcons.strokeRoundedComment01,
        size: size,
        color: color,
      ),
    ],
  );
}

  // ตัวอย่าง
  // static Widget warning({
  //   double size = 18,
  //   Color color = Colors.orange,
  // }) {
  //   return _BaseHugeIcon.build(
  //     icon: HugeIcons.strokeRoundedWarning,
  //     size: size,
  //     color: color,
  //   );
  // }
}
class LinkLianIcon {
  // การบ้าน
  static const IconData homework = TablerIcons.checklist;
  // ห้องเรียน
  static const IconData classroom = TablerIcons.certificate;
  // ชุมชน
  static const IconData community = TablerIcons.users_group;
  // โปรไฟล์
  static const IconData profile = TablerIcons.user_circle;

  static const IconData message = TablerIcons.message_circle_filled;
  static const IconData notification = TablerIcons.bell_filled;
  static const IconData add = TablerIcons.square_rounded_plus_filled;
  
  //auth
  static const IconData info = TablerIcons.info_circle;          
  static const IconData eye = TablerIcons.eye;                  
  static const IconData eyeOff = TablerIcons.eye_off;          

  //role
  static const IconData student = TablerIcons.school;
  static const IconData teacher = TablerIcons.book;

  //classfeed  
  static const IconData location = TablerIcons.map_pin_filled;
  static const IconData expand = TablerIcons.square_rounded_chevron_down;
  static const IconData collapse = TablerIcons.square_rounded_chevron_up;
  static const IconData semester = TablerIcons.calendar;
  static const IconData attach = TablerIcons.file;
  static const IconData identifiedUser = TablerIcons.user;
  
  //post
  static const IconData post = TablerIcons.pencil;
  static const IconData photo = TablerIcons.photo;
  static const IconData link = TablerIcons.link;
  static const IconData paperclip = TablerIcons.paperclip;
  static const IconData close = TablerIcons.x;
  static const IconData back = TablerIcons.chevron_left;
  static const IconData filterpost = TablerIcons.filter;
  static const IconData send = TablerIcons.brand_telegram;

  // settings
  static const IconData settings = TablerIcons.settings;
  static const IconData account = TablerIcons.user_circle;
  static const IconData security = TablerIcons.lock;
  static const IconData privacy = TablerIcons.shield_lock;
  static const IconData logout = TablerIcons.logout;

  static const IconData chevronleft = TablerIcons.chevron_left;
  static const IconData chevronright = TablerIcons.chevron_right;

  static const IconData dashboard = TablerIcons.layout_dashboard;
  static const IconData filter = TablerIcons.filter;
  static const IconData edit = TablerIcons.edit;
  static const IconData phone = TablerIcons.phone;
  static const IconData pencil = TablerIcons.pencil;
  static const IconData camera = TablerIcons.camera;
  static const IconData check = TablerIcons.check;
  static const IconData cancel = TablerIcons.cancel;
  static const IconData delete = TablerIcons.trash;

  // assignment
  static const IconData assignment = TablerIcons.clipboard_list;
  static const IconData assignmentCheck = TablerIcons.clipboard_check;
  static const IconData clock = TablerIcons.clock;
  static const IconData alertCircle = TablerIcons.alert_circle;
  static const IconData circleCheck = TablerIcons.circle_check;
  static const IconData circleDot = TablerIcons.circle_dot;
  static const IconData users = TablerIcons.users;

  static double? get fontSubheading => null;

}