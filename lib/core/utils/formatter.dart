class Formatter {
  static String formatPrice(double price) {
    return "${price.toStringAsFixed(2)} บาท";
  }

  static String dayOfWeekToText(int d) {
  switch (d) {
    case 1:
      return 'วันจันทร์';
    case 2:
      return 'วันอังคาร';
    case 3:
      return 'วันพุธ';
    case 4:
      return 'วันพฤหัสบดี';
    case 5:
      return 'วันศุกร์';
    case 6:
      return 'วันเสาร์';
    case 7:
      return 'วันอาทิตย์';
    default:
      return '';
  }
}

static String formatTime(String time) {
  return time.length >= 5 ? time.substring(0, 5).replaceAll(':', '.') : time;
}

}
