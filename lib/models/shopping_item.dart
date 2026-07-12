class ShoppingItem {
  final String itemId;
  final String originalText;
  final String standardizedName;
  final String category;
  final String quantity;
  final bool isCompleted;
  final DateTime addedAt;

  ShoppingItem({
    required this.itemId,
    required this.originalText,
    required this.standardizedName,
    required this.category,
    required this.quantity,
    required this.isCompleted,
    required this.addedAt,
  });

  // Factory to convert incoming backend JSON directly into clear Dart objects
  factory ShoppingItem.fromJson(Map<String, dynamic> json) {
    return ShoppingItem(
      itemId: json['itemId'] ?? '',
      originalText: json['originalText'] ?? '',
      standardizedName: json['standardizedName'] ?? '',
      category: json['category'] ?? 'Uncategorized',
      quantity: json['quantity'] ?? '1',
      isCompleted: json['isCompleted'] ?? false,
      addedAt: DateTime.parse(
        json['addedAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}
