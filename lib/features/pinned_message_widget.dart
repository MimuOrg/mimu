import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:mimu/data/models/chat_models.dart';
import 'package:mimu/data/message_api.dart';

/// Виджет для отображения закрепленного сообщения
class PinnedMessageWidget extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback? onUnpin;
  final VoidCallback? onTap;

  const PinnedMessageWidget({
    super.key,
    required this.message,
    this.onUnpin,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border(
            left: BorderSide(
              color: Theme.of(context).primaryColor,
              width: 3,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              CupertinoIcons.pin_fill,
              size: 16,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Закрепленное сообщение',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message.text ?? 'Медиа',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            if (onUnpin != null)
              IconButton(
                icon: const Icon(CupertinoIcons.xmark, size: 18),
                color: Colors.white.withOpacity(0.7),
                onPressed: onUnpin,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
          ],
        ),
      ),
    );
  }
}

