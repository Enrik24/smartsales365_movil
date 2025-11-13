// lib/screens/client/notifications_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/notification_service.dart' as notification_service;
import '../../widgets/custom_bottom_navigation_bar.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/error_widget.dart';
import '../../models/notification_model.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _notificationService = notification_service.NotificationService();
  final List<AppNotification> _notifications = [];
  bool _isLoading = true;
  String _error = '';
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      if (!mounted) return;
      setState(() {
        _isLoading = true;
        _error = '';
      });

      final response = await _notificationService.getNotifications();

      if (!mounted) return;

      if (response.success && response.data != null) {
        setState(() {
          _notifications.clear();
          _notifications.addAll(response.data!);
          _unreadCount = _notifications.where((n) => !n.isRead).length;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response.error ?? 'Error al cargar notificaciones';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error de conexión: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _markAsRead(int notificationId) async {
    final response = await _notificationService.markAsRead(notificationId);

    if (!mounted) return;

    if (response.success) {
      setState(() {
        final index = _notifications.indexWhere((n) => n.id == notificationId);
        if (index != -1) {
          _notifications[index] = AppNotification(
            id: _notifications[index].id,
            tipo: _notifications[index].tipo,
            titulo: _notifications[index].titulo,
            mensaje: _notifications[index].mensaje,
            fechaCreacion: _notifications[index].fechaCreacion,
            fechaEnvio: _notifications[index].fechaEnvio,
            estado: 'leida', // Cambiar estado a leída
            datosAdicionales: _notifications[index].datosAdicionales,
          );
          _unreadCount = _notifications.where((n) => !n.isRead).length;
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response.error ?? 'Error al marcar como leída')),
      );
    }
  }

  Future<void> _markAllAsRead() async {
    final response = await _notificationService.markAllAsRead();

    if (!mounted) return;

    if (response.success) {
      setState(() {
        for (int i = 0; i < _notifications.length; i++) {
          if (!_notifications[i].isRead) {
            _notifications[i] = AppNotification(
              id: _notifications[i].id,
              tipo: _notifications[i].tipo,
              titulo: _notifications[i].titulo,
              mensaje: _notifications[i].mensaje,
              fechaCreacion: _notifications[i].fechaCreacion,
              fechaEnvio: _notifications[i].fechaEnvio,
              estado: 'leida',
              datosAdicionales: _notifications[i].datosAdicionales,
            );
          }
        }
        _unreadCount = 0;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Todas las notificaciones marcadas como leídas')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response.error ?? 'Error al marcar todas como leídas')),
      );
    }
  }

  Future<void> _deleteNotification(int notificationId) async {
    final response = await _notificationService.deleteNotification(notificationId);

    if (!mounted) return;

    if (response.success) {
      setState(() {
        _notifications.removeWhere((n) => n.id == notificationId);
        _unreadCount = _notifications.where((n) => !n.isRead).length;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notificación eliminada')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response.error ?? 'Error al eliminar notificación')),
      );
    }
  }

  void _onNotificationTap(AppNotification notification) {
    if (!notification.isRead) {
      _markAsRead(notification.id);
    }

    // Navegación según el tipo de notificación
    switch (notification.tipo) {
      case 'pedido':
        print('Navegando al pedido: ${notification.datosAdicionales?['order_id']}');
        break;
      case 'promocion':
        print('Navegando a la promoción: ${notification.datosAdicionales?['promotion_id']}');
        break;
      case 'inventario':
        print('Navegando al producto: ${notification.datosAdicionales?['product_id']}');
        break;
      default:
        print('Tipo de notificación: ${notification.tipo}');
        break;
    }
  }

  IconData _getNotificationIcon(String tipo) {
    switch (tipo) {
      case 'pedido':
        return Icons.shopping_cart;
      case 'inventario':
        return Icons.inventory_2;
      case 'promocion':
        return Icons.local_offer;
      case 'sistema':
        return Icons.notifications;
      default:
        return Icons.info;
    }
  }

  Color _getNotificationColor(String tipo) {
    switch (tipo) {
      case 'pedido':
        return Colors.blue;
      case 'inventario':
        return Colors.orange;
      case 'promocion':
        return Colors.green;
      case 'sistema':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Ahora mismo';
    } else if (difference.inHours < 1) {
      return 'Hace ${difference.inMinutes} min';
    } else if (difference.inDays < 1) {
      return 'Hace ${difference.inHours} h';
    } else if (difference.inDays < 7) {
      return 'Hace ${difference.inDays} d';
    } else {
      return DateFormat('dd/MM/yyyy').format(dateTime);
    }
  }

  Widget _buildNotificationItem(AppNotification notification) {
    final bool isUnread = !notification.isRead;
    final color = _getNotificationColor(notification.tipo);

    return Dismissible(
      key: Key('notification_${notification.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) => _deleteNotification(notification.id),
      child: ListTile(
        onTap: () => _onNotificationTap(notification),
        tileColor: isUnread ? color.withOpacity(0.08) : null,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(_getNotificationIcon(notification.tipo), color: color, size: 28),
        ),
        title: Text(
          notification.titulo,
          style: TextStyle(
            fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification.mensaje,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 4),
            Text(
              _formatDateTime(notification.fechaCreacion),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
        trailing: isUnread
            ? Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  shape: BoxShape.circle,
                ),
              )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
        actions: [
          if (_unreadCount > 0)
            IconButton(
              icon: const Icon(Icons.mark_email_read),
              onPressed: _markAllAsRead,
              tooltip: 'Marcar todas como leídas',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadNotifications,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: _isLoading
          ? const CustomLoadingIndicator(message: 'Cargando notificaciones...')
          : _error.isNotEmpty
              ? CustomErrorWidget(
                  message: _error,
                  onRetry: _loadNotifications,
                )
              : _notifications.isEmpty
                  ? _buildEmptyState()
                  : _buildNotificationsList(),
      bottomNavigationBar: const CustomBottomNavigationBar(currentIndex: 3),
    );
  }

  Widget _buildNotificationsList() {
    return Column(
      children: [
        if (_unreadCount > 0)
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            child: Row(
              children: [
                Icon(Icons.info, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Text(
                  '$_unreadCount notificación(es) no leída(s)',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: ListView.builder(
            itemCount: _notifications.length,
            itemBuilder: (context, index) {
              final notification = _notifications[index];
              return _buildNotificationItem(notification);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No hay notificaciones',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tus notificaciones aparecerán aquí',
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadNotifications,
            child: const Text('Recargar'),
          ),
        ],
      ),
    );
  }
}