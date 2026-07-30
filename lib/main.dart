import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'viewmodels/jarvis_viewmodel.dart';
import 'views/home_screen.dart';
import 'views/agent_screen.dart';
import 'views/security_screen.dart';
import 'views/communication_screen.dart';

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

class JARVISApp extends StatelessWidget {
  const JARVISApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => JARVISViewModel(),
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
    AgentScreen(),
    SecurityScreen(),
    CommunicationScreen(),
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
            icon: Icon(Icons.smartphone_outlined, color: JARVISTheme.textSecondary),
            selectedIcon: Icon(Icons.smartphone, color: JARVISTheme.secondary),
            label: 'AJAN',
          ),
          NavigationDestination(
            icon: Icon(Icons.security_outlined, color: JARVISTheme.textSecondary),
            selectedIcon: Icon(Icons.security, color: JARVISTheme.primary),
            label: 'GÜVENLİK',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_outlined, color: JARVISTheme.textSecondary),
            selectedIcon: Icon(Icons.chat, color: JARVISTheme.primary),
            label: 'İLETİŞİM',
          ),
        ],
      ),
    );
  }
}
