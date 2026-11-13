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
    final title = AuthScope.of(context).user.role == UserRole.provider
        ? 'Incoming service requests'
        : 'My service bookings';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadBookings),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  ChoiceChip(
                    key: BookingsKeys.statusFilter,
                    label: const Text('All'),
                    selected: _filterStatus == null,
                    onSelected: (selected) {
                      if (selected) setState(() => _filterStatus = null);
                    },
                  ),
                  const SizedBox(width: 8),
                  for (final st in BookingStatus.values) ...[
                    ChoiceChip(
                      label: Text(st.label),
                      selected: _filterStatus == st,
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
            const Divider(height: 1),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _errorMessage!,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: AppColors.error,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            OutlinedButton(
                              onPressed: _loadBookings,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : filtered.isEmpty
                  ? Center(
                      child: Text(
                        'No bookings found.',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadBookings,
                      child: ListView.builder(
                        key: BookingsKeys.bookingList,
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final booking = filtered[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: AppColors.border),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              title: Text(
                                booking.serviceTitle,
                                style: theme.textTheme.titleMedium,
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 6),
                                  Text(
                                    'Preferred: ${booking.preferredDateTime.toLocal().toString().split('.').first}',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: booking.status.color
                                              .withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Text(
                                          booking.status.label,
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(
                                                color: booking.status.color,
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        '\$${booking.price.toStringAsFixed(2)}',
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
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
