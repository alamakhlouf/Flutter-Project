import 'package:flutter/material.dart';
import '../../../core/network/api_exception.dart';
import '../../../design_system/app_colors.dart';
import '../../auth/auth_scope.dart';
import '../models/availability_model.dart';
import '../services/booking_service.dart';

class AvailabilityManagementScreen extends StatefulWidget {
  const AvailabilityManagementScreen({super.key});

  @override
  State<AvailabilityManagementScreen> createState() => _AvailabilityManagementScreenState();
}

class _AvailabilityManagementScreenState extends State<AvailabilityManagementScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  String? _successMessage;

  final List<String> _daysOfWeek = [
    'MONDAY',
    'TUESDAY',
    'WEDNESDAY',
    'THURSDAY',
    'FRIDAY',
    'SATURDAY',
    'SUNDAY'
  ];

  final Map<String, _DayScheduleState> _scheduleMap = {};
  List<ProviderUnavailableDate> _unavailableDates = [];
  final _reasonController = TextEditingController();
  DateTime _selectedUnavailableDate = DateTime.now().add(const Duration(days: 1));

  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    for (var day in _daysOfWeek) {
      _scheduleMap[day] = _DayScheduleState(
        enabled: day != 'SATURDAY' && day != 'SUNDAY',
        startTime: '09:00',
        endTime: '17:00',
        breakStart: '13:00',
        breakEnd: '14:00',
      );
    }
    _loadData();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiClient = AuthScope.of(context).api;
      final bookingService = BookingService(api: apiClient);

      final avs = await bookingService.fetchMyAvailability();
      final now = DateTime.now();
      final calendarDays = await bookingService.fetchProviderCalendar(
        startDate: DateTime(now.year, now.month, 1),
        endDate: DateTime(now.year, now.month + 3, 0),
      );

      final List<ProviderUnavailableDate> unDates = [];
      for (var day in calendarDays) {
        if (day.unavailableDate != null) {
          unDates.add(day.unavailableDate!);
        }
      }

      if (!mounted) return;
      setState(() {
        for (var av in avs) {
          _scheduleMap[av.dayOfWeek] = _DayScheduleState(
            enabled: true,
            startTime: av.startTime,
            endTime: av.endTime,
            breakStart: av.breakStart ?? '',
            breakEnd: av.breakEnd ?? '',
          );
        }
        _unavailableDates = unDates;
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
        _errorMessage = 'Failed to load availability: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveAvailability() async {
    setState(() {
      _isSaving = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final apiClient = AuthScope.of(context).api;
      final bookingService = BookingService(api: apiClient);

      List<ProviderAvailability> list = [];
      _scheduleMap.forEach((day, state) {
        if (state.enabled) {
          list.add(ProviderAvailability(
            dayOfWeek: day,
            startTime: state.startTime,
            endTime: state.endTime,
            breakStart: state.breakStart.isNotEmpty ? state.breakStart : null,
            breakEnd: state.breakEnd.isNotEmpty ? state.breakEnd : null,
          ));
        }
      });

      await bookingService.updateMyAvailability(list);

      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _successMessage = 'Working schedule updated successfully!';
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _isSaving = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Error saving schedule: $e';
        _isSaving = false;
      });
    }
  }

  Future<void> _addUnavailableDate() async {
    try {
      final apiClient = AuthScope.of(context).api;
      final bookingService = BookingService(api: apiClient);

      final newUn = await bookingService.addUnavailableDate(
        date: _selectedUnavailableDate,
        reason: _reasonController.text,
      );

      if (!mounted) return;
      setState(() {
        _unavailableDates.add(newUn);
        _reasonController.clear();
        _successMessage = 'Unavailable date added.';
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to add unavailable date: $e';
      });
    }
  }

  Future<void> _deleteUnavailableDate(String id) async {
    try {
      final apiClient = AuthScope.of(context).api;
      final bookingService = BookingService(api: apiClient);

      await bookingService.deleteUnavailableDate(id);

      if (!mounted) return;
      setState(() {
        _unavailableDates.removeWhere((item) => item.id == id);
        _successMessage = 'Unavailable date removed.';
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to delete: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Availability & Schedule')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.error),
                      ),
                      child: Text(_errorMessage!, style: const TextStyle(color: AppColors.error)),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (_successMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.success),
                      ),
                      child: Text(_successMessage!, style: const TextStyle(color: AppColors.success)),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Text('Weekly Working Schedule', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text('Configure your working hours and break times for each day.', style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: 16),
                  ..._daysOfWeek.map((day) {
                    final state = _scheduleMap[day]!;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(day, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                Switch(
                                  value: state.enabled,
                                  onChanged: (val) {
                                    setState(() {
                                      state.enabled = val;
                                    });
                                  },
                                ),
                              ],
                            ),
                            if (state.enabled) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      initialValue: state.startTime,
                                      decoration: const InputDecoration(labelText: 'Start Time (HH:MM)'),
                                      onChanged: (val) => state.startTime = val,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextFormField(
                                      initialValue: state.endTime,
                                      decoration: const InputDecoration(labelText: 'End Time (HH:MM)'),
                                      onChanged: (val) => state.endTime = val,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      initialValue: state.breakStart,
                                      decoration: const InputDecoration(labelText: 'Break Start (Optional)'),
                                      onChanged: (val) => state.breakStart = val,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextFormField(
                                      initialValue: state.breakEnd,
                                      decoration: const InputDecoration(labelText: 'Break End (Optional)'),
                                      onChanged: (val) => state.breakEnd = val,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _isSaving ? null : _saveAvailability,
                    child: _isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text('Save Working Schedule'),
                  ),
                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 16),
                  Text('Unavailable Dates / Time-off', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text('Mark specific dates when you are not available.', style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.calendar_today),
                          label: Text('${_selectedUnavailableDate.year}-${_selectedUnavailableDate.month.toString().padLeft(2, '0')}-${_selectedUnavailableDate.day.toString().padLeft(2, '0')}'),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _selectedUnavailableDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (picked != null) {
                              setState(() {
                                _selectedUnavailableDate = picked;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _reasonController,
                    decoration: const InputDecoration(
                      labelText: 'Reason (Optional)',
                      hintText: 'e.g., Vacation, Holiday...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _addUnavailableDate,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Unavailable Date'),
                  ),
                  const SizedBox(height: 16),
                  if (_unavailableDates.isEmpty)
                    const Text('No unavailable dates set.')
                  else
                    ..._unavailableDates.map((item) => Card(
                          child: ListTile(
                            title: Text('${item.date.year}-${item.date.month.toString().padLeft(2, '0')}-${item.date.day.toString().padLeft(2, '0')}'),
                            subtitle: item.reason != null && item.reason!.isNotEmpty ? Text(item.reason!) : null,
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: AppColors.error),
                              onPressed: () => _deleteUnavailableDate(item.id),
                            ),
                          ),
                        )),
                ],
              ),
            ),
    );
  }
}

class _DayScheduleState {
  _DayScheduleState({
    required this.enabled,
    required this.startTime,
    required this.endTime,
    required this.breakStart,
    required this.breakEnd,
  });

  bool enabled;
  String startTime;
  String endTime;
  String breakStart;
  String breakEnd;
}
