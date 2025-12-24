import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class GenrePieChart extends StatelessWidget {
  final Map<String, int> counts;
  final int totalMovies;

  const GenrePieChart({super.key, required this.counts, required this.totalMovies});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text("Genre Distribution", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 20),
        SizedBox(
          height: 250,
          child: PieChart(
            PieChartData(
              sections: _generateSections(),
              centerSpaceRadius: 40,
              sectionsSpace: 2,
            ),
          ),
        ),
        const SizedBox(height: 20),
        ...counts.entries.map((e) => ListTile(
              leading: Icon(Icons.circle, color: _getGenreColor(e.key), size: 12),
              title: Text(e.key, style: const TextStyle(color: Colors.white)),
              trailing: Text("${((e.value / totalMovies) * 100).toStringAsFixed(1)}%", style: const TextStyle(color: Colors.white)),
            )),
      ],
    );
  }

  List<PieChartSectionData> _generateSections() {
    return counts.entries.map((e) {
      return PieChartSectionData(
        color: _getGenreColor(e.key),
        value: e.value.toDouble(),
        title: '${e.value}',
        radius: 50,
        titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();
  }

  Color _getGenreColor(String genre) {
    switch (genre) {
      case 'Action':
        return const Color.fromARGB(255, 86, 10, 5);
      case 'Comedy':
        return const Color.fromARGB(255, 192, 173, 7);
      case 'Sci-Fi':
        return const Color.fromARGB(255, 73, 6, 84);
      case 'Romance':
        return const Color.fromARGB(255, 122, 8, 46);
      case 'Horror':
        return const Color.fromARGB(255, 4, 73, 34);
      case 'Drama':
        return const Color.fromARGB(255, 45, 46, 57);
      case 'Adventure':
        return const Color.fromARGB(255, 144, 85, 2);
      default:
        return const Color.fromARGB(255, 15, 59, 95);
    }
  }
}
