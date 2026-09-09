import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'data/services/app_version_service.dart';
import 'data/services/gamepad_service.dart';
import 'ui/core/app_theme.dart';
import 'ui/core/responsive_scaffold.dart';
import 'ui/core/spatial_route.dart';
import 'ui/features/big_picture/big_picture_view.dart';
import 'ui/features/home/home_view.dart';
import 'ui/features/home/home_view_model.dart';
import 'ui/features/library/library_view.dart';
import 'ui/features/package_managers/package_managers_view.dart';
import 'ui/features/settings/settings_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppVersionService.init();
  GamepadService().init();
  runApp(const NexusAppHubApp());
}

class NexusAppHubApp extends StatelessWidget {
  const NexusAppHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HomeViewModel()),
      ],
      child: MaterialApp(
        title: 'Nexus App Hub',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const MainNavigationHost(),
      ),
    );
  }
}

class MainNavigationHost extends StatefulWidget {
  const MainNavigationHost({super.key});

  @override
  State<MainNavigationHost> createState() => _MainNavigationHostState();
}

class _MainNavigationHostState extends State<MainNavigationHost> {
  int _currentIndex = 0;

  final List<Widget> _views = const [
    HomeView(),
    LibraryView(),
    PackageManagersView(),
    SettingsView(),
  ];

  @override
  void initState() {
    super.initState();
    GamepadService().onToggleBigPicture = _openBigPicture;
    GamepadService().onTabNext = _nextTab;
    GamepadService().onTabPrevious = _prevTab;
  }

  void _openBigPicture() {
    Navigator.of(context).push(
      Spatial3DRoute(page: const BigPictureView()),
    );
  }

  void _nextTab() {
    if (mounted) {
      setState(() => _currentIndex = (_currentIndex + 1) % _views.length);
    }
  }

  void _prevTab() {
    if (mounted) {
      setState(() => _currentIndex = (_currentIndex - 1 + _views.length) % _views.length);
    }
  }

  @override
  void dispose() {
    GamepadService().onToggleBigPicture = null;
    GamepadService().onTabNext = null;
    GamepadService().onTabPrevious = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      selectedIndex: _currentIndex,
      onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
      onOpenBigPicture: _openBigPicture,
      body: IndexedStack(
        index: _currentIndex,
        children: _views,
      ),
    );
  }
}