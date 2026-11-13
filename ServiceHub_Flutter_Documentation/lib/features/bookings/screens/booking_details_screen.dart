import 'package:flutter/material.dart';

import '../../../app/app_routes.dart';
import '../../../core/network/api_exception.dart';
import '../../../design_system/app_colors.dart';
import '../../auth/auth_scope.dart';
import '../../auth/models/auth_user.dart';
import '../../reviews/services/review_service.dart';
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
  late ReviewService _reviewService;
  bool _checkingReview = false;
  bool _reviewed = false;
  String? _reviewCheckError;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bookingServiceInitialized) return;

    _bookingServiceInitialized = true;
    _bookingService = BookingService(api: AuthScope.of(context).api);
    _reviewService = ReviewService(api: AuthScope.of(context).api);
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
      if (booking.status == BookingStatus.completed &&
          AuthScope.of(context).user.role == UserRole.customer &&
          AuthScope.of(context).user.id == booking.customerId) {
        await _checkReview(booking);
      }
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

  Future<void> _checkReview(BookingModel booking) async {
    setState(() {
      _checkingReview = true;
      _reviewCheckError = null;
    });
    try {
      final reviews = await _reviewService.forService(booking.serviceId);
      if (!mounted) return;
      setState(() {
        _reviewed = reviews.any((review) => review.bookingId == booking.id);
        _checkingReview = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _reviewCheckError = error.message;
        _checkingReview = false;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _reviewCheckError =
            'Unable to check whether this booking was reviewed.';
        _checkingReview = false;
      });
    }
  }

  Future<void> _writeReview(BookingModel booking) async {
    final submitted = await Navigator.of(context)
        .pushNamed(AppRoutes.createReview, arguments: booking);
    if (!mounted) return;
    if (submitted == true) {
      setState(() {
        _reviewed = true;
        _reviewCheckError = null;
      });
    } else {
      await _checkReview(booking);
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
        SnackBar(
          content: Text('Booking status updated to ${newStatus.label}'),
          backgroundColor: AppColors.success,
        ),
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cancel Booking?'),
        content: const Text(
          'Are you sure you want to cancel this booking request?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep Booking'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancel Booking'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final updated = await _bookingService.cancelBooking(widget.bookingId);
      if (!mounted) return;
      setState(() {
        _booking = updated;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking cancelled successfully')),
      );
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
      backgroundColor: AppColors.neutral,
      appBar: AppBar(
        title: const Text(
          'Booking Details',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: _isLoading
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
                      ],
                    ),
                  ),
                )
              : booking == null
                  ? const Center(child: Text('Booking not found'))
                  : SafeArea(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                        children: [
                          // Header Card
                          Container(
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
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.home_repair_service_rounded,
                                        size: 24,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Text(
                                        booking.serviceTitle,
                                        style: theme.textTheme.headlineSmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '\$${booking.price.toStringAsFixed(2)}',
                                      style: theme.textTheme.headlineMedium?.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
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
                                        style: theme.textTheme.labelMedium?.copyWith(
                                          color: booking.status.color,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Details Info Card
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.border),
                            ),
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _detailRow(
                                  theme,
                                  icon: Icons.event_available_rounded,
                                  label: 'Preferred Date & Time',
                                  value: _formatDate(booking.preferredDateTime),
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 10),
                                  child: Divider(height: 1, color: AppColors.border),
                                ),
                                if (booking.customerName != null) ...[
                                  _detailRow(
                                    theme,
                                    icon: Icons.person_outline_rounded,
                                    label: 'Customer Name',
                                    value: booking.customerName!,
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 10),
                                    child: Divider(height: 1, color: AppColors.border),
                                  ),
                                ],
                                _detailRow(
                                  theme,
                                  icon: Icons.description_outlined,
                                  label: 'Requirements / Description',
                                  value: booking.description.isEmpty
                                      ? 'No description provided'
                                      : booking.description,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Provider Actions
                          if (user.role == UserRole.provider) ...[
                            if (booking.status == BookingStatus.pending) ...[
                              SizedBox(
                                height: 50,
                                child: FilledButton.icon(
                                  key: BookingsKeys.acceptButton,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.success,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  icon: const Icon(Icons.check_circle_rounded),
                                  label: const Text('Accept Booking'),
                                  onPressed: () => _updateStatus(BookingStatus.accepted),
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                height: 50,
                                child: OutlinedButton.icon(
                                  key: BookingsKeys.rejectButton,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.error,
                                    side: const BorderSide(color: AppColors.error),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  icon: const Icon(Icons.cancel_outlined),
                                  label: const Text('Reject Booking'),
                                  onPressed: () => _updateStatus(BookingStatus.rejected),
                                ),
                              ),
                            ],
                            if (booking.status == BookingStatus.accepted) ...[
                              SizedBox(
                                height: 50,
                                child: FilledButton.icon(
                                  key: BookingsKeys.startProgressButton,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  icon: const Icon(Icons.play_circle_fill_rounded),
                                  label: const Text('Start Service (Mark In Progress)'),
                                  onPressed: () =>
                                      _updateStatus(BookingStatus.inProgress),
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                height: 50,
                                child: OutlinedButton.icon(
                                  key: BookingsKeys.cancelButton,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.error,
                                    side: const BorderSide(color: AppColors.error),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  icon: const Icon(Icons.cancel_outlined),
                                  label: const Text('Cancel Booking'),
                                  onPressed: _cancelBooking,
                                ),
                              ),
                            ],
                            if (booking.status == BookingStatus.inProgress) ...[
                              SizedBox(
                                height: 50,
                                child: FilledButton.icon(
                                  key: BookingsKeys.completeButton,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.success,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  icon: const Icon(Icons.check_circle_rounded),
                                  label: const Text('Mark Completed'),
                                  onPressed: () => _updateStatus(BookingStatus.completed),
                                ),
                              ),
                            ],
                          ],

                          // Customer Actions
                          if (user.role == UserRole.customer) ...[
                            if (booking.status == BookingStatus.pending ||
                                booking.status == BookingStatus.accepted) ...[
                              SizedBox(
                                height: 50,
                                child: OutlinedButton.icon(
                                  key: BookingsKeys.cancelButton,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.error,
                                    side: const BorderSide(color: AppColors.error),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  icon: const Icon(Icons.cancel_outlined),
                                  label: const Text('Cancel Booking'),
                                  onPressed: _cancelBooking,
                                ),
                              ),
                            ],
                            if (booking.status == BookingStatus.completed &&
                                user.id == booking.customerId) ...[
                              if (_checkingReview)
                                const Center(
                                  child: CircularProgressIndicator(color: AppColors.primary),
                                )
                              else if (_reviewCheckError != null)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _reviewCheckError!,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: AppColors.error,
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () => _checkReview(booking),
                                      child: const Text('Try again'),
                                    ),
                                  ],
                                )
                              else if (_reviewed)
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: AppColors.success.withOpacity(0.3),
                                    ),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle_rounded,
                                        color: AppColors.success,
                                      ),
                                      SizedBox(width: 10),
                                      Text(
                                        'You reviewed this service booking',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.success,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                SizedBox(
                                  height: 50,
                                  child: OutlinedButton.icon(
                                    key: const ValueKey('booking-write-review'),
                                    style: OutlinedButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    icon: const Icon(
                                      Icons.star_outline_rounded,
                                      color: AppColors.warning,
                                    ),
                                    label: const Text('Write a Review'),
                                    onPressed: () => _writeReview(booking),
                                  ),
                                ),
                            ],
                          ],
                        ],
                      ),
                    ),
    );
  }

  String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year} at ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  Widget _detailRow(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.neutral,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: AppColors.textSecondary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
