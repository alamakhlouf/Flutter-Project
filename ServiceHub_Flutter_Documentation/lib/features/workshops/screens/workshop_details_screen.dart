import 'package:flutter/material.dart';
import '../../../core/network/api_exception.dart';
import '../../../design_system/app_colors.dart';
import '../../auth/auth_scope.dart';
import '../models/workshop_model.dart';
import '../services/workshop_service.dart';

class WorkshopDetailsScreen extends StatefulWidget {
  const WorkshopDetailsScreen({super.key, required this.workshop});
  final WorkshopModel workshop;
  @override
  State<WorkshopDetailsScreen> createState() => _WorkshopDetailsScreenState();
}

class _WorkshopDetailsScreenState extends State<WorkshopDetailsScreen> {
  late final WorkshopService _service;
  late WorkshopModel _workshop;
  bool _busy = false;

  @override
  void initState() { super.initState(); _workshop = widget.workshop; }
  @override
  void didChangeDependencies() { super.didChangeDependencies(); _service = WorkshopService(api: AuthScope.of(context).api); }

  Future<void> _register() async {
    setState(() => _busy = true);
    try {
      await _service.register(_workshop.id);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registration confirmed.')));
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: AppColors.error));
    } finally { if (mounted) setState(() => _busy = false); }
  }

  @override
  Widget build(BuildContext context) {
    final canRegister = _workshop.status == WorkshopStatus.published && !_workshop.registrationClosed;
    return Scaffold(
      appBar: AppBar(title: const Text('Workshop details')),
      body: ListView(padding: const EdgeInsets.all(24), children: [
        Text(_workshop.title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Chip(label: Text(_workshop.status.label), backgroundColor: _workshop.status.color.withOpacity(.15)),
        const SizedBox(height: 16),
        Text(_workshop.description.isEmpty ? 'No description provided.' : _workshop.description),
        const SizedBox(height: 20),
        _detail(Icons.category_outlined, 'Category', _workshop.category),
        _detail(Icons.person_outline, 'Organizer', _workshop.organizerName),
        _detail(Icons.schedule, 'When', '${_workshop.startDateTime.toLocal()} - ${_workshop.endDateTime.toLocal()}'),
        _detail(Icons.location_on_outlined, 'Location', _workshop.location),
        _detail(Icons.groups_outlined, 'Capacity', '${_workshop.participantCount}/${_workshop.capacity} registered'),
        _detail(Icons.timer_outlined, 'Registration closes', _workshop.registrationDeadline.toLocal().toString()),
        const SizedBox(height: 24),
        FilledButton.icon(onPressed: canRegister && !_busy ? _register : null, icon: const Icon(Icons.how_to_reg), label: Text(_workshop.isFull ? 'Workshop full' : 'Register')),
      ]),
    );
  }

  Widget _detail(IconData icon, String label, String value) => ListTile(leading: Icon(icon, color: AppColors.primary), title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text(value));
}
