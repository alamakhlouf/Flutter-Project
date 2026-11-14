import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/utils/image_picker_helper.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/image_renderer.dart';
import '../../../design_system/app_colors.dart';
import '../../auth/auth_scope.dart';
import '../models/workshop_model.dart';
import '../services/workshop_service.dart';
import '../utils/workshop_date_format.dart';

class WorkshopFormScreen extends StatefulWidget {
  const WorkshopFormScreen({super.key, this.workshop});
  final WorkshopModel? workshop;
  @override
  State<WorkshopFormScreen> createState() => _WorkshopFormScreenState();
}

class _WorkshopFormScreenState extends State<WorkshopFormScreen>
    with WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();
  late final WorkshopService _service;
  late final TextEditingController _title,
      _description,
      _category,
      _location,
      _capacity,
      _coverImageUrl;
  DateTime _start = DateTime.now().add(const Duration(days: 1));
  DateTime _end = DateTime.now().add(const Duration(days: 1, hours: 2));
  DateTime _deadline = DateTime.now().add(const Duration(hours: 12));
  String _workshopType = 'IN_PERSON';
  bool _busy = false;
  bool _googleConnected = false;
  String? _googleEmail;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final w = widget.workshop;
    _title = TextEditingController(text: w?.title);
    _description = TextEditingController(text: w?.description);
    _category = TextEditingController(text: w?.category);
    _location = TextEditingController(
      text: w?.location ?? (w?.isOnline == true ? 'Google Meet (Online)' : ''),
    );
    _capacity = TextEditingController(text: w?.capacity.toString() ?? '10');
    _coverImageUrl = TextEditingController(text: w?.coverImageUrl ?? '');
    if (w != null) {
      _start = w.startDateTime;
      _end = w.endDateTime;
      _deadline = w.registrationDeadline;
      _workshopType = w.workshopType.toUpperCase();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadGoogleStatus();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _service = WorkshopService(api: AuthScope.of(context).api);
    _loadGoogleStatus();
  }

  Future<void> _loadGoogleStatus() async {
    try {
      final status = await _service.checkGoogleStatus();
      if (!mounted) return;
      setState(() {
        _googleConnected = status['connected'] == true;
        _googleEmail = status['googleEmail']?.toString();
      });
    } catch (_) {}
  }

  Future<void> _connectGoogle() async {
    setState(() => _busy = true);
    try {
      final authUrl = await _service.getGoogleConnectUrl();
      final launched = await launchUrl(
        Uri.parse(authUrl),
        mode: LaunchMode.externalApplication,
      );
      if (!launched) throw Exception('Could not open Google authorization');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Complete Google authorization, then return to ServiceHub.',
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google connect error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() ||
        _end.isBefore(_start) ||
        _deadline.isAfter(_start)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Check the dates: deadline must be before the start and end after the start.',
          ),
        ),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      final args = (
        title: _title.text,
        description: _description.text,
        category: _category.text,
        location: _workshopType == 'ONLINE'
            ? 'Google Meet (Online)'
            : _location.text,
        capacity: int.parse(_capacity.text),
        start: _start,
        end: _end,
        deadline: _deadline,
        workshopType: _workshopType,
      );
      if (widget.workshop == null) {
        await _service.create(
          title: args.title,
          description: args.description,
          category: args.category,
          coverImageUrl: _coverImageUrl.text,
          location: args.location,
          capacity: args.capacity,
          startDateTime: args.start,
          endDateTime: args.end,
          registrationDeadline: args.deadline,
          workshopType: args.workshopType,
        );
      } else {
        await _service.update(
          widget.workshop!.id,
          title: args.title,
          description: args.description,
          category: args.category,
          coverImageUrl: _coverImageUrl.text,
          location: args.location,
          capacity: args.capacity,
          startDateTime: args.start,
          endDateTime: args.end,
          registrationDeadline: args.deadline,
          workshopType: args.workshopType,
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not save workshop: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        widget.workshop == null ? 'Create workshop' : 'Edit workshop',
      ),
    ),
    body: Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          DropdownButtonFormField<String>(
            value: _workshopType,
            decoration: const InputDecoration(labelText: 'Workshop Type'),
            items: const [
              DropdownMenuItem(value: 'IN_PERSON', child: Text('In-Person')),
              DropdownMenuItem(
                value: 'ONLINE',
                child: Text('Online (Google Meet)'),
              ),
            ],
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _workshopType = val;
                  if (val == 'ONLINE') {
                    _location.text = 'Google Meet (Online)';
                  }
                });
              }
            },
          ),
          if (_workshopType == 'ONLINE') ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _googleConnected
                    ? AppColors.success.withOpacity(0.08)
                    : AppColors.error.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _googleConnected
                      ? AppColors.success.withOpacity(0.3)
                      : AppColors.error.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _googleConnected
                            ? Icons.check_circle
                            : Icons.warning_amber_rounded,
                        color: _googleConnected
                            ? AppColors.success
                            : AppColors.error,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _googleConnected
                              ? 'Google Account Connected (${_googleEmail ?? 'Connected'})'
                              : 'Google Account Required for Google Meet',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: _googleConnected
                                    ? AppColors.success
                                    : AppColors.error,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _googleConnected
                        ? 'A real Google Meet link will be automatically generated and assigned upon creation.'
                        : 'Please connect your Google account before creating an online workshop.',
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _connectGoogle,
                    icon: const Icon(Icons.link, size: 18),
                    label: Text(
                      _googleConnected
                          ? 'Reconnect Google Account'
                          : 'Connect Google Account',
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          for (final field in [
            _field(_title, 'Title'),
            _field(_description, 'Description', required: false, maxLines: 3),
            _field(_category, 'Category'),
            if (_workshopType != 'ONLINE') _field(_location, 'Location'),
            _field(_capacity, 'Capacity', keyboard: TextInputType.number),
          ])
            Padding(padding: const EdgeInsets.only(bottom: 16), child: field),
          Text('Cover Image', style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 6),
          OutlinedButton.icon(
            onPressed: _busy
                ? null
                : () async {
                    final base64Image =
                        await ImagePickerHelper.pickAndConvertToBase64(context);
                    if (base64Image != null && mounted) {
                      setState(() {
                        _coverImageUrl.text = base64Image;
                      });
                    }
                  },
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text('Pick Image from Device'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _coverImageUrl,
            keyboardType: TextInputType.url,
            textCapitalization: TextCapitalization.none,
            validator: Validators.imageUrl,
            decoration: const InputDecoration(
              labelText: 'Cover image (optional)',
              hintText: 'https://example.com/workshop.jpg or pick from device',
            ),
            onChanged: (_) => setState(() {}),
          ),
          if (_coverImageUrl.text.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 150,
                width: double.infinity,
                child: ImageRenderer(
                  imageUrl: _coverImageUrl.text,
                  placeholder: const Center(child: Text('Invalid image')),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          _dateButton(
            'Starts',
            _start,
            (value) => setState(() => _start = value),
          ),
          _dateButton('Ends', _end, (value) => setState(() => _end = value)),
          _dateButton(
            'Registration deadline',
            _deadline,
            (value) => setState(() => _deadline = value),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _busy ? null : _save,
            child: Text(_busy ? 'Saving...' : 'Save workshop'),
          ),
        ],
      ),
    ),
  );

  Widget _field(
    TextEditingController c,
    String label, {
    bool required = true,
    int maxLines = 1,
    TextInputType? keyboard,
  }) => TextFormField(
    controller: c,
    maxLines: maxLines,
    keyboardType: keyboard,
    decoration: InputDecoration(labelText: label),
    validator: required
        ? (v) => v == null || v.trim().isEmpty ? 'Required' : null
        : null,
  );
  Widget _dateButton(
    String label,
    DateTime value,
    ValueChanged<DateTime> onChanged,
  ) => ListTile(
    title: Text(label),
    subtitle: Text(formatWorkshopDateTime(value)),
    trailing: const Icon(Icons.edit_calendar),
    onTap: () async {
      final date = await showDatePicker(
        context: context,
        firstDate: DateTime.now().subtract(const Duration(days: 1)),
        lastDate: DateTime.now().add(const Duration(days: 730)),
        initialDate: value,
      );
      if (date == null || !mounted) return;
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(value),
      );
      if (time != null) {
        onChanged(
          DateTime(date.year, date.month, date.day, time.hour, time.minute),
        );
      }
    },
  );

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    for (final c in [
      _title,
      _description,
      _category,
      _location,
      _capacity,
      _coverImageUrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }
}
