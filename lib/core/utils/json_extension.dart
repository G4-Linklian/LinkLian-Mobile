extension JsonParsing on dynamic {
  int? toInt() {
    if (this == null) return null;
    if (this is int) return this as int;
    if (this is String) return int.tryParse(this as String);
    return null;
  }

  double? toDouble() {
    if (this == null) return null;
    if (this is double) return this as double;
    if (this is int) return (this as int).toDouble();
    if (this is String) return double.tryParse(this as String);
    return null;
  }

  DateTime? toDateTime() {
    if (this == null) return null;
    return DateTime.tryParse(this.toString());
  }

  String? toStr() {
    if (this == null) return null;
    return this.toString();
  }
}
