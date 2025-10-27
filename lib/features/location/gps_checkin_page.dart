import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/location_service.dart';
import '../../state/app_state.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

class GPSCheckInPage extends StatefulWidget {
  final String projectId;
  final String projectName;

  const GPSCheckInPage({
    super.key,
    required this.projectId,
    required this.projectName,
  });

  @override
  State<GPSCheckInPage> createState() => _GPSCheckInPageState();
}

class _GPSCheckInPageState extends State<GPSCheckInPage> {
  final LocationService _locationService = LocationService();
  final TextEditingController _notesController = TextEditingController();
  
  Position? _currentPosition;
  bool _isLoading = false;
  String? _error;
  List<CheckIn> _todayCheckIns = [];

  @override
  void initState() {
    super.initState();
    _loadTodayCheckIns();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadTodayCheckIns() async {
    final appState = context.read<AppState>();
    final userId = appState.currentUser?.id ?? '';

    final checkIns = await _locationService.getTodayCheckIns(userId);
    setState(() => _todayCheckIns = checkIns);
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final position = await _locationService.getCurrentPosition();
      setState(() {
        _currentPosition = position;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _checkIn() async {
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Getting location...')),
      );
      await _getCurrentLocation();
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _locationService.checkIn(
        projectId: widget.projectId,
        position: _currentPosition!,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Checked in successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }

      _notesController.clear();
      await _loadTodayCheckIns();
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _checkOut() async {
    if (_currentPosition == null) {
      await _getCurrentLocation();
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _locationService.checkOut(
        projectId: widget.projectId,
        position: _currentPosition!,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Checked out successfully!'),
            backgroundColor: Colors.orange,
          ),
        );
      }

      _notesController.clear();
      await _loadTodayCheckIns();
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lastCheckIn = _todayCheckIns.isNotEmpty ? _todayCheckIns.first : null;
    final isArrival = lastCheckIn?.checkInType != CheckInType.arrival;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('GPS Check-In'),
            Text(
              widget.projectName,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
            ),
          ],
        ),
      ),
      body: _isLoading && _currentPosition == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Current Location Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              color: _currentPosition != null ? Colors.green : Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Current Location',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (_currentPosition != null) ...[
                          Text('Latitude: ${_currentPosition!.latitude.toStringAsFixed(6)}'),
                          Text('Longitude: ${_currentPosition!.longitude.toStringAsFixed(6)}'),
                          Text('Accuracy: ${_currentPosition!.accuracy.toStringAsFixed(1)}m'),
                        ] else if (_error != null) ...[
                          Text(
                            'Error: $_error',
                            style: const TextStyle(color: Colors.red),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: _getCurrentLocation,
                            child: const Text('Retry'),
                          ),
                        ] else ...[
                          const Text('Getting location...'),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Notes Field
                TextField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    hintText: 'Add notes about this check-in...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),

                const SizedBox(height: 16),

                // Check In/Out Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isLoading || !isArrival ? null : _checkIn,
                        icon: const Icon(Icons.login),
                        label: const Text('Check In'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isLoading || isArrival ? null : _checkOut,
                        icon: const Icon(Icons.logout),
                        label: const Text('Check Out'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Today's Check-Ins
                Text(
                  "Today's Check-Ins",
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),

                if (_todayCheckIns.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(
                        child: Text('No check-ins today'),
                      ),
                    ),
                  )
                else
                  ..._todayCheckIns.map((checkIn) => _CheckInCard(checkIn: checkIn)),
              ],
            ),
    );
  }
}

class _CheckInCard extends StatelessWidget {
  final CheckIn checkIn;

  const _CheckInCard({required this.checkIn});

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('h:mm a');
    final isArrival = checkIn.checkInType == CheckInType.arrival;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isArrival ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            isArrival ? Icons.login : Icons.logout,
            color: isArrival ? Colors.green : Colors.orange,
          ),
        ),
        title: Text(
          isArrival ? 'Checked In' : 'Checked Out',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(timeFormat.format(checkIn.timestamp)),
            if (checkIn.isWithinGeofence != null)
              Row(
                children: [
                  Icon(
                    checkIn.isWithinGeofence! ? Icons.check_circle : Icons.warning,
                    size: 16,
                    color: checkIn.isWithinGeofence! ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    checkIn.isWithinGeofence! ? 'Within geofence' : checkIn.distanceText,
                    style: TextStyle(
                      fontSize: 12,
                      color: checkIn.isWithinGeofence! ? Colors.green : Colors.orange,
                    ),
                  ),
                ],
              ),
            if (checkIn.notes != null) ...[
              const SizedBox(height: 4),
              Text(
                checkIn.notes!,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ],
        ),
        trailing: Text(
          'Accuracy:\n${checkIn.accuracy.toStringAsFixed(0)}m',
          style: const TextStyle(fontSize: 11),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
