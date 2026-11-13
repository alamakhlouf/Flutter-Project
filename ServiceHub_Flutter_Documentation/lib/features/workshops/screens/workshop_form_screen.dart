import 'package:flutter/material.dart';

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

class _WorkshopFormScreenState extends State<WorkshopFormScreen> {
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
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final w = widget.workshop;
    _title = TextEditingController(text: w?.title);
    _description = TextEditingController(text: w?.description);
    _category = TextEditingController(text: w?.category);
    _location = TextEditingController(text: w?.location);
    _capacity = TextEditingController(text: w?.capacity.toString() ?? '10');
    _coverImageUrl = TextEditingController(text: w?.coverImageUrl ?? '');
    if (w != null) {
      _start = w.startDateTime;
      _end = w.endDateTime;
      _deadline = w.registrationDeadline;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _service = WorkshopService(api: AuthScope.of(context).api);
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
        location: _location.text,
        capacity: int.parse(_capacity.text),
        start: _start,
        end: _end,
        deadline: _deadline,
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
          for (final field in [
            _field(_title, 'Title'),
            _field(_description, 'Description', required: false, maxLines: 3),
            _field(_category, 'Category'),
            _field(_location, 'Location'),
            _field(_capacity, 'Capacity', keyboard: TextInputType.number),
          ])
            Padding(padding: const EdgeInsets.only(bottom: 16), child: field),
          TextFormField(
            controller: _coverImageUrl,
            keyboardType: TextInputType.url,
            textCapitalization: TextCapitalization.none,
            decoration: const InputDecoration(
              labelText: 'Cover image URL (optional)',
              hintText: 'https://example.com/workshop.jpg',
            ),
            validator: (value) {
              final url = value?.trim() ?? '';
              if (url.isEmpty) return null;
              if (url.length > 2048) {
                return 'Image URL must be 2048 characters or fewer.';
              }
              final uri = Uri.tryParse(url);
              if (uri == null ||
                  (uri.scheme != 'http' && uri.scheme != 'https') ||
                  uri.host.isEmpty) {
                return 'Enter a valid http or https image URL.';
              }
              return null;
            },
          ),
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
