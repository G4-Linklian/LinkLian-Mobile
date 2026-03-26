import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:LinkLian/core/constants/colors.dart';

class AIQuizPopup extends StatefulWidget {
  final Function(String difficulty, int questionCount, String mode) onGenerate;

  const AIQuizPopup({super.key, required this.onGenerate});

  @override
  State<AIQuizPopup> createState() => _AIQuizPopupState();
}

class _AIQuizPopupState extends State<AIQuizPopup> {
  double difficultyLevel = 2;
  int questionCount = 5;
  String mode = "learning";
  late final TextEditingController _questionController;

  final Map<int, String> difficultyValueMap = {
    1: "easy",
    2: "medium",
    3: "hard",
  };

  final Map<int, String> difficultyTextMap = {
    1: "ง่าย",
    2: "ปานกลาง",
    3: "ยาก",
  };

  @override
  void initState() {
    super.initState();
    _questionController = TextEditingController(text: questionCount.toString());
  }

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  void _updateQuestionCount(int value) {
    final clamped = value.clamp(1, 10);
    setState(() {
      questionCount = clamped;
      _questionController.text = clamped.toString();
      _questionController.selection = TextSelection.fromPosition(
        TextPosition(offset: _questionController.text.length),
      );
    });
  }

  void _onQuestionChanged(String value) {
    if (value.isEmpty) return;

    final parsed = int.tryParse(value);
    if (parsed == null) return;

    _updateQuestionCount(parsed);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),

      title: const Text(
        "สร้างแบบฝึกหัด",
        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
      ),

      content: SizedBox(
        width: 300,

        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "โหมดการใช้งาน",
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),

            //const SizedBox(height: 4),
            RadioListTile<String>(
              value: "learning",
              groupValue: mode,
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: const Text(
                "แบบการเรียนรู้",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              //subtitle: const Text("แสดงเฉลยทันที"),
              onChanged: (value) {
                if (value == null) return;
                setState(() => mode = value);
              },
            ),
            RadioListTile<String>(
              value: "exam",
              groupValue: mode,
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: const Text(
                "แบบทดสอบ",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              //subtitle: const Text("ทำครบก่อนดูเฉลย"),
              onChanged: (value) {
                if (value == null) return;
                setState(() => mode = value);
              },
            ),

            const SizedBox(height: 12),

            RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                children: [
                  const TextSpan(
                    text: "ระดับความยาก: ",
                    style: TextStyle(color: Colors.black),
                  ),
                  TextSpan(
                    text:
                        difficultyTextMap[difficultyLevel.toInt()] ?? "ปานกลาง",
                    style: TextStyle(color: AppColors.primaryPalette[700]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 6,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
                activeTrackColor: AppColors.primaryPalette[500],
                inactiveTrackColor: AppColors.primaryPalette[100],
                thumbColor: AppColors.primaryPalette[500],
                valueIndicatorColor: AppColors.primaryPalette[500],
                valueIndicatorTextStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              child: Slider(
                value: difficultyLevel,
                min: 1,
                max: 3,
                divisions: 2,
                label: difficultyTextMap[difficultyLevel.toInt()],
                onChanged: (value) {
                  setState(() {
                    difficultyLevel = value;
                  });
                },
              ),
            ),
            const SizedBox(height: 20),

            Text(
              "จำนวนคำถาม (สูงสุด 10 ข้อ)",
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),

            const SizedBox(height: 6),
            Row(
              children: [
                IconButton(
                  onPressed: questionCount > 1
                      ? () => _updateQuestionCount(questionCount - 1)
                      : null,
                  icon: const Icon(Icons.remove_circle_outline),
                  color: AppColors.primaryPalette[500],
                ),
                Expanded(
                  child: TextField(
                    controller: _questionController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(2),
                    ],
                    decoration: InputDecoration(
                      hintText: "1 - 10",
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      filled: true,
                      fillColor: AppColors.primaryPalette[100],
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: AppColors.primaryPalette[500]!,
                          width: 1.5,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: AppColors.primaryPalette[600]!,
                          width: 1.8,
                        ),
                      ),
                    ),
                    onChanged: _onQuestionChanged,
                    onEditingComplete: () {
                      final parsed =
                          int.tryParse(_questionController.text) ?? 1;
                      _updateQuestionCount(parsed);
                      FocusScope.of(context).unfocus();
                    },
                  ),
                ),
                IconButton(
                  onPressed: questionCount < 10
                      ? () => _updateQuestionCount(questionCount + 1)
                      : null,
                  icon: const Icon(Icons.add_circle_outline),
                  color: AppColors.primaryPalette[500],
                ),
              ],
            ),
            const SizedBox(height: 20),
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
            backgroundColor: AppColors.primaryPalette[400],
            foregroundColor: AppColors.primaryPalette[800],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          onPressed: () {
            final selectedDifficulty =
                difficultyValueMap[difficultyLevel.toInt()] ?? "medium";
            widget.onGenerate(selectedDifficulty, questionCount, mode);
          },

          child: const Text("เริ่มสร้างแบบฝึกหัด"),
        ),
      ],
    );
  }
}
