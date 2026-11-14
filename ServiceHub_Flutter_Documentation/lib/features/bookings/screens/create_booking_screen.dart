import 'package:flutter/material.dart';
import '../../../core/network/api_exception.dart';
import '../../../design_system/app_colors.dart';
import '../../auth/auth_scope.dart';
import '../../services/models/service_model.dart';
import '../bookings_keys.dart';
import '../models/availability_model.dart';
import '../services/booking_service.dart';

class CreateBookingScreen extends StatefulWidget {
  const CreateBookingScreen({super.key, required this.service});

  final ServiceModel service;

  @override
  State<CreateBookingScreen> createState() => _CreateBookingScreenState();
}

class _CreateBookingScreenState extends State<CreateBookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));

  bool _isLoadingSlots = false;
  bool _isLoading = false;
  String? _errorMessage;
  List<AvailableSlot> _availableSlots = [];
  AvailableSlot? _selectedSlot;

  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    _loadAvailableSlots();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableSlots() async {
    setState(() {
      _isLoadingSlots = true;
      _errorMessage = null;
      _selectedSlot = null;
      _availableSlots = [];
    });

    try {
      final apiClient = AuthScope.of(context).api;
      final bookingService = BookingService(api: apiClient);

      final slots = await bookingService.fetchAvailableSlots(
        providerId: widget.service.providerId,
        date: _selectedDate,
      );

      if (!mounted) return;
      setState(() {
        _availableSlots = slots;
        _isLoadingSlots = false;
        if (slots.isNotEmpty) {
          _selectedSlot = slots.first;
        }
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _isLoadingSlots = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load available slots: $e';
        _isLoadingSlots = false;
      });
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isBefore(now) ? now : _selectedDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedDate = DateTime(picked.year, picked.month, picked.day);
      });
      _loadAvailableSlots();
    }
  }

  Future<void> _submitBooking() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedSlot == null) {
      setState(() {
        _errorMessage = 'Please select an available time slot.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiClient = AuthScope.of(context).api;
      final bookingService = BookingService(api: apiClient);

      await bookingService.createBooking(
        serviceId: widget.service.id,
        preferredDateTime: _selectedSlot!.startDateTime.toUtc(),
        description: _descriptionController.text,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking request created successfully!')),
      );
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'An unexpected error occurred: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final service = widget.service;

    return Scaffold(
      appBar: AppBar(title: const Text('Book Service')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_errorMessage != null) ...[
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.error),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        _errorMessage!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Text(service.title, style: theme.textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text(
                  service.category,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                if (service.price != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    '\$${service.price!.toStringAsFixed(2)}',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Text('Select Date', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  key: BookingsKeys.preferredDateInput,
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: Text(
                    '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
                  ),
                  onPressed: _pickDate,
                ),
                const SizedBox(height: 24),
                Text('Available Time Slots', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                if (_isLoadingSlots)
                  const Center(child: CircularProgressIndicator())
                else if (_availableSlots.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text('No available time slots on this date (provider may be unavailable or working hours not set).', style: TextStyle(color: AppColors.textSecondary)),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _availableSlots.map((slot) {
                      final isSelected = _selectedSlot == slot;
                      final startTimeFormatted = '${slot.startDateTime.toLocal().hour.toString().padLeft(2, '0')}:${slot.startDateTime.toLocal().minute.toString().padLeft(2, '0')}';
                      final endTimeFormatted = '${slot.endDateTime.toLocal().hour.toString().padLeft(2, '0')}:${slot.endDateTime.toLocal().minute.toString().padLeft(2, '0')}';

                      return ChoiceChip(
                        label: Text('$startTimeFormatted - $endTimeFormatted'),
                        selected: isSelected,
                        selectedColor: AppColors.primary.withOpacity(0.2),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedSlot = slot;
                            });
                          }
                        },
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 24),
                TextFormField(
                  key: BookingsKeys.descriptionInput,
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Request Details / Requirements',
                    hintText: 'Describe what you need...',
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter booking details';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                FilledButton(
                  key: BookingsKeys.submitBooking,
                  onPressed: _isLoading || _availableSlots.isEmpty ? null : _submitBooking,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Confirm Booking Request'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
