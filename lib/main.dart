import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'ui/core/app_theme.dart';
import 'ui/core/responsive_scaffold.dart';
import 'ui/features/home/home_view.dart';
import 'ui/features/home/home_view_model.dart';
import 'ui/features/library/library_view.dart';
import 'ui/features/settings/settings_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
    SettingsView(),
  ];

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      selectedIndex: _currentIndex,
      onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
      body: IndexedStack(
        index: _currentIndex,
        children: _views,
      ),
    );
  }
}