import '../../core/network/api_client.dart';
import '../../models/shop_item.dart';
import '../api_mappers.dart';
import '_repo_support.dart';

class ShopRepository {
  ShopRepository(this._api);

  final ApiClient _api;

  Future<List<ShopItem>> listItems() async {
    final data = await _api.get('/shop/items');
    return asRows(data).map(ApiMappers.shopItem).toList();
  }

  Future<List<ShopItem>> listPurchasedItems() async {
    final data = await _api.get('/shop/purchases/mine');
    return asRows(data)
        .map((row) {
          final item = row['shop_items'];
          if (item is Map<String, dynamic>) return ApiMappers.shopItem(item);
          final itemId = row['shop_item_id']?.toString();
          if (itemId != null) {
            return ShopItem(
              id: itemId,
              title: itemId,
              description: '',
              cost: (row['points_spent'] as num?)?.toInt() ?? 0,
              category: ShopCategory.customizables,
              icon: ApiMappers.shopIcon(null),
            );
          }
          return null;
        })
        .whereType<ShopItem>()
        .toList();
  }

  Future<int?> purchase(String itemId) async {
    final result = await _api.post('/shop/purchase', body: {'item_id': itemId});
    final row = asRow(result);
    if (row == null) return null;
    return (row['points'] as num?)?.toInt();
  }
}
