import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'config/theme.dart';
import 'viewmodels/jarvis_viewmodel.dart';
import 'views/home_screen.dart';
import 'views/chat_screen.dart';
import 'views/agent_screen.dart';
import 'views/communication_screen.dart';
import 'views/settings_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  runApp(const JARVISApp());
}

class JARVISApp extends StatefulWidget {
  const JARVISApp({super.key});

  @override
  State<JARVISApp> createState() => _JARVISAppState();
}

class _JARVISAppState extends State<JARVISApp> {
  final JARVISViewModel _viewModel = JARVISViewModel();

  String? _initError;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      await _viewModel.init();
    } catch (e, st) {
      setState(() => _initError = '$e\n\n$st');
    }
  }

  @override
  void dispose() {
    _viewModel.disposeAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_initError != null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: JARVISTheme.darkTheme,
        home: Scaffold(
          backgroundColor: JARVISTheme.background,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('BAŞLANGIÇ HATASI',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: JARVISTheme.danger,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  Expanded(
                    child: SingleChildScrollView(
                      child: SelectableText(
                        _initError!,
                        style: const TextStyle(
                            color: JARVISTheme.textSecondary, fontSize: 13),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _initError!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Hata kopyalandı')),
                      );
                    },
                    icon: const Icon(Icons.copy),
                    label: const Text('HATAYI KOPYALA'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: MaterialApp(
        title: 'J.A.R.V.I.S.',
        debugShowCheckedModeBanner: false,
        theme: JARVISTheme.darkTheme,
        home: const MainNavigator(),
      ),
    );
  }
}

class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});

  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    ChatScreen(),
    AgentScreen(),
    CommunicationScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _screens[_currentIndex],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
          HapticFeedback.lightImpact();
        },
        backgroundColor: JARVISTheme.surface,
        indicatorColor: JARVISTheme.primary.withOpacity(0.15),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return TextStyle(
            color: states.contains(WidgetState.selected)
                ? JARVISTheme.primary
                : JARVISTheme.textSecondary,
            fontSize: 10,
            letterSpacing: 1,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.normal,
          );
        }),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined, color: JARVISTheme.textSecondary),
            selectedIcon: Icon(Icons.home, color: JARVISTheme.primary),
            label: 'MERKEZ',
          ),
          NavigationDestination(
            icon: Icon(Icons.smart_toy_outlined, color: JARVISTheme.textSecondary),
            selectedIcon: Icon(Icons.smart_toy, color: JARVISTheme.primary),
            label: 'JARVIS',
          ),
          NavigationDestination(
            icon: Icon(Icons.smartphone_outlined, color: JARVISTheme.textSecondary),
            selectedIcon: Icon(Icons.smartphone, color: JARVISTheme.secondary),
            label: 'AJAN',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_outlined, color: JARVISTheme.textSecondary),
            selectedIcon: Icon(Icons.chat, color: JARVISTheme.primary),
            label: 'İLETİŞİM',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined, color: JARVISTheme.textSecondary),
            selectedIcon: Icon(Icons.settings, color: JARVISTheme.primary),
            label: 'AYARLAR',
          ),
        ],
      ),
    );
  }
}
