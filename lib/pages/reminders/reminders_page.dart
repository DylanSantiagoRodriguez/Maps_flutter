import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:maps/pages/map/map_page.dart';
import 'package:maps/services/supabase_service.dart';

class ReminderItem {
  String? id;
  String title;
  String? description;
  DateTime? dateTime;
  LatLng? location;
  ReminderItem({
    this.id,
    required this.title,
    this.description,
    this.dateTime,
    this.location,
  });

  factory ReminderItem.fromMap(Map<String, dynamic> m) {
    return ReminderItem(
      id: m['id'] as String?,
      title: (m['title'] ?? '') as String,
      description: m['description'] as String?,
      dateTime: m['scheduled_at'] != null ? DateTime.parse(m['scheduled_at'] as String) : null,
      location: (m['lat'] != null && m['lng'] != null)
          ? LatLng((m['lat'] as num).toDouble(), (m['lng'] as num).toDouble())
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'description': description,
      'scheduled_at': dateTime?.toIso8601String(),
      'lat': location?.latitude,
      'lng': location?.longitude,
    };
  }
}

class RemindersPage extends StatefulWidget {
  const RemindersPage({super.key});

  @override
  State<RemindersPage> createState() => _RemindersPageState();
}

class _RemindersPageState extends State<RemindersPage> {
  final List<ReminderItem> _reminders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    try {
      final rows = await SupabaseService.instance.fetchReminders();
      setState(() {
        _reminders
          ..clear()
          ..addAll(rows.map(ReminderItem.fromMap));
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cargando recordatorios: $e')),
      );
    }
  }

  void _addReminder() async {
    final newItem = ReminderItem(title: '');
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _ReminderFormPage(item: newItem),
      ),
    );
    if (result is ReminderItem) {
      try {
        final inserted = await SupabaseService.instance.createReminder(result.toMap());
        setState(() {
          _reminders.add(ReminderItem.fromMap(inserted));
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error guardando recordatorio: $e')),
        );
      }
    }
  }

  void _editReminder(int index) async {
    final item = _reminders[index];
    final edited = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _ReminderFormPage(item: ReminderItem(
          id: item.id,
          title: item.title,
          description: item.description,
          dateTime: item.dateTime,
          location: item.location,
        )),
      ),
    );
    if (edited is ReminderItem) {
      try {
        final updated = await SupabaseService.instance.updateReminder(item.id!, edited.toMap());
        setState(() {
          _reminders[index] = ReminderItem.fromMap(updated);
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error actualizando recordatorio: $e')),
        );
      }
    }
  }

  Future<void> _deleteReminder(int index) async {
    final item = _reminders[index];
    try {
      await SupabaseService.instance.deleteReminder(item.id!);
      setState(() {
        _reminders.removeAt(index);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error eliminando recordatorio: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recordatorios')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _reminders.isEmpty
              ? const Center(child: Text('No hay recordatorios. Pulsa + para añadir'))
              : ListView.separated(
                  itemCount: _reminders.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final r = _reminders[index];
                    return ListTile(
                      title: Text(r.title),
                      subtitle: Text(
                        [
                          if (r.description?.isNotEmpty == true) r.description!,
                          if (r.dateTime != null) 'Fecha: ${r.dateTime}',
                          if (r.location != null)
                            'Ubicación: (${r.location!.latitude.toStringAsFixed(5)}, ${r.location!.longitude.toStringAsFixed(5)})',
                        ].join(' • '),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _editReminder(index),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _deleteReminder(index),
                          ),
                        ],
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addReminder,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _ReminderFormPage extends StatefulWidget {
  final ReminderItem item;
  const _ReminderFormPage({required this.item});

  @override
  State<_ReminderFormPage> createState() => _ReminderFormPageState();
}

class _ReminderFormPageState extends State<_ReminderFormPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  DateTime? _selectedDateTime;
  LatLng? _selectedLocation;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.item.title);
    _descriptionController = TextEditingController(text: widget.item.description ?? '');
    _selectedDateTime = widget.item.dateTime;
    _selectedLocation = widget.item.location;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime ?? DateTime.now()),
    );
    if (time == null) return;
    setState(() {
      _selectedDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _pickLocation() async {
    final LatLng? point = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const MapPage(selectionMode: true),
      ),
    );
    if (point != null) {
      setState(() {
        _selectedLocation = point;
      });
    }
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;
    final item = ReminderItem(
      id: widget.item.id,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      dateTime: _selectedDateTime,
      location: _selectedLocation,
    );
    Navigator.pop(context, item);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo recordatorio')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Título', prefixIcon: Icon(Icons.title)),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'El título es obligatorio' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Descripción', prefixIcon: Icon(Icons.notes)),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: Text(_selectedDateTime == null
                    ? 'Seleccionar fecha y hora'
                    : 'Fecha y hora: ${_selectedDateTime}'),
                onTap: _pickDateTime,
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.location_on),
                title: Text(_selectedLocation == null
                    ? 'Seleccionar ubicación en el mapa'
                    : 'Ubicación: (${_selectedLocation!.latitude.toStringAsFixed(5)}, ${_selectedLocation!.longitude.toStringAsFixed(5)})'),
                onTap: _pickLocation,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save),
                label: const Text('Guardar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}