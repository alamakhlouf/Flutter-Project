import 'package:flutter/material.dart';
import '../../../core/network/api_exception.dart';
import '../../../design_system/app_colors.dart';
import '../../auth/auth_scope.dart';
import '../models/workshop_model.dart';
import '../services/workshop_service.dart';
import 'workshop_details_screen.dart';

class WorkshopCatalogScreen extends StatefulWidget {
  const WorkshopCatalogScreen({super.key});
  @override
  State<WorkshopCatalogScreen> createState() => _WorkshopCatalogScreenState();
}

class _WorkshopCatalogScreenState extends State<WorkshopCatalogScreen> {
  late WorkshopService _service;
  final _search = TextEditingController();
  List<WorkshopModel> _items = [];
  String? _error;
  bool _loading = true;
  bool _availableOnly = false;
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
      final items = await _service.fetchWorkshops(search: _search.text, availability: _availableOnly);
      if (mounted) setState(() { _items = items; _loading = false; });
    } on ApiException catch (e) {
      if (mounted) setState(() { _error = e.message; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = 'Failed to load workshops: $e'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Workshops'), actions: [
        IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
      ]),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            controller: _search,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _load(),
            decoration: InputDecoration(labelText: 'Search workshops', prefixIcon: const Icon(Icons.search), suffixIcon: IconButton(onPressed: _load, icon: const Icon(Icons.arrow_forward))),
          ),
        ),
        SwitchListTile(title: const Text('Show available only'), value: _availableOnly, onChanged: (value) { setState(() => _availableOnly = value); _load(); }),
        Expanded(child: _loading ? const Center(child: CircularProgressIndicator()) : _error != null
          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text(_error!, style: const TextStyle(color: AppColors.error), textAlign: TextAlign.center), OutlinedButton(onPressed: _load, child: const Text('Retry'))]))
          : _items.isEmpty ? const Center(child: Text('No published workshops found.'))
          : RefreshIndicator(onRefresh: _load, child: ListView.builder(padding: const EdgeInsets.all(16), itemCount: _items.length, itemBuilder: (_, index) {
              final workshop = _items[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Text(workshop.title, style: theme.textTheme.titleMedium),
                  subtitle: Text('${workshop.category} • ${workshop.location}\n${_format(workshop.startDateTime)}\n${workshop.participantCount}/${workshop.capacity} participants'),
                  isThreeLine: true,
                  trailing: Chip(label: Text(workshop.isFull ? 'FULL' : 'OPEN'), backgroundColor: (workshop.isFull ? AppColors.warning : AppColors.success).withOpacity(.15)),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => WorkshopDetailsScreen(workshop: workshop))),
                ),
              );
            })),
        ),
      ]),
    );
  }

  String _format(DateTime date) => date.toLocal().toString().split('.').first;
  @override
  void dispose() { _search.dispose(); super.dispose(); }
}
