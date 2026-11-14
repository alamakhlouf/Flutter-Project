import 'package:flutter/material.dart';
import '../../../core/network/api_exception.dart';
import '../../../design_system/app_colors.dart';
import '../../auth/auth_scope.dart';
import '../models/availability_model.dart';
import '../models/booking_model.dart';
import '../services/booking_service.dart';
import '../../../app/app_routes.dart';

class ProviderCalendarScreen extends StatefulWidget {
  const ProviderCalendarScreen({super.key});

  @override
  State<ProviderCalendarScreen> createState() => _ProviderCalendarScreenState();
}

class _ProviderCalendarScreenState extends State<ProviderCalendarScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  DateTime _currentMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _selectedDate = DateTime.now();
  List<ProviderCalendarDay> _calendarDays = [];

  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    _loadCalendar();
  }

  Future<void> _loadCalendar() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiClient = AuthScope.of(context).api;
      final bookingService = BookingService(api: apiClient);

      final startDate = DateTime(_currentMonth.year, _currentMonth.month, 1);
      final endDate = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);

      final days = await bookingService.fetchProviderCalendar(
        startDate: startDate,
        endDate: endDate,
      );

      if (!mounted) return;
      setState(() {
        _calendarDays = days;
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
        _errorMessage = 'Failed to load calendar: $e';
        _isLoading = false;
      });
    }
  }

  void _changeMonth(int delta) {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + delta, 1);
      _selectedDate = _currentMonth;
    });
    _loadCalendar();
  }

  ProviderCalendarDay? _getDayData(DateTime date) {
    try {
      return _calendarDays.firstWhere(
        (d) => d.date.year == date.year && d.date.month == date.month && d.date.day == date.day,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedDayData = _getDayData(_selectedDate);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Provider Calendar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Manage Availability',
            onPressed: () async {
              await Navigator.of(context).pushNamed(AppRoutes.availabilityManagement);
              _loadCalendar();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(8),
                    color: AppColors.error.withOpacity(0.1),
                    child: Text(_errorMessage!, style: const TextStyle(color: AppColors.error)),
                  ),
                // Month Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: () => _changeMonth(-1),
                      ),
                      Text(
                        '${_currentMonth.year} - ${_currentMonth.month.toString().padLeft(2, '0')}',
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: () => _changeMonth(1),
                      ),
                    ],
                  ),
                ),
                // Days Grid
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      mainAxisSpacing: 4,
                      crossAxisSpacing: 4,
                    ),
                    itemCount: 35,
                    itemBuilder: (context, index) {
                      final firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
                      final offset = firstDayOfMonth.weekday - 1;
                      final dayNumber = index - offset + 1;
                      final daysInMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;

                      if (dayNumber < 1 || dayNumber > daysInMonth) {
                        return const SizedBox.shrink();
                      }

                      final date = DateTime(_currentMonth.year, _currentMonth.month, dayNumber);
                      final dayData = _getDayData(date);
                      final isSelected = _selectedDate.year == date.year &&
                          _selectedDate.month == date.month &&
                          _selectedDate.day == date.day;

                      final hasBookings = dayData != null && dayData.bookings.isNotEmpty;
                      final isUnavailable = dayData != null && dayData.unavailableDate != null;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedDate = date;
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : isUnavailable
                                    ? AppColors.error.withOpacity(0.2)
                                    : hasBookings
                                        ? AppColors.info.withOpacity(0.2)
                                        : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: isSelected ? Border.all(color: AppColors.primary, width: 2) : null,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '$dayNumber',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? Colors.white : AppColors.textPrimary,
                                ),
                              ),
                              if (hasBookings || isUnavailable)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (hasBookings)
                                      Container(
                                        width: 6,
                                        height: 6,
                                        margin: const EdgeInsets.symmetric(horizontal: 1),
                                        decoration: const BoxDecoration(
                                          color: AppColors.info,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    if (isUnavailable)
                                      Container(
                                        width: 6,
                                        height: 6,
                                        margin: const EdgeInsets.symmetric(horizontal: 1),
                                        decoration: const BoxDecoration(
                                          color: AppColors.error,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(),
                // Selected Day Details
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Schedule & Bookings for ${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        if (selectedDayData?.unavailableDate != null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.error.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Unavailable: ${selectedDayData?.unavailableDate?.reason ?? "Time off"}',
                              style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
                            ),
                          )
                        else if (selectedDayData?.availability != null)
                          Text(
                            'Working Hours: ${selectedDayData!.availability!.startTime} - ${selectedDayData.availability!.endTime}',
                            style: theme.textTheme.bodyMedium,
                          )
                        else
                          const Text('No working hours configured for this day.'),
                        const SizedBox(height: 12),
                        Text('Bookings (${selectedDayData?.bookings.length ?? 0}):', style: theme.textTheme.titleSmall),
                        const SizedBox(height: 8),
                        Expanded(
                          child: selectedDayData == null || selectedDayData.bookings.isEmpty
                              ? const Center(child: Text('No bookings on this day.'))
                              : ListView.builder(
                                  padding: const EdgeInsets.only(bottom: 24),
                                  itemCount: selectedDayData.bookings.length,
                                  itemBuilder: (context, index) {
                                    final booking = selectedDayData.bookings[index];
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
                                            await Navigator.of(context).pushNamed(
                                              AppRoutes.bookingDetails,
                                              arguments: booking,
                                            );
                                            _loadCalendar();
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
                                                const SizedBox(height: 14),
                                                Row(
                                                  children: [
                                                    const Icon(
                                                      Icons.schedule_rounded,
                                                      size: 16,
                                                      color: AppColors.textSecondary,
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      formattedDate,
                                                      style: theme.textTheme.bodyMedium?.copyWith(
                                                        color: AppColors.textPrimary,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 12),
                                                const Divider(height: 1, color: AppColors.border),
                                                const SizedBox(height: 12),
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Text(
                                                      'Price Snapshot',
                                                      style: theme.textTheme.bodySmall?.copyWith(
                                                        color: AppColors.textSecondary,
                                                      ),
                                                    ),
                                                    Text(
                                                      '\$${booking.price.toStringAsFixed(2)}',
                                                      style: theme.textTheme.titleMedium?.copyWith(
                                                        fontWeight: FontWeight.bold,
                                                        color: AppColors.primary,
                                                      ),
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
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
