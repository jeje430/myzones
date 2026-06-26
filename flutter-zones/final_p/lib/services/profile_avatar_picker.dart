import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import '../core/theme/zonez_colors.dart';

/// Picks an image (camera/gallery), crops it in a circular 1:1 mask, returns JPEG bytes.
class ProfileAvatarPicker {
  ProfileAvatarPicker._();

  static final ImagePicker _picker = ImagePicker();

  static Future<Uint8List?> pickCropAndReadBytes(BuildContext context) async {
    final source = await _showSourceSheet(context);
    if (source == null || !context.mounted) return null;

    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 92,
    );
    if (picked == null || !context.mounted) return null;

    final cropped = await ImageCropper().cropImage(
      sourcePath: picked.path,
      maxWidth: 400,
      maxHeight: 400,
      compressFormat: ImageCompressFormat.jpg,
      compressQuality: 85,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'تعديل الصورة',
          toolbarColor: ZonezColors.neonPurple,
          toolbarWidgetColor: Colors.white,
          activeControlsWidgetColor: ZonezColors.neonCyan,
          backgroundColor: ZonezColors.cardDark,
          cropGridColor: ZonezColors.neonPurple.withValues(alpha: 0.35),
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: true,
          cropStyle: CropStyle.circle,
          hideBottomControls: false,
        ),
        IOSUiSettings(
          title: 'تعديل الصورة',
          aspectRatioLockEnabled: true,
          resetAspectRatioEnabled: false,
          aspectRatioPickerButtonHidden: true,
          doneButtonTitle: 'تم',
          cancelButtonTitle: 'إلغاء',
        ),
      ],
    );

    if (cropped == null) return null;

    return cropped.readAsBytes();
  }

  static Future<ImageSource?> _showSourceSheet(BuildContext context) {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: ZonezColors.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'صورة الملف الشخصي',
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.photo_camera_outlined, color: ZonezColors.neonCyan),
                  title: Text(
                    'التقاط صورة (الكاميرا)',
                    style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                  onTap: () => Navigator.pop(ctx, ImageSource.camera),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined, color: ZonezColors.neonPurple),
                  title: Text(
                    'اختيار من المعرض',
                    style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                  onTap: () => Navigator.pop(ctx, ImageSource.gallery),
                ),
                const SizedBox(height: 4),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'إلغاء',
                    style: GoogleFonts.cairo(color: ZonezColors.textMuted),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
