import 'package:flutter/widgets.dart';

class ServicesKeys {
  const ServicesKeys._();

  static const catalogSearchInput = Key('catalog_search_input');
  static const catalogFilterButton = Key('catalog_filter_button');
  static const catalogRetryButton = Key('catalog_retry_button');
  static const openCatalog = Key('open_catalog');

  static const openMyServices = Key('open_my_services');
  static const createServiceButton = Key('create_service_button');
  static const myServicesRetryButton = Key('my_services_retry_button');

  static const formTitle = Key('service_form_title');
  static const formDescription = Key('service_form_description');
  static const formCategory = Key('service_form_category');
  static const formPrice = Key('service_form_price');
  static const formPriceDescription = Key('service_form_price_description');
  static const formLocation = Key('service_form_location');
  static const formImageUrl = Key('service_form_image_url');
  static const formIsActive = Key('service_form_is_active');
  static const formSaveButton = Key('service_form_save_button');

  static const deleteServiceButton = Key('delete_service_button');
  static const confirmDeleteButton = Key('confirm_delete_button');
  static const cancelDeleteButton = Key('cancel_delete_button');

  static const filterCategoryDropdown = Key('filter_category_dropdown');
  static const filterMaxPriceInput = Key('filter_max_price_input');
  static const filterLocationInput = Key('filter_location_input');
  static const filterApplyButton = Key('filter_apply_button');
  static const filterResetButton = Key('filter_reset_button');

  static const detailsBookButton = Key('details_book_button');
  static const detailsRetryButton = Key('details_retry_button');

  static Key categoryChip(String category) => Key('category_chip_$category');
  static Key serviceCard(String id) => Key('service_card_$id');
  static Key editServiceButton(String id) => Key('edit_service_button_$id');
  static Key deleteServiceAction(String id) => Key('delete_service_action_$id');
  static Key toggleActiveSwitch(String id) => Key('toggle_active_switch_$id');
}
