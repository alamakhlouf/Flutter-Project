import 'package:flutter/material.dart';

import '../../../app/app_routes.dart';
import '../../../core/services/fcm_service.dart';
import '../../../design_system/app_colors.dart';
import '../../workshops/screens/workshop_details_screen.dart';
import '../auth_scope.dart';
import '../../auth/models/auth_user.dart';
import '../../inventory/models/inventory_product_model.dart';
import '../../inventory/models/inventory_item_model.dart';
import '../../inventory/screens/inventory_form_screen.dart';
import '../../inventory/screens/inventory_catalog_screen.dart';
import '../../inventory/screens/inventory_details_screen.dart';
import '../../inventory/screens/inventory_list_screen.dart';
import '../../inventory/screens/supplier_inventory_screen.dart';
import '../../inventory/screens/favorite_products_screen.dart';
import '../../services/screens/favorite_services_screen.dart';
import '../../inventory/models/product_order_model.dart';
import '../../inventory/screens/product_orders_screen.dart';
import '../../inventory/services/product_order_service.dart';
import '../../notifications/screens/notifications_screen.dart';
import '../../bookings/models/booking_model.dart';
import '../../profile/screens/edit_profile_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../profile/screens/my_activity_screen.dart';
import '../../profile/services/profile_service.dart';
import '../../reports/models/report_target.dart';
import '../../reports/screens/admin_reports_screen.dart';
import '../../reports/screens/my_reports_screen.dart';
import '../../reports/screens/report_form_screen.dart';
import '../../reviews/screens/review_form_screen.dart';
import '../../services/models/service_model.dart';
import '../../services/screens/my_services_screen.dart';
import '../../services/screens/service_details_screen.dart';
import '../../services/screens/service_form_screen.dart';
import '../../services/screens/services_catalog_screen.dart';
import '../../bookings/screens/booking_details_screen.dart';
import '../../bookings/screens/booking_list_screen.dart';
import '../../bookings/screens/create_booking_screen.dart';
import '../../bookings/screens/provider_calendar_screen.dart';
import '../../bookings/screens/availability_management_screen.dart';
import '../../workshops/models/workshop_model.dart';
import '../../workshops/screens/workshop_catalog_screen.dart';
import '../../workshops/screens/workshop_form_screen.dart';
import '../../workshops/screens/workshop_management_screen.dart';
import '../../workshops/services/workshop_service.dart';

class SessionHomeScreen extends StatelessWidget {
  const SessionHomeScreen({super.key});

  Route<void> _homeRoute() {
    return MaterialPageRoute<void>(
      settings: const RouteSettings(name: AppRoutes.home),
      builder: (_) => const _AccountHome(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: FcmService.sessionNavigatorKey,
      initialRoute: AppRoutes.home,
      onGenerateInitialRoutes: (navigator, initialRoute) => [_homeRoute()],
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case AppRoutes.profile:
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => const ProfileScreen(),
            );
          case AppRoutes.myActivity:
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => const MyActivityScreen(),
            );
          case AppRoutes.notifications:
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => const NotificationsScreen(),
            );
          case AppRoutes.adminReports:
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => const AdminReportsScreen(),
            );
          case AppRoutes.productOrders:
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => const ProductOrdersScreen(),
            );
          case AppRoutes.productOrderDetails:
            final order = settings.arguments;
            if (order is ProductOrderModel) {
              return MaterialPageRoute<void>(
                settings: settings,
                builder: (_) => ProductOrderDetailsScreen(
                  order: order,
                  isSupplier:
                      AuthScope.of(context).user.role == UserRole.supplier,
                  orderService: ProductOrderService(
                    api: AuthScope.of(context).api,
                  ),
                ),
              );
            }
            if (order is String && order.isNotEmpty) {
              return MaterialPageRoute<void>(
                settings: settings,
                builder: (_) => _ProductOrderDetailsById(orderId: order),
              );
            }
            return _homeRoute();
          case AppRoutes.editProfile:
            final args = settings.arguments;
            if (args is Map<String, dynamic> &&
                args['user'] is AuthUser &&
                args['profileService'] is ProfileService) {
              return MaterialPageRoute<void>(
                settings: settings,
                builder: (_) => EditProfileScreen(
                  user: args['user'] as AuthUser,
                  profileService: args['profileService'] as ProfileService,
                ),
              );
            }
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => const ProfileScreen(),
            );
          case AppRoutes.myReports:
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => const MyReportsScreen(),
            );
          case AppRoutes.createReport:
            if (AuthScope.of(context).user.role == UserRole.admin) {
              return _homeRoute();
            }
            final target = settings.arguments is ReportTarget
                ? settings.arguments as ReportTarget
                : null;
            if (target == null) return _homeRoute();
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => ReportFormScreen(target: target),
            );
          case AppRoutes.createReview:
            final booking = settings.arguments;
            if (booking is! BookingModel ||
                AuthScope.of(context).user.role != UserRole.customer ||
                AuthScope.of(context).user.id != booking.customerId ||
                booking.status != BookingStatus.completed) {
              return _homeRoute();
            }
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => ReviewFormScreen(booking: booking),
            );
          case AppRoutes.servicesCatalog:
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => const ServicesCatalogScreen(),
            );
          case AppRoutes.serviceDetails:
            final service = settings.arguments is ServiceModel
                ? settings.arguments as ServiceModel
                : null;
            final serviceId = settings.arguments is String
                ? settings.arguments as String
                : null;
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) =>
                  ServiceDetailsScreen(service: service, serviceId: serviceId),
            );
          case AppRoutes.myServices:
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => const MyServicesScreen(),
            );
          case AppRoutes.createService:
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => const ServiceFormScreen(),
            );
          case AppRoutes.editService:
            final service = settings.arguments is ServiceModel
                ? settings.arguments as ServiceModel
                : null;
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => ServiceFormScreen(service: service),
            );
          case AppRoutes.inventoryList:
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (context) => switch (AuthScope.of(context).user.role) {
                UserRole.provider => const InventoryListScreen(),
                UserRole.supplier => const SupplierInventoryScreen(),
                _ => const InventoryCatalogScreen(),
              },
            );
          case AppRoutes.inventoryCatalog:
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => const InventoryCatalogScreen(),
            );
          case AppRoutes.favoriteProducts:
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => const FavoriteProductsScreen(),
            );
          case AppRoutes.favoriteServices:
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => const FavoriteServicesScreen(),
            );
          case AppRoutes.inventoryDetails:
            final product = settings.arguments is InventoryProduct
                ? settings.arguments as InventoryProduct
                : null;
            final productId = settings.arguments is String
                ? settings.arguments as String
                : null;
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => InventoryDetailsScreen(
                product: product,
                productId: productId,
              ),
            );
          case AppRoutes.createInventory:
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => const InventoryFormScreen(),
            );
          case AppRoutes.editInventory:
            final item = settings.arguments is InventoryItemModel
                ? settings.arguments as InventoryItemModel
                : null;
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => InventoryFormScreen(item: item),
            );
          case AppRoutes.bookingsList:
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => const BookingListScreen(),
            );
          case AppRoutes.createBooking:
            final service = settings.arguments is ServiceModel
                ? settings.arguments as ServiceModel
                : null;
            if (service == null) {
              return MaterialPageRoute<void>(
                settings: settings,
                builder: (_) => const ServicesCatalogScreen(),
              );
            }
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => CreateBookingScreen(service: service),
            );
          case AppRoutes.bookingDetails:
            final bookingId = settings.arguments is String
                ? settings.arguments as String
                : '';
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => BookingDetailsScreen(bookingId: bookingId),
            );
          case AppRoutes.providerCalendar:
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => const ProviderCalendarScreen(),
            );
          case AppRoutes.availabilityManagement:
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => const AvailabilityManagementScreen(),
            );
          case AppRoutes.workshops:
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => const WorkshopCatalogScreen(),
            );
          case AppRoutes.workshopDetails:
            final workshop = settings.arguments is WorkshopModel
                ? settings.arguments as WorkshopModel
                : null;
            if (workshop != null) {
              return MaterialPageRoute<void>(
                settings: settings,
                builder: (_) => WorkshopDetailsScreen(workshop: workshop),
              );
            }
            final workshopId = settings.arguments;
            if (workshopId is String && workshopId.isNotEmpty) {
              return MaterialPageRoute<void>(
                settings: settings,
                builder: (_) => _WorkshopDetailsById(workshopId: workshopId),
              );
            }
            return _homeRoute();
          case AppRoutes.createWorkshop:
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => const WorkshopFormScreen(),
            );
          case AppRoutes.editWorkshop:
            final workshop = settings.arguments is WorkshopModel
                ? settings.arguments as WorkshopModel
                : null;
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => WorkshopFormScreen(workshop: workshop),
            );
          case AppRoutes.myWorkshops:
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => const WorkshopManagementScreen(),
            );
          case AppRoutes.myWorkshopRegistrations:
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) =>
                  const WorkshopManagementScreen(registrations: true),
            );
          default:
            return _homeRoute();
        }
      },
    );
  }
}

class _AccountHome extends StatefulWidget {
  const _AccountHome();

  @override
  State<_AccountHome> createState() => _AccountHomeState();
}

class _AccountHomeState extends State<_AccountHome> {
  int _selectedIndex = 0;
  final List<Widget?> _pages = [
    const ServicesCatalogScreen(),
    null,
    null,
    null,
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FcmService.flushPendingNavigation();
    });
  }

  void _selectPage(int index) {
    setState(() {
      _selectedIndex = index;
      _pages[index] ??= switch (index) {
        1 => const InventoryCatalogScreen(),
        2 => const WorkshopCatalogScreen(),
        3 => const ProfileScreen(),
        _ => const ServicesCatalogScreen(),
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey(AppRoutes.home),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          for (var index = 0; index < _pages.length; index++)
            _pages[index] ?? const SizedBox.shrink(),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          key: const ValueKey('bottom_navigation_bar'),
          height: 68,
          decoration: const BoxDecoration(
            color: AppColors.navigationSurface,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              _buildNavigationDestination(
                index: 0,
                key: const ValueKey('bottom_nav_services'),
                icon: Icons.home_repair_service_outlined,
                selectedIcon: Icons.home_repair_service,
                label: 'Services',
              ),
              _buildNavigationDestination(
                index: 1,
                key: const ValueKey('bottom_nav_supplier'),
                icon: Icons.inventory_2_outlined,
                selectedIcon: Icons.inventory_2,
                label: 'Supplier',
              ),
              _buildNavigationDestination(
                index: 2,
                key: const ValueKey('bottom_nav_workshops'),
                icon: Icons.school_outlined,
                selectedIcon: Icons.school,
                label: 'Workshops',
              ),
              _buildNavigationDestination(
                index: 3,
                key: const ValueKey('bottom_nav_profile'),
                icon: Icons.person_outline,
                selectedIcon: Icons.person,
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationDestination({
    required int index,
    required Key key,
    required IconData icon,
    required IconData selectedIcon,
    required String label,
  }) {
    final isSelected = _selectedIndex == index;
    final foregroundColor = isSelected
        ? AppColors.primary
        : AppColors.textSecondary;

    return Expanded(
      child: Semantics(
        selected: isSelected,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _selectPage(index),
          child: Container(
            key: key,
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isSelected ? selectedIcon : icon,
                  size: 22,
                  color: foregroundColor,
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: foregroundColor,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductOrderDetailsById extends StatefulWidget {
  const _ProductOrderDetailsById({required this.orderId});

  final String orderId;

  @override
  State<_ProductOrderDetailsById> createState() =>
      _ProductOrderDetailsByIdState();
}

class _ProductOrderDetailsByIdState extends State<_ProductOrderDetailsById> {
  ProductOrderModel? _order;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_order != null || _error != null) return;
    _load();
  }

  Future<void> _load() async {
    try {
      final order = await ProductOrderService(api: AuthScope.of(context).api)
          .fetchOrder(widget.orderId);
      if (mounted) setState(() => _order = order);
    } on Object {
      if (mounted) {
        setState(() => _error = 'Unable to load this product order.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Order details')),
        body: Center(child: Text(_error!)),
      );
    }
    final order = _order;
    if (order == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return ProductOrderDetailsScreen(
      order: order,
      isSupplier: AuthScope.of(context).user.role == UserRole.supplier,
      orderService: ProductOrderService(api: AuthScope.of(context).api),
    );
  }
}

class _WorkshopDetailsById extends StatefulWidget {
  const _WorkshopDetailsById({required this.workshopId});

  final String workshopId;

  @override
  State<_WorkshopDetailsById> createState() => _WorkshopDetailsByIdState();
}

class _WorkshopDetailsByIdState extends State<_WorkshopDetailsById> {
  WorkshopModel? _workshop;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_workshop != null || _error != null) return;
    _load();
  }

  Future<void> _load() async {
    try {
      final workshop = await WorkshopService(api: AuthScope.of(context).api)
          .getWorkshop(widget.workshopId);
      if (mounted) setState(() => _workshop = workshop);
    } on Object {
      if (mounted) {
        setState(() => _error = 'Unable to load this workshop.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Workshop details')),
        body: Center(child: Text(_error!)),
      );
    }
    final workshop = _workshop;
    if (workshop == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return WorkshopDetailsScreen(workshop: workshop);
  }
}
