import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../map/screens/map_screen.dart';
import '../../commute/screens/discover_screen.dart';
import '../../chat/screens/conversations_screen.dart';
import '../../profile/screens/profile_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  final _screens = const [
    MapScreen(),
    DiscoverScreen(),
    ConversationsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.borderSubtle, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          items: [
            _navItem(Icons.map_outlined, Icons.map, 'MAP'),
            _navItem(Icons.explore_outlined, Icons.explore, 'RIDES'),
            _navItem(Icons.chat_bubble_outline, Icons.chat_bubble, 'INBOX'),
            _navItem(Icons.person_outline, Icons.person, 'ME'),
          ],
        ),
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/commute/create'),
              backgroundColor: AppColors.signalYellow,
              foregroundColor: AppColors.systemBlack,
              icon: const Icon(Icons.add),
              label: const Text(
                'OFFER RIDE',
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  fontSize: 12,
                ),
              ),
            )
          : null,
    );
  }

  BottomNavigationBarItem _navItem(IconData icon, IconData activeIcon, String label) {
    return BottomNavigationBarItem(
      icon: Icon(icon),
      activeIcon: Column(
        children: [
          Container(width: 24, height: 3, color: AppColors.signalYellow),
          const SizedBox(height: 4),
          Icon(activeIcon),
        ],
      ),
      label: label,
    );
  }
}
