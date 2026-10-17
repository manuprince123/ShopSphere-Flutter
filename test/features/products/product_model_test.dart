import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shopsphere/features/products/data/product_model.dart';

void main() {
  final fixture = jsonDecode(File('test/fixtures/product.json').readAsStringSync()) as Map<String, dynamic>;

  test('parses nullable brand and all review fields', () {
    final product = ProductModel.fromJson(fixture);
    expect(product.brand, isNull);
    expect(product.reviews.single.reviewerName, 'Ava');
    expect(product.reviews.single.date, DateTime.utc(2026, 10, 16, 10));
  });
  test('calculates discounted price without rounding prematurely', () {
    final product = ProductModel.fromJson(fixture);
    expect(product.salePrice, 60);
  });
  test('serializes and parses a product consistently', () {
    final first = ProductModel.fromJson(fixture);
    final second = ProductModel.fromJson(first.toJson());
    expect(second.title, first.title);
    expect(second.images, first.images);
    expect(second.reviews.single.comment, 'Excellent');
  });
  test('copies a domain product into a serializable snapshot', () {
    final original = ProductModel.fromJson(fixture);
    final snapshot = ProductModel.fromProduct(original);
    expect(snapshot.toJson()['reviews'], hasLength(1));
    expect(snapshot.salePrice, original.salePrice);
  });
  test('accepts a light list payload with absent optional fields', () {
    final product = ProductModel.fromJson({'id': 3, 'title': 'Cup', 'price': 12});
    expect(product.stock, 0);
    expect(product.images, isEmpty);
    expect(product.reviews, isEmpty);
  });
}
