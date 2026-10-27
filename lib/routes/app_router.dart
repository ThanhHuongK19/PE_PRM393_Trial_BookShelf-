import 'package:go_router/go_router.dart';

import '../models/book.dart';
import '../providers/auth_provider.dart';
import '../screens/add_book_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/sign_in_screen.dart';
import '../screens/auth/sign_up_screen.dart';
import '../screens/book_detail_screen.dart';
import '../screens/book_list_screen.dart';
import '../screens/home_screen.dart';
import '../screens/splash_screen.dart';

GoRouter createAppRouter(AuthProvider authProvider) {
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: authProvider,
    redirect: (context, state) {
      final location = state.matchedLocation;
      final isPublicRoute = {
        '/',
        '/sign-in',
        '/sign-up',
        '/forgot-password',
      }.contains(location);

      if (authProvider.isInitializing) {
        return location == '/splash' ? null : '/splash';
      }
      if (!authProvider.isSignedIn) {
        return isPublicRoute ? null : '/';
      }
      if (isPublicRoute || location == '/splash' || location == '/') {
        return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/sign-in',
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: '/sign-up',
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const BookListScreen(),
      ),
      GoRoute(
        path: '/books/add',
        builder: (context, state) => const AddBookScreen(),
      ),
      GoRoute(
        path: '/books/:id',
        builder: (context, state) {
          final bookId = state.pathParameters['id']!;
          final extra = state.extra;
          final book = extra is Book && extra.id == bookId ? extra : null;
          return BookDetailScreen(bookId: bookId, book: book);
        },
      ),
    ],
  );
}
