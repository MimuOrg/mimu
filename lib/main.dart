import 'package:flutter/material.dart';
import 'package:mimu/app/routes.dart';
import 'package:mimu/app/theme.dart';
import 'package:mimu/data/settings_service.dart';
import 'package:mimu/data/chat_store.dart';
import 'package:provider/provider.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SettingsService.init();
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
          return LiquidGlassLayer(
            child: MaterialApp(
              title: 'Mimu',
              theme: MimuTheme.darkTheme(themeProvider.accentColor, fontProvider: fontProvider),
              debugShowCheckedModeBanner: false,
              onGenerateRoute: AppRoutes.onGenerateRoute,
              initialRoute: AppRoutes.auth,
            ),
          );
        },
      ),
    );
  }
}