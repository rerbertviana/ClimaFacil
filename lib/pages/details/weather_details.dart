import 'package:flutter/material.dart';

class WeatherDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> details;

  const WeatherDetailsScreen({super.key, required this.details});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'DETALHES',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: double.infinity,
                  color: Colors.blue,
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    details['city'],
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildWeatherInfoRow(
                  context,
                  icon: Icons.public,
                  label: "Clima",
                  value: details['weather'],
                ),
                _buildWeatherInfoRow(
                  context,
                  icon: Icons.thermostat,
                  label: "Temperatura",
                  value: "${details['temperature']}°C",
                ),
                _buildWeatherInfoRow(
                  context,
                  icon: Icons.whatshot,
                  label: "Sensação Térmica",
                  value: "${details['feelsLike']}°C",
                ),
                _buildWeatherInfoRow(
                  context,
                  icon: Icons.water_drop,
                  label: "Umidade",
                  value: "${details['humidity']}%",
                ),
                _buildWeatherInfoRow(
                  context,
                  icon: Icons.air,
                  label: "Velocidade do Vento",
                  value: "${details['windSpeed']} km/h",
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWeatherInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.blue,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "$label: $value",
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }
}
