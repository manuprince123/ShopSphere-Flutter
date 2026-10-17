import '../domain/product.dart';

class ProductModel extends Product {
  ProductModel.fromJson(Map<String, dynamic> json)
      : super(
          id: json['id'] as int,
          title: json['title'] as String? ?? '',
          description: json['description'] as String? ?? '',
          price: (json['price'] as num?)?.toDouble() ?? 0,
          discountPercentage: (json['discountPercentage'] as num?)?.toDouble() ?? 0,
          rating: (json['rating'] as num?)?.toDouble() ?? 0,
          stock: json['stock'] as int? ?? 0,
          thumbnail: json['thumbnail'] as String? ?? '',
          images: (json['images'] as List<dynamic>? ?? const []).whereType<String>().toList(),
          reviews: (json['reviews'] as List<dynamic>? ?? const [])
              .whereType<Map<String, dynamic>>()
              .map((item) => Review(
                    rating: item['rating'] as int? ?? 0,
                    comment: item['comment'] as String? ?? '',
                    reviewerName: item['reviewerName'] as String? ?? 'Customer',
                    date: DateTime.tryParse(item['date'] as String? ?? ''),
                  ))
              .toList(),
          brand: json['brand'] as String?,
        );

  Map<String, dynamic> toJson() => {
    'id': id, 'title': title, 'description': description, 'price': price,
    'discountPercentage': discountPercentage, 'rating': rating, 'stock': stock,
    'thumbnail': thumbnail, 'images': images, 'brand': brand,
    'reviews': reviews.map((r) => {
      'rating': r.rating, 'comment': r.comment, 'reviewerName': r.reviewerName,
      if (r.date != null) 'date': r.date!.toIso8601String(),
    }).toList(),
  };
}
