# วิธีการเพิ่มฟอนต์ IBM Plex Sans Thai

## ขั้นตอนการดาวน์โหลดฟอนต์:

1. ไปที่ [Google Fonts - IBM Plex Sans Thai](https://fonts.google.com/specimen/IBM+Plex+Sans+Thai)
2. คลิก "Download family"
3. แตกไฟล์ zip
4. คัดลอกไฟล์ .ttf ไปใส่ในโฟลเดอร์ `assets/fonts/IBM_Plex_Sans_Thai/`

## ไฟล์ที่ต้องการ:
- `IBMPlexSansThai-Regular.ttf`
- `IBMPlexSansThai-Bold.ttf` (หรือ `IBMPlexSansThai-SemiBold.ttf`)

## เมื่อมีไฟล์ฟอนต์แล้ว:

1. ใน `pubspec.yaml` ให้ uncomment ส่วน fonts:
```yaml
fonts:
  - family: IBMPlexSansThai
    fonts:
      - asset: assets/fonts/IBM_Plex_Sans_Thai/IBMPlexSansThai-Regular.ttf
      - asset: assets/fonts/IBM_Plex_Sans_Thai/IBMPlexSansThai-Bold.ttf
        weight: 700
```

2. ใน `theme.dart` ให้ uncomment:
```dart
fontFamily: 'IBMPlexSansThai',
```

3. รัน `flutter pub get`
4. รัน `flutter clean && flutter build`