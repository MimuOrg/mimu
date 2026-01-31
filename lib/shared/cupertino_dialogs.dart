import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mimu/shared/app_styles.dart';

/// Cupertino dialog. Solid surfaces, no blur (per .cursorrules).
Widget buildCupertinoDialog({
  required BuildContext context,
  required String title,
  required Widget content,
  required List<CupertinoDialogAction> actions,
}) {
  final theme = Theme.of(context);
  final primaryColor = theme.primaryColor;

  return Container(
    decoration: AppStyles.surfaceDecoration(
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.5),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(AppStyles.radiusStandard),
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
  );
}

/// CupertinoActionSheet. Solid surface, no blur (per .cursorrules).
Widget buildCupertinoActionSheet({
  required BuildContext context,
  String? title,
  String? message,
  required List<CupertinoActionSheetAction> actions,
  CupertinoActionSheetAction? cancelButton,
}) {
  return ClipRRect(
    borderRadius: BorderRadius.vertical(top: Radius.circular(AppStyles.radiusStandard)),
    child: Container(
      decoration: BoxDecoration(
        color: AppStyles.surfaceDeep,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppStyles.radiusStandard)),
        border: Border(
          top: BorderSide(color: AppStyles.borderColor, width: AppStyles.borderWidth),
          left: BorderSide(color: AppStyles.borderColor, width: AppStyles.borderWidth),
          right: BorderSide(color: AppStyles.borderColor, width: AppStyles.borderWidth),
        ),
      ),
        child: Theme(
          data: Theme.of(context).copyWith(
            cupertinoOverrideTheme: CupertinoThemeData(
              primaryColor: Theme.of(context).primaryColor,
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
  );
}
