import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/error/failure.dart';
import '../domain/product.dart';
import '../domain/product_repository.dart';

enum CatalogStatus { loading, ready, empty, failure }

class CatalogController extends ChangeNotifier {
  CatalogController(this.repository, this.getProducts);
  final ProductRepository repository;
  final GetProducts getProducts;

  CatalogStatus status = CatalogStatus.loading;
  List<Product> products = [];
  List<Category> categories = [];
  Failure? failure;
  String search = '';
  String? category;
  ProductSort sort = ProductSort.featured;
  bool loadingMore = false;
  int total = 0;
  Timer? _debounce;
  int _generation = 0;

  bool get hasMore => products.length < total;

  Future<void> initialize() async {
    await Future.wait([load(), loadCategories()]);
  }

  Future<void> loadCategories() async {
    final result = await repository.getCategories();
    if (result case Success<List<Category>>(:final value)) {
      categories = value;
      notifyListeners();
    }
  }

  Future<void> load() async {
    final generation = ++_generation;
    status = CatalogStatus.loading;
    failure = null;
    notifyListeners();
    final result = await getProducts(ProductQuery(search: search, category: category, sort: sort));
    if (generation != _generation) return;
    if (result case Success<ProductPage>(:final value)) {
      products = value.products;
      total = value.total;
      status = products.isEmpty ? CatalogStatus.empty : CatalogStatus.ready;
    } else {
      failure = (result as Failed<ProductPage>).failure;
      status = CatalogStatus.failure;
    }
    notifyListeners();
  }

  Future<void> loadMore() async {
    if (loadingMore || status != CatalogStatus.ready || !hasMore) return;
    loadingMore = true;
    notifyListeners();
    final generation = _generation;
    final result = await getProducts(ProductQuery(
      search: search, category: category, sort: sort, skip: products.length,
    ));
    if (generation != _generation) return;
    if (result case Success<ProductPage>(:final value)) {
      products = [...products, ...value.products];
      total = value.total;
    } else {
      failure = (result as Failed<ProductPage>).failure;
    }
    loadingMore = false;
    notifyListeners();
  }

  void setSearch(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (search == value.trim()) return;
      search = value.trim();
      category = null;
      load();
    });
  }

  void setCategory(String? value) {
    if (category == value && search.isEmpty) return;
    _debounce?.cancel();
    category = value;
    search = '';
    load();
  }

  void setSort(ProductSort value) {
    if (sort == value) return;
    sort = value;
    load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
