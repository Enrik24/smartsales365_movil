  import 'package:flutter/material.dart';
  import '../screens/client/catalog_screen.dart';
  import '../screens/client/cart_screen.dart';
  import '../screens/client/checkout_screen.dart';
  import '../screens/client/order_tracking_screen.dart';
  import '../screens/client/order_history_screen.dart';
  import '../screens/client/profile_screen.dart';
  import '../screens/client/voice_commands_screen.dart';
  import '../screens/client/notifications_screen.dart';
  import '../screens/client/dashboard_screen.dart';
  import '../screens/auth/login_screen.dart';
  import '../screens/auth/register_screen.dart';
  import '../screens/onboarding_screen.dart';
  import '../models/product_model.dart';
  import '../models/order_model.dart';
  import '../models/cart_model.dart';

  class AppRouter {
    // Auth Routes
    static const String onboarding = '/onboarding';
    static const String login = '/login';
    static const String register = '/register';
    static const String emailVerification = '/email-verification';

    // Main App Routes
    static const String home = '/home';
    static const String catalog = '/catalog';
    static const String productDetail = '/product-detail';
    static const String cart = '/cart';
    static const String checkout = '/checkout';
    static const String orderTracking = '/order-tracking';
    static const String orderHistory = '/order-history';
    static const String profile = '/profile';
    static const String voiceCommands = '/voice-commands';
    static const String notifications = '/notifications';
    static const String dashboard = '/dashboard';

    static Route<dynamic> generateRoute(RouteSettings settings) {
      switch (settings.name) {
        case onboarding:
          return MaterialPageRoute(
            builder: (_) => const OnboardingScreen(),
            settings: settings,
          );

        case login:
          return MaterialPageRoute(
            builder: (_) => const LoginScreen(),
            settings: settings,
          );

        case register:
          return MaterialPageRoute(
            builder: (_) => const RegisterScreen(),
            settings: settings,
          );

        case home:
          return MaterialPageRoute(
            builder: (_) => const DashboardScreen(),
            settings: settings,
          );

        case catalog:
          return MaterialPageRoute(
            builder: (_) => const CatalogScreen(),
            settings: settings,
          );

        case productDetail:
          final product = settings.arguments as Product;
          return MaterialPageRoute(
            builder: (_) => ProductDetailScreen(product: product),
            settings: settings,
          );

        case cart:
          return MaterialPageRoute(
            builder: (_) => const CartScreen(),
            settings: settings,
          );

        case checkout:
          final cart = settings.arguments as Cart;
          return MaterialPageRoute(
            builder: (_) => CheckoutScreen(cart: cart),
            settings: settings,
          );

        case orderTracking:
          final order = settings.arguments as Order;
          return MaterialPageRoute(
            builder: (_) => OrderTrackingScreen(order: order),
            settings: settings,
          );

        case orderHistory:
          return MaterialPageRoute(
            builder: (_) => const OrderHistoryScreen(),
            settings: settings,
          );

        case profile:
          return MaterialPageRoute(
            builder: (_) => const ProfileScreen(),
            settings: settings,
          );

        case voiceCommands:
          return MaterialPageRoute(
            builder: (_) => const VoiceCommandsScreen(),
            settings: settings,
          );

        case notifications:
          return MaterialPageRoute(
            builder: (_) => const NotificationsScreen(),
            settings: settings,
          );

        case dashboard:
          return MaterialPageRoute(
            builder: (_) => const DashboardScreen(),
            settings: settings,
          );

        default:
          return MaterialPageRoute(
            builder: (_) => const LoginScreen(),
            settings: settings,
          );
      }
    }

    static Future<void> navigateBasedOnUserType(
      BuildContext context,
      String userType,
      String userName,
    ) async {
      switch (userType.toLowerCase()) {
        case 'admin':
        case 'administrador':
          Navigator.pushReplacementNamed(context, dashboard);
          break;
        case 'vendedor':
          Navigator.pushReplacementNamed(context, dashboard);
          break;
        case 'cliente':
        default:
          Navigator.pushReplacementNamed(context, home);
          break;
      }
    }

    // ✅ MÉTODOS CONVENIENTES PARA NAVEGACIÓN - SMART SALES
    static void navigateToProductDetail(BuildContext context, Product product) {
      Navigator.pushNamed(context, productDetail, arguments: product);
    }

    static void navigateToCart(BuildContext context) {
      Navigator.pushNamed(context, cart);
    }

    static void navigateToCheckout(BuildContext context, Cart cart) {
      Navigator.pushNamed(context, checkout, arguments: cart);
    }

    static void navigateToOrderTracking(BuildContext context, Order order) {
      Navigator.pushNamed(context, orderTracking, arguments: order);
    }

    static void navigateToVoiceCommands(BuildContext context) {
      Navigator.pushNamed(context, voiceCommands);
    }

    static void navigateHome(BuildContext context) {
      Navigator.pushNamedAndRemoveUntil(context, home, (route) => false);
    }

    static void navigateToDashboard(BuildContext context) {
      Navigator.pushNamedAndRemoveUntil(context, dashboard, (route) => false);
    }
  }