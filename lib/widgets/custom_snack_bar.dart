import 'package:flutter/material.dart';

enum CustomSnackBarState { warning, success, error }

class CustomSnackBar {
  static void show({
    required BuildContext context,
    required String message,
    required CustomSnackBarState state,
    bool showCloseIcon = true,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        content: Row(
          children: <Widget>[
            Icon(
              _chooseSnackBarIcon(state),
              color: Colors.white,
              size: 40,
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    _chooseSnackBarTitle(state, context),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    message,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        dismissDirection: DismissDirection.horizontal,
        showCloseIcon: showCloseIcon,
        closeIconColor: Colors.white,
        backgroundColor: _chooseSnackBarColor(state),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  static Color _chooseSnackBarColor(CustomSnackBarState state) {
    Color color;
    switch (state) {
      case CustomSnackBarState.success:
        color = Colors.green;
        break;
      case CustomSnackBarState.error:
        color = Colors.red;
        break;
      case CustomSnackBarState.warning:
        color = Colors.amber;
        break;
    }
    return color;
  }

  static IconData _chooseSnackBarIcon(CustomSnackBarState state) {
    IconData icon;

    switch (state) {
      case CustomSnackBarState.warning:
        icon = Icons.warning_amber_outlined;
        break;

      case CustomSnackBarState.success:
        icon = Icons.check_circle;
        break;

      case CustomSnackBarState.error:
        icon = Icons.error;
        break;
    }

    return icon;
  }

  static String _chooseSnackBarTitle(
    CustomSnackBarState state,
    BuildContext context,
  ) {
    String title;

    switch (state) {
      case CustomSnackBarState.error:
      case CustomSnackBarState.warning:
        title = 'Warning';
        break;

      case CustomSnackBarState.success:
        title = 'Success';
        break;
    }

    return title;
  }
}
