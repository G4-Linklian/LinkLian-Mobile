import 'package:flutter/material.dart';
import './sizes.dart';

class AppTextStyles {
  static const TextStyle _baseStyle = TextStyle(
    height: AppSizes.lineHeight,
    fontFamily: 'linklian-font', 
    color: Colors.black, 
  );

  // --- Header (24px) ---
  static TextStyle headerBold = _baseStyle.copyWith(
      fontSize: AppSizes.fontHeader, fontWeight: AppFontWeights.bold);
  static TextStyle headerSemiBold = _baseStyle.copyWith(
      fontSize: AppSizes.fontHeader, fontWeight: AppFontWeights.semiBold);
  static TextStyle headerMedium = _baseStyle.copyWith(
      fontSize: AppSizes.fontHeader, fontWeight: AppFontWeights.medium);
  static TextStyle headerRegular = _baseStyle.copyWith(
      fontSize: AppSizes.fontHeader, fontWeight: AppFontWeights.regular);
  static TextStyle headerLight = _baseStyle.copyWith(
      fontSize: AppSizes.fontHeader, fontWeight: AppFontWeights.light);

  // --- Title (20px) ---
  static TextStyle titleBold = _baseStyle.copyWith(
      fontSize: AppSizes.fontTitle, fontWeight: AppFontWeights.bold);
  static TextStyle titleSemiBold = _baseStyle.copyWith(
      fontSize: AppSizes.fontTitle, fontWeight: AppFontWeights.semiBold);
  static TextStyle titleMedium = _baseStyle.copyWith(
      fontSize: AppSizes.fontTitle, fontWeight: AppFontWeights.medium);
  static TextStyle titleRegular = _baseStyle.copyWith(
      fontSize: AppSizes.fontTitle, fontWeight: AppFontWeights.regular);
  static TextStyle titleLight = _baseStyle.copyWith(
      fontSize: AppSizes.fontTitle, fontWeight: AppFontWeights.light);

  // --- Subheading (18px) ---
  static TextStyle subheadingBold = _baseStyle.copyWith(
      fontSize: AppSizes.fontSubheading, fontWeight: AppFontWeights.bold);
  static TextStyle subheadingSemiBold = _baseStyle.copyWith(
      fontSize: AppSizes.fontSubheading, fontWeight: AppFontWeights.semiBold);
  static TextStyle subheadingMedium = _baseStyle.copyWith(
      fontSize: AppSizes.fontSubheading, fontWeight: AppFontWeights.medium);
  static TextStyle subheadingRegular = _baseStyle.copyWith(
      fontSize: AppSizes.fontSubheading, fontWeight: AppFontWeights.regular);
  static TextStyle subheadingLight = _baseStyle.copyWith(
      fontSize: AppSizes.fontSubheading, fontWeight: AppFontWeights.light);

  // --- Paragraph (16px) ---
  static TextStyle paragraphBold = _baseStyle.copyWith(
      fontSize: AppSizes.fontParagraph, fontWeight: AppFontWeights.bold);
  static TextStyle paragraphSemiBold = _baseStyle.copyWith(
      fontSize: AppSizes.fontParagraph, fontWeight: AppFontWeights.semiBold);
  static TextStyle paragraphMedium = _baseStyle.copyWith(
      fontSize: AppSizes.fontParagraph, fontWeight: AppFontWeights.medium);
  static TextStyle paragraphRegular = _baseStyle.copyWith(
      fontSize: AppSizes.fontParagraph, fontWeight: AppFontWeights.regular);
  static TextStyle paragraphLight = _baseStyle.copyWith(
      fontSize: AppSizes.fontParagraph, fontWeight: AppFontWeights.light);

  // --- Description (12px) ---
  static TextStyle descriptionBold = _baseStyle.copyWith(
      fontSize: AppSizes.fontDescription, fontWeight: AppFontWeights.bold);
  static TextStyle descriptionSemiBold = _baseStyle.copyWith(
      fontSize: AppSizes.fontDescription, fontWeight: AppFontWeights.semiBold);
  static TextStyle descriptionMedium = _baseStyle.copyWith(
      fontSize: AppSizes.fontDescription, fontWeight: AppFontWeights.medium);
  static TextStyle descriptionRegular = _baseStyle.copyWith(
      fontSize: AppSizes.fontDescription, fontWeight: AppFontWeights.regular);
  static TextStyle descriptionLight = _baseStyle.copyWith(
      fontSize: AppSizes.fontDescription, fontWeight: AppFontWeights.light);
}


// Text(
//   'Header Text',
//   style: AppTextStyles.headerBold,
// ),
// Text(
//   'Description text here',
//   style: AppTextStyles.descriptionRegular.copyWith(color: AppColors.primaryPalette[200]),
// ),