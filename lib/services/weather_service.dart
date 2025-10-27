import 'dart:convert';
import 'package:http/http.dart' as http;

/// Weather service using OpenWeatherMap API
/// Get your free API key at: https://openweathermap.org/api
class WeatherService {
  // TODO: Replace with your OpenWeatherMap API key
  static const String _apiKey = 'YOUR_API_KEY_HERE';
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5';

  /// Get current weather for a location
  Future<WeatherData> getCurrentWeather({
    required double latitude,
    required double longitude,
  }) async {
    final url = Uri.parse(
      '$_baseUrl/weather?lat=$latitude&lon=$longitude&appid=$_apiKey&units=imperial',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return WeatherData.fromJson(data);
    } else {
      throw Exception('Failed to load weather data: ${response.statusCode}');
    }
  }

  /// Get 5-day forecast (3-hour intervals)
  Future<WeatherForecast> getForecast({
    required double latitude,
    required double longitude,
  }) async {
    final url = Uri.parse(
      '$_baseUrl/forecast?lat=$latitude&lon=$longitude&appid=$_apiKey&units=imperial',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return WeatherForecast.fromJson(data);
    } else {
      throw Exception('Failed to load forecast: ${response.statusCode}');
    }
  }

  /// Get weather alerts (requires OpenWeatherMap One Call API)
  Future<List<WeatherAlert>> getAlerts({
    required double latitude,
    required double longitude,
  }) async {
    // Note: Alerts require One Call API 3.0 (paid) or One Call API 2.5 (free with registration)
    final url = Uri.parse(
      'https://api.openweathermap.org/data/2.5/onecall?lat=$latitude&lon=$longitude&appid=$_apiKey&units=imperial',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['alerts'] != null) {
          return (data['alerts'] as List)
              .map((alert) => WeatherAlert.fromJson(alert))
              .toList();
        }
      }
    } catch (e) {
      // Alerts may not be available on free tier
      print('Weather alerts not available: $e');
    }

    return [];
  }

  /// Check if weather is suitable for construction work
  WorkSuitability checkWorkSuitability(WeatherData weather) {
    // Rain check
    if (weather.rain1h != null && weather.rain1h! > 0.1) {
      return WorkSuitability(
        suitable: false,
        reason: 'Rain expected (${weather.rain1h!.toStringAsFixed(2)}" in last hour)',
        severity: SuitabilitySeverity.high,
      );
    }

    // Snow check
    if (weather.snow1h != null && weather.snow1h! > 0) {
      return WorkSuitability(
        suitable: false,
        reason: 'Snow conditions',
        severity: SuitabilitySeverity.high,
      );
    }

    // Temperature extremes
    if (weather.temperature < 20) {
      return WorkSuitability(
        suitable: false,
        reason: 'Temperature too cold (${weather.temperature.round()}°F)',
        severity: SuitabilitySeverity.medium,
      );
    }

    if (weather.temperature > 105) {
      return WorkSuitability(
        suitable: false,
        reason: 'Extreme heat (${weather.temperature.round()}°F) - Heat safety risk',
        severity: SuitabilitySeverity.high,
      );
    }

    if (weather.temperature > 95) {
      return WorkSuitability(
        suitable: true,
        reason: 'Hot conditions (${weather.temperature.round()}°F) - Take frequent breaks',
        severity: SuitabilitySeverity.low,
      );
    }

    // Wind check
    if (weather.windSpeed > 25) {
      return WorkSuitability(
        suitable: false,
        reason: 'High winds (${weather.windSpeed.round()} mph)',
        severity: SuitabilitySeverity.high,
      );
    }

    if (weather.windSpeed > 15) {
      return WorkSuitability(
        suitable: true,
        reason: 'Moderate winds (${weather.windSpeed.round()} mph) - Use caution',
        severity: SuitabilitySeverity.low,
      );
    }

    // Good conditions
    return WorkSuitability(
      suitable: true,
      reason: 'Good working conditions',
      severity: SuitabilitySeverity.none,
    );
  }
}

/// Current weather data
class WeatherData {
  final String description;
  final String icon;
  final double temperature;
  final double feelsLike;
  final double tempMin;
  final double tempMax;
  final int humidity;
  final double windSpeed;
  final int? windDirection;
  final int? clouds;
  final double? rain1h;
  final double? rain3h;
  final double? snow1h;
  final DateTime timestamp;
  final String cityName;

  WeatherData({
    required this.description,
    required this.icon,
    required this.temperature,
    required this.feelsLike,
    required this.tempMin,
    required this.tempMax,
    required this.humidity,
    required this.windSpeed,
    this.windDirection,
    this.clouds,
    this.rain1h,
    this.rain3h,
    this.snow1h,
    required this.timestamp,
    required this.cityName,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    final weather = json['weather'][0];
    final main = json['main'];
    final wind = json['wind'];

    return WeatherData(
      description: weather['description'] ?? '',
      icon: weather['icon'] ?? '',
      temperature: (main['temp'] as num).toDouble(),
      feelsLike: (main['feels_like'] as num).toDouble(),
      tempMin: (main['temp_min'] as num).toDouble(),
      tempMax: (main['temp_max'] as num).toDouble(),
      humidity: main['humidity'] as int,
      windSpeed: (wind['speed'] as num).toDouble(),
      windDirection: wind['deg'] as int?,
      clouds: json['clouds']?['all'] as int?,
      rain1h: json['rain']?['1h'] as double?,
      rain3h: json['rain']?['3h'] as double?,
      snow1h: json['snow']?['1h'] as double?,
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['dt'] * 1000),
      cityName: json['name'] ?? '',
    );
  }

  String get iconUrl => 'https://openweathermap.org/img/wn/$icon@2x.png';
}

/// Weather forecast (5-day, 3-hour intervals)
class WeatherForecast {
  final List<ForecastItem> items;
  final String cityName;

  WeatherForecast({required this.items, required this.cityName});

  factory WeatherForecast.fromJson(Map<String, dynamic> json) {
    final list = json['list'] as List;
    return WeatherForecast(
      items: list.map((item) => ForecastItem.fromJson(item)).toList(),
      cityName: json['city']['name'] ?? '',
    );
  }

  /// Get daily forecast (one item per day, using noon forecast)
  List<ForecastItem> get dailyForecast {
    final Map<String, ForecastItem> dailyMap = {};

    for (final item in items) {
      final dateKey = '${item.timestamp.year}-${item.timestamp.month}-${item.timestamp.day}';
      
      // Prefer noon forecasts (12:00)
      if (!dailyMap.containsKey(dateKey) || item.timestamp.hour == 12) {
        dailyMap[dateKey] = item;
      }
    }

    return dailyMap.values.toList()..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }
}

class ForecastItem {
  final DateTime timestamp;
  final double temperature;
  final double feelsLike;
  final String description;
  final String icon;
  final int humidity;
  final double windSpeed;
  final double? rain3h;
  final double? snow3h;
  final int clouds;
  final double precipProbability;

  ForecastItem({
    required this.timestamp,
    required this.temperature,
    required this.feelsLike,
    required this.description,
    required this.icon,
    required this.humidity,
    required this.windSpeed,
    this.rain3h,
    this.snow3h,
    required this.clouds,
    required this.precipProbability,
  });

  factory ForecastItem.fromJson(Map<String, dynamic> json) {
    final weather = json['weather'][0];
    final main = json['main'];
    final wind = json['wind'];

    return ForecastItem(
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['dt'] * 1000),
      temperature: (main['temp'] as num).toDouble(),
      feelsLike: (main['feels_like'] as num).toDouble(),
      description: weather['description'] ?? '',
      icon: weather['icon'] ?? '',
      humidity: main['humidity'] as int,
      windSpeed: (wind['speed'] as num).toDouble(),
      rain3h: json['rain']?['3h'] as double?,
      snow3h: json['snow']?['3h'] as double?,
      clouds: json['clouds']['all'] as int,
      precipProbability: (json['pop'] as num).toDouble(),
    );
  }

  String get iconUrl => 'https://openweathermap.org/img/wn/$icon@2x.png';
}

/// Weather alert
class WeatherAlert {
  final String senderName;
  final String event;
  final DateTime start;
  final DateTime end;
  final String description;

  WeatherAlert({
    required this.senderName,
    required this.event,
    required this.start,
    required this.end,
    required this.description,
  });

  factory WeatherAlert.fromJson(Map<String, dynamic> json) {
    return WeatherAlert(
      senderName: json['sender_name'] ?? '',
      event: json['event'] ?? '',
      start: DateTime.fromMillisecondsSinceEpoch(json['start'] * 1000),
      end: DateTime.fromMillisecondsSinceEpoch(json['end'] * 1000),
      description: json['description'] ?? '',
    );
  }
}

/// Work suitability assessment
class WorkSuitability {
  final bool suitable;
  final String reason;
  final SuitabilitySeverity severity;

  WorkSuitability({
    required this.suitable,
    required this.reason,
    required this.severity,
  });
}

enum SuitabilitySeverity {
  none,   // No issues
  low,    // Minor concerns
  medium, // Proceed with caution
  high,   // Unsafe conditions
}
