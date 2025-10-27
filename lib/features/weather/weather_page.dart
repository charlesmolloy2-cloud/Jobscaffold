import 'package:flutter/material.dart';
import '../../services/weather_service.dart';
import 'package:geolocator/geolocator.dart';

class WeatherPage extends StatefulWidget {
  final String projectId;
  final double? projectLatitude;
  final double? projectLongitude;

  const WeatherPage({
    super.key,
    required this.projectId,
    this.projectLatitude,
    this.projectLongitude,
  });

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  final WeatherService _weatherService = WeatherService();
  
  WeatherData? _currentWeather;
  WeatherForecast? _forecast;
  List<WeatherAlert> _alerts = [];
  WorkSuitability? _workSuitability;
  bool _isLoading = true;
  String? _error;

  double? _latitude;
  double? _longitude;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    // Use project location if provided, otherwise get current location
    if (widget.projectLatitude != null && widget.projectLongitude != null) {
      _latitude = widget.projectLatitude;
      _longitude = widget.projectLongitude;
      await _loadWeather();
    } else {
      await _getCurrentLocation();
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }

      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });

      await _loadWeather();
    } catch (e) {
      setState(() {
        _error = 'Unable to get location: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadWeather() async {
    if (_latitude == null || _longitude == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final current = await _weatherService.getCurrentWeather(
        latitude: _latitude!,
        longitude: _longitude!,
      );

      final forecast = await _weatherService.getForecast(
        latitude: _latitude!,
        longitude: _longitude!,
      );

      final alerts = await _weatherService.getAlerts(
        latitude: _latitude!,
        longitude: _longitude!,
      );

      final suitability = _weatherService.checkWorkSuitability(current);

      setState(() {
        _currentWeather = current;
        _forecast = forecast;
        _alerts = alerts;
        _workSuitability = suitability;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weather'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadWeather,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadWeather,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadWeather,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Work Suitability Banner
                      if (_workSuitability != null) _WorkSuitabilityBanner(
                        suitability: _workSuitability!,
                      ),

                      const SizedBox(height: 16),

                      // Weather Alerts
                      if (_alerts.isNotEmpty) ...[
                        _WeatherAlertsSection(alerts: _alerts),
                        const SizedBox(height: 16),
                      ],

                      // Current Weather
                      if (_currentWeather != null) ...[
                        _CurrentWeatherCard(weather: _currentWeather!),
                        const SizedBox(height: 16),
                      ],

                      // 5-Day Forecast
                      if (_forecast != null) ...[
                        const Text(
                          '5-Day Forecast',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        _ForecastList(forecast: _forecast!),
                      ],
                    ],
                  ),
                ),
    );
  }
}

class _WorkSuitabilityBanner extends StatelessWidget {
  final WorkSuitability suitability;

  const _WorkSuitabilityBanner({required this.suitability});

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    IconData icon;

    switch (suitability.severity) {
      case SuitabilitySeverity.high:
        backgroundColor = Colors.red;
        textColor = Colors.white;
        icon = Icons.warning;
        break;
      case SuitabilitySeverity.medium:
        backgroundColor = Colors.orange;
        textColor = Colors.white;
        icon = Icons.info;
        break;
      case SuitabilitySeverity.low:
        backgroundColor = Colors.yellow[700]!;
        textColor = Colors.black;
        icon = Icons.lightbulb_outline;
        break;
      case SuitabilitySeverity.none:
        backgroundColor = Colors.green;
        textColor = Colors.white;
        icon = Icons.check_circle;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  suitability.suitable ? 'SUITABLE FOR WORK' : 'NOT SUITABLE FOR WORK',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  suitability.reason,
                  style: TextStyle(color: textColor, fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WeatherAlertsSection extends StatelessWidget {
  final List<WeatherAlert> alerts;

  const _WeatherAlertsSection({required this.alerts});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text(
              'Weather Alerts',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...alerts.map((alert) => Card(
          color: Colors.red[50],
          child: ListTile(
            leading: const Icon(Icons.warning, color: Colors.red),
            title: Text(
              alert.event,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(alert.description),
            trailing: Text(
              '${alert.start.month}/${alert.start.day}',
              style: const TextStyle(fontSize: 12),
            ),
          ),
        )),
      ],
    );
  }
}

class _CurrentWeatherCard extends StatelessWidget {
  final WeatherData weather;

  const _CurrentWeatherCard({required this.weather});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              weather.cityName,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.network(
                  weather.iconUrl,
                  width: 100,
                  height: 100,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.cloud, size: 100);
                  },
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${weather.temperature.round()}°F',
                      style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Feels like ${weather.feelsLike.round()}°F',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              weather.description.toUpperCase(),
              style: const TextStyle(fontSize: 18, letterSpacing: 1.2),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _WeatherDetail(
                  icon: Icons.thermostat,
                  label: 'High/Low',
                  value: '${weather.tempMax.round()}° / ${weather.tempMin.round()}°',
                ),
                _WeatherDetail(
                  icon: Icons.water_drop,
                  label: 'Humidity',
                  value: '${weather.humidity}%',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _WeatherDetail(
                  icon: Icons.air,
                  label: 'Wind',
                  value: '${weather.windSpeed.round()} mph',
                ),
                _WeatherDetail(
                  icon: Icons.cloud,
                  label: 'Clouds',
                  value: '${weather.clouds ?? 0}%',
                ),
              ],
            ),
            if (weather.rain1h != null) ...[
              const SizedBox(height: 16),
              _WeatherDetail(
                icon: Icons.water,
                label: 'Rain (1h)',
                value: '${weather.rain1h!.toStringAsFixed(2)}"',
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _WeatherDetail extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _WeatherDetail({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _ForecastList extends StatelessWidget {
  final WeatherForecast forecast;

  const _ForecastList({required this.forecast});

  @override
  Widget build(BuildContext context) {
    final dailyForecast = forecast.dailyForecast;

    return Column(
      children: dailyForecast.map((item) {
        final day = _getDayName(item.timestamp);
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Image.network(
              item.iconUrl,
              width: 50,
              height: 50,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.cloud, size: 50);
              },
            ),
            title: Text(day, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(item.description),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${item.temperature.round()}°F',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (item.rain3h != null)
                  Text(
                    '${(item.precipProbability * 100).round()}% rain',
                    style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  String _getDayName(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final itemDate = DateTime(date.year, date.month, date.day);

    if (itemDate == today) return 'Today';
    if (itemDate == today.add(const Duration(days: 1))) return 'Tomorrow';

    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return '${days[date.weekday % 7]} ${date.month}/${date.day}';
  }
}
