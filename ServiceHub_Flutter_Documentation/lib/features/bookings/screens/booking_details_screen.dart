import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../../../design_system/app_colors.dart';
import '../../auth/auth_scope.dart';
import '../../auth/models/auth_user.dart';
import '../bookings_keys.dart';
import '../models/booking_model.dart';
import '../services/booking_service.dart';

class BookingDetailsScreen extends StatefulWidget {
  const BookingDetailsScreen({super.key, required this.bookingId});

  final String bookingId;

  @override
  State<BookingDetailsScreen> createState() => _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends State<BookingDetailsScreen> {
  late final BookingService _bookingService;
  bool _isLoading = true;
  String? _errorMessage;
  BookingModel? _booking;
  bool _bookingServiceInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bookingServiceInitialized) return;

    _bookingServiceInitialized = true;
    _bookingService = BookingService(api: AuthScope.of(context).api);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadBooking();
    });
  }

  Future<void> _loadBooking() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final booking = await _bookingService.getBookingById(widget.bookingId);
      if (!mounted) return;
      setState(() {
        _booking = booking;
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
        _errorMessage = 'Failed to load booking details: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _updateStatus(BookingStatus newStatus) async {
    try {
      final updated = await _bookingService.updateBookingStatus(
        id: widget.bookingId,
        status: newStatus,
      );
      if (!mounted) return;
      setState(() {
        _booking = updated;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Booking status updated to ${newStatus.label}')),
      );
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _cancelBooking() async {
    try {
      final updated = await _bookingService.cancelBooking(widget.bookingId);
      if (!mounted) return;
      setState(() {
        _booking = updated;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Booking cancelled')));
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = AuthScope.of(context).user;
    final booking = _booking;

    return Scaffold(
      appBar: AppBar(title: const Text('Booking Details')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _errorMessage!,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppColors.error,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : booking == null
          ? const Center(child: Text('Booking not found'))
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          booking.serviceTitle,
                          style: theme.textTheme.headlineMedium,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: booking.status.color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          booking.status.label,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: booking.status.color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _infoRow(
                    theme,
                    'Preferred Date & Time',
                    booking.preferredDateTime
                        .toLocal()
                        .toString()
                        .split('.')
                        .first,
                  ),
                  const SizedBox(height: 12),
                  _infoRow(
                    theme,
                    'Agreed Price',
                    '\$${booking.price.toStringAsFixed(2)}',
                  ),
                  const SizedBox(height: 12),
                  _infoRow(
                    theme,
                    'Description / Requirements',
                    booking.description.isEmpty
                        ? 'No description provided'
                        : booking.description,
                  ),
                  if (booking.customerName != null) ...[
                    const SizedBox(height: 12),
                    _infoRow(theme, 'Customer Name', booking.customerName!),
                  ],
                  const SizedBox(height: 32),
                  if (user.role == UserRole.provider) ...[
                    if (booking.status == BookingStatus.pending) ...[
                      FilledButton.icon(
                        key: BookingsKeys.acceptButton,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.success,
                        ),
                        icon: const Icon(Icons.check),
                        label: const Text('Accept Booking'),
                        onPressed: () => _updateStatus(BookingStatus.accepted),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        key: BookingsKeys.rejectButton,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                        ),
                        icon: const Icon(Icons.close),
                        label: const Text('Reject Booking'),
                        onPressed: () => _updateStatus(BookingStatus.rejected),
                      ),
                    ],
                    if (booking.status == BookingStatus.accepted) ...[
                      FilledButton.icon(
                        key: BookingsKeys.startProgressButton,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                        ),
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Mark In Progress'),
                        onPressed: () =>
                            _updateStatus(BookingStatus.inProgress),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        key: BookingsKeys.cancelButton,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                        ),
                        icon: const Icon(Icons.cancel_outlined),
                        label: const Text('Cancel Booking'),
                        onPressed: _cancelBooking,
                      ),
                    ],
                    if (booking.status == BookingStatus.inProgress) ...[
                      FilledButton.icon(
                        key: BookingsKeys.completeButton,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.success,
                        ),
                        icon: const Icon(Icons.done_all),
                        label: const Text('Mark Completed'),
                        onPressed: () => _updateStatus(BookingStatus.completed),
                      ),
                    ],
                  ],
                  if (user.role == UserRole.customer) ...[
                    if (booking.status == BookingStatus.pending ||
                        booking.status == BookingStatus.accepted) ...[
                      OutlinedButton.icon(
                        key: BookingsKeys.cancelButton,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                        ),
                        icon: const Icon(Icons.cancel_outlined),
                        label: const Text('Cancel Booking'),
                        onPressed: _cancelBooking,
                      ),
                    ],
                  ],
                ],
              ),
            ),
    );
  }

  Widget _infoRow(ThemeData theme, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(value, style: theme.textTheme.bodyLarge),
      ],
    );
  }
}
