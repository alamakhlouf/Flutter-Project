import 'package:flutter/material.dart';
import '../../../core/network/api_exception.dart';
import '../../../design_system/app_colors.dart';
import '../../auth/auth_scope.dart';
import '../models/workshop_model.dart';
import '../services/workshop_service.dart';

class WorkshopManagementScreen extends StatefulWidget {
  const WorkshopManagementScreen({super.key, this.registrations = false});
  final bool registrations;
  @override
  State<WorkshopManagementScreen> createState() => _WorkshopManagementScreenState();
}

class _WorkshopManagementScreenState extends State<WorkshopManagementScreen> {
  late final WorkshopService _service;
  List<WorkshopModel> _workshops = [];
  List<WorkshopRegistration> _registrations = [];
  String? _error;
  bool _loading = true;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    _service = WorkshopService(api: AuthScope.of(context).api);
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      if (widget.registrations) {
        _registrations = await _service.fetchMyRegistrations();
      } else {
        _workshops = await _service.fetchOrganized();
      }
      if (mounted) setState(() => _loading = false);
    } on ApiException catch (e) {
      if (mounted) setState(() { _error = e.message; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = 'Failed to load workshops: $e'; _loading = false; });
    }
  }

  Future<void> _changeStatus(WorkshopModel workshop, bool publish) async {
    try {
      if (publish) {
        await _service.publish(workshop.id);
      } else {
        await _service.cancel(workshop.id);
      }
      await _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not update workshop: $e')));
    }
  }

  Future<void> _cancelRegistration(String id) async {
    try {
      await _service.cancelRegistration(id);
      await _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not cancel registration: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.registrations ? 'My workshop registrations' : 'My organized workshops';
    return Scaffold(
      appBar: AppBar(title: Text(title), actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))]),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: AppColors.error)))
              : widget.registrations ? _registrationList() : _organizedList(),
    );
  }

  Widget _organizedList() {
    if (_workshops.isEmpty) return const Center(child: Text('You have not organized any workshops.'));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _workshops.length,
      itemBuilder: (_, index) {
        final workshop = _workshops[index];
        return Card(
          child: ListTile(
            title: Text(workshop.title),
            subtitle: Text('${workshop.status.label} • ${workshop.participantCount}/${workshop.capacity} participants'),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'publish') _changeStatus(workshop, true);
                if (value == 'cancel') _changeStatus(workshop, false);
              },
              itemBuilder: (_) => [
                if (workshop.status == WorkshopStatus.draft) const PopupMenuItem(value: 'publish', child: Text('Publish')),
                if (workshop.status == WorkshopStatus.published) const PopupMenuItem(value: 'cancel', child: Text('Cancel')),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _registrationList() {
    if (_registrations.isEmpty) return const Center(child: Text('You have no workshop registrations.'));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _registrations.length,
      itemBuilder: (_, index) {
        final registration = _registrations[index];
        return Card(
          child: ListTile(
            title: Text('Workshop ${registration.workshopId}'),
            subtitle: Text(registration.status),
            trailing: registration.isActive
                ? IconButton(onPressed: () => _cancelRegistration(registration.workshopId), icon: const Icon(Icons.cancel_outlined))
                : null,
          ),
        );
      },
    );
  }
}
