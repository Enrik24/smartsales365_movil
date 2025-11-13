// lib/widgets/custom_bottom_navigation_bar.dart (Actualizado)
import 'package:flutter/material.dart';
import '../screens/client/dashboard_screen.dart';
import '../screens/client/catalog_screen.dart';
import '../screens/client/order_history_screen.dart';
import '../screens/client/notifications_screen.dart';
import '../screens/client/profile_screen.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  
  const CustomBottomNavigationBar({
    super.key,
    this.currentIndex = 2, // Por defecto, home está activo
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            offset: const Offset(0, -2),
            blurRadius: 10,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(context, Icons.store, 0, 'Catálogo'),
          _buildNavItem(context, Icons.history, 1, 'Historial'),
          _buildNavItem(context, Icons.home, 2, 'Inicio'),
          _buildNavItem(context, Icons.notifications, 3, 'Notificaciones'),
          _buildNavItem(context, Icons.person, 4, 'Perfil'),
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, IconData icon, int index, String tooltip) {
    final isActive = index == currentIndex;
    
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: () => _handleNavigation(context, index),
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            shape: BoxShape.circle,
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.grey.shade300,
                      offset: const Offset(4, 4),
                      blurRadius: 8,
                      spreadRadius: 0,
                    ),
                    BoxShadow(
                      color: Colors.white,
                      offset: const Offset(-4, -4),
                      blurRadius: 8,
                      spreadRadius: 0,
                    ),
                  ]
                : null,
          ),
          child: Icon(
            icon,
            color: isActive ? Colors.blue : Colors.black54,
            size: 24,
          ),
        ),
      ),
    );
  }

  void _handleNavigation(BuildContext context, int index) {
    switch (index) {
      case 0: // Catálogo
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const CatalogScreen()),
        );
        break;
      case 1: // Historial
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const OrderHistoryScreen()),
        );
        break;
      case 2: // Dashboard
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
        );
        break;
      case 3: // Notificaciones
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const NotificationsScreen()),
        );
        break;
      case 4: // Perfil
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ProfileScreen()),
        );
        break;
      default:
        _showComingSoon(context, 'Navegación');
    }
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature - Próximamente disponible'),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}