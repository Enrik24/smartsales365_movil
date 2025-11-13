// lib/screens/client/catalog_screen.dart
import 'package:flutter/material.dart';
import 'dart:async';
import '../../services/product_service.dart' as product_service;
import '../../services/auth_service.dart' as auth_service;
import '../../models/product_model.dart' as product_models;
import '../../widgets/custom_bottom_navigation_bar.dart';
import '../../widgets/neumorphic_card.dart';
import '../../widgets/product_card.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/product_card.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final _productService = product_service.ProductService();
  final List<product_models.Product> _products = [];
  final List<product_models.Product> _filteredProducts = [];
  bool _isLoading = true;
  String _error = '';
  String _searchQuery = '';
  String _selectedCategory = 'Todos';
  String _selectedSort = 'Relevancia';
  int _currentPage = 1;
  bool _hasMore = true;

  // Categorías y opciones de ordenamiento
  List<String> _categories = ['Todos'];
  final List<String> _sortOptions = [
    'Relevancia', 
    'Precio: Menor a Mayor', 
    'Precio: Mayor a Menor',
    'Nombre: A-Z',
    'Nombre: Z-A'
  ];

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent && _hasMore) {
      _loadMoreProducts();
    }
  }

  Future<void> _loadInitialData() async {
    await _loadCategories();
    await _loadProducts();
  }

  Future<void> _loadCategories() async {
    final response = await _productService.getCategories();
    if (response.success && response.data != null) {
      setState(() {
        _categories = ['Todos'];
        _categories.addAll(response.data!.map((cat) => cat.nombre).where((name) => name.isNotEmpty));
      });
    }
  }

  Future<void> _loadProducts() async {
    try {
      setState(() {
        _isLoading = true;
        _error = '';
      });

      final response = await _productService.getProducts(
        page: _currentPage,
        search: _searchQuery.isEmpty ? null : _searchQuery,
        category: _selectedCategory == 'Todos' ? null : _selectedCategory,
        sortBy: _getSortParameter(),
      );

      if (response.success && response.data != null) {
        setState(() {
          _products.clear();
          _products.addAll(response.data!);
          _filteredProducts.clear();
          _filteredProducts.addAll(response.data!);
          _hasMore = response.data!.isNotEmpty;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response.error ?? 'Error al cargar productos';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error de conexión: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreProducts() async {
    if (_isLoading || !_hasMore) return;

    try {
      final nextPage = _currentPage + 1;
      final response = await _productService.getProducts(
        page: nextPage,
        search: _searchQuery.isEmpty ? null : _searchQuery,
        category: _selectedCategory == 'Todos' ? null : _selectedCategory,
        sortBy: _getSortParameter(),
      );

      if (response.success && response.data != null && response.data!.isNotEmpty) {
        setState(() {
          _products.addAll(response.data!);
          _filteredProducts.addAll(response.data!);
          _currentPage = nextPage;
          _hasMore = response.data!.isNotEmpty;
        });
      } else {
        setState(() {
          _hasMore = false;
        });
      }
    } catch (e) {
      // Silenciar errores de carga adicional
    }
  }

  String? _getSortParameter() {
    switch (_selectedSort) {
      case 'Precio: Menor a Mayor':
        return 'precio';
      case 'Precio: Mayor a Menor':
        return '-precio';
      case 'Nombre: A-Z':
        return 'nombre';
      case 'Nombre: Z-A':
        return '-nombre';
      default:
        return null;
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _debounceFilter();
  }

  void _onCategoryChanged(String? category) {
    if (category != null) {
      setState(() {
        _selectedCategory = category;
        _currentPage = 1;
      });
      _loadProducts();
    }
  }

  void _onSortChanged(String? sort) {
    if (sort != null) {
      setState(() {
        _selectedSort = sort;
        _currentPage = 1;
      });
      _loadProducts();
    }
  }

  void _debounceFilter() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _currentPage = 1;
      _loadProducts();
    });
  }

  void _showProductDetail(product_models.Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailScreen(product: product),
      ),
    );
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filtrar y Ordenar',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              // Categoría
              const Text('Categoría', style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownButton<String>(
                value: _selectedCategory,
                isExpanded: true,
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: _onCategoryChanged,
              ),
              
              const SizedBox(height: 16),
              
              // Ordenamiento
              const Text('Ordenar por', style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownButton<String>(
                value: _selectedSort,
                isExpanded: true,
                items: _sortOptions.map((sort) {
                  return DropdownMenuItem(
                    value: sort,
                    child: Text(sort),
                  );
                }).toList(),
                onChanged: _onSortChanged,
              ),
              
              const SizedBox(height: 24),
              
              // Botones de acción
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        _loadProducts();
                        Navigator.pop(context);
                      },
                      child: const Text('Aplicar'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catálogo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Buscar productos...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
          ),

          // Filtros rápidos
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: _categories.map((category) {
                final isSelected = category == _selectedCategory;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) => _onCategoryChanged(selected ? category : 'Todos'),
                    backgroundColor: Colors.grey.shade200,
                    selectedColor: Colors.blue.shade100,
                    checkmarkColor: Colors.blue,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.blue : Colors.grey.shade700,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Contador de resultados
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_filteredProducts.length} productos encontrados',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  _selectedSort,
                  style: TextStyle(
                    color: Colors.blue.shade600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // Lista de productos
          Expanded(
            child: _isLoading && _products.isEmpty
                ? const CustomLoadingIndicator(message: 'Cargando productos...')
                : _error.isNotEmpty
                    ? CustomErrorWidget(
                        message: _error,
                        onRetry: _loadProducts,
                      )
                    : _filteredProducts.isEmpty
                        ? _buildEmptyState()
                        : _buildProductGrid(),
          ),
        ],
      ),
      bottomNavigationBar: const CustomBottomNavigationBar(currentIndex: 0),
    );
  }

  Widget _buildProductGrid() {
    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.7,
      ),
      itemCount: _filteredProducts.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _filteredProducts.length) {
          return const Center(child: CircularProgressIndicator());
        }
        final product = _filteredProducts[index];
        return ProductCard(
          product: product,
          onTap: () => _showProductDetail(product),
          onFavorite: () {
            _productService.toggleFavorite(product.id);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${product.name} agregado a favoritos')),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No se encontraron productos',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'Intenta con otros términos de búsqueda'
                : 'No hay productos disponibles en este momento',
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              _searchController.clear();
              _onSearchChanged('');
              _onCategoryChanged('Todos');
            },
            child: const Text('Mostrar todos los productos'),
          ),
        ],
      ),
    );
  }
}

class ProductDetailScreen extends StatelessWidget {
  final product_models.Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(product.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // Compartir producto
            },
          ),
          IconButton(
            icon: const Icon(Icons.favorite_border),
            onPressed: () {
              // Agregar a favoritos
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen del producto
            Container(
              height: 300,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey.shade200,
                image: product.imageUrl.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(product.imageUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: product.imageUrl.isEmpty
                  ? const Icon(Icons.image, size: 64, color: Colors.grey)
                  : null,
            ),
            const SizedBox(height: 16),

            // Información del producto
            Text(
              product.name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Precio y rating
            Row(
              children: [
                Text(
                  '\$${product.price}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const Spacer(),
                Icon(Icons.star, color: Colors.amber, size: 20),
                const SizedBox(width: 4),
                Text(
                  '${product.rating} (${product.reviewCount})',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Descripción
            Text(
              product.description,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),

            // Especificaciones
            _buildSpecifications(),
            const SizedBox(height: 24),

            // Botón de acción
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: product.hasStock && product.isActive
                    ? () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${product.name} agregado al carrito')),
                        );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: product.hasStock && product.isActive ? Colors.blue : Colors.grey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  product.hasStock && product.isActive 
                      ? 'Agregar al Carrito' 
                      : 'No Disponible',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecifications() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Especificaciones',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        _buildSpecItem('SKU', product.sku),
        _buildSpecItem('Marca', product.brand),
        _buildSpecItem('Categoría', product.category),
        _buildSpecItem('Stock disponible', '${product.stock} unidades'),
        _buildSpecItem('Estado', _getStatusText(product.estado)),
        if (product.inventario?.ubicacionAlmacen != null && product.inventario!.ubicacionAlmacen.isNotEmpty)
          _buildSpecItem('Ubicación', product.inventario!.ubicacionAlmacen),
      ],
    );
  }

  Widget _buildSpecItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(value.isNotEmpty ? value : 'No especificado'),
        ],
      ),
    );
  }

  String _getStatusText(String estado) {
    switch (estado) {
      case 'activo': return 'Disponible';
      case 'inactivo': return 'No disponible';
      case 'agotado': return 'Agotado';
      default: return estado;
    }
  }
}