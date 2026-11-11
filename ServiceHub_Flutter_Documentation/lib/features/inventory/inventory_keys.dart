import 'package:flutter/widgets.dart';

class InventoryKeys {
  const InventoryKeys._();

  static const openMyInventory = Key('open_my_inventory');
  static const createInventoryButton = Key('create_inventory_button');
  static const inventorySearchInput = Key('inventory_search_input');
  static const inventoryRetryButton = Key('inventory_retry_button');

  static const formName = Key('inventory_form_name');
  static const formDescription = Key('inventory_form_description');
  static const formQuantity = Key('inventory_form_quantity');
  static const formUnit = Key('inventory_form_unit');
  static const formLowStockThreshold = Key('inventory_form_low_stock_threshold');
  static const formSaveButton = Key('inventory_form_save_button');

  static const deleteInventoryButton = Key('delete_inventory_button');
  static const confirmDeleteButton = Key('confirm_delete_button');
  static const cancelDeleteButton = Key('cancel_delete_button');

  static Key inventoryCard(String id) => Key('inventory_card_$id');
  static Key editInventoryButton(String id) => Key('edit_inventory_button_$id');
  static Key updateQuantityButton(String id) => Key('update_quantity_button_$id');
  static Key deleteInventoryAction(String id) => Key('delete_inventory_action_$id');
}
