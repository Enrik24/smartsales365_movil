import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';
import '../client/catalog_screen.dart';
import '../client/cart_screen.dart';
import '../client/order_history_screen.dart';
import '../client/order_tracking_screen.dart';
import '../client/voice_commands_screen.dart';
import '../client/notifications_screen.dart';
import '../client/profile_screen.dart';
import '../../widgets/neumorphic_card.dart';
import '../../widgets/bottom_navigation_bar.dart';

class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({super.key});

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  final _authService = AuthService();
  User? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final response = await _authService.getCurrentUser();
      if (response.success && response.data != null) {
        setState(() {
          _currentUser = response.data;
          _isLoading = false;
        });
      } else {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Column(
                children: [
                  // Header con información del usuario
                  _buildHeader(),
                  
                  // Contenido principal - Grid 2x3 con funcionalidades
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 20,
                        mainAxisSpacing: 20,
                        children: [
                          _buildNeumorphicCard(
                            icon: Icons.store,
                            title: 'Catálogo',
                            subtitle: 'Explora productos',
                            color: Colors.blue,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const CatalogScreen(),
                              ),
                            ),
                          ),
                          _buildNeumorphicCard(
                            icon: Icons.shopping_cart,
                            title: 'Carrito',
                            subtitle: 'Ver mi carrito',
                            color: Colors.green,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const CartScreen(),
                              ),
                            ),
                          ),
                          _buildNeumorphicCard(
                            icon: Icons.history,
                            title: 'Historial',
                            subtitle: 'Mis compras',
                            color: Colors.orange,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const OrderHistoryScreen(),
                              ),
                            ),
                          ),
                          _buildNeumorphicCard(
                            icon: Icons.track_changes,
                            title: 'Seguimiento',
                            subtitle: 'Rastrear pedidos',
                            color: Colors.red,
                            onTap: () => _showComingSoon('Seguimiento de Pedidos'),
                          ),
                          _buildNeumorphicCard(
                            icon: Icons.mic,
                            title: 'Comandos Voz',
                            subtitle: 'Navegar por voz',
                            color: Colors.indigo,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const VoiceCommandsScreen(),
                              ),
                            ),
                          ),
                          _buildNeumorphicCard(
                            icon: Icons.person,
                            title: 'Perfil',
                            subtitle: 'Mi cuenta',
                            color: Colors.teal,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ProfileScreen(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: const CustomBottomNavigationBar(currentIndex: 0),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '¡Bienvenido!',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Text(
                _currentUser?.firstName ?? 'Cliente',
                style: const TextStyle(fontSize: 16, color: Colors.black54),
              ),
            ],
          ),
          NeumorphicButton(
            onTap: () => Navigator.pushNamed(context, '/notifications'),
            width: 50,
            height: 50,
            padding: const EdgeInsets.all(12),
            child: const Icon(
              Icons.notifications_outlined,
              color: Colors.black87,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNeumorphicCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return NeumorphicButton(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 24, color: color),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 2),
            Flexible(
              child: Text(
                subtitle,
                style: const TextStyle(fontSize: 10, color: Colors.grey),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature - Próximamente disponible'),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}