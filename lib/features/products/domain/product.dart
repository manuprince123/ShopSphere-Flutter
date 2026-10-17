class Review {
  const Review({required this.rating, required this.comment, required this.reviewerName, required this.date});
  final int rating;
  final String comment;
  final String reviewerName;
  final DateTime? date;
}

class Product {
  const Product({required this.id, required this.title, required this.description,
    required this.price, required this.discountPercentage, required this.rating,
    required this.stock, required this.thumbnail, required this.images,
    required this.reviews, this.brand});
  final int id;
  final String title;
  final String description;
  final double price;
  final double discountPercentage;
  final double rating;
  final int stock;
  final String thumbnail;
  final List<String> images;
  final List<Review> reviews;
  final String? brand;

  double get salePrice => price * (1 - discountPercentage / 100);
}

class Category {
  const Category(this.slug, this.name);
  final String slug;
  final String name;
}

class ProductPage {
  const ProductPage(this.products, this.total);
  final List<Product> products;
  final int total;
}

enum ProductSort { featured, priceLow, priceHigh, rating, title }

class ProductQuery {
  const ProductQuery({this.search = '', this.category, this.sort = ProductSort.featured,
    this.skip = 0, this.limit = 20});
  final String search;
  final String? category;
  final ProductSort sort;
  final int skip;
  final int limit;
}
