import 'package:flutter/material.dart';
import 'package:mimu/app/routes.dart';
import 'package:mimu/app/theme.dart';
import 'package:mimu/data/settings_service.dart';
import 'package:mimu/data/chat_store.dart';
import 'package:mimu/data/user_service.dart';
import 'package:mimu/data/browser_service.dart';
import 'package:mimu/data/channel_service.dart';
import 'package:mimu/data/status_service.dart';
import 'package:mimu/data/services/notification_service.dart';
import 'package:mimu/data/analytics_service.dart';
import 'package:mimu/data/server_config.dart';
import 'package:mimu/data/message_queue.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await SettingsService.init();
  await ServerConfig.init();
  await UserService.init();
  await BrowserService.init();
  await ChannelService.init();
  await StatusService.init();
  
  // Инициализация уведомлений (опционально, может не работать без Firebase)
  try {
    await NotificationService().initialize();
  } catch (e) {
    debugPrint('Failed to initialize notifications: $e');
  }
  
  // Инициализация Sentry (опционально)
  try {
    await AnalyticsService.initializeSentry();
  } catch (e) {
    debugPrint('Failed to initialize Sentry: $e');
  }
  
  // Инициализация очереди сообщений
  MessageQueue().initialize();
  
  runApp(const MimuApp());
}

class MimuApp extends StatelessWidget {
  const MimuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) {
            final provider = ThemeProvider();
            final savedTheme = SettingsService.getTheme();
            provider.changeTheme(savedTheme);
            return provider;
          },
        ),
        ChangeNotifierProvider(create: (_) => FontProvider()),
        ChangeNotifierProvider(
          create: (_) {
            final chatStore = ChatStore();
            chatStore.init();
            return chatStore;
          },
        ),
      ],
      child: Consumer2<ThemeProvider, FontProvider>(
        builder: (context, themeProvider, fontProvider, child) {
          return MaterialApp(
            title: 'Mimu',
            theme: MimuTheme.darkTheme(
              themeProvider.accentColor,
              fontProvider: fontProvider,
            ),
            debugShowCheckedModeBanner: false,
            onGenerateRoute: AppRoutes.onGenerateRoute,
            initialRoute: AppRoutes.auth,
          );
        },
      ),
    );
  }
}