import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/state_views.dart';
import '../domain/product.dart';
import 'catalog_controller.dart';

class CatalogPage extends StatefulWidget {
  const CatalogPage({super.key, required this.onProductTap, this.listMode = false});
  final ValueChanged<int> onProductTap;
  final bool listMode;
  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  final searchController = TextEditingController();

  @override
  void dispose() { searchController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogController>();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('SHOPSPHERE', style: TextStyle(color: AppTheme.jade,
              fontWeight: FontWeight.w800, letterSpacing: 2, fontSize: 11)),
            const SizedBox(height: 4),
            Text('Discover your next find', style: Theme.of(context).textTheme.headlineMedium),
          ])),
          const CircleAvatar(backgroundColor: Color(0xFFE3EDE7),
            child: Icon(Icons.auto_awesome, color: AppTheme.jade)),
        ])),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 20),
        child: TextField(controller: searchController,
          onChanged: catalog.setSearch,
          decoration: InputDecoration(hintText: 'Search products',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: searchController.text.isEmpty ? null : IconButton(
              tooltip: 'Clear search', icon: const Icon(Icons.close),
              onPressed: () { searchController.clear(); catalog.setSearch(''); setState(() {}); }),
          ),
        )),
      const SizedBox(height: 14),
      SizedBox(height: 48, child: ListView(scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20), children: [
          _chip(context, catalog, null, 'All'),
          for (final category in catalog.categories)
            _chip(context, catalog, category.slug, category.name),
        ])),
      Padding(padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
        child: Row(children: [
          Expanded(child: Text(catalog.status == CatalogStatus.ready
              ? '${catalog.total} products' : 'Curated for you',
              style: Theme.of(context).textTheme.titleMedium)),
          PopupMenuButton<ProductSort>(tooltip: 'Sort products',
            icon: const Icon(Icons.tune_rounded),
            initialValue: catalog.sort,
            onSelected: catalog.setSort,
            itemBuilder: (_) => const [
              PopupMenuItem(value: ProductSort.featured, child: Text('Featured')),
              PopupMenuItem(value: ProductSort.priceLow, child: Text('Price: low to high')),
              PopupMenuItem(value: ProductSort.priceHigh, child: Text('Price: high to low')),
              PopupMenuItem(value: ProductSort.rating, child: Text('Top rated')),
              PopupMenuItem(value: ProductSort.title, child: Text('Title: A to Z')),
            ]),
        ])),
      Expanded(child: switch (catalog.status) {
        CatalogStatus.loading => const LoadingCards(),
        CatalogStatus.empty => const EmptyView(
          icon: Icons.search_off_rounded, title: 'No products found',
          message: 'Try another search or category.'),
        CatalogStatus.failure => ErrorView(message: catalog.failure!.message,
          onRetry: catalog.load),
        CatalogStatus.ready => _productList(catalog),
      }),
    ]);
  }

  Widget _chip(BuildContext context, CatalogController catalog, String? slug, String label) {
    final selected = catalog.category == slug && catalog.search.isEmpty;
    return Padding(padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(label: Text(label), selected: selected,
        onSelected: (_) { searchController.clear(); setState(() {}); catalog.setCategory(slug); },
        showCheckmark: false,
        selectedColor: AppTheme.jade,
        labelStyle: TextStyle(color: selected ? Colors.white : AppTheme.ink),
        side: BorderSide.none,
        backgroundColor: Colors.white,
      ));
  }

  Widget _productList(CatalogController catalog) => NotificationListener<ScrollNotification>(
    onNotification: (notification) {
      if (notification.metrics.pixels > notification.metrics.maxScrollExtent - 400) {
        catalog.loadMore();
      }
      return false;
    },
    child: RefreshIndicator(onRefresh: catalog.load,
      child: LayoutBuilder(builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width < 600 ? 2 : width < 850 ? 3 : 4;
        if (widget.listMode) {
          return ListView.builder(padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            itemCount: catalog.products.length + (catalog.loadingMore ? 1 : 0),
            itemBuilder: (context, index) => index >= catalog.products.length
                ? const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator()))
                : ProductRow(product: catalog.products[index], onTap: () => widget.onProductTap(catalog.products[index].id)));
        }
        return GridView.builder(padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          itemCount: catalog.products.length + (catalog.loadingMore ? 1 : 0),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns, crossAxisSpacing: 12, mainAxisSpacing: 12,
            mainAxisExtent: 304),
          itemBuilder: (context, index) => index >= catalog.products.length
              ? const Center(child: CircularProgressIndicator())
              : ProductCard(product: catalog.products[index],
                  onTap: () => widget.onProductTap(catalog.products[index].id)),
        );
      }),
    ),
  );
}

class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product, required this.onTap});
  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(clipBehavior: Clip.antiAlias,
    child: InkWell(onTap: onTap, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(height: 172, width: double.infinity, child: Stack(children: [
        Positioned.fill(child: ColoredBox(color: const Color(0xFFF1F3EE),
          child: CachedNetworkImage(imageUrl: product.thumbnail, fit: BoxFit.contain,
            errorWidget: (_, _, _) => const Icon(Icons.image_not_supported_outlined),
            placeholder: (_, _) => const Center(child: CircularProgressIndicator(strokeWidth: 2))))),
        if (product.discountPercentage > 0)
          Positioned(top: 10, left: 10, child: DecoratedBox(
            decoration: BoxDecoration(color: AppTheme.coral, borderRadius: BorderRadius.circular(8)),
            child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text('-${product.discountPercentage.round()}%',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11))))),
      ])),
      Padding(padding: const EdgeInsets.fromLTRB(12, 11, 12, 0),
        child: Text(product.title, maxLines: 2, overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium)),
      const Spacer(),
      Padding(padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('\$${product.salePrice.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: AppTheme.jade)),
          const SizedBox(height: 4),
          Row(children: [
            const Icon(Icons.star_rounded, size: 16, color: Color(0xFFE9A63B)),
            Text(' ${product.rating.toStringAsFixed(1)}', style: const TextStyle(fontSize: 12)),
            if (product.discountPercentage > 0) ...[
              const Spacer(),
              Text('\$${product.price.toStringAsFixed(0)}', style: const TextStyle(
                decoration: TextDecoration.lineThrough, color: Color(0xFF84918B), fontSize: 12)),
            ],
          ]),
        ])),
    ])));
}

class ProductRow extends StatelessWidget {
  const ProductRow({super.key, required this.product, required this.onTap});
  final Product product;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(child: InkWell(onTap: onTap,
    borderRadius: BorderRadius.circular(22), child: Padding(padding: const EdgeInsets.all(10),
      child: Row(children: [
        SizedBox(width: 88, height: 88, child: CachedNetworkImage(imageUrl: product.thumbnail,
          fit: BoxFit.contain, errorWidget: (_, _, _) => const Icon(Icons.image_not_supported_outlined))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(product.title, maxLines: 2, overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 5),
          Text('\$${product.salePrice.toStringAsFixed(2)}',
            style: const TextStyle(color: AppTheme.jade, fontWeight: FontWeight.w800)),
          Text('★ ${product.rating.toStringAsFixed(1)}', style: const TextStyle(fontSize: 12)),
        ])),
        const Icon(Icons.chevron_right_rounded),
      ]))));
}
