import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../../../design_system/app_colors.dart';
import '../../auth/auth_scope.dart';
import '../../auth/models/auth_user.dart';
import '../bookings_keys.dart';
import '../models/booking_model.dart';
import '../services/booking_service.dart';
import 'booking_details_screen.dart';

class BookingListScreen extends StatefulWidget {
  const BookingListScreen({super.key});

  @override
  State<BookingListScreen> createState() => _BookingListScreenState();
}

class _BookingListScreenState extends State<BookingListScreen> {
  late final BookingService _bookingService;
  bool _isLoading = true;
  String? _errorMessage;
  List<BookingModel> _bookings = [];
  BookingStatus? _filterStatus;
  bool _bookingServiceInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bookingServiceInitialized) return;

    _bookingServiceInitialized = true;
    _bookingService = BookingService(api: AuthScope.of(context).api);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadBookings();
    });
  }

  Future<void> _loadBookings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await _bookingService.fetchMyBookings();
      if (!mounted) return;
      setState(() {
        _bookings = list;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load bookings: $e';
        _isLoading = false;
      });
    }
  }

  List<BookingModel> get _filteredBookings {
    if (_filterStatus == null) return _bookings;
    return _bookings.where((b) => b.status == _filterStatus).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _filteredBookings;
    final isProvider = AuthScope.of(context).user.role == UserRole.provider;
    final title = isProvider
        ? 'Incoming Service Requests'
        : 'My Service Bookings';

    return Scaffold(
      backgroundColor: AppColors.neutral,
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadBookings,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Filter Chips Bar
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  ChoiceChip(
                    key: BookingsKeys.statusFilter,
                    label: const Text('All'),
                    selected: _filterStatus == null,
                    selectedColor: AppColors.primary.withOpacity(0.15),
                    labelStyle: TextStyle(
                      color: _filterStatus == null
                          ? AppColors.primary
                          : AppColors.textSecondary,
                      fontWeight: _filterStatus == null
                          ? FontWeight.bold
                          : FontWeight.w500,
                    ),
                    onSelected: (selected) {
                      if (selected) setState(() => _filterStatus = null);
                    },
                  ),
                  const SizedBox(width: 8),
                  for (final st in BookingStatus.values) ...[
                    ChoiceChip(
                      label: Text(st.label),
                      selected: _filterStatus == st,
                      selectedColor: st.color.withOpacity(0.15),
                      labelStyle: TextStyle(
                        color: _filterStatus == st
                            ? st.color
                            : AppColors.textSecondary,
                        fontWeight: _filterStatus == st
                            ? FontWeight.bold
                            : FontWeight.w500,
                      ),
                      onSelected: (selected) {
                        setState(() {
                          _filterStatus = selected ? st : null;
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    )
                  : _errorMessage != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.error_outline_rounded,
                                  size: 48,
                                  color: AppColors.error,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _errorMessage!,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: AppColors.error,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                OutlinedButton.icon(
                                  onPressed: _loadBookings,
                                  icon: const Icon(Icons.refresh_rounded),
                                  label: const Text('Try Again'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : filtered.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 72,
                                      height: 72,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withOpacity(0.08),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.calendar_month_outlined,
                                        size: 36,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No Bookings Found',
                                      style: theme.textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'There are no service bookings under this filter.',
                                      textAlign: TextAlign.center,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : RefreshIndicator(
                              color: AppColors.primary,
                              onRefresh: _loadBookings,
                              child: ListView.builder(
                                key: BookingsKeys.bookingList,
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                                itemCount: filtered.length,
                                itemBuilder: (context, index) {
                                  final booking = filtered[index];
                                  final dt = booking.preferredDateTime.toLocal();
                                  final formattedDate =
                                      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} at ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 14),
                                    decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: AppColors.border),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.primary.withOpacity(0.04),
                                          blurRadius: 16,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      borderRadius: BorderRadius.circular(20),
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(20),
                                        onTap: () async {
                                          final updated = await Navigator.of(context)
                                              .push<bool>(
                                            MaterialPageRoute(
                                              builder: (_) => BookingDetailsScreen(
                                                bookingId: booking.id,
                                              ),
                                            ),
                                          );
                                          if (updated == true) {
                                            _loadBookings();
                                          }
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.all(18),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.all(8),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.primary.withOpacity(0.08),
                                                      borderRadius: BorderRadius.circular(10),
                                                    ),
                                                    child: const Icon(
                                                      Icons.home_repair_service_rounded,
                                                      size: 20,
                                                      color: AppColors.primary,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Text(
                                                      booking.serviceTitle,
                                                      style: theme.textTheme.titleMedium?.copyWith(
                                                        fontWeight: FontWeight.bold,
                                                        color: AppColors.primary,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 5,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: booking.status.color.withOpacity(0.08),
                                                      borderRadius: BorderRadius.circular(20),
                                                      border: Border.all(
                                                        color: booking.status.color.withOpacity(0.3),
                                                      ),
                                                    ),
                                                    child: Text(
                                                      booking.status.label,
                                                      style: theme.textTheme.labelSmall?.copyWith(
                                                        color: booking.status.color,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 12),
                                              Row(
                                                children: [
                                                  const Icon(
                                                    Icons.event_outlined,
                                                    size: 16,
                                                    color: AppColors.textSecondary,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Text(
                                                      'Preferred: $formattedDate',
                                                      style: theme.textTheme.bodySmall?.copyWith(
                                                        color: AppColors.textSecondary,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              if (booking.customerName != null && isProvider) ...[
                                                const SizedBox(height: 6),
                                                Row(
                                                  children: [
                                                    const Icon(
                                                      Icons.person_outline_rounded,
                                                      size: 16,
                                                      color: AppColors.textSecondary,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Text(
                                                        'Customer: ${booking.customerName}',
                                                        style: theme.textTheme.bodySmall?.copyWith(
                                                          color: AppColors.textSecondary,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                              const SizedBox(height: 14),
                                              const Divider(height: 1, color: AppColors.border),
                                              const SizedBox(height: 12),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(
                                                    '\$${booking.price.toStringAsFixed(2)}',
                                                    style: theme.textTheme.titleMedium?.copyWith(
                                                      color: AppColors.primary,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                  Row(
                                                    children: [
                                                      Text(
                                                        'View details',
                                                        style: theme.textTheme.labelMedium?.copyWith(
                                                          color: AppColors.primary,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 4),
                                                      const Icon(
                                                        Icons.arrow_forward_rounded,
                                                        size: 16,
                                                        color: AppColors.primary,
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
