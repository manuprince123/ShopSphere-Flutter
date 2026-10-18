import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/state_views.dart';
import '../../wishlist/presentation/wishlist_controller.dart';
import '../domain/product.dart';
import 'catalog_controller.dart';

class CatalogPage extends StatefulWidget {
  const CatalogPage({
    super.key,
    required this.onProductTap,
    this.listMode = false,
  });
  final ValueChanged<int> onProductTap;
  final bool listMode;
  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  final searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    searchController.text = context.read<CatalogController>().search;
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogController>();
    final compactHeight = MediaQuery.sizeOf(context).height < 520;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            compactHeight ? 8 : 20,
            20,
            compactHeight ? 8 : 14,
          ),
          child: compactHeight
              ? Text(
                  context.l10n.t('appName'),
                  style: Theme.of(context).textTheme.titleLarge,
                )
              : Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.t('appName').toUpperCase(),
                            style: TextStyle(
                              color: AppTheme.jade,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            context.l10n.t('discover'),
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                        ],
                      ),
                    ),
                    const CircleAvatar(
                      backgroundColor: Color(0xFFE3EDE7),
                      child: Icon(Icons.auto_awesome, color: AppTheme.jade),
                    ),
                  ],
                ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: TextField(
            controller: searchController,
            onChanged: (value) {
              setState(() {});
              catalog.setSearch(value);
            },
            decoration: InputDecoration(
              hintText: context.l10n.t('searchProducts'),
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: searchController.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: context.l10n.t('clearSearch'),
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        searchController.clear();
                        catalog.setSearch('');
                        setState(() {});
                      },
                    ),
            ),
          ),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: catalog.isOffline
              ? Container(
                  key: const ValueKey('offline-banner'),
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.cloud_off_outlined, size: 20),
                      const SizedBox(width: 9),
                      Expanded(child: Text(context.l10n.t('offlineBanner'))),
                      TextButton(
                        onPressed: catalog.load,
                        child: Text(context.l10n.t('retry')),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(key: ValueKey('online')),
        ),
        SizedBox(height: compactHeight ? 6 : 14),
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              _chip(context, catalog, null, context.l10n.t('all')),
              for (final category in catalog.categories)
                _chip(context, catalog, category.slug, category.name),
              if (catalog.categoriesFailure != null)
                ActionChip(
                  label: Text(context.l10n.t('retryCategories')),
                  avatar: const Icon(Icons.refresh, size: 18),
                  onPressed: catalog.loadCategories,
                ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            compactHeight ? 4 : 12,
            20,
            compactHeight ? 4 : 10,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  catalog.status == CatalogStatus.ready
                      ? context.l10n.productCount(catalog.total)
                      : context.l10n.t('curated'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              PopupMenuButton<ProductSort>(
                tooltip: context.l10n.t('sortProducts'),
                icon: const Icon(Icons.tune_rounded),
                initialValue: catalog.sort,
                onSelected: catalog.setSort,
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: ProductSort.featured,
                    child: Text(context.l10n.t('featured')),
                  ),
                  PopupMenuItem(
                    value: ProductSort.priceLow,
                    child: Text(context.l10n.t('priceLow')),
                  ),
                  PopupMenuItem(
                    value: ProductSort.priceHigh,
                    child: Text(context.l10n.t('priceHigh')),
                  ),
                  PopupMenuItem(
                    value: ProductSort.rating,
                    child: Text(context.l10n.t('topRated')),
                  ),
                  PopupMenuItem(
                    value: ProductSort.title,
                    child: Text(context.l10n.t('titleSort')),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: switch (catalog.status) {
            CatalogStatus.loading => const LoadingCards(),
            CatalogStatus.empty => EmptyView(
              icon: Icons.search_off_rounded,
              title: context.l10n.t('noProducts'),
              message: context.l10n.t('trySearch'),
            ),
            CatalogStatus.failure => ErrorView(
              message: catalog.failure!.message,
              onRetry: catalog.load,
            ),
            CatalogStatus.ready => _productList(catalog),
          },
        ),
      ],
    );
  }

  Widget _chip(
    BuildContext context,
    CatalogController catalog,
    String? slug,
    String label,
  ) {
    final selected = catalog.category == slug && catalog.search.isEmpty;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) {
          searchController.clear();
          setState(() {});
          catalog.setCategory(slug);
        },
        showCheckmark: false,
        selectedColor: AppTheme.jade,
        labelStyle: TextStyle(
          color: selected
              ? Colors.white
              : Theme.of(context).colorScheme.onSurface,
        ),
        side: BorderSide.none,
        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      ),
    );
  }

  Widget _productList(CatalogController catalog) =>
      NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.metrics.pixels >
              notification.metrics.maxScrollExtent - 400) {
            catalog.loadMore();
          }
          return false;
        },
        child: RefreshIndicator(
          onRefresh: catalog.load,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final availableWidth = constraints.maxWidth;
              final columns = availableWidth < 500
                  ? 2
                  : availableWidth < 850
                  ? 3
                  : 4;
              if (widget.listMode) {
                return ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount:
                      catalog.products.length +
                      (catalog.loadingMore || catalog.failure != null ? 1 : 0),
                  itemBuilder: (context, index) =>
                      index >= catalog.products.length
                      ? _footer(catalog)
                      : ProductRow(
                          product: catalog.products[index],
                          onTap: () =>
                              widget.onProductTap(catalog.products[index].id),
                        ),
                );
              }
              return GridView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount:
                    catalog.products.length +
                    (catalog.loadingMore || catalog.failure != null ? 1 : 0),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  mainAxisExtent: 332,
                ),
                itemBuilder: (context, index) =>
                    index >= catalog.products.length
                    ? _footer(catalog)
                    : ProductCard(
                        product: catalog.products[index],
                        onTap: () =>
                            widget.onProductTap(catalog.products[index].id),
                      ),
              );
            },
          ),
        ),
      );

  Widget _footer(CatalogController catalog) => catalog.failure == null
      ? const Center(child: CircularProgressIndicator())
      : Center(
          child: TextButton.icon(
            onPressed: catalog.retryLoadMore,
            icon: const Icon(Icons.refresh),
            label: Text(context.l10n.t('retryLoadingMore')),
          ),
        );
}

class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product, required this.onTap});
  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 154,
            width: double.infinity,
            child: Stack(
              children: [
                Positioned.fill(
                  child: ColoredBox(
                    color: const Color(0xFFF1F3EE),
                    child: Hero(
                      tag: 'product-${product.id}',
                      child: CachedNetworkImage(
                        imageUrl: product.thumbnail,
                        fit: BoxFit.contain,
                        errorWidget: (_, _, _) =>
                            const Icon(Icons.image_not_supported_outlined),
                        placeholder: (_, _) => const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                  ),
                ),
                if (product.discountPercentage > 0)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppTheme.coral,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: Text(
                          '-${product.discountPercentage.round()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: Consumer<WishlistController>(
                    builder: (context, wishlist, _) {
                      final saved = wishlist.contains(product.id);
                      return IconButton.filledTonal(
                        tooltip: context.l10n.t(
                          saved ? 'removeSaved' : 'saveItem',
                        ),
                        onPressed: () => wishlist.toggle(product),
                        icon: Icon(
                          saved ? Icons.favorite : Icons.favorite_border,
                          color: saved ? AppTheme.coral : null,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 11, 12, 0),
            child: Text(
              product.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '\$${product.salePrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                      color: AppTheme.jade,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 2,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 16,
                          color: Color(0xFFE9A63B),
                        ),
                        Text(
                          ' ${product.rating.toStringAsFixed(1)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    if (product.discountPercentage > 0)
                      Text(
                        '\$${product.price.toStringAsFixed(0)}',
                        style: const TextStyle(
                          decoration: TextDecoration.lineThrough,
                          color: Color(0xFF84918B),
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class ProductRow extends StatelessWidget {
  const ProductRow({super.key, required this.product, required this.onTap});
  final Product product;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            SizedBox(
              width: 88,
              height: 88,
              child: CachedNetworkImage(
                imageUrl: product.thumbnail,
                fit: BoxFit.contain,
                errorWidget: (_, _, _) =>
                    const Icon(Icons.image_not_supported_outlined),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '\$${product.salePrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: AppTheme.jade,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    '★ ${product.rating.toStringAsFixed(1)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    ),
  );
}
