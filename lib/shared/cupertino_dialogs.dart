import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:ui';

/// Обертка для CupertinoAlertDialog с темно-фиолетовыми цветами и уменьшенными размерами
Widget buildCupertinoDialog({
  required BuildContext context,
  required String title,
  required Widget content,
  required List<CupertinoDialogAction> actions,
}) {
  final theme = Theme.of(context);
  final primaryColor = theme.primaryColor;
  final surfaceColor = theme.colorScheme.surface;

  return Container(
    decoration: BoxDecoration(
      color: surfaceColor.withOpacity(0.95),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: Colors.white.withOpacity(0.06),
        width: 0.5,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.45),
          blurRadius: 28,
          offset: const Offset(0, 14),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 1, sigmaY: 1),
        child: Theme(
          data: theme.copyWith(
            cupertinoOverrideTheme: CupertinoThemeData(
              primaryColor: primaryColor,
              brightness: Brightness.dark,
            ),
          ),
          child: CupertinoAlertDialog(
            title: Text(
              title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
            content: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: DefaultTextStyle(
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 13,
                ),
                child: content,
              ),
            ),
            actions: actions
                .map(
                  (action) => CupertinoDialogAction(
                    onPressed: action.onPressed,
                    isDefaultAction: action.isDefaultAction,
                    isDestructiveAction: action.isDestructiveAction,
                    child: DefaultTextStyle(
                      style: TextStyle(
                        color: action.isDestructiveAction
                            ? CupertinoColors.destructiveRed
                            : primaryColor,
                        fontSize: 17,
                        fontWeight: action.isDefaultAction
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                      child: action.child,
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    ),
  );
}

/// Обертка для CupertinoActionSheet с богатыми черными цветами, 90% прозрачности и минимальным блюром
Widget buildCupertinoActionSheet({
  required BuildContext context,
  String? title,
  String? message,
  required List<CupertinoActionSheetAction> actions,
  CupertinoActionSheetAction? cancelButton,
}) {
  final primaryColor = Theme.of(context).primaryColor;
  // Богатый черный вместо фиолетового
  final richBlack = const Color(0xFF0A0A0A);
  final sheetBackground = const Color(0xFF000000); // Чистый черный фон

  return ClipRRect(
    borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 1.0, sigmaY: 1.0),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              sheetBackground.withOpacity(0.96),
              sheetBackground.withOpacity(0.92),
            ],
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          border: Border.all(
            color: Colors.white.withOpacity(0.06),
            width: 0.8,
          ),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(
            cupertinoOverrideTheme: CupertinoThemeData(
              primaryColor: richBlack,
              brightness: Brightness.dark,
            ),
          ),
          child: CupertinoActionSheet(
            title: title != null
                ? Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                : null,
            message: message != null
                ? Text(
                    message,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  )
                : null,
            actions: actions.map((action) {
              return CupertinoActionSheetAction(
                onPressed: action.onPressed,
                isDestructiveAction: action.isDestructiveAction,
                child: DefaultTextStyle(
                  style: TextStyle(
                    color: action.isDestructiveAction
                        ? CupertinoColors.destructiveRed
                        : Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                  child: action.child,
                ),
              );
            }).toList(),
            cancelButton: cancelButton != null
                ? CupertinoActionSheetAction(
                    onPressed: cancelButton.onPressed,
                    child: DefaultTextStyle(
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.92),
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                      child: cancelButton.child,
                    ),
                  )
                : null,
          ),
        ),
      ),
    ),
  );
}
