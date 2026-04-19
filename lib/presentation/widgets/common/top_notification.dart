import 'package:flutter/material.dart';

enum NotificationType { success, error, info }

class TopNotification {
  static void show(BuildContext context, String message, {NotificationType type = NotificationType.info}) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.clearSnackBars();

    Color backgroundColor;
    IconData icon;

    switch (type) {
      case NotificationType.success:
        backgroundColor = const Color(0xFF10B981);
        icon = Icons.check_circle_rounded;
        break;
      case NotificationType.error:
        backgroundColor = const Color(0xFFEF4444);
        icon = Icons.error_outline_rounded;
        break;
      case NotificationType.info:
      default:
        backgroundColor = const Color(0xFF3B82F6);
        icon = Icons.info_outline_rounded;
        break;
    }

    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        elevation: 8,
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height - 130, // 显示在顶部
          left: 20,
          right: 20,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 2),
        dismissDirection: DismissDirection.up,
      ),
    );
  }
}
