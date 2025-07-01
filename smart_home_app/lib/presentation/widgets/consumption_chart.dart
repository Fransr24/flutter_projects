import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class ConsumptionChart extends StatelessWidget {
  final List<dynamic> consumptions;

  const ConsumptionChart({super.key, required this.consumptions});

  @override
  Widget build(BuildContext context) {
    final List<String> fechas =
        consumptions.map((c) => c['fecha'] as String).toList();

    final List<FlSpot> spots = [];
    for (int i = 0; i < consumptions.length; i++) {
      final potencia =
          double.tryParse(consumptions[i]['potencia'].toString()) ?? 0.0;
      spots.add(FlSpot(i.toDouble(), potencia));
    }

    return SizedBox(
      height: 300,
      width: double.infinity,
      child: LineChart(
        LineChartData(
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              belowBarData: BarAreaData(show: true),
              barWidth: 1,
            ),
          ],
          titlesData: FlTitlesData(
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                reservedSize: 32,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() < fechas.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        fechas[value.toInt()].substring(5),
                        style: const TextStyle(fontSize: 12),
                      ),
                    );
                  } else {
                    return const SizedBox.shrink();
                  }
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${value.toInt()}',
                    style: const TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: true),
          minX: 0,
          maxX: (spots.length - 1).toDouble(),
          minY: 0,
        ),
      ),
    );
  }
}
