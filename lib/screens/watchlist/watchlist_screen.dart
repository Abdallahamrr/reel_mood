import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubits/watchlist_cubit.dart';
import '../../widgets/watchlist_movie_tile.dart';

class WatchlistScreen extends StatefulWidget {
  const WatchlistScreen({super.key});

  @override
  State<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen> {
  final Set<int> _expandedMovies = {};

  void _toggleExpanded(int movieId) {
    setState(() {
      if (_expandedMovies.contains(movieId)) {
        _expandedMovies.remove(movieId);
      } else {
        _expandedMovies.add(movieId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('My Watchlist'),
        centerTitle: true,
        backgroundColor: Colors.black,
      ),
      body: BlocBuilder<WatchlistCubit, List<Map<String, dynamic>>>(
        builder: (context, list) {
          if (list.isEmpty) {
            return const Center(
              child: Text(
                'No movies saved yet',
                style: TextStyle(color: Color(0xFF8E8E93), fontSize: 18),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: list.length,
            itemBuilder: (context, i) {
              final movie = list[i];
              final isExpanded = _expandedMovies.contains(movie['id']);
              return WatchlistMovieTile(
                movie: movie,
                isExpanded: isExpanded,
                toggleExpanded: () => _toggleExpanded(movie['id']),
              );
            },
          );
        },
      ),
      floatingActionButton: BlocBuilder<WatchlistCubit, List<Map<String, dynamic>>>(
        builder: (context, list) {
          if (list.isEmpty) return const SizedBox.shrink();
          return Opacity(
            opacity: 0.85,
            child: FloatingActionButton.extended(
              backgroundColor: const Color.fromARGB(255, 159, 7, 14),
              icon: const Icon(Icons.delete_forever),
              label: const Text('Remove All'),
              onPressed: () => _showClearWatchlistDialog(context),
            ),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  void _showClearWatchlistDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.black,
        title: const Text('Clear Watchlist?', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to remove all movies from your watchlist?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              context.read<WatchlistCubit>().clearWatchlist();
              Navigator.pop(context);
            },
            child: const Text('Remove All', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
