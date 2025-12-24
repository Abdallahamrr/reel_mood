import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../cubits/watchlist_cubit.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/genre_pie_chart.dart';
import '../../core/helpers.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Watchlist Insights'),
        backgroundColor: Colors.black,
        centerTitle: true,
      ),
      body: BlocBuilder<WatchlistCubit, List<Map<String, dynamic>>>(
        builder: (context, watchlist) {
          if (watchlist.isEmpty) {
            return const Center(child: Text("Add movies to see stats!", style: TextStyle(color: Colors.white)));
          }

          final totalMovies = watchlist.length;

          final genreCounts = <String, int>{};
          for (var movie in watchlist) {
            String genre = movie['saved_Genre'] ?? 'Unknown';
            genreCounts[genre] = (genreCounts[genre] ?? 0) + 1;
          }
          final filteredCounts = Map<String, int>.from(genreCounts)..remove('Search');
          final mostWatchedGenre = genreCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Top Stat Cards
                Row(
                  children: [
                    StatCard(title: "Total Movies", value: totalMovies.toString(), icon: Icons.movie),
                    const SizedBox(width: 15),
                    StatCard(title: "Top Genre", value: mostWatchedGenre, icon: Icons.favorite, color: Colors.redAccent),
                  ],
                ),
                const SizedBox(height: 30),

                // Pie Chart
                GenrePieChart(counts: filteredCounts, totalMovies: totalMovies),
              ],
            ),
          );
        },
      ),
    );
  }
}
