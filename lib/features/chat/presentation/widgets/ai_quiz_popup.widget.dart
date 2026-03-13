import 'package:flutter/material.dart';
import 'package:LinkLian/core/constants/colors.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

class AIQuizPopup extends StatefulWidget {
  final Function(String difficulty, int questionCount) onGenerate;

  const AIQuizPopup({super.key, required this.onGenerate});

  @override
  State<AIQuizPopup> createState() => _AIQuizPopupState();
}

class _AIQuizPopupState extends State<AIQuizPopup> {
  String difficulty = "medium";
  double questionCount = 5;

  final List<Map<String, String>> difficultyItems = [
    {"value": "easy", "text": "ง่าย"},
    {"value": "medium", "text": "ปานกลาง"},
    {"value": "hard", "text": "ยาก"},
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),

      title: const Text(
        "สร้างแบบทดสอบด้วย AI",
        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
      ),

      content: SizedBox(
        width: 300,

        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "ระดับความยาก",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 8),
            DropdownButtonHideUnderline(
              child: DropdownButton2<String>(
                value: difficulty,
                isExpanded: true,

                items: difficultyItems.map((item) {
                  return DropdownMenuItem<String>(
                    value: item["value"],

                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(item["text"]!),
                    ),
                  );
                }).toList(),

                onChanged: (value) {
                  setState(() {
                    difficulty = value!;
                  });
                },

                buttonStyleData: ButtonStyleData(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primaryPalette[500]!,
                      width: 1.5,
                    ),
                  ),
                ),

                iconStyleData: const IconStyleData(
                  icon: Icon(Icons.keyboard_arrow_down),
                ),

                dropdownStyleData: DropdownStyleData(
                  maxHeight: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white,
                    boxShadow: const [
                      BoxShadow(blurRadius: 10, color: Colors.black12),
                    ],
                  ),
                ),

                menuItemStyleData: const MenuItemStyleData(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  height: 40,
                ),
              ),
            ),
            const SizedBox(height: 20),

            Text(
              "จำนวนข้อ (${questionCount.toInt()} ข้อ)",
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 6),

            // SliderTheme(
            //   data: SliderTheme.of(context).copyWith(
            //     trackHeight: 8,

            //     thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),

            //     overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),

            //     activeTrackColor: AppColors.primaryPalette[500],
            //     inactiveTrackColor: AppColors.primaryPalette[100],

            //     thumbColor: AppColors.primaryPalette[500],
            //   ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 6,

                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),

                overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),

                activeTrackColor: AppColors.primaryPalette[500],
                inactiveTrackColor: AppColors.primaryPalette[100],

                thumbColor: AppColors.primaryPalette[500],

                /// สีพื้นหลังเลข
                valueIndicatorColor: AppColors.primaryPalette[500],

                /// สีตัวเลข
                valueIndicatorTextStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),

              child: Slider(
                value: questionCount,
                min: 1,
                max: 10,
                divisions: 9,

                label: questionCount.toInt().toString(),

                onChanged: (value) {
                  setState(() {
                    questionCount = value;
                  });
                },
              ),
            ),
          ],
        ),
      ),

      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text("ยกเลิก"),
        ),

        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryPalette[500],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          onPressed: () {
            widget.onGenerate(difficulty, questionCount.toInt());

            Navigator.pop(context);
          },

          child: const Text("สร้างแบบทดสอบ"),
        ),
      ],
    );
  }
}
