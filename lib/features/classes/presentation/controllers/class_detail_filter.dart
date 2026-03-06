enum ClassPostFilter {
  all,
  announcement,
  assignment,
  question,
}

extension ClassPostFilterX on ClassPostFilter {
  String get label {
    switch (this) {
      case ClassPostFilter.all:
        return 'ทั้งหมด';
      case ClassPostFilter.announcement:
        return 'ประกาศ';
      case ClassPostFilter.assignment:
        return 'การบ้าน';
      case ClassPostFilter.question:
        return 'คำถาม';
    }
  }

  String? get apiValue {
    switch (this) {
      case ClassPostFilter.all:
        return null; 
      case ClassPostFilter.announcement:
        return 'announcement';
      case ClassPostFilter.assignment:
        return 'assignment';
      case ClassPostFilter.question:
        return 'question';
    }
  }
}