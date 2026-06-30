import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/commute/screens/create_commute_screen.dart';
import '../../features/commute/screens/commute_detail_screen.dart';
import '../../features/chat/screens/chat_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/map/screens/location_picker_screen.dart';
import '../../features/commute/screens/suggestions_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authNotifierProvider).value ?? const AuthState();

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoggedIn = authState.token != null;
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      if (!isLoggedIn && !isAuthRoute) return '/login';
      if (isLoggedIn && isAuthRoute) return '/';
      return null;
    },
    routes: [
      // Auth
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),

      // Main shell
      GoRoute(path: '/', builder: (_, __) => const HomeScreen()),

      // Commute
      GoRoute(path: '/commute/create', builder: (_, __) => const CreateCommuteScreen()),
      GoRoute(
        path: '/commute/:id',
        builder: (_, state) => CommuteDetailScreen(
          commuteId: state.pathParameters['id']!,
        ),
      ),

      // Location picker — returns PickedLocation via pop()
      GoRoute(
        path: '/location-picker',
        builder: (_, __) => const LocationPickerScreen(),
      ),

      // Suggestions
      GoRoute(path: '/suggestions', builder: (_, __) => const SuggestionsScreen()),

      // Chat
      GoRoute(
        path: '/chat/:conversationId',
        builder: (_, state) => ChatScreen(
          conversationId: state.pathParameters['conversationId']!,
        ),
      ),

      // Profile
      GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),

      // Notifications
      GoRoute(path: '/notifications', builder: (_, __) => const NotificationsScreen()),
    ],
  );
});
