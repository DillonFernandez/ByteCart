class ShopFilter {
  String sort;
  String category;
  String brand;
  String color;
  double? minPrice;
  double? maxPrice;
  bool inStock;

  ShopFilter({
    this.sort = '',
    this.category = '',
    this.brand = '',
    this.color = '',
    this.minPrice,
    this.maxPrice,
    this.inStock = false,
  });
}
