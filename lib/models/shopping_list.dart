import 'shopping_item.dart';

class ShoppingList {
  final String id;
  final String userId;
  final String listName;
  final String selectedSupermarket;
  final bool isArchived;
  final List<ShoppingItem> items;
  final DateTime createdAt;

  ShoppingList({
    required this.id,
    required this.userId,
    required this.listName,
    required this.selectedSupermarket,
    required this.isArchived,
    required this.items,
    required this.createdAt,
  });

  factory ShoppingList.fromJson(Map<String, dynamic> json) {
    var listItems = json['items'] as List? ?? [];
    List<ShoppingItem> parsedItems = listItems
        .map((i) => ShoppingItem.fromJson(i))
        .toList();

    return ShoppingList(
      id: json['_id'] ?? '',
      userId: json['userId'] ?? '',
      listName: json['listName'] ?? 'Trolley Run',
      selectedSupermarket: json['selectedSupermarket'] ?? 'GENERAL',
      isArchived: json['isArchived'] ?? false,
      items: parsedItems,
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}
