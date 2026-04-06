import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'constants.dart';
import 'screens/connection_screen.dart';
import 'screens/main_shell.dart';
import 'screens/log_detail_screen.dart';

GoRouter buildRouter() {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) async {
      if (state.matchedLocation == '/') {
        final prefs = await SharedPreferences.getInstance();
        final url = prefs.getString(FarmLensConstants.prefKeyBaseUrl) ?? '';
        if (url.isNotEmpty) return '/main';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const ConnectionScreen(),
      ),
      GoRoute(
        path: '/main',
        builder: (context, state) => const MainShell(),
      ),
      GoRoute(
        path: '/log/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return LogDetailScreen(cycleId: id);
        },
      ),
    ],
  );
}