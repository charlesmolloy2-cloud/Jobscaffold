import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:geolocator/geolocator.dart';
import '../../models/budget.dart';

import '../../services/task_service.dart';
import '../../services/time_tracking_service.dart';
import '../../services/budget_service.dart';
import '../../services/weather_service.dart';
import '../../services/location_service.dart';

class ProjectDashboardPage extends StatefulWidget {
  final String projectId;
  final String? projectName;

  const ProjectDashboardPage({super.key, required this.projectId, this.projectName});

  @override
  State<ProjectDashboardPage> createState() => _ProjectDashboardPageState();
}

class _ProjectDashboardPageState extends State<ProjectDashboardPage> {
  final _taskService = TaskService();
  final _timeService = TimeTrackingService();
  final _budgetService = BudgetService();
  final _weatherService = WeatherService();
  final _locationService = LocationService();

  GeoPoint? _projectLocation;
  WeatherData? _weather;
  TimeSummary? _timeSummary;
  TaskStats? _taskStats;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() { _loading = true; _error = null; });
    try {
      // Fetch project location (optional)
      final projDoc = await FirebaseFirestore.instance.collection('projects').doc(widget.projectId).get();
      final projData = projDoc.data();
      _projectLocation = projData != null ? projData['location'] as GeoPoint? : null;

      // Parallel requests where possible
      final futures = <Future>[];
      futures.add(_timeService.getProjectTimeSummary(widget.projectId).then((v) => _timeSummary = v));
      futures.add(_taskService.getTaskStats(widget.projectId).then((v) => _taskStats = v));
      if (_projectLocation != null) {
        futures.add(_weatherService.getCurrentWeather(
          latitude: _projectLocation!.latitude,
          longitude: _projectLocation!.longitude,
        ).then((v) => _weather = v));
      }
      await Future.wait(futures);
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.projectName ?? 'Project Dashboard')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 48),
                        const SizedBox(height: 12),
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        ElevatedButton(onPressed: _loadAll, child: const Text('Retry')),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadAll,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _Header(projectName: widget.projectName),
                      const SizedBox(height: 12),
                      _CardsRow(children: [
                        _StatCard(
                          title: 'Tasks',
                          value: _taskStats != null ? '${_taskStats!.completed}/${_taskStats!.total}' : '--',
                          subtitle: 'Done / Total',
                          color: Colors.blue,
                          icon: Icons.check_circle_outline,
                        ),
                        _StatCard(
                          title: 'Hours',
                          value: _timeSummary != null ? _timeSummary!.totalHours.toStringAsFixed(1) : '--',
                          subtitle: '${_timeSummary?.entryCount ?? 0} entries',
                          color: Colors.deepPurple,
                          icon: Icons.schedule,
                        ),
                        StreamBuilder<Budget?>(
                          stream: _budgetService.watchBudgetByProject(widget.projectId),
                          builder: (context, snap) {
                            final b = snap.data;
                            return _StatCard(
                              title: 'Budget',
                              value: b != null ? '\$${b.totalActual.toStringAsFixed(0)}' : '--',
                              subtitle: b != null ? 'Est: \$${b.totalEstimate.toStringAsFixed(0)}' : 'No budget',
                              color: Colors.teal,
                              icon: Icons.attach_money,
                            );
                          },
                        ),
                      ]),
                      const SizedBox(height: 16),
                      if (_weather != null) _WeatherCard(weather: _weather!),
                      const SizedBox(height: 16),
                      _RecentCheckIns(projectId: widget.projectId, locationService: _locationService),
                    ],
                  ),
                ),
    );
  }
}

class _Header extends StatelessWidget {
  final String? projectName;
  const _Header({required this.projectName});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.dashboard, size: 28),
        const SizedBox(width: 8),
        Text(projectName ?? 'Project', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _CardsRow extends StatelessWidget {
  final List<Widget> children;
  const _CardsRow({required this.children});
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth < 640) {
          return Column(
            children: children.map((w) => Padding(padding: const EdgeInsets.only(bottom: 8), child: w)).toList(),
          );
        }
        return Row(
          children: children
              .map((w) => Expanded(child: Padding(padding: const EdgeInsets.only(right: 8), child: w)))
              .toList(),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color color;
  final IconData icon;
  const _StatCard({required this.title, required this.value, required this.subtitle, required this.color, required this.icon});
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(backgroundColor: color.withOpacity(0.15), child: Icon(icon, color: color)),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: TextStyle(color: Colors.grey[700])),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            ]),
          ],
        ),
      ),
    );
  }
}

class _WeatherCard extends StatelessWidget {
  final WeatherData weather;
  const _WeatherCard({required this.weather});
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Image.network(weather.iconUrl, width: 64, height: 64, errorBuilder: (_, __, ___) => const Icon(Icons.cloud, size: 64)),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${weather.cityName}  •  ${weather.description.toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('${weather.temperature.round()}°F (feels ${weather.feelsLike.round()}°F)'),
              Text('Wind ${weather.windSpeed.round()} mph • Humidity ${weather.humidity}%'),
            ]),
          ],
        ),
      ),
    );
  }
}

class _RecentCheckIns extends StatelessWidget {
  final String projectId;
  final LocationService locationService;
  const _RecentCheckIns({required this.projectId, required this.locationService});
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ListTile(leading: Icon(Icons.place), title: Text('Recent check-ins')),
            StreamBuilder<List<CheckIn>>(
              stream: locationService.getProjectCheckIns(projectId),
              builder: (context, snap) {
                if (!snap.hasData) return const Padding(padding: EdgeInsets.all(16), child: LinearProgressIndicator());
                final items = snap.data!;
                if (items.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No check-ins yet', style: TextStyle(color: Colors.grey)),
                  );
                }
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length > 5 ? 5 : items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final c = items[i];
                    final time = TimeOfDay.fromDateTime(c.timestamp);
                    final type = c.checkInType.toString().split('.').last.replaceAll('_', ' ');
                    return ListTile(
                      leading: const Icon(Icons.person_pin_circle),
                      title: Text(type),
                      subtitle: Text('${c.timestamp.year}-${c.timestamp.month.toString().padLeft(2, '0')}-${c.timestamp.day.toString().padLeft(2, '0')} • ${time.format(context)}'),
                      trailing: Text(c.distanceText, style: TextStyle(color: Colors.grey[600])),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
