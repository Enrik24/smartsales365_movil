// lib/widgets/product_card.dart
import 'package:flutter/material.dart';
import '../models/product_model.dart' as product_models;

class ProductCard extends StatelessWidget {
  final product_models.Product product;
  final VoidCallback onTap;
  final VoidCallback onFavorite;
  final bool showFavoriteButton;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    required this.onFavorite,
    this.showFavoriteButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen del producto
            _buildProductImage(),
            
            // Información del producto
            _buildProductInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildProductImage() {
    return Stack(
      children: [
        Container(
          height: 120,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            color: Colors.grey.shade200,
            image: product.imageUrl.isNotEmpty
                ? DecorationImage(
                    image: NetworkImage(product.imageUrl),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: product.imageUrl.isEmpty
              ? const Center(
                  child: Icon(
                    Icons.image_not_supported_outlined,
                    size: 40,
                    color: Colors.grey,
                  ),
                )
              : null,
        ),
        
        // Badge de estado
        Positioned(
          top: 8,
          left: 8,
          child: _buildStatusBadge(),
        ),
        
        // Botón de favoritos
        if (showFavoriteButton)
          Positioned(
            top: 8,
            right: 8,
            child: _buildFavoriteButton(),
          ),
      ],
    );
  }

  Widget _buildStatusBadge() {
    Color badgeColor;
    String badgeText;
    
    if (!product.isActive) {
      badgeColor = Colors.red;
      badgeText = 'No disponible';
    } else if (product.isOutOfStock) {
      badgeColor = Colors.orange;
      badgeText = 'Agotado';
    } else if (product.stock < 10) {
      badgeColor = Colors.orange.shade700;
      badgeText = 'Poco stock';
    } else {
      badgeColor = Colors.green;
      badgeText = 'Disponible';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        badgeText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildFavoriteButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: const Icon(
          Icons.favorite_border,
          size: 20,
          color: Colors.red,
        ),
        onPressed: onFavorite,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(
          minWidth: 36,
          minHeight: 36,
        ),
      ),
    );
  }

  Widget _buildProductInfo() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Nombre del producto
            Text(
              product.name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            
            // Marca
            if (product.brand.isNotEmpty)
              Text(
                product.brand,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            
            // Precio y stock
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Precio
                Text(
                  '\$${product.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                
                const SizedBox(height: 4),
                
                // Stock
                Row(
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 12,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Stock: ${product.stock}',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Versión alternativa del ProductCard para diferentes layouts
class ProductCardHorizontal extends StatelessWidget {
  final product_models.Product product;
  final VoidCallback onTap;
  final VoidCallback onFavorite;

  const ProductCardHorizontal({
    super.key,
    required this.product,
    required this.onTap,
    required this.onFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Imagen
            _buildProductImage(),
            
            // Información
            Expanded(
              child: _buildProductInfo(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductImage() {
    return Container(
      width: 80,
      height: 80,
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey.shade200,
        image: product.imageUrl.isNotEmpty
            ? DecorationImage(
                image: NetworkImage(product.imageUrl),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: product.imageUrl.isEmpty
          ? const Center(
              child: Icon(
                Icons.image_not_supported_outlined,
                size: 24,
                color: Colors.grey,
              ),
            )
          : null,
    );
  }

  Widget _buildProductInfo() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Nombre
          Text(
            product.name,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          
          // Marca
          if (product.brand.isNotEmpty)
            Text(
              product.brand,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          
          // Precio y acciones
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Precio
              Text(
                '\$${product.price.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              
              // Botón de favorito
              IconButton(
                icon: const Icon(
                  Icons.favorite_border,
                  size: 20,
                  color: Colors.red,
                ),
                onPressed: onFavorite,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 36,
                  minHeight: 36,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Widget para mostrar productos en lista
class ProductListItem extends StatelessWidget {
  final product_models.Product product;
  final VoidCallback onTap;
  final VoidCallback onFavorite;

  const ProductListItem({
    super.key,
    required this.product,
    required this.onTap,
    required this.onFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      elevation: 1,
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey.shade200,
            image: product.imageUrl.isNotEmpty
                ? DecorationImage(
                    image: NetworkImage(product.imageUrl),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: product.imageUrl.isEmpty
              ? const Icon(
                  Icons.image_not_supported_outlined,
                  color: Colors.grey,
                )
              : null,
        ),
        title: Text(
          product.name,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (product.brand.isNotEmpty)
              Text(
                product.brand,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            Text(
              '\$${product.price.toStringAsFixed(2)} • Stock: ${product.stock}',
              style: const TextStyle(
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: Icon(
            Icons.favorite_border,
            color: Colors.red.shade400,
          ),
          onPressed: onFavorite,
        ),
        onTap: onTap,
      ),
    );
  }
}